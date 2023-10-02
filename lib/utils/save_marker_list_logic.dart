import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> removeMarkerFromList(
    LatLng marker, List<LatLng> savedMarkers) async {
  if (savedMarkers.contains(marker)) {
    savedMarkers.remove(marker);
    await saveMarkersToSharedPreferences(savedMarkers);
  }
}

Future<void> saveMarkersToSharedPreferences(List<LatLng> markers) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> markerList = markers
      .map((LatLng marker) => "${marker.latitude},${marker.longitude}")
      .toList();

  await prefs.setStringList('savedMarkers', markerList);
}

Future<void> loadSavedMarkers(Function(List<LatLng>) onLoadedMarkers) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? markerStrings = prefs.getStringList('savedMarkers');
  if (markerStrings != null) {
    List<LatLng> loadedMarkers = markerStrings.map((markerString) {
      List<String> parts = markerString.split(',');
      double latitude = double.parse(parts[0]);
      double longitude = double.parse(parts[1]);
      return LatLng(latitude, longitude);
    }).toList();
    onLoadedMarkers(loadedMarkers);
  }
}

// MẪU CỦA ANH AN 
// void rotateMap(AnimatedMapController animatedMapController, double rotate) {
//   if (rotate > 180) {
//     return;
//   }
//   animatedMapController.animatedRotateFrom(
//     rotate,
//   );
// }