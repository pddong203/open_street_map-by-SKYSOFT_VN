import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skysoft/widgets/search_bar/search_fullScreen.dart';
import 'package:skysoft/widgets/search_bar/search_home.dart';
import 'package:skysoft/widgets/save_marker_list_popup.dart';

class PanelBar extends StatefulWidget {
  final void Function(LatLng) showMarkerOnMap; // Add this line

  const PanelBar(
      {super.key, required this.showMarkerOnMap}); // Add this constructor

  @override
  State<PanelBar> createState() => _PanelBarState();
}

class _PanelBarState extends State<PanelBar> with TickerProviderStateMixin {
  String homeAddress = "Set once and go";
  String workAddress = "Set once and go";

// NÚT SAVE MARKER
  void showSaveMarkersList() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SavedMarkersList(
          showMarkerOnMap: widget.showMarkerOnMap,
        );
      },
    );
  }

  void showModal(Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return content;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Icon(
                      Icons.horizontal_rule,
                      color: Colors.grey,
                      size: 35, // Adjust the size of the icon as desired
                    ),
                  ),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.1),
                child: GestureDetector(
                  onTap: () async {
                    String? temp = await getHomeAddress();
                    String? temp2 = await getWorkAddress();
                    if (temp != null) {
                      homeAddress = temp;
                    }
                    if (temp2 != null) {
                      workAddress = temp2;
                    }
                    // ignore: use_build_context_synchronously
                    showModal(SearchFullScreen(
                        context,
                        homeAddress,
                        workAddress,
                        widget
                            .showMarkerOnMap)); // Call the function to show the fullscreen container
                  },
                  child: Container(
                    // Add your custom decoration here
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.grey[200],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 15.0),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.blueAccent),
                        SizedBox(
                            width:
                                10), // Add some space between the icon and text
                        Text(
                          'Where to ?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(), // Add a spacer to push the mic icon to the right
                        Icon(Icons.mic, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return SearchHome(true);
                    },
                  ); // Call the function to show the fullscreen container
                  log("Home");
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.home,
                      color: Colors.pink,
                    ),
                    title: const Text(
                      'Home',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      homeAddress,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return SearchHome(true);
                    },
                  ); // Call the function to show the fullscreen container
                  log("Work");
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.work,
                      color: Colors.brown,
                    ),
                    title: const Text(
                      'Work',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      workAddress,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  log("Drive to friend & family");
                  // showSearchFullScreen(); // Call the function to show the fullscreen container
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: const ListTile(
                    leading: Icon(
                      Icons.directions_car,
                      color: Colors.cyan,
                    ),
                    title: Text(
                      'Drive to friend & family',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Search contacts',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  log("Connect calendar");
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: const ListTile(
                    leading: Icon(
                      Icons.calendar_month,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      'Connect calendar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Sync your calendar for route planning',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Lấy vị trí HOME từ SharedPreferences
Future<String?> getHomeAddress() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('home_address');
}

// Lấy vị trí WORK từ SharedPreferences
Future<String?> getWorkAddress() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('work_address');
}
