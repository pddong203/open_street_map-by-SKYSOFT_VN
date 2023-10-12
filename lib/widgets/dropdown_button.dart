import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';

// ignore: must_be_immutable
class DropDownButton extends StatefulWidget {
  AnimatedMapController animatedMapController;
  Function clearAllMarkers;
  Function centerMarkers;

  DropDownButton({
    super.key,
    required this.animatedMapController,
    required this.clearAllMarkers,
    required this.centerMarkers,
  });

  @override
  State<DropDownButton> createState() => _DropDownButtonState();
}

class _DropDownButtonState extends State<DropDownButton>
    with TickerProviderStateMixin {
  bool isExpanded = false;
  late LatLng modifiedCenter;
  double finalDirection = 0.0;

  @override
  void initState() {
    super.initState();
    modifiedCenter = widget.animatedMapController.mapController.center;
  }

  void rotateMapAroundMarker() {
    // Calculate the desired rotation angle by decrementing 25 degrees from the current rotation.
    double desiredRotation =
        widget.animatedMapController.mapController.rotation - 25;

    // Define the total duration of the animation in milliseconds.
    const int animationDuration = 500;

    // Define the number of steps for the animation to achieve smooth rotation.
    const int totalSteps = 60;

    // Calculate the angle to rotate in each step to reach the desired rotation smoothly.
    double stepRotation = (desiredRotation -
            widget.animatedMapController.mapController.rotation) /
        totalSteps;

    // Calculate the delay between each step to control the animation speed.
    int stepDelay = animationDuration ~/ totalSteps;

    // Initialize a step counter to keep track of animation progress.
    int stepCount = 0;

    // Create a periodic timer to update the map rotation smoothly over time.
    Timer.periodic(Duration(milliseconds: stepDelay), (timer) {
      // Calculate the new rotation angle for this step.
      double newRotation =
          widget.animatedMapController.mapController.rotation + stepRotation;

      // Save the current map center before the rotation.
      LatLng currentMapCenter =
          widget.animatedMapController.mapController.center;

      // Update the map rotation using the mapController.rotateAroundPoint() method.
      double scale = 1.21473;
      double offsetLng = 248.07142;

      // Adjust the offsetLng based on the device screen height for proper map centering.
      if (MediaQuery.of(context).size.height < 896) {
        offsetLng = 248.07142;
      } else {
        offsetLng = 248.07142 * scale;
      }

      widget.animatedMapController.mapController
          .rotateAroundPoint(newRotation, offset: Offset(0, offsetLng));

      // Log the new rotation angle and the saved current map center.
      log("New Rotation: $newRotation, Current Map Center: $currentMapCenter");

      // Store the modified center after offset and rotation.
      modifiedCenter = widget.animatedMapController.mapController.center;

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
    double latOffsetIncrement = (savedLatitude -
            widget.animatedMapController.mapController.center.latitude) /
        totalSteps;
    double lngOffsetIncrement = (savedLongitude -
            widget.animatedMapController.mapController.center.longitude) /
        totalSteps;

    // Calculate the rotation increment
    double initialRotation =
        widget.animatedMapController.mapController.rotation;
    double rotationDelta = (desiredRotation - initialRotation);
    double rotationIncrement = rotationDelta / totalSteps;

    int stepCount = 0;

    Timer.periodic(
        const Duration(milliseconds: animationDuration ~/ totalSteps), (timer) {
      double newLatitude =
          widget.animatedMapController.mapController.center.latitude +
              latOffsetIncrement;
      double newLongitude =
          widget.animatedMapController.mapController.center.longitude +
              lngOffsetIncrement;

      // Calculate the desired zoom level (e.g., 18)
      double desiredZoom = 18;

      // Move the map using the mapController.move() method with the new latitude, longitude, and zoom level.
      widget.animatedMapController.mapController
          .move(LatLng(newLatitude, newLongitude), desiredZoom);

      // Calculate the new rotation angle
      double newRotation = initialRotation + stepCount * rotationIncrement;

      // Rotate the map using the mapController.rotate() method.
      widget.animatedMapController.mapController.rotate(newRotation);

      stepCount++;

      if (stepCount >= totalSteps) {
        // Move the map to the saved latitude and longitude with the desired zoom level.
        widget.animatedMapController.mapController
            .move(LatLng(savedLatitude, savedLongitude), desiredZoom);

        // Rotate the map to the desired final rotation
        widget.animatedMapController.mapController.rotate(desiredRotation);

        timer.cancel();
      }
    });
  }

  void rotateMap(double value) {
    widget.animatedMapController.animatedRotateFrom(
      value,
    );
  }

// ZOOM IN PHÓNG TO BẢN ĐỒ
  void zoomIn() {
    widget.animatedMapController.animatedZoomIn();
  }

// ZOOM OUT THU NHỎ BẢN ĐỒ
  void zoomOut() {
    widget.animatedMapController.animatedZoomOut();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
                // onPressed: () => rotateMap(widget, 10), MẪU CỦA ANH AN
                onPressed: () {
                  return rotateMap(-90);
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
                onPressed: () => rotateMap(90),
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
                child: const Icon(Icons.zoom_in_map, color: Colors.white),
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
                child: const Icon(Icons.zoom_out_map, color: Colors.white),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton(
                backgroundColor: Colors.blueGrey,
                onPressed: () => widget.centerMarkers(),
                tooltip: 'Center the Markers',
                child:
                    const Icon(Icons.center_focus_strong, color: Colors.white),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton(
                backgroundColor: Colors.blueGrey,
                onPressed: () => widget.clearAllMarkers(),
                tooltip: 'Clear Marker onTAP',
                child: const Icon(Icons.clear_all, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
