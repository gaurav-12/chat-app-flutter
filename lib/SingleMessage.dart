import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SingleMessage extends StatefulWidget {
  String message;

  SingleMessage(this.message);

  @override
  SingleMessageState createState() => SingleMessageState();
}

class SingleMessageState extends State<SingleMessage>
    with TickerProviderStateMixin {
  Animation<Offset> slideAnim;
  AnimationController animController;
  double messageBoxOpacity;

  @override
  void initState() {
    messageBoxOpacity = 0;
    animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    slideAnim = Tween<Offset>(begin: Offset(2, 0), end: Offset.zero)
        .animate(new CurvedAnimation(parent: animController, curve: Curves.ease));

    WidgetsBinding.instance.addPostFrameCallback((_) => {
          this.setState(() {
            messageBoxOpacity = 1;
            animController.forward();
          })
        });
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        duration: Duration(milliseconds: 800),
        opacity: messageBoxOpacity,
        curve: Curves.ease,
        child: SlideTransition(
            position: slideAnim,
            child: Container(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: window.physicalSize.height * 0.12 + 40),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  widget.message,
                  style: TextStyle(color: Colors.black, fontSize: 15.0),
                ),
              ),
            )));
  }
}
