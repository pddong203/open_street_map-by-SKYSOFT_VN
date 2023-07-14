import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onClose;
  const Sidebar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade300,
            ),
            child: Container(
              width: 200, // Adjust the width to make the decoration smaller
              height: 100, // Adjust the height to make the decoration smaller
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'HELLO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle the View Profile button tap
                          },
                          child: Text(
                            'View Profile',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: Icon(
              Icons.drive_eta,
              color: Colors.black,
            ), // Add an icon for the "Plan a drive" ListTile
            title: Text(
              'Plan a drive',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Make the text bold
              ),
            ),
            onTap: () {
              // Handle item 1 tap
            },
          ),
          ListTile(
            leading: Icon(
              Icons.inbox,
              color: Colors.black,
            ), // Add an icon for the "Inbox" ListTile
            title: Text(
              'Inbox',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Make the text bold
              ),
            ),
            onTap: () {
              // Handle item 2 tap
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Colors.black,
            ), // Add an icon for the "Setting" ListTile
            title: Text(
              'Setting',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Make the text bold
              ),
            ),
            onTap: () {
              // Handle item 3 tap
            },
          ),
          ListTile(
            leading: Icon(
              Icons.help,
              color: Colors.black,
            ), // Add an icon for the "Help and feedback" ListTile
            title: Text(
              'Help and feedback',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Make the text bold
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
