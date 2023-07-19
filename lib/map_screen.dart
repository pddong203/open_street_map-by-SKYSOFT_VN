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
  int _currentIndex = 0;
  bool _isBottomSheetExpanded = false;
  bool _isSidebarOpen = false;
  bool isExpanded = false;
  List<Marker> markers = [];
  List listOfPoints = []; // Track the expansion state of the button
  LatLng curloca = new LatLng(21.03276589493197, 105.83989509524008);

  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

// NỐI 2 ĐIỂM !
  getCoordinates() async {
    // Requesting for openrouteservice api
    var response = await http
        .get(getRouteUrl("105.77977,21.05229", '105.79954,21.000041'));
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

  // @override
  // void initState() {
  //   super.initState();
  //   markers = []; // Clear existing markers
  //   markers.add(
  //     Marker(
  //       point: LatLng(21.03276589493197, 105.83989509524008),
  //       width: 80,
  //       height: 80,
  //       builder: (context) => IconButton(
  //         onPressed: () {},
  //         icon: const Icon(Icons.flag),
  //         color: Colors.redAccent,
  //         iconSize: 45,
  //       ),
  //     ),
  //   );
  // }

  @override
  void initState() {
    super.initState();
    markers.addAll([
      Marker(
        point: LatLng(21.03276589493197, 105.83989509524008),
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
      mapController.move(curloca, 18.0);
    });
  }

  static final navigationMarkerBuilder = (BuildContext context) => IconButton(
        onPressed: () {},
        icon: const Icon(Icons.navigation),
        color: Colors.green,
        iconSize: 45,
      );

  void handleButtonPress() {
    // Perform the desired action when the button is pressed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //THANH TOP BAR
      appBar: AppBar(
        backgroundColor: Colors.grey.shade700,
        title: Image.network(
          'https://tracking.skysoft.vn/img/skysoft_logo.png', // Replace with the correct image path
          fit: BoxFit.fitHeight, // Adjust the fit according to your needs
          width: 250, // Adjust the width as desired
          height: 45, // Adjust the height as desired
        ),
      ),
      drawer: Sidebar(onClose: toggleSidebar),
      // THANH BOTTOM BAR BUTTON BÊN TRONG CUỐI CÙNG
      body: SlidingUpPanel(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        panelBuilder: (ScrollController sc) => _scrollingList(sc),
        // BẢN ĐỒ VÀ CÁC NÚT
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                  zoom: 15,
                  center: LatLng(21.03283599324495, 105.8398736375679)),
              mapController: mapController,
              nonRotatedChildren: const [],
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),

                // ĐIỂM ĐÁNH DẤU MARKER
                MarkerLayer(
                  rotate: true,
                  markers: markers,
                ),

                // ĐƯỜNG NỐI CÁC ĐIỂM  POLYLINE
                // PolylineLayer(
                //   polylineCulling: false,
                //   polylines: [
                //     Polyline(
                //         points: points,
                //         color: Colors.blueAccent,
                //         strokeWidth: 5),
                //   ],
                // ),
              ],
            ),

            // NÚT TRÊN ĐẦU MÀN HÌNH-BUTTON TOP OF SCREEN
            Positioned(
              top: 3,
              left: 10,
              child: Row(
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.cyan,
                    onPressed: handleButtonPress,
                    child: const Column(
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
              top: 3,
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
                      backgroundColor: Colors.amber,
                      child: isExpanded
                          ? const Icon(
                              Icons.close,
                              color: Colors.white,
                            )
                          : const Icon(
                              Icons.track_changes,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(
                        height: 2), // Add some spacing between the buttons
                    FloatingActionButton(
                      onPressed: () {
                        // Handle the second button tap
                      },
                      backgroundColor: Colors.blueGrey,
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                        height: 8), // Add some spacing between the buttons
                    FloatingActionButton(
                      onPressed: () {
                        // Handle the third button tap
                      },
                      backgroundColor: Colors.blueGrey,
                      child: const Icon(
                        Icons.two_wheeler,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                        height: 8), // Add some spacing between the buttons
                    FloatingActionButton(
                      onPressed: () {
                        // Handle the third button tap
                      },
                      backgroundColor: Colors.blueGrey,
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                        height: 8), // Add some spacing between the buttons
                    FloatingActionButton(
                      onPressed: () {
                        // Handle the third button tap
                      },
                      backgroundColor: Colors.blueGrey,
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                      ),
                    ),
                    // Add more Floating Action Buttons as needed
                  ],
                ],
              ),
            ),

            // NÚT Ở DƯỚI MÀN HÌNH - BUTTON UNDER SCREEN

            // NÚT XOAY BẢN ĐỒ
            Positioned(
                top: 350,
                right: 12,
                child: Column(
                  children: [
                    SizedBox(
                      width: 40, // Specify the desired width
                      height: 40, // Specify the desired height
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey.shade300,
                        onPressed: () {
                          mapController.rotate(mapController.rotation + 90);
                        },
                        tooltip: 'Rotate Map',
                        child: const Icon(Icons.rotate_right),
                      ),
                    ),
                  ],
                )),
            Positioned(
              top: 400,
              right: 5,
              child: Column(
                children: [
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

            // NÚT ZOOM IN + OUT
            Positioned(
              top: 300,
              left: 12,
              child: Column(
                children: [
                  SizedBox(
                    width: 40, // Specify the desired width
                    height: 40, // Specify the desired height
                    child: FloatingActionButton(
                      backgroundColor: Colors.blueGrey.shade300,
                      onPressed: () {
                        mapController.move(
                            mapController.center, mapController.zoom - 1);
                      },
                      child: const Icon(
                        Icons.zoom_in_map,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 350,
              left: 12,
              child: Column(
                children: [
                  SizedBox(
                    width: 40, // Specify the desired width
                    height: 40, // Specify the desired height
                    child: FloatingActionButton(
                      backgroundColor: Colors.blueGrey.shade300,
                      onPressed: () {
                        mapController.move(
                            mapController.center, mapController.zoom + 1);
                      },
                      child: const Icon(
                        Icons.zoom_out_map,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // NÚT GET LOCATION HIỆN TẠI
            Positioned(
              top: 400,
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
                  Row(
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
