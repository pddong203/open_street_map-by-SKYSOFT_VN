import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Remove marker at a specific index
Future<void> removeMarkerAtIndex(int index) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? markerStrings = prefs.getStringList('savedMarkers');
    if (markerStrings != null && index >= 0 && index < markerStrings.length) {
      markerStrings.removeAt(index);
      await prefs.setStringList('savedMarkers', markerStrings);
      if (kDebugMode) {
        print('Marker removed successfully at index: $index');
      }
    } else {
      if (kDebugMode) {
        print('Invalid index or marker not found at index: $index');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error removing marker: $e');
    }
  }
}

// Save a marker to SharedPreferences
Future<void> saveMarkerToSharedPreferences(String marker) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? markerStrings = prefs.getStringList('savedMarkers');
  markerStrings = markerStrings ?? [];
  markerStrings.add(marker);

  await prefs.setStringList('savedMarkers', markerStrings);
}

// Load markers from SharedPreferences
Future<void> loadSavedMarkers(Function(List<LatLng>) onLoadedMarkers) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? markerStrings = prefs.getStringList('savedMarkers');
    if (markerStrings != null) {
      List<LatLng> loadedMarkers = [];
      for (String markerString in markerStrings) {
        List<String> parts = markerString.split(',');
        if (parts.length >= 2) {
          double latitude = double.parse(parts[0]);
          double longitude = double.parse(parts[1]);
          loadedMarkers.add(LatLng(latitude, longitude));
        }
      }
      onLoadedMarkers(loadedMarkers);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error loading markers: $e');
    }
  }
}
