import 'package:flutter/material.dart';
import './ChatPage.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

void main() => runApp(MyMaterialApp());

class MyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) {
          return brightness == Brightness.light
              ? ThemeData(
                  primarySwatch: Colors.lightBlue,
                  backgroundColor: Colors.lightBlue,
                  cardColor: Colors.lightBlue[50],
                  primaryTextTheme: TextTheme(
                    button: TextStyle(
                      color: Colors.lightBlue,
                      decorationColor: Colors.lightBlue,
                    ),
                    subtitle2: TextStyle(
                      color: Colors.lightBlue,
                    ),
                    subtitle1: TextStyle(
                      color: Colors.black,
                    ),
                    headline1: TextStyle(color: Colors.lightBlue[800]),
                  ),
                  bottomAppBarColor: Colors.lightBlue[900],
                  iconTheme: IconThemeData(color: Colors.lightBlue),
                  brightness: brightness,
                )
              : ThemeData(
                  primarySwatch: Colors.blueGrey,
                  backgroundColor: Colors.blueGrey[900],
                  cardColor: Colors.black,
                  primaryTextTheme: TextTheme(
                    button: TextStyle(
                      color: Colors.blueGrey[200],
                      decorationColor: Colors.blueGrey[900],
                    ),
                    subtitle2: TextStyle(
                      color: Colors.white,
                    ),
                    subtitle1: TextStyle(
                      color: Colors.blueGrey[300],
                    ),
                    headline1: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  bottomAppBarColor: Colors.black,
                  iconTheme: IconThemeData(color: Colors.blueGrey[200]),
                  brightness: brightness,
                );
        },
        themedWidgetBuilder: (context, data) => MaterialApp(
              theme: data,
              debugShowCheckedModeBanner: false,
              title: 'ChatApp',
              home: ChatPage(),
            ));
  }
}
