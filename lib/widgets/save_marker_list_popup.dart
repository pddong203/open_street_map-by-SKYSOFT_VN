import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart'; // Import the package for LatLng if needed

class SavedMarkersList extends StatelessWidget {
  final List<LatLng> savedMarkers;
  final Function(LatLng) onRemoveMarker;
  final Function(LatLng) onShowMarkerOnMap;

  const SavedMarkersList({
    super.key,
    required this.savedMarkers,
    required this.onRemoveMarker,
    required this.onShowMarkerOnMap,
  });

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
                                      onRemoveMarker(marker);
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
                        onShowMarkerOnMap(marker);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
          // ...
        ],
      ),
    );
  }
}
