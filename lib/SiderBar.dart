// ignore: file_names
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onClose;
  const Sidebar({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Image.network(
                            'https://play-lh.googleusercontent.com/RIU1oM-b4OadLlOuvhwvuzjw1fVh54gHNq-CQfT2UdOzOG6rajBVqPm3wkkKirxyPr0=w300',
                            // Replace with the correct image path
                            width: 90,
                            // Adjust the width as desired
                            height: 70,
                            fit: BoxFit.contain,
                            // Adjust the height as desired
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text(
                            'Hey SKYSOFT!',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontStyle: FontStyle.normal,
                              // Make the text italic
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextButton(
                          onPressed: () {
                            // Handle the View Profile button tap
                          },
                          child: const Text(
                            'View Profile',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onClose();
                    },
                    child: const Icon(
                      Icons.close,
                      // Replace with your desired close icon
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.map,
              color: Colors.black,
            ), // Add an icon for the "Plan a drive" ListTile
            title: const Text(
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
            leading: const Icon(
              Icons.inbox,
              color: Colors.black,
            ), // Add an icon for the "Inbox" ListTile
            title: const Text(
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
            leading: const Icon(
              Icons.settings,
              color: Colors.black,
            ), // Add an icon for the "Setting" ListTile
            title: const Text(
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
            leading: const Icon(
              Icons.help,
              color: Colors.black,
            ), // Add an icon for the "Help and feedback" ListTile
            title: const Text(
              'Help and feedback',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Make the text bold
              ),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(
              Icons.power_settings_new,
              color: Colors.black,
            ), // Add an icon for the "Plan a drive" ListTile
            title: const Text(
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
