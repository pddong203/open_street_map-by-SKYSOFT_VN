import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';

// ignore: non_constant_identifier_names
Widget ButtonNormal(
  bool isDesktop,
  bool isTablet,
  double vRightDesktop,
  double vRightTablet,
  double vRightMobile,
  bool isTilt,
  Function callBack,
) {
  return Positioned(
      bottom: 110,
      right: isDesktop
          ? vRightDesktop
          : isTablet
              ? vRightTablet
              : vRightMobile,
      child: FloatingActionButton(
        backgroundColor: isTilt ? Colors.blue : Colors.red,
        onPressed: () => callBack(),
        child: Icon(
          isTilt ? Icons.explore : Icons.explore_off,
        ),
      ));
}

// ignore: non_constant_identifier_names
Widget ButtonGlowSos(
  double vTop,
  double vLeft,
  BuildContext context,
  Function callBack,
) {
  return Positioned(
    top: vTop,
    left: vLeft,
    child: AvatarGlow(
      glowColor: Colors.red.shade700,
      endRadius: 90.0,
      duration: const Duration(milliseconds: 2000),
      repeat: true,
      showTwoGlows: true,
      repeatPauseDuration: const Duration(milliseconds: 200),
      child: Material(
        elevation: 8.0,
        shape: const CircleBorder(),
        child: CircleAvatar(
          radius: 28.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        side: const BorderSide(
                          color: Colors.red, // Set the border color
                          width: 3.0, // Set the border width
                        ),
                      ),
                      backgroundColor: Colors.white, // Set the background color
                      title: Row(
                        children: [
                          const Icon(
                            Icons.dangerous,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Warning Your Safe',
                            style: TextStyle(
                              color: Colors.red.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Emergency Situation Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'If you are in danger, turn on SOS mode',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        Builder(
                          builder: (BuildContext context) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      callBack();
                                    },
                                    child: const Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.car_crash, size: 40), // Increase icon size
                    SizedBox(height: 4), // Add spacing
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ignore: non_constant_identifier_names
Widget ButtonGlowWarning(
  double vTop,
  double vLeft,
  BuildContext context,
) {
  return Positioned(
    top: vTop,
    left: vLeft,
    child: AvatarGlow(
      glowColor: Colors.orange.shade700,
      endRadius: 90.0,
      duration: const Duration(milliseconds: 2000),
      repeat: true,
      showTwoGlows: true,
      repeatPauseDuration: const Duration(milliseconds: 200),
      child: Material(
        elevation: 8.0,
        shape: const CircleBorder(),
        child: CircleAvatar(
          radius: 28.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.yellow,
                onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        side: const BorderSide(
                          color: Colors.amber, // Set the border color
                          width: 3.0, // Set the border width
                        ),
                      ),
                      backgroundColor: Colors.white, // Set the background color
                      title: const Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Alert Your Speed!',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Maximum Speed: 80km',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'You drive faster than the required speed',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Please slow down to be safe !!!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.warning, size: 40), // Increase icon size
                    SizedBox(height: 4), // Add spacing
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
