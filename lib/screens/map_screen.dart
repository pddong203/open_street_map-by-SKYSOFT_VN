import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skysoft/models/info_location.dart';
import 'package:skysoft/models/tilt.dart';
import 'package:skysoft/widgets/app_bar.dart';
import 'package:skysoft/widgets/side_bar.dart';
import 'package:http/http.dart' as http;
import 'package:skysoft/widgets/button_view.dart';
import 'package:skysoft/widgets/kdgaugeview.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// ========== CLASS CHO MAIN CHẠY ===================================================================================================================================================================
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

//========= CLASS CHÍNH ================================================================================================================================================================================
class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  //  KHAI BÁO CÁC BIẾN
  bool isCurrentLocationLayerActive = false;
  bool areAdditionalMarkersVisible = false;
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
  //Marker tracking
  double? currentSpeed = 0.0;
  ValueNotifier<double> speedNotifier = ValueNotifier<double>(0.0);
  late bool _navigationMode;
  late int _pointerCount;
  late FollowOnLocationUpdate _followOnLocationUpdate;
  late TurnOnHeadingUpdate _turnOnHeadingUpdate;
  late StreamController<double?> _followCurrentLocationStreamController;
  late StreamController<void> _turnHeadingUpStreamController;
  //SEARCH BAR:
  final MapController mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<InfoLocation> _options = <InfoLocation>[];
  LatLng route = const LatLng(0, 0);
  //Animation map
  int tapCount = 0;
  late final _animatedMapController = AnimatedMapController(vsync: this);
  bool isInitialZoom = false;
  late LatLng finalCenter;
  double tilt = 0.0;

// ================WIDGET HIỆN TRÊN MÀN HÌNH CỦA APP ==================================================================================================================================================================================================================//
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1024;
    final isTablet = screenSize.width <= 1024 && screenSize.width > 600;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppBarWidget(),
      drawer: Sidebar(
        onClose: toggleSidebar,
      ),
      // THANH BOTTOM BAR BUTTON BÊN TRONG CUỐI CÙNG
      body: SlidingUpPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
        panelBuilder: (ScrollController sc) => scrollingList(sc),
        // BẢN ĐỒ VÀ CÁC NÚT
        body: Stack(
          children: [
            TiltedMap(
              tilt: tilt,
              child: FlutterMap(
                options: MapOptions(
                  onTap: (tapPosition, point) => handleMapTap(point),
                  zoom: 15,
                  maxZoom: 18,
                  minZoom: 3,
                  center: const LatLng(21.053306461723658, 105.77996412889881),
                  onPointerDown: _onPointerDown,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerUp,
                ),
                mapController: _animatedMapController.mapController,
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),

                  MarkerLayer(
                    rotate: true,
                    markers: [...markers, ...tappedMarkers],
                  ),

                  // Conditionally render CurrentLocationLayer and additional markers
                  if (isCurrentLocationLayerActive)
                    Visibility(
                      visible:
                          !_navigationMode, // Hide if _navigationMode is true
                      child: CurrentLocationLayer(),
                    ),
                  if (isCurrentLocationLayerActive && _navigationMode)
                    CurrentLocationLayer(
                      followScreenPoint: const CustomPoint(0.0, 0.40),
                      followScreenPointOffset: const CustomPoint(0.0, -50.0),
                      followOnLocationUpdate: _followOnLocationUpdate,
                      turnOnHeadingUpdate: _turnOnHeadingUpdate,
                      style: const LocationMarkerStyle(
                        marker: Icon(
                          Icons.navigation,
                          color: Colors.green,
                        ),
                        markerSize: Size(40, 40),
                        markerDirection: MarkerDirection.heading,
                      ),
                    ),

                  if (areAdditionalMarkersVisible)
                    MarkerLayer(
                      rotate: true,
                      markers: [...markers, ...tappedMarkers],
                    ),
                ],
              ),
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
              top: 90,
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
                    // const SizedBox(height: 3),
                    // SizedBox(
                    //   width: 40,
                    //   height: 40,
                    //   child: FloatingActionButton(
                    //     backgroundColor: Colors.blueGrey,
                    //     onPressed: () {
                    //       moveMapCenterToSavedLatLng();
                    //     },
                    //     tooltip: 'Move Map Center to Saved LatLng',
                    //     child: const Icon(Icons.adjust),
                    //   ),
                    // ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FloatingActionButton(
                        backgroundColor: Colors.blueGrey,
                        // onPressed: () => rotateMap(_animatedMapController, 10), MẪU CỦA ANH AN
                        onPressed: () {
                          rotateMapLeft();
                        },
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
            ButtonGlowSos(25, 150, context, toggleStackVisibility),
            ButtonGlowWarning(25, 5, context),
            ButtonNormal(
                isDesktop, isTablet, 20, 20, 30, tilt == 0.0, _toggleTilt),
            ButtonNormal(
                isDesktop, isTablet, 100, 80, 90, tilt == 0.0, _toggleTracking),
            Positioned(
              bottom: isDesktop
                  ? 110
                  : isTablet
                      ? 110
                      : 110,
              right: isDesktop
                  ? 100
                  : isTablet
                      ? 80
                      : 90,
              child: FloatingActionButton(
                backgroundColor: _navigationMode ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                onPressed: () {
                  setState(
                    () {
                      _navigationMode = !_navigationMode;
                      _followOnLocationUpdate = _navigationMode
                          ? FollowOnLocationUpdate.always
                          : FollowOnLocationUpdate.never;
                      _turnOnHeadingUpdate = _navigationMode
                          ? TurnOnHeadingUpdate.always
                          : TurnOnHeadingUpdate.never;
                    },
                  );
                  if (_navigationMode) {
                    _followCurrentLocationStreamController.add(18);
                    _turnHeadingUpStreamController.add(null);
                  }
                },
                child: Icon(
                  _navigationMode ? Icons.near_me_disabled : Icons.near_me,
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
            Speedometer()
          ],
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget Speedometer() {
    final key = GlobalKey<KdGaugeViewState>();
    updateSpeed(speedNotifier);

    return Positioned(
      top: 85,
      left: 4,
      child: SpeedometerWidget(speedNotifier: speedNotifier, key: key),
    );
  }

  // ignore: non_constant_identifier_names
  Widget SpeedometerWidget({
    required final ValueNotifier<double> speedNotifier,
    required final GlobalKey<KdGaugeViewState> key,
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(30),
        ),
        child: ValueListenableBuilder<double>(
          valueListenable: speedNotifier,
          builder: (context, value, child) {
            if (kDebugMode) {
              print(value);
            }
            return KdGaugeView(
              key: key,
              minSpeed: 0,
              maxSpeed: 100,
              speed: value,
              animate: false,
              alertSpeedArray: const [40, 80, 90],
              alertColorArray: const [Colors.yellow, Colors.orange, Colors.red],
              duration: const Duration(seconds: 10),
            );
          },
        ),
      ),
    );
  }

  // THANH BOTTOM BAR SLIDE-UP
  Widget scrollingList(ScrollController sc) {
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

        _options =
            decodedResponse.map((e) => InfoLocation.fromJson(e)).toList();

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

  void _toggleTilt() {
    setState(() {
      tilt = (tilt == 0.0) ? 45.0 : 0.0;
    });
  }

  void _toggleTracking() {
    setState(
      () {
        _navigationMode = !_navigationMode;
        _followOnLocationUpdate = _navigationMode
            ? FollowOnLocationUpdate.always
            : FollowOnLocationUpdate.never;
        _turnOnHeadingUpdate = _navigationMode
            ? TurnOnHeadingUpdate.always
            : TurnOnHeadingUpdate.never;
      },
    );
    if (_navigationMode) {
      _followCurrentLocationStreamController.add(18);
      _turnHeadingUpStreamController.add(null);
    }
  }

// NÚT SAVE MARKER
  // void showSaveMarkersList() async {
  //   log("message");
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) {
  //       return SavedMarkersList(
  //         savedMarkers: savedMarkers,
  //         onRemoveMarker: (LatLng marker) {
  //           removeMarkerFromList(marker, savedMarkers);
  //         },
  //         onShowMarkerOnMap: (LatLng marker) {
  //           showMarkerOnMap(marker);
  //         },
  //       );
  //     },
  //   );
  // }

  // void updateSavedMarkers(List<LatLng> markers) {
  //   setState(() {
  //     savedMarkers = markers;
  //   });
  // }

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

  void toggleStackVisibility() {
    setState(() {
      isStackVisible = !isStackVisible;
    });
  }

// MỞ SIDEBAR
  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

// THANH SEARCH SLIDE BOTTOM BAR
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
                  Navigator.of(context).pop();
                  showSearchFullScreen(); // Close the existing modal
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
                                            // showSaveMarkersList();
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
                            Navigator.of(context).pop();
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
                            Navigator.of(context).pop();
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
                      repNameLocation(value).then((value) {
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
        // ignore: dead_code
        Navigator.of(context).pop();
        showSearchFullScreen();
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text(
            'Save Home Address',
            style: TextStyle(color: Colors.pinkAccent),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to save this address as your home?',
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 16),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                saveHomeAddress(
                    address, latitude, longitude); // Lưu địa chỉ và tọa độ
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context).pop(); // Đóng dialog
                showHomeAddress();
                _searchController.clear();
                _options.clear();
                handleHomeButton();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Yes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
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
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Đặt bo tròn viền
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8), // Màu nền nhạt hơn
              borderRadius: BorderRadius.circular(20.0), // Đặt bo tròn viền
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white), // Màu biểu tượng
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
                    color: Colors.white, // Đặt màu cho tiêu đề
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Are you sure you want to delete your home address?',
                  style: TextStyle(
                    color: Colors.white, // Đặt màu cho nội dung
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    deleteHomeAddress();
                    Navigator.of(context).pop(); // Đóng dialog
                    Navigator.of(context).pop();
                    showSearchBar();
                    _searchController.clear();
                    _options.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Màu nền nút
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20.0), // Đặt bo tròn nút
                    ),
                  ),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ),
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
          backgroundColor: Colors.white, // Màu nền nhạt hơn
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Đặt bo tròn viền
          ),
          title: const Text(
            'Save Work Address',
            style: TextStyle(color: Colors.brown), // Đặt màu cho tiêu đề
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to save this address as your work?',
                style: TextStyle(color: Colors.black), // Đặt màu cho nội dung
              ),
              SizedBox(height: 16), // Khoảng cách giữa nội dung và nút
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                saveWorkAddress(address, latitude, longitude); // Lưu địa chỉ
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context).pop(); // Đóng dialog
                showWorkAddress();
                _searchController.clear();
                _options.clear();
                handleWorkButton(); // Xử lý hành động của nút Work Address
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Màu nền nút
              ),
              child: const Text('Yes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Màu nền nút
              ),
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
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const Text(
                  'Delete Work Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Are you sure you want to delete your work address?',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    deleteWorkAddress();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    showSearchBar();
                    _searchController.clear();
                    _options.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ),
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

// setup data khi khởi động app (thoát app hoặc tắt đa nhiệm vẫn lưu dữ liệu trừ khi gỡ bỏ)
  @override
  void initState() {
    super.initState();
    updateSpeed(speedNotifier);
    showHomeAddress();
    showWorkAddress();
    // loadSavedMarkers(updateSavedMarkers);
    showStackRepeatedly();
    markers.addAll([
      Marker(
        point: const LatLng(21.05330395855624, 105.77996412889745),
        width: 80,
        height: 80,
        builder: (context) => IconButton(
          onPressed: () {},
          icon: const Icon(Icons.pin_drop),
          color: Colors.orange,
          iconSize: 35,
        ),
      ),
    ]);
    // MARKER NAVIAGETION
    _navigationMode = false;
    _pointerCount = 0;
    _followOnLocationUpdate = FollowOnLocationUpdate.never;
    _turnOnHeadingUpdate = TurnOnHeadingUpdate.never;
    _followCurrentLocationStreamController = StreamController<double?>();
    _turnHeadingUpStreamController = StreamController<void>();
  }

  @override
  void dispose() {
    _followCurrentLocationStreamController.close();
    _turnHeadingUpStreamController.close();
    super.dispose();
  }

  void updateSpeed(ValueNotifier<double> speedNotifier) async {
    Position data = await _determinePosition();
    double speed = data.speed; // Speed in m/s

    // Convert speed to km/h
    double speedKmH = speed * 3.6;

    // Update the current speed
    speedNotifier.value = speedKmH;
  }

  // void updateSpeed1() async {
  //   // Position data = await _determinePosition();
  //   // Convert speed to km/h

  //   double speed = kdgaueModel.currentSpeed! + 10;
  //   double speedKmH = speed * 3.6;
  //   // Update the current speed
  //   // speedNotifier.value = speedKmH;
  //   kdgaueModel.updateSpeed(speedKmH);

  //   setState(() {});
  // }

// Disable follow and turn temporarily when user is manipulating the map.
  void _onPointerDown(e, l) {
    _pointerCount++;
    setState(() {
      _followOnLocationUpdate = FollowOnLocationUpdate.never;
      _turnOnHeadingUpdate = TurnOnHeadingUpdate.never;
    });
  }

  // Enable follow and turn again when user end manipulation.
  void _onPointerUp(e, l) {
    if (--_pointerCount == 0 && _navigationMode) {
      setState(() {
        _followOnLocationUpdate = FollowOnLocationUpdate.always;
        _turnOnHeadingUpdate = TurnOnHeadingUpdate.always;
      });
      _followCurrentLocationStreamController.add(18);
      _turnHeadingUpStreamController.add(null);
    }
  }

// THÊM MARKER LÊN BẢN ĐỒ BẰNG SEARCH BAR
  void showMarkerOnMap(LatLng location) {
    setState(() {
      tappedMarkers.add(
        Marker(
          point: location,
          width: 80,
          height: 80,
          builder: (context) => IconButton(
            icon: const Icon(Icons.location_on),
            color: Colors.red,
            iconSize: 45,
            onPressed: () => {handleMarkerTap(location)},
          ),
        ),
      );
      _animatedMapController.centerOnPoint(location);
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
            icon: const Icon(Icons.location_on),
            color: Colors.blue,
            iconSize: 45,
            onPressed: () => handleMarkerTap(tappedPoint),
          ),
        ),
      );
      _animatedMapController.centerOnPoint(tappedPoint);
    });
  }

// XEM THÔNG TIN CỦA MARKER ĐÓ ( POPUP HIỆN SAVE MARKER + DELETE MARKER + CLOSE)
  Future<void> handleMarkerTap(LatLng tappedPoint) {
    // Show the information about the marker (latitude and longitude)
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // Log the latitude and longitude of the tapped marker
        log("Tapped Marker - Latitude: ${tappedPoint.latitude}, Longitude: ${tappedPoint.longitude}");

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
                // await saveMarkersToSharedPreferences(savedMarkers);
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
    );
  }

// ROTATE CẢ BẢN ĐỒ THEO TÂM 90 ĐỘ PHẢI
  void rotateMapRight() {
    _animatedMapController.animatedRotateFrom(
      -90,
    );
  }

// ZOOM IN PHÓNG TO BẢN ĐỒ
  void zoomIn() {
    _animatedMapController.animatedZoomIn();
  }

// ZOOM OUT THU NHỎ BẢN ĐỒ
  void zoomOut() {
    _animatedMapController.animatedZoomOut();
  }

// XÓA TẤT CẢ MARKER ONTAP HOẶC SEARCH TRÊN BẢN ĐỒ ( VỊ TRÍ HIỆN TẠI SẼ K XÓA)
  void clearAllMarkers() {
    setState(() {
      tappedMarkers.clear();
    });
  }

// XOAY ĐIỀU HƯỚNG TÂM XOAY QUANH ĐIỂM OFFSET
  double finalDirection = 0.0;
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
      log("New Rotation: $newRotation, Current Map Center: $currentMapCenter");

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
        log("Final Direction: $finalDirection");

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

  // void toggleLocationTracking() {
  //   if (isTracking) {
  //     stopLocationTracking(); // If tracking is active, stop it
  //   } else {
  //     startLocationTracking(); // If tracking is inactive, start it
  //   }
  // }

  // void startLocationTracking() {
  //   // Set up a periodic timer to update the location and speed
  //   timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
  //     if (kDebugMode) {
  //       print("Updating location and speed...");
  //     }
  //     currentLoc1(); // Call the current location update function
  //   });

  //   isTracking = true; // Set tracking state to active
  // }

  // void stopLocationTracking() {
  //   // Cancel the timer and reset tracking state
  //   timer?.cancel();
  //   isTracking = false;
  // }

  // void currentLoc1() async {
  //   Position data = await _determinePosition();
  //   double speed = data.speed; // Speed in m/s

  //   // Update the speed text with rounded value
  //   int roundedSpeed =
  //       (speed * 3.6).toInt(); // Round the speed to the nearest integer
  //   speedText = "$roundedSpeed km/h";

  //   setState(() {
  //     curloca = LatLng(data.latitude, data.longitude);
  //     updateMarkerAndZoom1(); // Update using the new function
  //   });
  // }

  // void updateMarkerAndZoom1() {
  //   double latOffsetIncrement = 0.0013;
  //   const double scale = 1.25;

  //   double offsetIncrement;
  //   if (MediaQuery.of(context).size.height < 896) {
  //     offsetIncrement = 0.00002;
  //   } else {
  //     offsetIncrement = 0.00002 * scale;
  //   }

  //   // Calculate the new center based on the marker's position and offset
  //   LatLng newCenter = LatLng(
  //     curloca.latitude + latOffsetIncrement,
  //     curloca.longitude + offsetIncrement,
  //   );

  //   // Remove the existing navigation marker if it exists
  //   if (navigationMarker != null) {
  //     markers.remove(navigationMarker);
  //   }

  //   // Create a new navigation marker
  //   navigationMarker = Marker(
  //     point: curloca,
  //     width: 80,
  //     height: 80,
  //     builder: (ctx) =>
  //         buildNavigationMarker(ctx, speedText), // Update the marker's builder
  //   );

  //   // Add the new navigation marker to the markers list
  //   markers.add(navigationMarker!);

  //   // Move the map to the new center with a zoom level of 18
  //   _animatedMapController.mapController.move(newCenter, 18.0);

  //   // Save the final center and direction after updating the marker and zooming
  //   finalCenter = newCenter;
  //   finalDirection = _animatedMapController.mapController.rotation;
  // }

  // IconButton buildNavigationMarker(BuildContext context, String speedText) {
  //   return IconButton(
  //     onPressed: () {},
  //     icon: const Icon(Icons.navigation),
  //     color: Colors.greenAccent.shade700,
  //     iconSize: 40,
  //   );
  // }

// TÌM VỊ TRÍ HIỆN TẠI CỦA NGƯỜI DÙNG QUA GPS
  void currentLoc() async {
    Position data = await _determinePosition();

    setState(() {
      curloca = LatLng(data.latitude, data.longitude);
      updateMarkerAndZoom();
    });
  }

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
}
