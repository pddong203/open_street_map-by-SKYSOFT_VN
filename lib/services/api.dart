import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// API THANH SEARCH
Future<List<dynamic>> repNameLocation(String value) async {
  try {
    String url =
        'https://nominatim.openstreetmap.org/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';

    var response =
        await http.get(Uri.parse(url)); // Use http.get for a GET request

    if (response.statusCode == 200) {
      var decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return decodedResponse;
    }
  } catch (error) {
    // Handle any exceptions that occur during the process
    if (kDebugMode) {
      print('Error: $error');
    }
  }
  return [];
}
