import 'dart:developer';
import 'dart:async';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:routesapp/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SiderBar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LatLong {
  final double latitude;
  final double longitude;
  LatLong(this.latitude, this.longitude);
}

class InfoLocation {
  final String displayname;
  final double lat;
  final double lon;
  InfoLocation(
      {required this.displayname, required this.lat, required this.lon});
  @override
  String toString() {
    return displayname;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is InfoLocation && other.displayname == displayname;
  }

  @override
  int get hashCode => Object.hash(displayname, lat, lon);
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<LatLng> points = [];
  bool _isSidebarOpen = false;
  bool isExpanded = false;
  List<Marker> markers = [];
  List listOfPoints = []; // Track the expansion state of the button
  LatLng curloca = const LatLng(21.03276589493197, 105.83989509524008);
  List<Marker> tappedMarkers = [];
  bool isShowingStack = true;
  bool isStackVisible = false;
  //SEARCH BAR:
  final MapController mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<InfoLocation> _options = <InfoLocation>[];
  Timer? _debounce;
  var client = http.Client();

  Future<void> repNameLocation(String value) async {
    var client = http.Client();
    try {
      String url =
          'https://nominatim.openstreetmap.org/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';
      if (kDebugMode) {
        print(url);
      }
      var response = await client.post(Uri.parse(url));
      var decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      if (kDebugMode) {
        print(decodedResponse);
      }
      _options = decodedResponse
          .map((e) => InfoLocation(
              displayname: e['display_name'],
              lat: double.parse(e['lat']),
              lon: double.parse(e['lon'])))
          .toList();
      setState(() {});
    } finally {
      client.close();
    }
    setState(() {});
  }

// đo tốc độ hiện thời
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
                'Your Speed!',
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

// cảnh báo tốc độ
  void show80KmDialog() {
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
          title: Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                'Alert Your Speed!',
                style: TextStyle(
                  color: Colors.amber.shade500,
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

// cảnh báo nguy hiểm + hiệu ứng
  void showDangerDialog() {
    // Show the SOS dialog
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
                        color: Colors
                            .yellowAccent, // Set the background color here
                        borderRadius: BorderRadius.circular(
                            25), // Optional: Add rounded corners
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();

                          // Toggle the visibility of the stack when SOS button is clicked
                          setState(() {
                            isStackVisible = !isStackVisible;
                          });
                        },
                        child: const Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.red, // Set the text color to red
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

// mở sidebar
  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

// Search fullscreen
  void _showSearchFullScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // Container 1 - Search TextFormField
              TextFormField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Where to ?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.blueAccent),
                  suffixIcon: const Icon(Icons.mic, color: Colors.red),
                  filled: true,
                  fillColor: Colors.grey[300],
                ),
                onChanged: (String value) {
                  if (_debounce?.isActive ?? false) {
                    _debounce?.cancel();
                  }

                  _debounce =
                      Timer(const Duration(milliseconds: 600), () async {
                    if (kDebugMode) {
                      print(value);
                    }

                    await repNameLocation(value);
                  });
                },
              ),

              Stack(
                children: [
                  Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.1, // Reduced the height to make the buttons smaller
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 12,
                              itemBuilder: (context, index) {
                                List<IconData> buttonIcons = [
                                  Icons.bookmark,
                                  Icons.local_parking,
                                  Icons.ev_station,
                                  Icons.local_gas_station,
                                  Icons.fastfood,
                                  Icons.local_cafe,
                                  Icons.shopping_cart,
                                  Icons.medication,
                                  Icons.store,
                                  Icons.local_hospital,
                                  Icons.hotel,
                                  Icons.park,
                                  Icons.garage,
                                ];

                                List<String> buttonTexts = [
                                  'Saved',
                                  'Parking',
                                  'Electric',
                                  'Gas',
                                  'Food',
                                  'Coffee',
                                  'Shopping',
                                  'Pharmacies',
                                  'Grocery',
                                  'Hospital ',
                                  'Hotel',
                                  'Parks',
                                  'Garages',
                                ];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal:
                                          4.0), // Reduced horizontal padding
                                  child: SizedBox(
                                    width:
                                        80, // Reduced the width to make the buttons smaller
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (kDebugMode) {
                                          print('Button $index pressed!');
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.all(
                                            6.0), // Reduced padding inside the button
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              12.0), // Slightly reduced the border radius
                                          side: const BorderSide(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            buttonIcons[index],
                                            size: 20.0, // Reduced icon size
                                            color: Colors.black,
                                          ),
                                          const SizedBox(
                                              height:
                                                  1.0), // Reduced gap between icon and text
                                          Flexible(
                                            child: Text(
                                              buttonTexts[index],
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize:
                                                    12.0, // Reduced text size
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines:
                                                  1, // Ensures the text stays in one line
                                              overflow: TextOverflow
                                                  .ellipsis, // Truncate with ellipsis if overflowed
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Container 4 - Another Additional Container
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
                  ]),
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.7, // You can adjust the height as needed
                    child: Stack(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              color: Colors.white,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount:
                                    _options.length > 20 ? 20 : _options.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Colors.black, width: 0.1),
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(_options[index].displayname),
                                      onTap: () {
                                        mapController.move(
                                          LatLng(_options[index].lat,
                                              _options[index].lon),
                                          15.0,
                                        );

                                        handleSearchTap(
                                          LatLng(_options[index].lat,
                                              _options[index].lon),
                                        );
                                        _options.clear();
                                        _searchController.clear();
                                        setState(() {});
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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

// Chức năng của ứng dụng
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
    showStackRepeatedly();
  }

  void showStackRepeatedly() {
    // Toggle the visibility of the stack
    setState(() {
      isShowingStack = !isShowingStack;
    });

    // Repeat the process after a short delay (e.g., 500 milliseconds)
    Timer(const Duration(milliseconds: 900), () {
      showStackRepeatedly();
    });
  }

  void handleSearchTap(LatLng location) {
    setState(() {
      tappedMarkers.add(
        // Add the tapped marker to the tappedMarkers list
        Marker(
          point: location,
          width: 80,
          height: 80,
          builder: (context) => IconButton(
            icon: const Icon(Icons.location_on),
            color: Colors.blue,
            iconSize: 45,
            onPressed: () => handleMarkerTap(
                location), // Call the handleMarkerTap method when the marker is tapped
          ),
        ),
      );
    });
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(
              color: Colors.blueAccent, // Set the border color
              width: 3.0, // Set the border width
            ),
          ),
          title: Text(
            'Marker Info',
            style: TextStyle(
              color: Colors
                  .blue.shade500, // Change the color of the title text here
            ),
          ),
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

  Widget placeholderImageWidget() {
    // Replace this with your custom placeholder image widget
    return Container(
      width: 250,
      height: 56,
      color: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1024;
    final isTablet = screenSize.width <= 1024 && screenSize.width > 600;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: CachedNetworkImage(
          imageUrl: 'https://tracking.skysoft.vn/img/skysoft_logo.png',
          fit: BoxFit.fitHeight,
          width: 250,
          height: 56,
          errorWidget: (context, url, error) => placeholderImageWidget(),
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
            Stack(
              children: [
                if (isStackVisible)
                  IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: isShowingStack ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                            ),
                            BoxShadow(
                              color: Colors.white70.withOpacity(0.1),
                              spreadRadius: -50.0,
                              blurRadius: 50.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // NÚT TRÊN ĐẦU MÀN HÌNH-BUTTON TOP OF SCREEN
            Positioned(
              top: 23,
              left: 95,
              child: AvatarGlow(
                glowColor: Colors.red.shade700,
                endRadius: 90.0,
                duration: const Duration(milliseconds: 2000),
                repeat: true,
                showTwoGlows: true,
                repeatPauseDuration: const Duration(milliseconds: 100),
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
                          onPressed: showDangerDialog,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.car_crash),
                              Text(
                                "Danger",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.bold, // Set the font size here
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 23,
              left: 5,
              child: AvatarGlow(
                glowColor: Colors.yellow.shade900,
                endRadius: 90.0,
                duration: const Duration(milliseconds: 2000),
                repeat: true,
                showTwoGlows: true,
                repeatPauseDuration: const Duration(milliseconds: 500),
                child: Material(
                  elevation: 8.0,
                  shape: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 28.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FloatingActionButton(
                          backgroundColor: Colors.amberAccent,
                          onPressed: show80KmDialog,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.warning),
                              Text(
                                "80km/h",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.bold, // Set the font size here
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 85,
              left: 3, // Adjust the left position according to your preference.
              child: FloatingActionButton(
                backgroundColor: Colors.cyan.shade500,
                onPressed: show60KmDialog,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.speed),
                    Text(
                      "60km/h",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold, // Set the font size here
                      ),
                    )
                  ],
                ),
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
                              Icons.tune,
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
            // NÚT BÊN DƯỚI GẦN BOTTOM
            // NÚT NỐI 2 ĐIỂM !
            Positioned(
              // The position for the polyline button based on screen size
              bottom: isDesktop
                  ? 110
                  : isTablet
                      ? 110
                      : 130,
              right: isDesktop ? 30 : 10,
              // The position for the polyline button based on screen size
              child: FloatingActionButton(
                backgroundColor: Colors.blueAccent,
                onPressed: getCoordinates,
                tooltip: 'Polyline',
                child: const Icon(
                  Icons.route,
                  color: Colors.white,
                ),
              ),
            ),

            Positioned(
              // The position for the current location button based on screen size
              bottom: isDesktop
                  ? 110
                  : isTablet
                      ? 110
                      : 130,
              left: isDesktop ? 30 : 10,
              // The position for the current location button based on screen size
              child: FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: currentLoc,
                tooltip: 'Get Current Location',
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
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
                    child: GestureDetector(
                      onTap: () {
                        _showSearchFullScreen(); // Call the function to show the fullscreen container
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
                      _showSearchFullScreen(); // Call the function to show the fullscreen container
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
                  ),
                  GestureDetector(
                    onTap: () {
                      _showSearchFullScreen(); // Call the function to show the fullscreen container
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
                  ),
                  GestureDetector(
                    onTap: () {
                      _showSearchFullScreen(); // Call the function to show the fullscreen container
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
