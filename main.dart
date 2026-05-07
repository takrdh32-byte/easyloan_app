import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyLoan',
      home: Scaffold(
        appBar: AppBar(title: Text('EasyLoan')),
        body: Center(child: Text('App is working!')),
      ),
    );
  }
}
