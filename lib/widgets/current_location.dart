// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class CurrentLocation extends StatelessWidget {
  final bool navigationMode;
  final FollowOnLocationUpdate followOnLocationUpdate;
  final TurnOnHeadingUpdate turnOnHeadingUpdate;
  final StreamController<double?> followCurrentLocationStreamController;
  final StreamController<void> turnHeadingUpStreamController;

  const CurrentLocation({
    Key? key,
    required this.navigationMode,
    required this.followOnLocationUpdate,
    required this.turnOnHeadingUpdate,
    required this.followCurrentLocationStreamController,
    required this.turnHeadingUpStreamController,
    required Function() toggleCurrentLocationLayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log("CurrentLocation: $navigationMode");
    return navigationMode
        ? CurrentLocationLayer(
            followScreenPoint: const CustomPoint(0.0, 0.40),
            followScreenPointOffset: const CustomPoint(0.0, -50.0),
            followOnLocationUpdate: followOnLocationUpdate,
            turnOnHeadingUpdate: turnOnHeadingUpdate,
            style: const LocationMarkerStyle(
              marker: Icon(
                Icons.navigation,
                color: Colors.green,
              ),
              markerSize: Size.square(100),
              markerDirection: MarkerDirection.heading,
              showAccuracyCircle: false,
              showHeadingSector: false,
            ),
          )
        : CurrentLocationLayer();
  }
}
