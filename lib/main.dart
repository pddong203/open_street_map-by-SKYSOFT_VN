import 'package:flutter/material.dart';
import 'package:skysoft/map_screen.dart';

import 'navigation_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Skysoft Map',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MapScreen());
  }
}
