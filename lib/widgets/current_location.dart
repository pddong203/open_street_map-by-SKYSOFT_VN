import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class CurrentLocation extends StatefulWidget {
  bool isCurrentLocationLayerActive;
  bool navigationMode;
  FollowOnLocationUpdate followOnLocationUpdate;
  TurnOnHeadingUpdate turnOnHeadingUpdate;
  StreamController<double?> followCurrentLocationStreamController;
  StreamController<void> turnHeadingUpStreamController;
  CurrentLocation(
      {super.key,
      required this.isCurrentLocationLayerActive,
      required this.navigationMode,
      required this.followOnLocationUpdate,
      required this.turnOnHeadingUpdate,
      required this.followCurrentLocationStreamController,
      required this.turnHeadingUpStreamController});
  @override
  State<CurrentLocation> createState() => _CurrentLocationState();
}

class _CurrentLocationState extends State<CurrentLocation> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.followCurrentLocationStreamController.close();
    widget.turnHeadingUpStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurrentLocationLayer(
      followScreenPoint: const CustomPoint(0.0, 0.40),
      followScreenPointOffset: const CustomPoint(0.0, -50.0),
      followOnLocationUpdate: widget.followOnLocationUpdate,
      turnOnHeadingUpdate: widget.turnOnHeadingUpdate,
      style: widget.navigationMode
          ? const LocationMarkerStyle(
              marker: Icon(
                Icons.navigation,
                color: Colors.green,
              ),
              markerSize: Size(40, 40),
              markerDirection: MarkerDirection.heading,
            )
          : const LocationMarkerStyle(),
    );
  }
}
