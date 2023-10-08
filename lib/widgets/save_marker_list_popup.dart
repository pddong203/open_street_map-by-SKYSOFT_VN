import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:skysoft/utils/save_marker_list_logic.dart';

class SavedMarkersList extends StatefulWidget {
  const SavedMarkersList({
    Key? key,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SavedMarkersListState createState() => _SavedMarkersListState();
}

class _SavedMarkersListState extends State<SavedMarkersList> {
  List<LatLng> savedMarkers = [];

  @override
  void initState() {
    super.initState();
    loadSavedMarkers();
  }

  void loadSavedMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? markerStrings = prefs.getStringList('savedMarkers');
    if (markerStrings != null) {
      setState(() {
        savedMarkers = markerStrings.map((markerString) {
          List<String> parts = markerString.split(',');
          double latitude = double.parse(parts[0]);
          double longitude = double.parse(parts[1]);
          return LatLng(latitude, longitude);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                      setState(() {
                                        savedMarkers.remove(marker);
                                      });
                                      saveMarkersToSharedPreferences(
                                          savedMarkers);
                                      Navigator.pop(dialogContext);
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
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
