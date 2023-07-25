import 'package:flutter/material.dart';

import 'SE_lib.dart';

class SEDO extends StatefulWidget {
  const SEDO({super.key});

  @override
  State<SEDO> createState() => _SEDOState();
}

class _SEDOState extends State<SEDO> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("SE")),
        body: Container(
            child: SE(
          center: LatLong(21.053651971972496, 105.78010937333369),
          buttonColor: Colors.blue,
        )));
  }
}
