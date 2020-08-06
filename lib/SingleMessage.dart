import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SingleMessage extends StatefulWidget {
  dynamic messageObj;
  Animation<double> entryAnim;

  SingleMessage(this.messageObj, this.entryAnim);

  @override
  SingleMessageState createState() => SingleMessageState();
}

class SingleMessageState extends State<SingleMessage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Animation<Offset> slideAnim;
  AnimationController animController;
  double messageBoxOpacity;

  @override
  void initState() {
    print(widget.messageObj);

    super.initState();
  }

  final Radius borderRadius = Radius.circular(15);
  final Radius borderRadiusZ = Radius.zero;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SlideTransition(
        position: Tween<Offset>(
                begin: widget.messageObj['source'] == 'self'
                    ? Offset(1, 0)
                    : Offset(-1, 0),
                end: Offset.zero)
            .animate(widget.entryAnim),
        child: Container(
          alignment: widget.messageObj['source'] == 'self'
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(top: 10, bottom: 10, right: 50, left: 50),
              decoration: BoxDecoration(
                color: widget.messageObj['source'] == 'self'
                    ? Colors.black12
                    : Colors.black26,
                borderRadius: BorderRadius.only(
                    bottomLeft: widget.messageObj['source'] == 'self'
                        ? borderRadius
                        : borderRadiusZ,
                    bottomRight: widget.messageObj['source'] == 'self'
                        ? borderRadiusZ
                        : borderRadius,
                    topLeft: borderRadius,
                    topRight: borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.messageObj['source'] == 'self'
                        ? 'You'
                        : widget.messageObj['name'],
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Text(
                      widget.messageObj['message'],
                      style: TextStyle(color: Colors.black, fontSize: 15.0),
                    ),
                  )
                ],
              )),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
