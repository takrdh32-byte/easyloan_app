import 'package:flutter/material.dart';

void main() {
  runApp(const CloneLabApp());
}

class CloneLabApp extends StatelessWidget {
  const CloneLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloneLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        primaryColor: const Color(0xFF6C63FF),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('CloneLab Engine Ready', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}