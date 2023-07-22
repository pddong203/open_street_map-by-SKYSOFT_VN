import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:routesapp/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SiderBar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> points = [];
  bool _isSidebarOpen = false;
  bool isExpanded = false;
  List<Marker> markers = [];
  List listOfPoints = []; // Track the expansion state of the button
  LatLng curloca = const LatLng(21.03276589493197, 105.83989509524008);
  List<Marker> tappedMarkers = [];

  // Method to show the "60km" dialog
  void show60KmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(
              color: Colors.blueAccent, // Set the border color
              width: 3.0, // Set the border width
            ),
          ),
          backgroundColor: Colors.white, // Set the background color
          title: const Row(
            children: [
              Icon(
                Icons.speed,
                color: Colors.blueAccent,
              ),
              SizedBox(width: 8),
              Text(
                'Normal Speed!',
                style: TextStyle(
                  color: Colors.blueAccent,
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
                'Minimum Speed: 60km',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your requirement speed minimum of 60 km/h.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

// Method to show the "80km" dialog
  void show80KmDialog() {
    showDialog(
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
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                'Warning Your Speed!',
                style: TextStyle(
                  color: Colors.red,
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
                  color: Colors.redAccent,
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
                'Please slow down to be safe!!!',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  // NỐI 2 ĐIỂM !
  getCoordinates() async {
    // Requesting for openrouteservice api
    var response = await http.get(getRouteUrl(
        "105.7798917,21.0528818", '105.78040038164905, 21.05396746735106'));
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

// set marker có sẵn trên bản đồ !
  @override
  void initState() {
    super.initState();
    markers.addAll([
      Marker(
        point: const LatLng(21.03276589493197, 105.83989509524008),
        width: 80,
        height: 80,
        builder: (context) => IconButton(
          onPressed: () {},
          icon: const Icon(Icons.flag),
          color: Colors.redAccent,
          iconSize: 45,
        ),
      ),
    ]);
  }

// add marker location trên bản đồ khi OnTap
  void handleMapTap(LatLng tappedPoint) {
    setState(() {
      tappedMarkers.add(
        // Add the tapped marker to the tappedMarkers list
        Marker(
          point: tappedPoint,
          width: 80,
          height: 80,
          builder: (context) => IconButton(
            onPressed: () => handleMarkerTap(tappedPoint),
            icon: const Icon(Icons.location_on),
            color: Colors.blue,
            iconSize: 45,
          ),
        ),
      );
    });
  }

  // Method to handle marker tap
  void handleMarkerTap(LatLng tappedPoint) {
    // Show the information about the marker (latitude and longitude)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Log the latitude and longitude of the tapped marker
        log("Tapped Marker - Latitude: ${tappedPoint.latitude}, Longitude: ${tappedPoint.longitude}");

        return AlertDialog(
          title: const Text('Marker Info'),
          content: Text(
            'Latitude: ${tappedPoint.latitude}\nLongitude: ${tappedPoint.longitude}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Remove the tapped marker from the tappedMarkers list
                setState(() {
                  tappedMarkers
                      .removeWhere((marker) => marker.point == tappedPoint);
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Delete Marker',
                style: TextStyle(
                  color: Colors.red,
                  // Change the color of the text here
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Rotate the map around the marker by 90 degrees
  void rotateMapAroundMarker() async {
    double lat = curloca.latitude - mapController.center.latitude;
    double lng = curloca.longitude - mapController.center.longitude;

    Offset offset = Offset(lat, lng);
    log("Rotate around marker: $lat - $lng - ${offset.dx}");

    // Use the mapController.rotateAroundPoint() method to rotate the map
    mapController.rotateAroundPoint(mapController.rotation + 90,
        offset: offset);
  }

// Move the map down and zoom in to level 18
  void offsetDownAndZoomIn() {
    double zoomIncrement = 0.0009;
    route = LatLng(
      mapController.center.latitude + zoomIncrement,
      mapController.center.longitude,
    );
    mapController.move(route, 18); // Set the zoom level to 18
    log("Move: $route");
  }

// Rotate the entire map by 90 degrees
  void rotateMap() {
    mapController.rotate(mapController.rotation + 90);
  }

// Zoom in by decreasing the zoom level by 1
  void zoomIn() {
    mapController.move(mapController.center, mapController.zoom - 1);
  }

// Zoom out by increasing the zoom level by 1
  void zoomOut() {
    mapController.move(mapController.center, mapController.zoom + 1);
  }

  void clearAllMarkers() {
    setState(() {
      tappedMarkers.clear();
    });
  }

  @override
  double? lat;
  double? long;
  String address = "";

  // XIN CẦP QUYỀN TRUY CẬP GPS
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
  }

  MapController mapController = MapController();

  currentLoc() async {
    Position data = await _determinePosition();
    log(data.latitude.toString());
    log(data.longitude.toString());
    setState(() {
      curloca = LatLng(data.latitude, data.longitude);
      points.add(curloca); // Add the current location as a new point
      markers.removeWhere((marker) =>
          marker.builder ==
          navigationMarkerBuilder); // Remove the navigation marker
      markers.add(
        Marker(
          point: curloca,
          width: 80,
          height: 80,
          builder: navigationMarkerBuilder, // Use the navigation marker builder
        ),
      );
      mapController.move(curloca, 18);
    });
  }

  // ignore: prefer_function_declarations_over_variables
  static final navigationMarkerBuilder = (BuildContext context) => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.navigation),
        color: Colors.green,
        iconSize: 45,
      );

  void handleButtonPress() {}

  LatLng route = const LatLng(0, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Image.network(
          'https://tracking.skysoft.vn/img/skysoft_logo.png',
          fit: BoxFit.fitHeight,
          width: 250,
          height: 56,
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            );
          },
        ),
      ),
      drawer: Sidebar(
        onClose: toggleSidebar,
      ),
      // THANH BOTTOM BAR BUTTON BÊN TRONG CUỐI CÙNG
      body: SlidingUpPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
        panelBuilder: (ScrollController sc) => _scrollingList(sc),
        // BẢN ĐỒ VÀ CÁC NÚT
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                  onTap: (tapPosition, point) => handleMapTap(point),
                  zoom: 15,
                  center: const LatLng(21.03283599324495, 105.8398736375679)),
              mapController: mapController,
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),

                // ĐIỂM ĐÁNH DẤU MARKER
                MarkerLayer(
                  rotate: true,
                  markers: [...markers, ...tappedMarkers],
                ),
              ],
            ),

            // NÚT TRÊN ĐẦU MÀN HÌNH-BUTTON TOP OF SCREEN
            Positioned(
              top: 85,
              left: 5,
              child: Row(
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.cyan,
                    onPressed: show60KmDialog, // Call the show60KmDialog method
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.speed),
                        Text("60km"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  FloatingActionButton(
                    backgroundColor: Colors.redAccent,
                    onPressed: show80KmDialog, // Call the show80KmDialog method
                    child: const Column(
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
            Positioned(
              top: 85,
              right: 5,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 300), // Set the duration of the animation
                    height: isExpanded
                        ? 80
                        : 60, // Adjust the width based on the expansion state
                    width: 60,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          isExpanded =
                              !isExpanded; // Toggle the expansion state when pressed
                        });
                      },
                      backgroundColor: Colors.grey,
                      child: isExpanded
                          ? const Icon(
                              Icons.close,
                              color: Colors.white,
                            )
                          : const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(
                        height: 2), // Add some spacing between the buttons
                    SizedBox(
                      width: 40, // Specify the desired width
                      height: 40, // Specify the desired height
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: rotateMapAroundMarker,
                        tooltip: 'Rotate around marker',
                        child: const Icon(Icons.cached),
                      ),
                    ),
                    const SizedBox(
                        height: 8), // Add some spacing between the buttons
                    SizedBox(
                      width: 40, // Specify the desired width
                      height: 40, // Specify the desired height
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: offsetDownAndZoomIn,
                        tooltip: 'Offset down',
                        child: const Icon(Icons.filter_center_focus),
                      ),
                    ),

                    const SizedBox(
                        height: 8), // Add some spacing between the buttons
                    SizedBox(
                      width: 40, // Specify the desired width
                      height: 40, // Specify the desired height
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: rotateMap,
                        tooltip: 'Rotate Map',
                        child: const Icon(Icons.rotate_right),
                      ),
                    ),
                    const SizedBox(
                        height: 8), // Add some spacing between the buttons
                    SizedBox(
                      width: 40, // Specify the desired width
                      height: 40, // Specify the desired height
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: zoomIn,
                        tooltip: 'Zoom In',
                        child:
                            const Icon(Icons.zoom_in_map, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 40, // Specify the desired width
                      height: 40, // Specify the desired height
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: zoomOut,
                        tooltip: 'Zoom Out',
                        child:
                            const Icon(Icons.zoom_out_map, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 40, // Specify the desired width
                      height: 40, // Specify the desired height
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: clearAllMarkers,
                        tooltip: 'Clear Marker onTAP',
                        child: const Icon(Icons.clear_all, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // NÚT NỐI 2 ĐIỂM !
            Positioned(
              top: 480,
              right: 5,
              child: Column(
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.blueAccent,
                    onPressed: getCoordinates,
                    tooltip: 'Polyline',
                    child: const Icon(
                      Icons.route,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // NÚT GET LOCATION HIỆN TẠI
            Positioned(
              top: 480,
              left: 5,
              child: Column(
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: () => {
                      currentLoc(),
                    },
                    tooltip: 'Get Current Location',
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // THANH BOTTOM BAR !
  Widget _scrollingList(ScrollController sc) {
    return Stack(
      children: [
        Positioned(
          child: GestureDetector(
            child: SingleChildScrollView(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 0.1),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Where to ?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.blueAccent),
                        suffixIcon: const Icon(Icons.mic, color: Colors.red),
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
                    child: const ListTile(
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
                    child: const ListTile(
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
                  Container(
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
