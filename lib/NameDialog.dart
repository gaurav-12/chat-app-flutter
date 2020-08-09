import 'dart:async';
import 'dart:ui';

import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NameDialog extends StatefulWidget {
  final InitSocketCallback initSocket;
  final BuildContext parentContext;
  NameDialog(this.initSocket, this.parentContext);

  @override
  NameDialogState createState() => new NameDialogState();
}

class NameDialogState extends State<NameDialog> {
  bool submittingName;
  bool nameValid;
  TextEditingController nameFieldController;

  @override
  void initState() {
    super.initState();

    nameFieldController = TextEditingController();
    submittingName = false;
    nameValid = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DynamicTheme.of(widget.parentContext).loadBrightness().then((v) {
        setState(() {});
      });
    });
  }

  Timer timer;
  void submitName() {
    if (!submittingName) {
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

        widget.initSocket(nameFieldController.text.trim());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        color: Theme.of(widget.parentContext).brightness == Brightness.light
            ? Colors.white
            : Colors.blueGrey[800],
        constraints: BoxConstraints.expand(height: 350, width: 500),
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
                    fontSize: 16,
                    color: Theme.of(widget.parentContext).brightness ==
                            Brightness.light
                        ? Colors.black87
                        : Colors.white70,
                  ),
                ),
              ),
              Container(
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.transparent),
                  child: TextField(
                      textInputAction: TextInputAction.done,
                      controller: nameFieldController,
                      onSubmitted: (value) => submitName(),
                      enabled: !submittingName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(widget.parentContext).brightness ==
                                Brightness.light
                            ? Colors.lightBlue
                            : Colors.white70,
                      ),
                      decoration: InputDecoration(
                          hintText: 'Unique user name...',
                          counterText: '',
                          errorStyle: TextStyle(
                            color: Theme.of(widget.parentContext).brightness ==
                                    Brightness.light
                                ? Colors.red[700]
                                : Colors.red[200],
                          ),
                          errorText: nameValid
                              ? null
                              : "Please enter a unique user name for others to identify you"),
                      maxLines: 1,
                      maxLength: 15)),
              AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Theme.of(widget.parentContext).brightness ==
                              Brightness.light
                          ? Colors.lightBlue
                          : Colors.blueGrey[900],
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 3,
                            color: Theme.of(widget.parentContext).brightness ==
                                    Brightness.light
                                ? Colors.lightBlue[200]
                                : Colors.black54,
                            offset: Offset(0, 1))
                      ]),
                  child: RawMaterialButton(
                    shape: new RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0)),
                    onPressed: () => submitName(),
                    padding: EdgeInsets.only(
                        left: 25, top: 15, right: 25, bottom: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          submittingName ? "SAVING..." : "CONTINUE",
                          style: TextStyle(
                              color: submittingName
                                  ? Colors.white38
                                  : Colors.white,
                              fontSize: 18),
                        ),
                        !submittingName
                            ? Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.white,
                              )
                            : Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    backgroundColor:
                                        Theme.of(widget.parentContext)
                                                    .brightness ==
                                                Brightness.light
                                            ? Colors.lightBlue
                                            : Colors.blueGrey[900],
                                    strokeWidth: 2.0,
                                    valueColor: new AlwaysStoppedAnimation(
                                        Colors.white38),
                                  ),
                                ),
                              )
                      ],
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}

typedef InitSocketCallback = void Function(String name);
