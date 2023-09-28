import 'package:flutter/material.dart';

void warningDialog(BuildContext context) {
  showDialog(
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
  );
}
