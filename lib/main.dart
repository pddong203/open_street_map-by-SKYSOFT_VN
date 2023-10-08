import 'package:flutter/material.dart';
import 'package:skysoft/screens/home.dart';
import 'package:skysoft/screens/map_skysoft.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, title: 'SKYSOFT Map', home: Home());
  }
}
