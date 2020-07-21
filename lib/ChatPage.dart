import 'dart:async';
import 'dart:ui';

import 'package:ChatApp/NameDialog.dart';
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
  Animation<Offset> slideAnim;
  AnimationController animController;

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

  final String url = "https://chat-app-flutter-node.herokuapp.com";

  @override
  void initState() {
    super.initState();

    socketIO = SocketIO.io(url, <String, dynamic>{
      'autoConnect': false,
    });
    newMemberName = '';
    notificationBoxOp = 0;
    animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    slideAnim = Tween<Offset>(begin: Offset(0, -100), end: Offset.zero).animate(
        new CurvedAnimation(parent: animController, curve: Curves.easeInOut));

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showInitDialog(scaffoldContext);
    });
  }

  bool connected = false;
  Timer notificationTimer;
  void initSocket(name) {
    socketIO.on('receive_message', (message) {
      setState(() {
        message['source'] = 'other';
        messages.add(message);
        scrollController.animateTo(scrollController.position.maxScrollExtent,
            curve: Curves.ease, duration: Duration(milliseconds: 500));
      });
    });

    socketIO.on('new_member', (message) {
      print("New member added: " + message['name']);

      animController.forward();
      setState(() {
        notificationBoxOp = 1;
        newMemberName = message['name'];
      });

      if (notificationTimer != null) notificationTimer.cancel();
      notificationTimer = Timer(Duration(seconds: 5), () {
        animController.reverse();
        setState(() {
          notificationBoxOp = 0;
        });
      });
    });

    socketIO.on('connect', (_) {
      print('Successfully connected!');
      if (!connected) {
        selfName = name.trim();
        Navigator.of(scaffoldContext).pop();
        connected = true;

        socketIO.emit('new_member', {'name': selfName});
      }
    });

    socketIO.on('connect_error', (_) {
      print('An error occured while connecting to the server');
    });
    socketIO.on('error', (_) {
      print('an error occured');
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

  bool showingDialog = false;
  dynamic showInitDialog(contextParent) {
    showingDialog = true;

    return showCupertinoDialog(
        barrierDismissible: false,
        context: contextParent,
        builder: (BuildContext context) {
          return NameDialog(initSocket);
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

  Widget buildSingleMessage(int index) {
    return SingleMessage(messages[index]);
  }

  Widget buildMessageList() {
    return Container(
      height: height,
      width: width,
      child: ListView.builder(
        reverse: true,
        padding: EdgeInsets.only(top: 100, bottom: 110),
        controller: scrollController,
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          return buildSingleMessage(index);
        },
      ),
    );
  }

  Widget buildChatInput() {
    return Expanded(
        child: AnimatedContainer(
      duration: Duration(milliseconds: 250),
      curve: Curves.ease,
      height: textFieldHeight,
      padding: EdgeInsets.symmetric(horizontal: 30),
      margin: EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
                blurRadius: 5, offset: Offset(0, 2), color: Colors.black54)
          ]),
      child: Align(
          alignment: Alignment.centerLeft,
          child: TextField(
            focusNode: messageFocusNode,
            maxLines: null,
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white, fontSize: textFieldFontSize),
            decoration: InputDecoration.collapsed(
              hintStyle: TextStyle(color: Colors.white30),
              hintText: 'Some message here...',
            ),
            controller: textController,
          )),
    ));
  }

  Widget buildSendButton() {
    return Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                  blurRadius: 5, offset: Offset(0, 2), color: Colors.black54)
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
                  print(ackObj);

                  //Add the message to the list
                  setState(() {
                    messages.add(messageObj);
                    sendingMessage = false;
                  });

                  // Resetting animated text field's properties
                  numOfLines = 1;
                  textController.text = '';

                  Timer(Duration(milliseconds: 100), () {
                    //Scrolldown the list to show the latest message
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 600),
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
                    color: Colors.white,
                  )
                : Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.black,
                        strokeWidth: 2.0,
                        valueColor: new AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  )));
  }

  Widget buildInputArea() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.only(left: 20, bottom: 20, right: 20),
          width: width,
          child: Row(
            children: <Widget>[
              buildChatInput(),
              buildSendButton(),
            ],
          ),
        ));
  }

  Widget buildNotificationBox() {
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
          duration: Duration(milliseconds: 250),
          opacity: notificationBoxOp,
          child: SlideTransition(
            position: slideAnim,
            child: Container(
              width: 500,
              height: 80,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(0, 1))
                  ]),
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    child: Icon(Icons.notifications_active,
                        color: Colors.white, size: 35),
                    padding: EdgeInsets.only(right: 30),
                  ),
                  Flexible(
                    child: RichText(
                        text: TextSpan(
                            text: "Welcome another Rick to the Citadel with an interesting name, ",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            children: [
                          TextSpan(
                            text: newMemberName,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
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
                          padding: EdgeInsets.zero,
                          shape: CircleBorder(),
                          color: Colors.white12,
                          onPressed: () {
                            animController.reverse();
                            setState(() {
                              notificationBoxOp = 0;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
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

  final mainScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    scaffoldContext = context;

    return Scaffold(
        key: mainScaffoldKey,
        body: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: <Widget>[buildMessageList()],
              ),
            ),
            buildInputArea(),
            buildNotificationBox()
          ],
        ));
  }
}
