import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:skysoft/models/tilt.dart';
import 'package:skysoft/screens/app_bar.dart';
import 'package:skysoft/screens/side_bar.dart';
import 'package:skysoft/utils/save_marker_list_logic.dart';
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

  double tilt = 0.0;
  bool isShowDrawer = false;
  late int _pointerCount;
  late CurrentLocation currentLocation;
  List<Marker> tappedMarkers = [];
  List<LatLng> savedMarkers = [];

  @override
  void initState() {
    super.initState();
    _pointerCount = 0;
    currentLocation = CurrentLocation(
        isCurrentLocationLayerActive: true,
        navigationMode: true,
        turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
        followOnLocationUpdate: FollowOnLocationUpdate.never,
        followCurrentLocationStreamController: StreamController<double?>(),
        turnHeadingUpStreamController: StreamController<void>());
  }

  void _onPointerDown(e, l) {
    // log("_onPointerDown");
    _pointerCount++;
    setState(() {
      currentLocation = CurrentLocation(
          isCurrentLocationLayerActive: true,
          navigationMode: true,
          turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
          followOnLocationUpdate: FollowOnLocationUpdate.never,
          followCurrentLocationStreamController: StreamController<double?>(),
          turnHeadingUpStreamController: StreamController<void>());
    });
  }

  // Enable follow and turn again when user end manipulation.
  void _onPointerUp(e, l) {
    // log("_onPointerUp");
    if (--_pointerCount == 0) {
      setState(() {
        StreamController<double?> followCurrentLocationStreamController =
            StreamController<double?>();
        followCurrentLocationStreamController.add(18);

        StreamController<void> turnHeadingUpStreamController =
            StreamController<void>();
        turnHeadingUpStreamController.add(null);
        currentLocation = CurrentLocation(
            isCurrentLocationLayerActive: true,
            navigationMode: true,
            turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
            followOnLocationUpdate: FollowOnLocationUpdate.never,
            followCurrentLocationStreamController:
                followCurrentLocationStreamController,
            turnHeadingUpStreamController: turnHeadingUpStreamController);
      });
    }
  }

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
            onPressed: () => infoDialog(tappedPoint),
          ),
        ),
      );
      _animatedMapController.centerOnPoint(tappedPoint);
    });
  }

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

  void clearAllMarkers() {
    setState(() {
      tappedMarkers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        panel: const PanelBar(),
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
                  currentLocation,
                  MarkerLayer(
                    rotate: true,
                    markers: [
                      Marker(
                        point:
                            const LatLng(21.05330395855624, 105.77996412889745),
                        width: 80,
                        height: 80,
                        builder: (context) => IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.pin_drop),
                          color: Colors.orange,
                          iconSize: 35,
                        ),
                      )
                    ],
                  ),
                  MarkerLayer(
                    rotate: true,
                    markers: tappedMarkers,
                  ),
                ],
              ),
            ),
            DropDownButton(
              animatedMapController: _animatedMapController,
              clearAllMarkers: clearAllMarkers,
            ),
          ],
        ),
      ),
    );
  }
}
