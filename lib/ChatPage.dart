import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as SocketIO;

import 'SingleMessage.dart';

class ChatPage extends StatefulWidget {
  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  SocketIO.Socket socketIO;
  List<dynamic> messages;
  double height, width;
  TextEditingController textController;
  ScrollController scrollController;
  TextEditingController nameFieldController;
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

    messages = List<dynamic>();

    textController = TextEditingController();
    textController.addListener(onTextChange);

    scrollController = ScrollController();
    nameFieldController = TextEditingController();

    textFieldHeight = 60;
    baseTextFieldHeight = 60;
    textFieldFontSize = 18;

    submittingName = false;
    nameValid = true;
    selfName = '';
  }

  bool connected = false;
  void initSocket(context) {
    print('Init Socket...');
    socketIO = SocketIO.io(url);

    socketIO.on('receive_message', (message) {
      setState(() {
        message['source'] = 'other';
        messages.add(message);
        scrollController.animateTo(scrollController.position.maxScrollExtent,
            curve: Curves.ease, duration: Duration(milliseconds: 500));
      });
    });

    socketIO.connect();
    socketIO.on('connect', (_) {
      print('successfully connected!');
      if (!connected) {
        selfName = nameFieldController.text.trim();
        Navigator.of(context).pop();
        connected = true;
      }
    });
    socketIO.on('connect_error', (_) {
      print('an error occured while connecting to the server');
    });
    socketIO.on('error', (_) {
      print('an error occured');
    });
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
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            child: Container(
              constraints: BoxConstraints.expand(height: 280),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      child: Text(
                          'So, what should others call you? Enter a unique name for others to identify you',
                          style: TextStyle(
                            fontSize: 16
                          ),
                          ),
                    ),
                    Container(
                        margin: EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white),
                        child: TextField(
                            controller: nameFieldController,
                            onSubmitted: (value) => submitName(contextParent),
                            enabled: !submittingName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black),
                            decoration: InputDecoration(
                                hintText: 'Unique user name...',
                                counterText: '',
                                errorText: nameValid
                                    ? null
                                    : "Please enter a unique user name for others to identify you"),
                            autofocus: true,
                            maxLines: 1,
                            maxLength: 15)),
                    Container(
                        margin: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100.0),
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                  color: Colors.black54)
                            ]),
                        child: RawMaterialButton(
                          shape: new RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100.0)),
                          onPressed: () => submitName(contextParent),
                          padding: EdgeInsets.only(
                              left: 25, top: 15, right: 25, bottom: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "CONTINUE",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              !submittingName
                                  ? Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Colors.white,
                                    )
                                  : CupertinoActivityIndicator(
                                      animating: true, radius: 15)
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ),
          );
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
            if (textController.text.trim().isNotEmpty) {
              // Resetting animated text field's properties
              numOfLines = 1;

              Map<String, String> messageObj = {
                'source': 'self',
                'name': selfName,
                'message': textController.text.trim()
              };

              //Send the message as JSON data to send_message event
              socketIO.emit('send_message', messageObj);

              //Add the message to the list
              setState(() => messages.add(messageObj));

              textController.text = '';

              Timer(Duration(milliseconds: 100), () {
                //Scrolldown the list to show the latest message
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 600),
                  curve: Curves.ease,
                );
              });
            }
          },
          child: Icon(
            Icons.send,
            size: 25,
            color: Colors.white,
          ),
        ));
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

  final mainScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    scaffoldContext = context;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showingDialog && !connected) {
        Navigator.pop(context);
        showInitDialog(context);
      } else if (!connected) {
        showInitDialog(context);
      }
    });

    return Scaffold(
        key: mainScaffoldKey,
        body: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: <Widget>[buildMessageList()],
              ),
            ),
            buildInputArea()
          ],
        ));
  }
}
