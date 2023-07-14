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
                            Image.network(
                              'https://play-lh.googleusercontent.com/RIU1oM-b4OadLlOuvhwvuzjw1fVh54gHNq-CQfT2UdOzOG6rajBVqPm3wkkKirxyPr0=w300', // Replace with the correct image path
                              width: 50, // Adjust the width as desired
                              height: 45,
                              fit: BoxFit
                                  .fitHeight, // Adjust the height as desired
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              'Login here!',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 30,
                                fontStyle:
                                    FontStyle.italic, // Make the text italic
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextButton(
                            onPressed: () {
                              // Handle the View Profile button tap
                            },
                            child: Text(
                              'View Profile',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.route,
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
          ListTile(
            leading: Icon(
              Icons.power_settings_new,
              color: Colors.black,
            ), // Add an icon for the "Plan a drive" ListTile
            title: Text(
              'Sleep mode',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Make the text bold
              ),
            ),
            onTap: () {
              // Handle item 1 tap
            },
          ),
        ],
      ),
    );
  }
}
