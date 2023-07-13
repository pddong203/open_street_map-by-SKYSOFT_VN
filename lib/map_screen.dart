import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:routesapp/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> listOfPoints = [];
  List<LatLng> points = [];
  int _currentIndex = 0;
  bool _isBottomSheetExpanded = false;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  getCoordinates() async {
    var response = await http.get(getRouteUrl(
        "21.053559580851587, 105.78037866772688",
        '21.053564062843243, 105.78005271591009'));
    setState(() {
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        listOfPoints = data['features'][0]['geometry']['coordinates'];
        points = listOfPoints
            .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
            .toList();
      }
    });
  }

  void handleButtonPress() {
    // Perform the desired action when the button is pressed
  }

  void toggleBottomSheet() {
    setState(() {
      _isBottomSheetExpanded = !_isBottomSheetExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              zoom: 15,
              center: LatLng(21.05331612310779, 105.7799679029661),
              rotation: 90.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'dev.fleaflet.flutter_map.example',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(21.05331612310779, 105.7799679029661),
                    width: 80,
                    height: 80,
                    builder: (context) => IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation),
                      color: Colors.green,
                      iconSize: 45,
                    ),
                  ),
                  Marker(
                    point: LatLng(21.05481566372693, 105.78049783495892),
                    width: 80,
                    height: 80,
                    builder: (context) => IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.location_on),
                      color: Colors.lightBlue,
                      iconSize: 45,
                    ),
                  ),
                ],
              ),
              PolylineLayer(
                polylineCulling: false,
                polylines: [
                  Polyline(points: points, color: Colors.black, strokeWidth: 5),
                ],
              ),
            ],
          ),
          // BUTTON TOP OF SCREEN
          Positioned(
            top: 30,
            left: 10,
            child: Row(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.cyan,
                  onPressed: handleButtonPress,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.speed),
                      Text("60km"),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: handleButtonPress,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.warning),
                      Text("80km"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // BUTTON UNDER SCREEN
          Positioned(
            top: 400,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: () => getCoordinates(),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  onPressed: handleButtonPress,
                  child: const Icon(
                    Icons.shortcut,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: toggleBottomSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: _isBottomSheetExpanded ? 350 : 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.0)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        child: ListTile(
                          leading: Icon(Icons.unfold_more),
                          title: Text(
                            'FIND THE PLACE HERE !!!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.unfold_more),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 0.1),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Where to ?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.blueAccent),
                            suffixIcon: Icon(Icons.mic, color: Colors.red),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.home,
                            color: Colors.pink,
                          ),
                          title: Text(
                            'Home',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            'Set once and go',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.work,
                            color: Colors.brown,
                          ),
                          title: Text(
                            'Work',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            'Set once and go',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: ListTile(
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
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: ListTile(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
