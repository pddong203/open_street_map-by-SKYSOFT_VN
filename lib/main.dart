import 'package:flutter/material.dart';
import 'package:skysoft/models/map_screen.dart';
import 'package:skysoft/screens/home.dart';

void main() {
  runApp(const MyApp());
}

// muti languages
// theme

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, title: 'SKYSOFT Map', home: Home());
  }
}
