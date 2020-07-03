import 'package:flutter/material.dart';
import './ChatPage.dart';

void main() => runApp(MyMaterialApp());

class MyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatPage(),
    );
  }
}