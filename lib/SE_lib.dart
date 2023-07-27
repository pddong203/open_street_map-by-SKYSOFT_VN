// ignore: file_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SE extends StatefulWidget {
  const SE({
    Key? key,
  }) : super(key: key);

  @override
  State<SE> createState() => _SEState();
}

class LatLong {
  final double latitude;
  final double longitude;
  LatLong(this.latitude, this.longitude);
}

class InfoLocation {
  final String displayname;
  final double lat;
  final double lon;
  InfoLocation(
      {required this.displayname, required this.lat, required this.lon});
  @override
  String toString() {
    return displayname;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is InfoLocation && other.displayname == displayname;
  }

  @override
  int get hashCode => Object.hash(displayname, lat, lon);
}

class _SEState extends State<SE> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<InfoLocation> _options = <InfoLocation>[];
  List<Marker> markers = [];
  List<Marker> tappedMarkers = [];
  Timer? _debounce;
  var client = http.Client();

  void handleMapTap(LatLng location) {
    setState(() {
      tappedMarkers.add(
        // Add the tapped marker to the tappedMarkers list
        Marker(
          point: location,
          width: 80,
          height: 80,
          builder: (context) => IconButton(
            icon: const Icon(Icons.location_on),
            color: Colors.blue,
            iconSize: 45,
            onPressed: () {},
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Stack(
      children: [
        Positioned.fill(
            child: FlutterMap(
          options: MapOptions(zoom: 15.0, maxZoom: 18, minZoom: 6),
          mapController: _mapController,
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
              // attributionBuilder: (_) {
              //   return Text("© OpenStreetMap contributors");
              // },
            ),
            MarkerLayer(
              rotate: true,
              markers: [...markers, ...tappedMarkers],
            ),
          ],
        )),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                TextFormField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(),
                    onChanged: (String value) {
                      if (_debounce?.isActive ?? false) _debounce?.cancel();

                      _debounce =
                          Timer(const Duration(milliseconds: 150), () async {
                        if (kDebugMode) {
                          print(value);
                        }

                        await repNameLocation(value);
                      });
                    }),
                StatefulBuilder(builder: ((context, setState) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _options.length > 5 ? 5 : _options.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_options[index].displayname),
                        onTap: () {
                          _mapController.move(
                            LatLng(_options[index].lat, _options[index].lon),
                            15.0,
                          );

                          _focusNode.unfocus();
                          handleMapTap(
                              LatLng(_options[index].lat, _options[index].lon));

                          _options.clear();
                          setState(() {});
                        },
                      );
                    },
                  );
                })),
              ],
            ),
          ),
        ),
      ],
    )));
  }

  Future<void> repNameLocation(String value) async {
    var client = http.Client();
    try {
      String url =
          'https://nominatim.openstreetmap.org/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';
      if (kDebugMode) {
        print(url);
      }
      var response = await client.post(Uri.parse(url));
      var decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      if (kDebugMode) {
        print(decodedResponse);
      }
      _options = decodedResponse
          .map((e) => InfoLocation(
              displayname: e['display_name'],
              lat: double.parse(e['lat']),
              lon: double.parse(e['lon'])))
          .toList();
      setState(() {});
    } finally {
      client.close();
    }
    setState(() {});
  }
}
