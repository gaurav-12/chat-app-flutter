import 'dart:async';
import 'dart:ui';
import 'dart:html' as html;

import 'package:ChatApp/NameDialog.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as SocketIO;

import 'SingleMessage.dart';

class ChatPage extends StatefulWidget {
  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  SocketIO.Socket socketIO;
  String newMemberName;
  double notificationBoxOp;
  Animation<Offset> notificationSlideAnim;
  AnimationController notificationAnimController;

  double membersCount;
  double userCountBoxOp;
  Animation<Offset> userCountSlideAnim;
  AnimationController slideAnimController;

  double inputAreaBoxOp;
  Animation<Offset> inputAreaSlideAnim;

  double nightModeSwitchOp;
  Animation<Offset> nightModeSwitchSlideAnim;

  List<dynamic> messages;
  double height, width;
  TextEditingController textController;
  ScrollController scrollController;
  TextEditingController nameFieldController;
  FocusNode messageFocusNode;

  bool sendingMessage;

  BuildContext scaffoldContext;

  double textFieldHeight;
  double textFieldFontSize;
  double baseTextFieldHeight;

  bool submittingName;
  bool nameValid;
  String selfName;

  final GlobalKey<AnimatedListState> messagesListKey =
      GlobalKey<AnimatedListState>();

  final String url = "https://chat-app-flutter-node.herokuapp.com";

  @override
  void initState() {
    super.initState();

    socketIO = SocketIO.io(url, <String, dynamic>{
      'autoConnect': false,
    });
    newMemberName = '';
    membersCount = 0;
    notificationBoxOp = 0;
    notificationAnimController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    notificationSlideAnim =
        Tween<Offset>(begin: Offset(0, -2), end: Offset.zero).animate(
            new CurvedAnimation(
                parent: notificationAnimController, curve: Curves.easeInOut));

    slideAnimController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));

    userCountBoxOp = 0;
    userCountSlideAnim = Tween<Offset>(begin: Offset(-2, 0), end: Offset.zero)
        .animate(new CurvedAnimation(
            parent: slideAnimController, curve: Curves.easeInOut));

    inputAreaBoxOp = 0;
    inputAreaSlideAnim = Tween<Offset>(begin: Offset(0, 2), end: Offset.zero)
        .animate(new CurvedAnimation(
            parent: slideAnimController, curve: Curves.easeInOut));

    nightModeSwitchOp = 0;
    nightModeSwitchSlideAnim =
        Tween<Offset>(begin: Offset(2, 0), end: Offset.zero).animate(
            new CurvedAnimation(
                parent: slideAnimController, curve: Curves.easeInOut));

    messages = List<dynamic>();

    textController = TextEditingController();
    textController.addListener(onTextChange);
    messageFocusNode = FocusNode();

    sendingMessage = false;

    scrollController = ScrollController();
    nameFieldController = TextEditingController();

    textFieldHeight = 60;
    baseTextFieldHeight = 60;
    textFieldFontSize = 18;

    submittingName = false;
    nameValid = true;
    selfName = '';

    html.window.onBeforeUnload.listen((onData) {
      socketIO.emitWithAck('count_change', {'name': selfName}, ack: (ackObj) {
        if (ackObj['success']) socketIO.disconnect();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showInitDialog(scaffoldContext);

      // Test Notification box
      // notificationAnimController.forward();
      // setState(() {
      //   notificationBoxOp = 1;
      //   newMemberName = 'Some Unique User Name';
      // });
    });
  }

  bool connected = false;
  Timer notificationTimer;
  void initSocket(name) {
    socketIO.on('receive_message', (message) {
      message['source'] = 'other';
      messages.insert(0, message);
      messagesListKey.currentState
          .insertItem(0, duration: Duration(milliseconds: 500));

      Timer(Duration(milliseconds: 100), () {
        //Scrolldown the list to show the latest message
        scrollController.animateTo(
          scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      });
    });

    socketIO.on('new_member', (message) {
      print("New member added: " + message['name']);

      setState(() {
        notificationBoxOp = 1;
        newMemberName = message['name'];
      });
      notificationAnimController.forward();

      if (notificationTimer != null) notificationTimer.cancel();
      notificationTimer = Timer(Duration(seconds: 5), () {
        notificationAnimController.reverse();
        setState(() {
          notificationBoxOp = 0;
        });
      });
    });
    socketIO.on('count_change', (count) {
      setState(() {
        membersCount = count;
      });
    });

    socketIO.on('connect', (_) {
      print('Successfully connected!');
      if (!connected) {
        selfName = name.trim();
        Navigator.of(scaffoldContext).pop();
        connected = true;

        socketIO.emitWithAck('new_member', {'name': selfName},
            ack: (usersCount) {
          print('Users connected: ' + usersCount.toString());

          slideAnimController.forward();
          setState(() {
            membersCount = usersCount;
            userCountBoxOp = 1;
            inputAreaBoxOp = 1;
            nightModeSwitchOp = 1;
          });
        });
      }
    });

    socketIO.on('connect_error', (_) {
      print('An error occured while connecting to the server');
    });
    socketIO.on('disconnect', (_) {
      print('Disconnected!');
    });

    socketIO.on('error', (_) {
      print('An error occured');
    });

    print('Init Socket...');
    socketIO.connect();
  }

  Timer timer;
  void submitName(context) {
    print('Submitting name...');
    if (nameFieldController.text.trim().isEmpty) {
      print('Invalid name');

      setState(() {
        nameValid = false;
      });

      if (timer != null) timer.cancel();
      timer = Timer(Duration(seconds: 3), () {
        setState(() {
          nameValid = true;
        });
      });
    } else {
      print('Valid name');
      if (timer != null) timer.cancel();
      setState(() {
        submittingName = true;
        nameValid = true;
      });

      initSocket(context);
    }
  }

  dynamic showInitDialog(contextParent) {
    return showCupertinoDialog(
        barrierDismissible: false,
        context: contextParent,
        builder: (BuildContext context) {
          return NameDialog(initSocket, contextParent);
        }).then((val) {
      if (!connected) {
        print('Dialog closed without connecting...reopening now...');
        showInitDialog(contextParent);
      }
    });
  }

  int numOfLines = 1;
  final int maxLines = 9;
  void onTextChange() {
    var value = textController.text;
    var newNumLines = '\n'.allMatches(value).length;
    if (newNumLines != numOfLines) {
      setState(() {
        if (newNumLines > maxLines) {
          textFieldHeight =
              baseTextFieldHeight + (textFieldFontSize * maxLines);
          numOfLines = maxLines;
        } else {
          textFieldHeight =
              baseTextFieldHeight + (textFieldFontSize * newNumLines);
          numOfLines = newNumLines;
        }
      });
    }
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    socketIO.disconnect();
    super.dispose();
  }

  Widget buildMessageList() {
    return Container(
      height: height,
      width: width,
      child: AnimatedList(
        key: messagesListKey,
        physics: BouncingScrollPhysics(),
        reverse: true,
        padding: EdgeInsets.only(top: 100, bottom: 110),
        controller: scrollController,
        initialItemCount: messages.length,
        itemBuilder:
            (BuildContext context, int index, Animation<double> animation) {
          return SingleMessage(messages[index], animation, scaffoldContext);
        },
      ),
    );
  }

  Widget buildChatInput() {
    return Expanded(
        child: AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
      height: textFieldHeight,
      padding: EdgeInsets.symmetric(horizontal: 30),
      margin: EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Theme.of(scaffoldContext).brightness == Brightness.light
              ? Colors.white
              : Colors.blueGrey[900],
          boxShadow: [
            BoxShadow(
                blurRadius: 3,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.lightBlue[200]
                    : Colors.black54,
                offset: Offset(0, 1))
          ]),
      child: Align(
          alignment: Alignment.centerLeft,
          child: TextField(
            scrollPhysics: BouncingScrollPhysics(),
            focusNode: messageFocusNode,
            maxLines: null,
            cursorColor:
                Theme.of(scaffoldContext).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white70,
            style: TextStyle(
                color: Theme.of(scaffoldContext).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white70,
                fontSize: textFieldFontSize),
            decoration: InputDecoration.collapsed(
              hintStyle: TextStyle(
                  color:
                      Theme.of(scaffoldContext).brightness == Brightness.light
                          ? Colors.black45
                          : Colors.white30),
              hintText: 'Some message here...',
            ),
            controller: textController,
          )),
    ));
  }

  Widget buildSendButton() {
    return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: 60,
        width: 60,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(scaffoldContext).brightness == Brightness.light
                ? Colors.lightBlue
                : Colors.blueGrey[900],
            boxShadow: [
              BoxShadow(
                  blurRadius: 3,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.lightBlue[200]
                      : Colors.black54,
                  offset: Offset(0, 1))
            ]),
        child: RawMaterialButton(
            shape: new CircleBorder(),
            onPressed: () {
              //Check if the textfield is not empty and it does not contain only whitespaces
              if (!sendingMessage && textController.text.trim().isNotEmpty) {
                messageFocusNode.unfocus();
                setState(() {
                  sendingMessage = true;
                });

                Map<String, String> messageObj = {
                  'source': 'self',
                  'name': selfName,
                  'message': textController.text.trim()
                };

                //Send the message as JSON data to send_message event
                socketIO.emitWithAck('send_message', messageObj, ack: (ackObj) {
                  //Add the message to the list
                  messages.insert(0, messageObj);
                  messagesListKey.currentState
                      .insertItem(0, duration: Duration(milliseconds: 500));
                  setState(() {
                    sendingMessage = false;
                  });

                  // Resetting animated text field's properties
                  numOfLines = 1;
                  textController.text = '';

                  Timer(Duration(milliseconds: 100), () {
                    //Scrolldown the list to show the latest message
                    scrollController.animateTo(
                      scrollController.position.minScrollExtent,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  });
                });
              }
            },
            child: !sendingMessage
                ? Icon(
                    Icons.send,
                    size: 25,
                    color:
                        Theme.of(scaffoldContext).brightness == Brightness.light
                            ? Colors.white
                            : Colors.white70,
                  )
                : Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        backgroundColor: Theme.of(scaffoldContext).brightness ==
                                Brightness.light
                            ? Colors.lightBlue
                            : Colors.blueGrey[900],
                        strokeWidth: 2.0,
                        valueColor: new AlwaysStoppedAnimation(
                            Theme.of(scaffoldContext).brightness ==
                                    Brightness.light
                                ? Colors.white
                                : Colors.white70),
                      ),
                    ),
                  )));
  }

  Widget buildInputArea() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedOpacity(
            duration: Duration(milliseconds: 250),
            opacity: inputAreaBoxOp,
            child: SlideTransition(
                position: inputAreaSlideAnim,
                child: Container(
                  padding: EdgeInsets.only(left: 20, bottom: 20, right: 20),
                  width: width,
                  child: Row(
                    children: <Widget>[
                      buildChatInput(),
                      buildSendButton(),
                    ],
                  ),
                ))));
  }

  Widget buildNotificationBox() {
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
          duration: Duration(milliseconds: 250),
          opacity: notificationBoxOp,
          child: SlideTransition(
            position: notificationSlideAnim,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 500,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.lightBlue
                      : Colors.blueGrey[900],
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 3,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.lightBlue[200]
                            : Colors.black54,
                        offset: Offset(0, 1))
                  ]),
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    child: Icon(Icons.notifications_active,
                        color: Theme.of(scaffoldContext).brightness ==
                                Brightness.light
                            ? Colors.white
                            : Colors.white70,
                        size: 35),
                    padding: EdgeInsets.only(right: 30),
                  ),
                  Flexible(
                    child: RichText(
                        text: TextSpan(
                            text:
                                "Welcome another Rick to the Citadel with an interesting name, ",
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(scaffoldContext).brightness ==
                                      Brightness.light
                                  ? Colors.white70
                                  : Colors.white54,
                            ),
                            children: [
                          TextSpan(
                            text: newMemberName,
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(scaffoldContext).brightness ==
                                        Brightness.light
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.bold),
                          )
                        ])),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30),
                    child: SizedBox(
                        height: 40,
                        width: 40,
                        child: MaterialButton(
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: CircleBorder(),
                          color: Colors.white12,
                          onPressed: () {
                            notificationAnimController.reverse();
                            setState(() {
                              notificationBoxOp = 0;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            color: Theme.of(scaffoldContext).brightness ==
                                    Brightness.light
                                ? Colors.white
                                : Colors.white70,
                            size: 20,
                          ),
                        )),
                  )
                ],
              ),
            ),
          )),
    );
  }

  Widget buildUserCountBox() {
    return Align(
        alignment: Alignment.topLeft,
        child: AnimatedOpacity(
            duration: Duration(milliseconds: 250),
            opacity: userCountBoxOp,
            child: SlideTransition(
                position: userCountSlideAnim,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 90,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.lightBlue
                          : Colors.blueGrey[900],
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 3,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.lightBlue[200]
                                    : Colors.black54,
                            offset: Offset(0, 1))
                      ]),
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  margin: EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        child: Icon(Icons.group,
                            color: Theme.of(scaffoldContext).brightness ==
                                    Brightness.light
                                ? Colors.white
                                : Colors.white70,
                            size: 25),
                        padding: EdgeInsets.only(right: 20),
                      ),
                      Text(
                        membersCount.toString(),
                        style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(scaffoldContext).brightness ==
                                    Brightness.light
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ))));
  }

  Widget buildNightModeSwitch() {
    return Align(
        alignment: Alignment.topRight,
        child: AnimatedOpacity(
            duration: Duration(milliseconds: 250),
            opacity: nightModeSwitchOp,
            child: SlideTransition(
                position: nightModeSwitchSlideAnim,
                child: GestureDetector(
                    onTap: () {
                      DynamicTheme.of(context).setBrightness(
                          Theme.of(context).brightness == Brightness.dark
                              ? Brightness.light
                              : Brightness.dark);
                    },
                    child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 90,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.lightBlue
                                    : Colors.blueGrey[900],
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 3,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.lightBlue[200]
                                      : Colors.black54,
                                  offset: Offset(0, 1))
                            ]),
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        margin: EdgeInsets.all(15),
                        child: Wrap(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedAlign(
                                  alignment:
                                      Theme.of(scaffoldContext).brightness ==
                                              Brightness.light
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                  duration: Duration(milliseconds: 1000),
                                  curve: Curves.easeOutQuart,
                                  child: Icon(
                                    Theme.of(scaffoldContext).brightness ==
                                            Brightness.light
                                        ? Icons.cloud
                                        : Icons.star,
                                    size: 20,
                                    color:
                                        Theme.of(scaffoldContext).brightness ==
                                                Brightness.light
                                            ? Colors.white24
                                            : Colors.blueGrey[800],
                                  ),
                                ),
                                AnimatedAlign(
                                  alignment:
                                      Theme.of(scaffoldContext).brightness ==
                                              Brightness.light
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.bounceOut,
                                  child: Icon(
                                    Theme.of(scaffoldContext).brightness ==
                                            Brightness.light
                                        ? Icons.brightness_7
                                        : Icons.brightness_3,
                                    size: 25,
                                    color:
                                        Theme.of(scaffoldContext).brightness ==
                                                Brightness.light
                                            ? Colors.white
                                            : Colors.lightBlue[50],
                                  ),
                                )
                              ],
                            )
                          ],
                        ))))));
  }

  final mainScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    scaffoldContext = context;

    return Scaffold(
        key: mainScaffoldKey,
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.lightBlue[100]
                        : Colors.blueGrey[900],
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.lightBlue[50]
                        : Colors.blueGrey[800]
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[buildMessageList()],
                  ),
                ),
                buildInputArea(),
                buildUserCountBox(),
                buildNightModeSwitch(),
                buildNotificationBox()
              ],
            )));
  }
}
