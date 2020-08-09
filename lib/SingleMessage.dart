import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SingleMessage extends StatefulWidget {
  final dynamic messageObj;
  final Animation<double> entryAnim;
  final BuildContext parentContext;

  SingleMessage(this.messageObj, this.entryAnim, this.parentContext);

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
          child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.only(top: 10, bottom: 10, right: 50, left: 50),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      blurRadius: 1,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.lightBlue[200]
                          : Colors.black54,
                      offset: Offset(0, 1))
                ],
                color: widget.messageObj['source'] == 'self'
                    ? (Theme.of(widget.parentContext).brightness ==
                            Brightness.light
                        ? Colors.lightBlue[200]
                        : Colors.blueGrey[600])
                    : (Theme.of(widget.parentContext).brightness ==
                            Brightness.light
                        ? Colors.lightBlue[400]
                        : Colors.blueGrey[700]),
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
                        color: (Theme.of(widget.parentContext).brightness ==
                                Brightness.light
                            ? Colors.black
                            : Colors.white),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Text(
                      widget.messageObj['message'],
                      style: TextStyle(
                          color: Theme.of(widget.parentContext).brightness ==
                                  Brightness.light
                              ? Colors.black87
                              : Colors.white70,
                          fontSize: 15.0),
                    ),
                  )
                ],
              )),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
