import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:skysoft/api.dart';
import 'SiderBar.dart';

// ===================CÁC CLASS PHỤ =================================================================================================================================================================
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
// =========CÁC CLASS CHÍNH  =========================================================================================================================================================================

// ========== CLASS CHO MAIN CHẠY ===================================================================================================================================================================
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

//========= CLASS CHÍNH ================================================================================================================================================================================
class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  //  KHAI BÁO CÁC BIẾN
  List<LatLng> points = [];
  bool _isSidebarOpen = false;
  bool isExpanded = false;
  List<Marker> markers = [];
  List listOfPoints = [];
  LatLng curloca = const LatLng(21.03276589493197, 105.83989509524008);
  List<Marker> tappedMarkers = [];
  List<LatLng> savedMarkers = [];
  bool isShowingStack = true;
  bool isStackVisible = false;
  bool isSavingHomeAddress = false;
  bool isSavingWorkAddress = false;
  String homeAddress = "Set once and go";
  String workAddress = "Set once and go";
  //SEARCH BAR:
  final MapController mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<InfoLocation> _options = <InfoLocation>[];
  LatLng route = const LatLng(0, 0);
  //Animation map
  static const _useTransformerId = 'useTransformerId';
  final bool _useTransformer = true;
  late final _animatedMapController = AnimatedMapController(vsync: this);
  bool isInitialZoom = false;
  late LatLng finalCenter;

// ============================= VOID LOGIC CỦA CÁC BUTTON =================================================

// API lấy ra vị trí tọa độ điểm cần tìm trên bản đồ ( API THANH SEARCH)
  Future<void> repNameLocation(String value) async {
    try {
      String url =
          'https://nominatim.openstreetmap.org/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';

      if (kDebugMode) {
        print(url);
      }

      var response =
          await http.get(Uri.parse(url)); // Use http.get for a GET request
      if (response.statusCode == 200) {
        var decodedResponse =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

        if (kDebugMode) {
          print(decodedResponse);
        }

        _options = decodedResponse
            .map((e) => InfoLocation(
                displayname: e['display_name'],
                lat: double.parse(e['lat'].toString()),
                lon: double.parse(e['lon'].toString())))
            .toList();

        setState(() {});
      } else {
        // Handle error here if the response status code is not 200
        if (kDebugMode) {
          print('Request failed with status: ${response.statusCode}');
        }
      }
    } catch (error) {
      // Handle any exceptions that occur during the process
      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

// NÚT SAVE MARKER
  void showSaveMarkersList() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Saved Markers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              savedMarkers.isEmpty
                  ? const Text('No saved markers.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: savedMarkers.length,
                      itemBuilder: (context, index) {
                        LatLng marker = savedMarkers[index];
                        return ListTile(
                          title: Text(
                            'Marker ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Latitude: ${marker.latitude}, Longitude: ${marker.longitude}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text(
                                        'Are you sure you want to delete this marker?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          removeMarkerFromList(marker);
                                          Navigator.pop(dialogContext);
                                          Navigator.pop(context);
                                          showSaveMarkersList();
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          onTap: () {
                            // Ấn vào maker để hiển thị biểu tượng tương ứng trên bản đồ
                            showMarkerOnMap(marker);
                            Navigator.of(context).pop();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
              // ...
            ],
          ),
        );
      },
    );
  }

  // logic xóa marker đã save
  void removeMarkerFromList(LatLng marker) async {
    if (savedMarkers.contains(marker)) {
      setState(() {
        savedMarkers.remove(marker);
      });
      await saveMarkersToSharedPreferences(savedMarkers);
    }
  }

  // logic lưu marker vào SharedPreferences
  Future<void> saveMarkersToSharedPreferences(List<LatLng> markers) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> markerList = markers
        .map((LatLng marker) => "${marker.latitude},${marker.longitude}")
        .toList();

    await prefs.setStringList('savedMarkers', markerList);
  }

  // lưu data marker khi thoát ra khỏi app
  Future<void> loadSavedMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? markerStrings = prefs.getStringList('savedMarkers');
    if (markerStrings != null) {
      List<LatLng> loadedMarkers = markerStrings.map((markerString) {
        List<String> parts = markerString.split(',');
        double latitude = double.parse(parts[0]);
        double longitude = double.parse(parts[1]);
        return LatLng(latitude, longitude);
      }).toList();
      setState(() {
        savedMarkers = loadedMarkers;
      });
    }
  }

// THÔNG BÁO TỐC ĐỘ HIỆN THỜI
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

// CẢNH BÁO TỐC ĐỘ
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

//  NÚT SOS + HIỆU ỨNG CẢNH BÁO
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

// HIỆU ỨNG NHẤP NHÁY CẢNH BÁO
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

// MỞ SIDEBAR
  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

// THANH SLIDE BOTTOM BAR
  void showSearchFullScreen() {
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
                onFieldSubmitted: (String value) async {
                  if (kDebugMode) {
                    print(value);
                  }

                  await repNameLocation(value).then((value) {
                    setState(() {}); // Trigger a rebuild of the widget
                  });

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Close the existing modal
                  openSearchModal(); // Open the search modal back
                },
              ),

              Stack(
                children: [
                  Column(
                    children: [
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
                                itemCount: 14,
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
                                    Icons.more_horiz,
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
                                    'More',
                                  ];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            4.0), // Reduced horizontal padding
                                    child: SizedBox(
                                      width:
                                          70, // Reduced the width to make the buttons smaller
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (kDebugMode) {
                                            print('Button $index pressed!');
                                          }
                                          if (index == 0) {
                                            showSaveMarkersList();
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
                                              color: Colors.grey,
                                              width:
                                                  0.2, // Set the border width to 1.0 pixel
                                            ),
                                          ),
                                          elevation:
                                              0.0, // Set the elevation to 0.0 to remove the shadow
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              buttonIcons[index],
                                              size: 20.0, // Reduced icon size
                                              color: Colors.grey,
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
                                                      11.0, // Reduced text size
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
                          onTap: () {
                            handleHomeButton();
                          },
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
                          onTap: () {
                            handleWorkButton();
                          },
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
                  _options.isNotEmpty
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
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
                                      _animatedMapController.mapController.move(
                                        LatLng(_options[index].lat,
                                            _options[index].lon),
                                        15.0,
                                      );
                                      _focusNode.unfocus();
                                      showMarkerOnMap(
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
                        )
                      : Container()
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void openSearchModal() {
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
                onFieldSubmitted: (String value) async {
                  if (kDebugMode) {
                    print(value);
                  }

                  await repNameLocation(value).then((value) {
                    setState(() {}); // Trigger a rebuild of the widget
                  });

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Close the existing modal
                  openSearchModal(); // Open the search modal back
                },
              ),

              Stack(
                children: [
                  Column(
                    children: [
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
                                itemCount: 14,
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
                                    Icons.more_horiz,
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
                                    'More',
                                  ];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            4.0), // Reduced horizontal padding
                                    child: SizedBox(
                                      width:
                                          70, // Reduced the width to make the buttons smaller
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (kDebugMode) {
                                            print('Button $index pressed!');
                                          }
                                          if (index == 0) {
                                            showSaveMarkersList();
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
                                              color: Colors.grey,
                                              width:
                                                  0.2, // Set the border width to 1.0 pixel
                                            ),
                                          ),
                                          elevation:
                                              0.0, // Set the elevation to 0.0 to remove the shadow
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              buttonIcons[index],
                                              size: 20.0, // Reduced icon size
                                              color: Colors.grey,
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
                                                      11.0, // Reduced text size
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
                          onTap: () {
                            handleHomeButton();
                          },
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
                          onTap: () {
                            handleWorkButton();
                          },
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
                  _options.isNotEmpty
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
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
                                      _animatedMapController.mapController.move(
                                        LatLng(_options[index].lat,
                                            _options[index].lon),
                                        15.0,
                                      );
                                      _focusNode.unfocus();
                                      showMarkerOnMap(
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
                        )
                      : Container()
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void showSearchBar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const Text(
                    'Search for a location:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter a location...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[300],
                    ),
                    onChanged: (String value) async {
                      await repNameLocation(value).then((value) {
                        setState(() {}); // Update UI after search
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_options[index].displayname),
                          onTap: () {
                            if (isSavingHomeAddress) {
                              String selectedAddress =
                                  _options[index].displayname;
                              double? latitude = _options[index].lat;
                              double? longitude = _options[index].lon;
                              showSaveHomeAddressDialog(
                                  selectedAddress, latitude, longitude);
                            } else if (isSavingWorkAddress) {
                              String selectedAddress =
                                  _options[index].displayname;
                              double? latitude = _options[index].lat;
                              double? longitude = _options[index].lon;
                              showSaveWorkAddressDialog(
                                  selectedAddress, latitude, longitude);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// NÚT HOME Ở BOTTOM BAR

  // logic nút home
  void handleHomeButton() async {
    setState(() {
      isSavingHomeAddress = true;
      isSavingWorkAddress = false;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedHomeAddress = prefs.getString('home_address');

    if (savedHomeAddress != null) {
      // ignore: use_build_context_synchronously
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Home Address',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade400, // Thay đổi màu sắc
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey, // Thay đổi màu sắc
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    savedHomeAddress,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          handleSavedHomeAddress(savedHomeAddress);
                          Navigator.of(context).pop();
                        },
                        // ignore: sort_child_properties_last
                        child: const Text(
                          'Use This Address',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.pink.shade400, // Thay đổi màu sắc
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red, // Thay đổi màu sắc
                        ),
                        onPressed: () {
                          showDeleteHomeConfirmationDialog(savedHomeAddress);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      showSearchBar();
      _searchController.clear();
      _options.clear();
    }
  }

  // hiển thị popup
  void showSaveHomeAddressDialog(
      String address, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Home Address'),
          content: const Text('Do you want to save this address as your home?'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                saveHomeAddress(
                    address, latitude, longitude); // Lưu địa chỉ và tọa độ
                Navigator.of(context).pop(); // Đóng dialog
                showHomeAddress();
                _searchController.clear();
                _options.clear();
                handleHomeButton();
              },
              child: const Text('Yes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  // thêm marker lên bản đồ
  void handleSavedHomeAddress(String address) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double latitude = prefs.getDouble('home_latitude') ?? 0.0;
    double longitude = prefs.getDouble('home_longitude') ?? 0.0;

    if (latitude != 0.0 && longitude != 0.0) {
      LatLng homeLatLng = LatLng(latitude, longitude);
      showMarkerOnMap(homeLatLng);
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Đóng bottom sheet
    }
  }

  // hiển thị popup xóa địa chỉ home
  void showDeleteHomeConfirmationDialog(String address) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const Text(
                    'Delete Home Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Are you sure you want to delete your home address?',
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      deleteHomeAddress();
                      Navigator.of(context).pop();
                      showHomeAddress();
                      setState(() {});
                      Navigator.of(context).pop(); // Đóng modal bottom sheet
                      showSearchBar();
                      _searchController.clear();
                      _options.clear();
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // logic nút xóa nhà
  void deleteHomeAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('home_address');
    setState(() {
      homeAddress = "Set once and go";
    });
  }

  // Lưu địa điểm HOME vào SharedPreferences
  void saveHomeAddress(
      String address, double latitude, double longitude) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('home_address', address);
    prefs.setDouble('home_latitude', latitude);
    prefs.setDouble('home_longitude', longitude);
  }

  // Lấy vị trí HOME từ SharedPreferences
  Future<String?> getHomeAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('home_address');
  }

  // Thay đổi tên địa điểm ở nút HOME + Lưu khi thoát app
  void showHomeAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedHomeAddress = prefs.getString('home_address');

    // Kiểm tra nếu địa chỉ nhà đã lưu
    if (savedHomeAddress != null) {
      setState(() {
        homeAddress = savedHomeAddress;
      });
    }
  }

//==========================================================================================//

// NÚT WORK Ở BOTTOM BAR

  // logic nút work
  void handleWorkButton() async {
    setState(() {
      isSavingHomeAddress = false;
      isSavingWorkAddress = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedWorkAddress = prefs.getString('work_address');
    if (savedWorkAddress != null) {
      // ignore: use_build_context_synchronously
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Work Address',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade400, // Thay đổi màu sắc
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey, // Thay đổi màu sắc
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    savedWorkAddress,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          handleSavedWorkAddress(savedWorkAddress);
                          Navigator.of(context).pop();
                        },
                        // ignore: sort_child_properties_last
                        child: const Text(
                          'Use This Address',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.brown.shade400, // Thay đổi màu sắc
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red, // Thay đổi màu sắc
                        ),
                        onPressed: () {
                          showDeleteWorkConfirmationDialog(savedWorkAddress);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      showSearchBar();
      _searchController.clear();
      _options.clear();
    }
  }

  // hiển thị popup
  void showSaveWorkAddressDialog(
      String address, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Work Address'),
          content: const Text('Do you want to save this address as your work?'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                saveWorkAddress(
                    address, latitude, longitude); // Save the address
                Navigator.of(context).pop(); // Close the dialog
                showWorkAddress();
                _searchController.clear();
                _options.clear();
                handleWorkButton(); // Handle work address button action
              },
              child: const Text('Yes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  // thêm marker lên bản đồ
  void handleSavedWorkAddress(String address) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double latitude = prefs.getDouble('work_latitude') ?? 0.0;
    double longitude = prefs.getDouble('work_longitude') ?? 0.0;
    if (latitude != 0.0 && longitude != 0.0) {
      LatLng workLatLng = LatLng(latitude, longitude);
      showMarkerOnMap(workLatLng);
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Đóng bottom sheet
    }
  }

  // hiển thị popup xóa địa chỉ work
  void showDeleteWorkConfirmationDialog(String address) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        // Đóng modal bottom sheet
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const Text(
                    'Delete Work Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Are you sure you want to delete your work address?',
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Thực hiện xóa địa chỉ công việc
                      deleteWorkAddress();
                      Navigator.of(context).pop();
                      setState(() {});
                      // Đóng modal bottom sheet
                      Navigator.of(context).pop();
                      showSearchBar();
                      _searchController.clear();
                      _options.clear();
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // logic nút xóa work
  void deleteWorkAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('work_address');
    setState(() {
      workAddress = "Set once and go";
    });
  }

  // Lưu địa điểm WORK vào SharedPreferences
  void saveWorkAddress(
      String address, double latitude, double longitude) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('work_address', address);
    prefs.setDouble('work_latitude', latitude);
    prefs.setDouble('work_longitude', longitude);
  }

  // Lấy vị trí WORK từ SharedPreferences
  Future<String?> getWorkAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('work_address');
  }

  // Thay đổi tên địa điểm ở nút WORK + Lưu khi thoát app
  void showWorkAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedWorkAddress = prefs.getString('work_address');

    // Kiểm tra nếu địa chỉ công việc đã lưu
    if (savedWorkAddress != null) {
      setState(() {
        workAddress = savedWorkAddress;
      });
    }
  }

  // NỐI 2 ĐIỂM !
  getCoordinates() async {
    // Requesting for openrouteservice api
    var response = await http.get(getRouteUrl(
        "21.052895356327777, 105.77986458185414", '21.052962, 105.779735'));
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

// setup data khi khởi động app (thoát app hoặc tắt đa nhiệm vẫn lưu dữ liệu trừ khi gỡ bỏ)
  @override
  void initState() {
    super.initState();
    showHomeAddress();
    showWorkAddress();
    loadSavedMarkers();
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

// THÊM MARKER LÊN BẢN ĐỒ BẰNG SEARCH BAR
  void showMarkerOnMap(LatLng location) {
    _animatedMapController.centerOnPoint(location);
    setState(() {
      tappedMarkers.add(
        Marker(
          point: location,
          width: 100,
          height: 100,
          builder: (context) => IconButton(
            icon: const Icon(Icons.location_on),
            color: Colors.red,
            iconSize: 45,
            onPressed: () => handleMarkerTap(location),
          ),
        ),
      );
    });
  }

// THÊM MARKER LÊN BẢN ĐỒ BẰNG TAY ONTAP
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

      // Center the map on the tapped location
      _animatedMapController.centerOnPoint(
        tappedPoint,
        customId: _useTransformer ? _useTransformerId : null,
      );
    });
  }

// XEM THÔNG TIN CỦA MARKER ĐÓ ( POPUP HIỆN SAVE MARKER + DELETE MARKER + CLOSE)
  void handleMarkerTap(LatLng tappedPoint) {
    // Show the information about the marker (latitude and longitude)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Log the latitude and longitude of the tapped marker
        developer.log(
            "Tapped Marker - Latitude: ${tappedPoint.latitude}, Longitude: ${tappedPoint.longitude}");

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(
              color: Colors.blueAccent,
              width: 3.0,
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
              onPressed: () async {
                setState(() {
                  // Lưu lại vị trí của marker vào danh sách lưu trữ
                  savedMarkers.add(tappedPoint);
                });
                await saveMarkersToSharedPreferences(savedMarkers);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Đóng hộp thoại
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marker saved'),
                    duration:
                        Duration(seconds: 2), // Thời gian hiển thị của SnackBar
                  ),
                );
              },
              child: const Text(
                'Save Marker',
                style: TextStyle(
                  color: Colors.green,
                ),
              ),
            ),
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

// LẤY CENTER MAP LÀ MARKER
  int tapCount = 0;
  void centerMarkers() {
    // Increment the tap count on each tap
    tapCount++;

    if (tappedMarkers.isEmpty) return;

    final points = tappedMarkers.map((m) => m.point).toList();
    if (points.isNotEmpty) {
      if (tapCount == 1) {
        // Center on the points for the first tap
        _animatedMapController.centerOnPoints(
          points,
          customId: _useTransformer ? _useTransformerId : null,
        );
      } else if (tapCount == 2) {
        // Zoom out on the second tap
        _animatedMapController.animatedZoomOut(curve: Curves.easeInOut);

        // Reset the tap count after the second tap
        tapCount = 0;
      }
    }
  }

// ROTATE CẢ BẢN ĐỒ THEO TÂM 90 ĐỘ TRÁI
  void rotateMapLeft() {
    _animatedMapController.animatedRotateFrom(
      90,
      customId: _useTransformer ? _useTransformerId : null,
    );
  }

// ROTATE CẢ BẢN ĐỒ THEO TÂM 90 ĐỘ PHẢI
  void rotateMapRight() {
    _animatedMapController.animatedRotateFrom(
      -90,
      customId: _useTransformer ? _useTransformerId : null,
    );
  }

// ZOOM IN PHÓNG TO BẢN ĐỒ
  void zoomIn() {
    _animatedMapController.animatedZoomIn(
      customId: _useTransformer ? _useTransformerId : null,
    );
  }

// ZOOM OUT THU NHỎ BẢN ĐỒ
  void zoomOut() {
    _animatedMapController.animatedZoomOut(
      customId: _useTransformer ? _useTransformerId : null,
    );
  }

// XÓA TẤT CẢ MARKER ONTAP HOẶC SEARCH TRÊN BẢN ĐỒ ( VỊ TRÍ HIỆN TẠI SẼ K XÓA)
  void clearAllMarkers() {
    setState(() {
      tappedMarkers.clear();
    });
  }

// XOAY ĐIỀU HƯỚNG TÂM XOAY QUANH ĐIỂM OFFSET
  void moveMapCenterToSavedLatLng() {
    // Define the desired animation duration and total steps
    const int animationDuration = 1500;
    const int totalSteps = 60;

    // Retrieve the saved latitude, longitude, and direction
    double savedLatitude =
        modifiedCenter.latitude; // Replace with actual saved latitude
    double savedLongitude =
        modifiedCenter.longitude; // Replace with actual saved longitude
    double desiredRotation = finalDirection; // Use the saved final direction

    // Calculate the offset increments for movement
    double latOffsetIncrement =
        (savedLatitude - _animatedMapController.mapController.center.latitude) /
            totalSteps;
    double lngOffsetIncrement = (savedLongitude -
            _animatedMapController.mapController.center.longitude) /
        totalSteps;

    // Calculate the rotation increment
    double initialRotation = _animatedMapController.mapController.rotation;
    double rotationDelta = (desiredRotation - initialRotation);
    double rotationIncrement = rotationDelta / totalSteps;

    int stepCount = 0;

    Timer.periodic(
        const Duration(milliseconds: animationDuration ~/ totalSteps), (timer) {
      double newLatitude =
          _animatedMapController.mapController.center.latitude +
              latOffsetIncrement;
      double newLongitude =
          _animatedMapController.mapController.center.longitude +
              lngOffsetIncrement;

      // Calculate the desired zoom level (e.g., 18)
      double desiredZoom = 18;

      // Move the map using the mapController.move() method with the new latitude, longitude, and zoom level.
      _animatedMapController.mapController
          .move(LatLng(newLatitude, newLongitude), desiredZoom);

      // Calculate the new rotation angle
      double newRotation = initialRotation + stepCount * rotationIncrement;

      // Rotate the map using the mapController.rotate() method.
      _animatedMapController.mapController.rotate(newRotation);

      stepCount++;

      if (stepCount >= totalSteps) {
        // Move the map to the saved latitude and longitude with the desired zoom level.
        _animatedMapController.mapController
            .move(LatLng(savedLatitude, savedLongitude), desiredZoom);

        // Rotate the map to the desired final rotation
        _animatedMapController.mapController.rotate(desiredRotation);

        timer.cancel();
      }
    });
  }

  late LatLng modifiedCenter;

  void rotateMapAroundMarker() {
    // Calculate the desired rotation angle by decrementing 25 degrees from the current rotation.
    double desiredRotation = _animatedMapController.mapController.rotation - 25;

    // Define the total duration of the animation in milliseconds.
    const int animationDuration = 500;

    // Define the number of steps for the animation to achieve smooth rotation.
    const int totalSteps = 60;

    // Calculate the angle to rotate in each step to reach the desired rotation smoothly.
    double stepRotation =
        (desiredRotation - _animatedMapController.mapController.rotation) /
            totalSteps;

    // Calculate the delay between each step to control the animation speed.
    int stepDelay = animationDuration ~/ totalSteps;

    // Initialize a step counter to keep track of animation progress.
    int stepCount = 0;

    // Create a periodic timer to update the map rotation smoothly over time.
    Timer.periodic(Duration(milliseconds: stepDelay), (timer) {
      // Calculate the new rotation angle for this step.
      double newRotation =
          _animatedMapController.mapController.rotation + stepRotation;

      // Save the current map center before the rotation.
      LatLng currentMapCenter = _animatedMapController.mapController.center;

      // Update the map rotation using the mapController.rotateAroundPoint() method.
      double scale = 1.21473;
      double offsetLng = 248.07142;

      // Adjust the offsetLng based on the device screen height for proper map centering.
      if (MediaQuery.of(context).size.height < 896) {
        offsetLng = 248.07142;
      } else {
        offsetLng = 248.07142 * scale;
      }

      _animatedMapController.mapController
          .rotateAroundPoint(newRotation, offset: Offset(0, offsetLng));

      // Log the new rotation angle and the saved current map center.
      developer.log(
          "New Rotation: $newRotation, Current Map Center: $currentMapCenter");

      // Store the modified center after offset and rotation.
      modifiedCenter = _animatedMapController.mapController.center;

      // Update the final direction after the animation.
      finalDirection = newRotation; // Save the new rotation

      // Increment the step counter to keep track of the animation progress.
      stepCount++;

      // Check if the animation is complete by comparing the step count with total steps.
      if (stepCount >= totalSteps) {
        // Now you have the modified center saved in 'modifiedCenter' and the final direction saved in 'finalDirection'.
        // You can use these values as needed.

        // Log the final direction after the animation is completed.
        developer.log("Final Direction: $finalDirection");

        // Cancel the timer when the animation is done to stop further updates.
        timer.cancel();
      }
    });
  }

// OFFSET CHO MARKER NAVIGATE XUỐNG DƯỚI GẦN THANH BOTTOM BAR
  double finalDirection = 0.0;
  void moveMapToSavedCenter(double finalDirection) {
    // Use the saved finalCenter from the offset animation
    LatLng targetCenter = finalCenter;

    // Define the desired zoom level for the map
    double desiredZoom = 18; // You can adjust this value as needed

    // Define the total duration of the animation in milliseconds.
    const int animationDuration = 500;

    // Define the number of steps for the animation to achieve smooth movement.
    const int totalSteps = 60;

    // Calculate the latitude offset increment for each step to move the map smoothly.
    double latOffsetIncrement = (targetCenter.latitude -
            _animatedMapController.mapController.center.latitude) /
        totalSteps;

    // Calculate the longitude offset increment for each step to move the map smoothly.
    double lngOffsetIncrement = (targetCenter.longitude -
            _animatedMapController.mapController.center.longitude) /
        totalSteps;

    // Calculate the direction increment for each step to rotate the map smoothly.
    double directionIncrement =
        (finalDirection - _animatedMapController.mapController.rotation) /
            totalSteps;

    // Initialize a step counter to keep track of animation progress.
    int stepCount = 0;

    // Create a periodic timer to update the map's position and rotation smoothly over time.
    Timer.periodic(
        const Duration(milliseconds: animationDuration ~/ totalSteps), (timer) {
      // Calculate the new latitude and longitude for this step by incrementing the current values.
      double newLatitude =
          _animatedMapController.mapController.center.latitude +
              latOffsetIncrement;
      double newLongitude =
          _animatedMapController.mapController.center.longitude +
              lngOffsetIncrement;

      // Calculate the new rotation angle for this step by incrementing the current rotation.
      double newRotation =
          _animatedMapController.mapController.rotation + directionIncrement;

      // Move the map using the mapController.move() method with the new latitude, longitude.
      _animatedMapController.mapController.move(
          LatLng(newLatitude, newLongitude),
          _animatedMapController.mapController.zoom);

      // Set the new rotation angle for the map.
      _animatedMapController.mapController.rotate(newRotation);

      // Increment the step counter to keep track of the animation progress.
      stepCount++;

      // Check if the animation is complete by comparing the step count with total steps.
      if (stepCount >= totalSteps) {
        // Move the map to the target center and set the desired zoom level and rotation.
        _animatedMapController.mapController.move(targetCenter, desiredZoom);

        // Set the final rotation angle for the map.
        _animatedMapController.mapController.rotate(finalDirection);

        // Cancel the timer when the animation is done to stop further updates.
        timer.cancel();
      }
    });
  }

  void offsetUpAndZoomIn() {
    // Define the total duration of the animation in milliseconds.
    const int animationDuration = 500;

    // Define the number of steps for the animation to achieve smooth movement and zooming.
    const int totalSteps = 60;

    // Define the scaling factor for offset increment to adjust animation smoothness.
    const double scale = 1.25;

    // Calculate the offset increment for each step to move the map up smoothly.
    double offsetIncrement = 0.0015 / totalSteps;

    // Adjust the offset increment based on the device screen height for proper map centering.
    if (MediaQuery.of(context).size.height < 896) {
      offsetIncrement = 0.00002;
    } else {
      offsetIncrement = 0.00002 * scale;
    }

    // Calculate the zoom increment for each step to zoom in smoothly.
    double zoomIncrement =
        (18 - _animatedMapController.mapController.zoom) / totalSteps;

    // Initialize a step counter to keep track of animation progress.
    int stepCount = 0;

    // Variable to store the final center after the animation.
    finalCenter = _animatedMapController.mapController.center;
    double finalDirection = _animatedMapController
        .mapController.rotation; // Save the initial direction

    // Create a periodic timer to update the map's position and zoom level smoothly over time.
    Timer.periodic(
        const Duration(milliseconds: animationDuration ~/ totalSteps), (timer) {
      // Calculate the new latitude for this step by incrementing the current latitude.
      double newLatitude =
          _animatedMapController.mapController.center.latitude +
              offsetIncrement;

      // Calculate the new zoom level for this step by incrementing the current zoom level.
      double newZoom =
          _animatedMapController.mapController.zoom + zoomIncrement;

      // Move the map using the mapController.move() method with the new latitude and zoom level.
      _animatedMapController.mapController.move(
          LatLng(newLatitude,
              _animatedMapController.mapController.center.longitude),
          newZoom);

      // Update the final center after the animation.
      finalCenter = LatLng(
          newLatitude, _animatedMapController.mapController.center.longitude);

      // Update the final direction after the animation.
      finalDirection = _animatedMapController.mapController.rotation;

      // Log the new latitude and longitude for debugging purposes.
      developer.log(
          "New Latitude: $newLatitude, New Longitude: ${_animatedMapController.mapController.center.longitude} - offsetLatlng: $offsetIncrement");

      // Increment the step counter to keep track of the animation progress.
      stepCount++;

      // Check if the animation is complete by comparing the step count with total steps.
      if (stepCount >= totalSteps) {
        // Cancel the timer when the animation is done to stop further updates.
        timer.cancel();

        // Log the final center and direction after the animation is completed.
        developer.log(
            "Final Center: Latitude: ${finalCenter.latitude}, Longitude: ${finalCenter.longitude}");
        developer.log("Final Direction: $finalDirection");

        // Here you can save the finalCenter and finalDirection or perform any other action after the animation.
      }
    });
  }

  void offsetMapAndZoom(double latOffsetIncrement, double lngOffsetIncrement,
      double zoomIncrement, int animationDuration, int totalSteps) {
    // Initialize a step counter to keep track of animation progress.
    int stepCount = 0;

    // Create a periodic timer to update the map's position and zoom level smoothly over time.
    Timer.periodic(Duration(milliseconds: animationDuration ~/ totalSteps),
        (timer) {
      // Calculate the new latitude and longitude for this step by incrementing the current values.
      double newLatitude =
          _animatedMapController.mapController.center.latitude +
              latOffsetIncrement;
      double newLongitude =
          _animatedMapController.mapController.center.longitude +
              lngOffsetIncrement;

      // Calculate the new zoom level for this step by incrementing the current zoom level.
      double newZoom =
          _animatedMapController.mapController.zoom + zoomIncrement;

      // Move the map using the mapController.move() method with the new latitude, longitude, and zoom level.
      _animatedMapController.mapController
          .move(LatLng(newLatitude, newLongitude), newZoom);

      // Log the new latitude and longitude for debugging purposes.
      developer.log(
          "New Latitude: $newLatitude, New Longitude: $newLongitude, New Zoom: $newZoom");

      // Increment the step counter to keep track of the animation progress.
      stepCount++;

      // Check if the animation is complete by comparing the step count with total steps.
      if (stepCount >= totalSteps) {
        // Cancel the timer when the animation is done to stop further updates.
        timer.cancel();
      }
    });
  }

// CHỨC NĂNG ĐANG ĐỂ TRỐNG ĐỀ CHỜ!
  void handleButtonPress() {}

// KIỂM TRA QUYỀN TRUY CẬP ĐỊNH VỊ GPS
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

// TRACKING VỊ TRÍ HIỆN TẠI KHI DI CHUYỂN
  String speedText = "0 km/h";
  bool isTracking = false; // Track the current tracking state
  Marker? navigationMarker;
  Timer? timer; // Store the timer instance for later cancellation

  void toggleLocationTracking() {
    if (isTracking) {
      stopLocationTracking(); // If tracking is active, stop it
    } else {
      startLocationTracking(); // If tracking is inactive, start it
    }
  }

  void startLocationTracking() {
    // Set up a periodic timer to update the location and speed
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (kDebugMode) {
        print("Updating location and speed...");
      }
      currentLoc1(); // Call the current location update function
    });

    isTracking = true; // Set tracking state to active
  }

  void stopLocationTracking() {
    // Cancel the timer and reset tracking state
    timer?.cancel();
    isTracking = false;
  }

  void currentLoc1() async {
    Position data = await _determinePosition();
    double speed = data.speed; // Speed in m/s

    // Update the speed text with rounded value
    int roundedSpeed =
        (speed * 3.6).toInt(); // Round the speed to the nearest integer
    speedText = "$roundedSpeed km/h";

    setState(() {
      curloca = LatLng(data.latitude, data.longitude);
      updateMarkerAndZoom1(); // Update using the new function
    });
  }

  void updateMarkerAndZoom1() {
    double latOffsetIncrement = 0.0013;
    const double scale = 1.25;

    double offsetIncrement;
    if (MediaQuery.of(context).size.height < 896) {
      offsetIncrement = 0.00002;
    } else {
      offsetIncrement = 0.00002 * scale;
    }

    // Calculate the new center based on the marker's position and offset
    LatLng newCenter = LatLng(
      curloca.latitude + latOffsetIncrement,
      curloca.longitude + offsetIncrement,
    );

    // Remove the existing navigation marker if it exists
    if (navigationMarker != null) {
      markers.remove(navigationMarker);
    }

    // Create a new navigation marker
    navigationMarker = Marker(
      point: curloca,
      width: 80,
      height: 80,
      builder: (ctx) =>
          buildNavigationMarker(ctx, speedText), // Update the marker's builder
    );

    // Add the new navigation marker to the markers list
    markers.add(navigationMarker!);

    // Move the map to the new center with a zoom level of 18
    _animatedMapController.mapController.move(newCenter, 18.0);

    // Save the final center and direction after updating the marker and zooming
    finalCenter = newCenter;
    finalDirection = _animatedMapController.mapController.rotation;
  }

  IconButton buildNavigationMarker(BuildContext context, String speedText) {
    return IconButton(
      onPressed: () {},
      icon: const Icon(Icons.navigation),
      color: Colors.greenAccent.shade700,
      iconSize: 40,
    );
  }

// TÌM VỊ TRÍ HIỆN TẠI CỦA NGƯỜI DÙNG QUA GPS
  void currentLoc() async {
    Position data = await _determinePosition();
    double speed = data.speed; // Speed in m/s

    // Update the speed text with rounded value
    int roundedSpeed =
        (speed * 3.6).toInt(); // Round the speed to the nearest integer
    speedText = "$roundedSpeed km/h";

    setState(() {
      curloca = LatLng(data.latitude, data.longitude);
      updateMarkerAndZoom();
    });
  }

  bool isCurrentLocationLayerActive =
      false; // Flag to control the visibility of the CurrentLocationLayer
  bool areAdditionalMarkersVisible =
      false; // Flag to control the visibility of additional markers

  void updateMarkerAndZoom() {
    // Remove the existing navigation marker if it exists
    if (navigationMarker != null) {
      markers.remove(navigationMarker);
    }

    // Update the marker and zoom level as before

    if (!isInitialZoom) {
      isInitialZoom =
          true; // Set the flag to true to prevent running the animation again

      // Store the initial zoom level and adjust the target zoom level
      double initialZoom = _animatedMapController.mapController.zoom;
      double targetZoom =
          initialZoom + 2.5; // Increase the targetZoom for more zoom-in effect

      // Create a custom zoom tween to smoothly animate the zoom level
      const animationDuration =
          Duration(seconds: 3); // Adjust the duration to control the smoothness

      // Create an AnimationController
      final animationController = AnimationController(
        vsync: this,
        duration: animationDuration,
      );

      // Create a zoom Tween
      final zoomTween = Tween<double>(begin: initialZoom, end: targetZoom);

      // Start the animation
      animationController.forward();

      // Add a listener to update the map's zoom level during the animation
      animationController.addListener(() {
        final currentZoom = zoomTween.evaluate(animationController);
        _animatedMapController.mapController.move(curloca, currentZoom);
      });
    } else {
      double currentZoom = _animatedMapController.mapController.zoom;

      if (currentZoom < 18.0) {
        _animatedMapController.mapController.move(curloca, 18.0);
      } else {
        _animatedMapController.mapController.move(curloca, currentZoom);
      }
    }

    // Set the flags to activate the layers
    isCurrentLocationLayerActive = true;
    areAdditionalMarkersVisible = true;
    // At this point, the layers should be added to the map automatically
  }

// ================WIDGET HIỆN TRÊN MÀN HÌNH CỦA APP ==================================================================================================================================================================================================================

// THAY THẾ ẢNH LOGO SKYSOFT Ở MÀN VIEW PC : MOBILE + TABLET VẪN HIỆN LOGO
  Widget placeholderImageWidget() {
    // PC SẼ ĐỂ ẨN MẤT ẢNH LOGO SKYSOFT CÒN MOBILE + TABLET VẪN HIỆN LOGO
    return Container(
      width: 250,
      height: 56,
      color: Colors.transparent,
    );
  }

// CÁC THÀNH PHẦN CHÍNH
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
        ), // ảnh logo
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
                zoom: 14,
                maxZoom: 18,
                minZoom: 3,
                center: const LatLng(21.03283599324495, 105.8398736375679),
              ),
              // tâm của bản đồ
              nonRotatedChildren: [
                Container(
                  alignment: Alignment.center,
                  child: const Icon(Icons.add),
                ),
              ],
              mapController: _animatedMapController.mapController,
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
                if (isCurrentLocationLayerActive) CurrentLocationLayer(),
                if (areAdditionalMarkersVisible)
                  MarkerLayer(
                    markers: [...markers, ...tappedMarkers],
                  ),
                // Add the CurrentLocationLayer and additional markers conditionally
              ],
            ),

            // HIỆU ỨNG CẢNH BÁO CẢ MÀN HÌNH
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

            Positioned(
              top: 85,
              right: 5,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isExpanded ? 80 : 60,
                    width: 60,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
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
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: rotateMapAroundMarker,
                        tooltip: 'Rotate around marker',
                        child: const Icon(Icons.cached),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: () {
                          moveMapCenterToSavedLatLng();
                        },
                        tooltip: 'Move Map Center to Saved LatLng',
                        child: const Icon(Icons.adjust),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: offsetUpAndZoomIn,
                        tooltip: 'Offset north',
                        child: const Icon(Icons.north),
                      ),
                    ), // moveMapCenterToLatLng(finalCenter);
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: () {
                          moveMapToSavedCenter(
                              finalDirection); // Pass the finalDirection value
                        },
                        tooltip: 'Center after offset',
                        child: const Icon(Icons.filter_tilt_shift),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: rotateMapLeft,
                        tooltip: 'Rotate Map Left',
                        child: const Icon(Icons.rotate_left),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: rotateMapRight,
                        tooltip: 'Rotate Map Right',
                        child: const Icon(Icons.rotate_right),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: zoomOut,
                        tooltip: 'Zoom Out',
                        child:
                            const Icon(Icons.zoom_in_map, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: zoomIn,
                        tooltip: 'Zoom In',
                        child:
                            const Icon(Icons.zoom_out_map, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        onPressed: centerMarkers,
                        tooltip: 'Center the Markers',
                        child: const Icon(Icons.center_focus_strong,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
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
            // NÚT BÊN TRÊN ĐẦU MÀN HÌNH
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
                                  fontWeight: FontWeight.bold,
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
              left: 3,
              child: FloatingActionButton(
                backgroundColor: Colors.cyan.shade500,
                onPressed: show60KmDialog,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // const Icon(Icons.speed),
                    Text(
                      speedText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // NÚT BÊN DƯỚI MÀN HÌNH
            Positioned(
              // The position for the polyline button based on screen size
              bottom: isDesktop
                  ? 110
                  : isTablet
                      ? 110
                      : 110,
              right: isDesktop
                  ? 20
                  : isTablet
                      ? 20
                      : 30,
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
              bottom: isDesktop
                  ? 110
                  : isTablet
                      ? 110
                      : 110,
              right: isDesktop
                  ? 200
                  : isTablet
                      ? 200
                      : 90,
              child: FloatingActionButton(
                backgroundColor: isTracking ? Colors.red : Colors.grey,
                onPressed:
                    toggleLocationTracking, // Toggle tracking on button press
                tooltip: isTracking ? 'Stop Tracking' : 'Start Tracking',
                child: Icon(
                  isTracking
                      ? Icons.location_disabled
                      : Icons.location_searching,
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
                      : 110,
              left: isDesktop
                  ? 20
                  : isTablet
                      ? 20
                      : 30,
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

  // THANH BOTTOM BAR SLIDE-UP
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
                        showSearchFullScreen(); // Call the function to show the fullscreen container
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
                      showSearchFullScreen(); // Call the function to show the fullscreen container
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
                        onTap: () {
                          handleHomeButton();
                        },
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showSearchFullScreen(); // Call the function to show the fullscreen container
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
                        onTap: () {
                          handleWorkButton();
                        },
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showSearchFullScreen(); // Call the function to show the fullscreen container
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
