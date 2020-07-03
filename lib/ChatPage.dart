import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as SocketIO;

import 'SingleMessage.dart';

class ChatPage extends StatefulWidget {
  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  SocketIO.Socket socketIO;
  List<String> messages;
  double height, width;
  TextEditingController textController;
  ScrollController scrollController;

  double textFieldHeight;
  double textFieldFontSize;
  double baseTextFieldHeight;

  final String url = "https://chat-app-flutter-node.herokuapp.com";

  @override
  void initState() {
    messages = List<String>();

    textController = TextEditingController();
    textController.addListener(onTextChange);

    scrollController = ScrollController();

    textFieldHeight = window.physicalSize.height * 0.12;
    baseTextFieldHeight = window.physicalSize.height * 0.12;
    textFieldFontSize = 18;

    socketIO = SocketIO.io(url);

    socketIO.on('receive_message', (message) {
      setState(() {
        messages.add(message);
        scrollController.animateTo(
            scrollController.position.maxScrollExtent +
                window.physicalSize.height * 0.16,
            curve: Curves.ease,
            duration: Duration(milliseconds: 500));
      });
    });

    socketIO.connect();

    super.initState();
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
        padding:
            EdgeInsets.symmetric(vertical: window.physicalSize.height * 0.16),
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
        height: window.physicalSize.height * 0.13,
        width: window.physicalSize.height * 0.13,
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

              //Send the message as JSON data to send_message event
              socketIO.emit('send_message', textController.text.trim());

              //Add the message to the list
              setState(() => messages.add(textController.text.trim()));

              textController.text = '';

              Timer(Duration(milliseconds: 100), () {
                //Scrolldown the list to show the latest message
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent +
                      window.physicalSize.height * 0.16,
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

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
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
