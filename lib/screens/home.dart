import 'package:flutter/material.dart';
import 'package:skysoft/screens/map_screen.dart';

import 'package:skysoft/screens/map_skysoft.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return const MapScreen();
  }
}
