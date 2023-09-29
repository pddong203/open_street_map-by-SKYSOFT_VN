import 'package:flutter/material.dart';

Future sosDialog(BuildContext context, Function toggleStackVisibility) {
  return showDialog(
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
                        toggleStackVisibility();
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
  );
}

AlertDialog sosDialog1() {
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
                    // toggleStackVisibility();
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
}
