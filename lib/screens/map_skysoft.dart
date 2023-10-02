import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:skysoft/models/tilt.dart';
import 'package:skysoft/screens/app_bar.dart';
import 'package:skysoft/screens/side_bar.dart';
import 'package:skysoft/utils/save_marker_list_logic.dart';
import 'package:skysoft/widgets/button_view.dart';
import 'package:skysoft/widgets/current_location.dart';
import 'package:skysoft/widgets/dropdown_button.dart';
import 'package:skysoft/widgets/panel_bar.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MapSkysoft extends StatefulWidget {
  const MapSkysoft({super.key});

  @override
  State<MapSkysoft> createState() => _MapSkysoftState();
}

class _MapSkysoftState extends State<MapSkysoft> with TickerProviderStateMixin {
  late final _animatedMapController = AnimatedMapController(vsync: this);
  MapController mapController = MapController();
  double tilt = 0.0;
  bool isShowDrawer = false;
  late int _pointerCount;
  late CurrentLocation currentLocation;
  List<Marker> tappedMarkers = [];
  List<LatLng> savedMarkers = [];
  List<Marker> markers = [];
  bool isShowingStack = true;
  bool isStackVisible = false;
  //TRACKING CURRENT LOCATION
  LatLng curloca = const LatLng(21.03276589493197, 105.83989509524008);
  late bool navigationMode;
  late int pointerCount;
  late FollowOnLocationUpdate followOnLocationUpdate;
  late TurnOnHeadingUpdate turnOnHeadingUpdate;
  late StreamController<double?> followCurrentLocationStreamController;
  late StreamController<void> turnHeadingUpStreamController;
  bool isCurrentLocationLayerActive = false;
  bool areAdditionalMarkersVisible = false;
  bool isInitialZoom = false;

// KHỞI TẠO DỮ LIỆU CHO APP KHI KHỞI ĐỘNG
  @override
  void initState() {
    super.initState();
    showStackRepeatedly();
    _pointerCount = 0;
    currentLocation = CurrentLocation(
      followCurrentLocationStreamController:
          followCurrentLocationStreamController = StreamController<double?>(),
      followOnLocationUpdate: followOnLocationUpdate =
          FollowOnLocationUpdate.never,
      navigationMode: navigationMode = false,
      turnHeadingUpStreamController: turnHeadingUpStreamController =
          StreamController<void>(),
      turnOnHeadingUpdate: turnOnHeadingUpdate = TurnOnHeadingUpdate.never,
      toggleCurrentLocationLayer: () {},
    );
  }

// Tắt tính năng theo dõi và rẽ tạm thời khi người dùng đang thao tác trên bản đồ.
  void _onPointerDown(e, l) {
    // log("_onPointerDown");
    _pointerCount++;

    currentLocation = CurrentLocation(
      navigationMode: navigationMode,
      turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
      followOnLocationUpdate: FollowOnLocationUpdate.never,
      followCurrentLocationStreamController: StreamController<double?>(),
      turnHeadingUpStreamController: StreamController<void>(),
      toggleCurrentLocationLayer: () {},
    );
    setState(() {});
  }

  // Cho phép theo dõi và quay lại khi người dùng kết thúc thao tác.
  void _onPointerUp(e, l) {
    if (--_pointerCount == 0) {
      StreamController<double?> followCurrentLocationStreamController =
          StreamController<double?>();
      followCurrentLocationStreamController.add(18);

      StreamController<void> turnHeadingUpStreamController =
          StreamController<void>();
      turnHeadingUpStreamController.add(null);

      currentLocation = CurrentLocation(
        navigationMode: navigationMode,
        turnOnHeadingUpdate: TurnOnHeadingUpdate.always,
        followOnLocationUpdate: FollowOnLocationUpdate.always,
        followCurrentLocationStreamController:
            followCurrentLocationStreamController,
        turnHeadingUpStreamController: turnHeadingUpStreamController,
        toggleCurrentLocationLayer: () {},
      );
      setState(() {});
    }
  }

// DÙNG GPS ĐỊNH VỊ VỊ TRÍ HIỆN TẠI
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

// TÌM VỊ TRÍ HIỆN TẠI
  void currentLoc() async {
    Position data = await _determinePosition();
    curloca = LatLng(data.latitude, data.longitude);
    updateMarkerAndZoom();
    // Toggle the visibility of the CurrentLocationLayer
    isCurrentLocationLayerActive = true;
    navigationMode = false;
    areAdditionalMarkersVisible = true;
    currentLocation = CurrentLocation(
      navigationMode: navigationMode,
      turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
      followOnLocationUpdate: FollowOnLocationUpdate.never,
      followCurrentLocationStreamController: StreamController<double?>(),
      turnHeadingUpStreamController: StreamController<void>(),
      toggleCurrentLocationLayer: () {},
    );
    setState(() {});
  }

// ANIMATION ZOOM VÀO VỊ TRÍ HIỆN TẠI
  void updateMarkerAndZoom() {
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
  }

// CHỨC NĂNG TILT NGHIÊNG 45 ĐỘ BẢN ĐỒ
  void toggleTilt() {
    setState(() {
      tilt = (tilt == 0.0) ? 45.0 : 0.0;
    });
  }

// SHOW MARKER MÀU ĐỎ LÊN BẢN ĐỒ ( THANH SEARCH + SAVE MARKER)
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
            onPressed: () => {infoDialog(location)},
          ),
        ),
      );
      _animatedMapController.centerOnPoint(location);
    });
  }

// TAP LÊN MÀN HÌNH SHOW MARKER LÊN BẢN ĐỒ
  void handleMapTap(LatLng tappedPoint) {
    setState(() {
      tappedMarkers.add(
        Marker(
          point: tappedPoint,
          width: 80,
          height: 80,
          builder: (context) => IconButton(
            icon: const Icon(Icons.location_on),
            color: Colors.blue,
            iconSize: 45,
            onPressed: () => infoDialog(tappedPoint),
          ),
        ),
      );
      _animatedMapController.centerOnPoint(tappedPoint);
    });
  }

// TAP VÀO MARKER MỞ DIALOG ( Save marker + Delete + Close)
  Future<void> infoDialog(LatLng tappedPoint) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
                        duration: Duration(
                            seconds: 2), // Thời gian hiển thị của SnackBar
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
            ));
  }

// XÓA CÁC MARKER CÓ TRÊN BẢN ĐỒ
  void clearAllMarkers() {
    setState(() {
      tappedMarkers.clear();
    });
  }

// HIỆU ỨNG NHÁY MÀU ĐỎ
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

// BẤM NÚT ĐỂ HIỆN HIỆU ỨNG CẢNH BÁO SOS
  void toggleStackVisibility() {
    setState(() {
      isStackVisible = !isStackVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1024;
    final isTablet = screenSize.width <= 1024 && screenSize.width > 600;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppBarWidget(),
      drawer: Sidebar(
        onClose: () => setState(() {
          isShowDrawer = !isShowDrawer;
        }),
      ),
      body: SlidingUpPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
        panel: PanelBar(showMarkerOnMap: showMarkerOnMap),
        onPanelOpened: () => {log("onPanelOpened")},
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
                  if (isCurrentLocationLayerActive) currentLocation,
                  MarkerLayer(
                    rotate: true,
                    markers: tappedMarkers,
                  ),
                ],
              ),
            ),
            // HIỆU ỨNG NHÁY MÀN HÌNH NGUY HIỂM
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
            // BUTTON BÊN TRÊN !
            DropDownButton(
              animatedMapController: _animatedMapController,
              clearAllMarkers: clearAllMarkers,
            ),
            ButtonGlowSos(25, 150, context, toggleStackVisibility),
            ButtonGlowWarning(25, 5, context),
            ButtonNormal(
                isDesktop, isTablet, 20, 20, 30, tilt == 0.0, toggleTilt),
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
                backgroundColor: navigationMode ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                onPressed: () {
                  navigationMode = !navigationMode;
                  followOnLocationUpdate = navigationMode
                      ? FollowOnLocationUpdate.always
                      : FollowOnLocationUpdate.never;
                  turnOnHeadingUpdate = navigationMode
                      ? TurnOnHeadingUpdate.always
                      : TurnOnHeadingUpdate.never;

                  if (navigationMode) {
                    followCurrentLocationStreamController.add(18);
                    turnHeadingUpStreamController.add(null);
                  }

                  currentLocation = CurrentLocation(
                    navigationMode: navigationMode,
                    turnOnHeadingUpdate: turnOnHeadingUpdate,
                    followOnLocationUpdate: followOnLocationUpdate,
                    followCurrentLocationStreamController:
                        followCurrentLocationStreamController,
                    turnHeadingUpStreamController:
                        turnHeadingUpStreamController,
                    toggleCurrentLocationLayer: () {},
                  );
                  setState(
                    () {},
                  );
                },
                child: Icon(
                  navigationMode ? Icons.near_me_disabled : Icons.near_me,
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
}
