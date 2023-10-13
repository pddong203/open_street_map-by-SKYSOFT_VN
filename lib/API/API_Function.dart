import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:skysoft/screens/map_screen.dart';

List<PointLatLng> decodedPoints = [];
String distance = '';
String time = '';
List<dynamic> instructions = [];
List<Map<String, String>> typedInstructions = [];
List<Polyline> signPolylines = [];
List<Marker> arrowMarkers = [];
int currentIndex = 0;
TextEditingController firstMarkerTextController = TextEditingController();
TextEditingController secondMarkerTextController = TextEditingController();

Future<void> pathInformation(dynamic responseData) async {
  String polylineString = responseData["paths"][0]["points"];
  PolylinePoints polylinePoints = PolylinePoints();
  decodedPoints = polylinePoints.decodePolyline(polylineString);
  latLngPoints = decodedPoints.map((point) {
    return LatLng(point.latitude, point.longitude);
  }).toList();

  distance = responseData["paths"][0]["distance"].toString();
  time = responseData["paths"][0]["time"].toString();
  var instructionsList = responseData["paths"][0]["instructions"];
  for (var instruction in instructionsList) {
    var pointsData = instruction["points"];
    if (pointsData != null) {
      var points = pointsData as List<dynamic>;
      if (points.length == 2) {
        double latitude = points[1];
        double longitude = points[0];
        pointsListIntruction.add(LatLng(latitude, longitude));
      }
    }
    // Chuyển đổi dữ liệu hướng dẫn thành kiểu Map<String, String>
    Map<String, String> typedInstruction = {
      "distance": instruction["distance"].toString(),
      "sign": instruction["sign"].toString(),
      "text": utf8.decode(instruction["text"].codeUnits),
      "time": instruction["time"].toString(),
      "street_name": utf8.decode(instruction["street_name"].codeUnits),
      "points": instruction["points"].toString(),
    };

    typedInstructions.add(typedInstruction);
  }
  instructions = typedInstructions;
}

// void calculateAndDisplaySignPolyline() {
//   for (int i = 1; i < latLngPoints.length - 1; i++) {
//     LatLng R1 = latLngPoints[i - 1];
//     LatLng R2 = latLngPoints[i];
//     LatLng R3 = latLngPoints[i + 1];

//     LatLng S2 = R2;

//     double s1Latitude = (R1.latitude + R2.latitude * 2) / 3;
//     double s1Longitude = (R1.longitude + R2.longitude * 2) / 3;
//     LatLng S1 = LatLng(s1Latitude, s1Longitude);

//     double s3Latitude = (R2.latitude * 2 + R3.latitude) / 3;
//     double s3Longitude = (R2.longitude * 2 + R3.longitude) / 3;
//     LatLng S3 = LatLng(s3Latitude, s3Longitude);

//     Polyline signPolyline = Polyline(
//       points: [S1, S2, S3],
//       color: Colors.red,
//       strokeWidth: 7,
//       borderStrokeWidth: 2,
//       borderColor: Colors.black,
//     );
//     signPolylines.add(signPolyline);
//     double angle =
//         math.atan2(S3.latitude - S2.latitude, S3.longitude - S2.longitude);
//     Marker arrowMarker = Marker(
//       point: S3,
//       width: 50,
//       height: 50,
//       builder: (context) {
//         if (angle >= -math.pi / 4 && angle <= math.pi / 4) {
//           return Transform.rotate(
//             angle: math.pi,
//             child: Stack(
//               children: [
//                 Positioned(
//                   top: 0,
//                   left: 0,
//                   right: 0,
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.black,
//                     size: 50,
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   left: 0,
//                   right: 0,
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.black,
//                     size: 50,
//                   ),
//                 ),
//                 Center(
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.red,
//                     size: 45,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         } else if (angle >= math.pi / 4 && angle <= 3 * math.pi / 4) {
//           return Transform.rotate(
//             angle: math.pi / 2,
//             child: Stack(
//               children: [
//                 Positioned(
//                   top: 0,
//                   left: 0,
//                   right: 0,
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.black,
//                     size: 50,
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   left: 0,
//                   right: 0,
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.black,
//                     size: 50,
//                   ),
//                 ),
//                 Center(
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.red,
//                     size: 45,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         } else if (angle >= -3 * math.pi / 4 && angle <= -math.pi / 4) {
//           return Transform.rotate(
//             angle: -math.pi / 2,
//             child: Stack(
//               children: [
//                 Positioned(
//                   top: 0,
//                   left: 0,
//                   right: 0,
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.black,
//                     size: 50,
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   left: 0,
//                   right: 0,
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.black,
//                     size: 50,
//                   ),
//                 ),
//                 Center(
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.red,
//                     size: 45,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         } else {
//           return Transform.rotate(
//             angle: 0,
//             child: Stack(
//               children: [
//                 Positioned(
//                   top: 0,
//                   left: 0,
//                   right: 0,
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.black,
//                     size: 50,
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   left: 0,
//                   right: 0,
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.black,
//                     size: 50,
//                   ),
//                 ),
//                 Center(
//                   child: Icon(
//                     Icons.arrow_left,
//                     color: Colors.red,
//                     size: 45,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//       },
//     );

//     //   Marker arrowMarker = Marker(
//     //     point: S3,
//     //     width: 50,
//     //     height: 50,
//     //     builder: (context) {
//     //       if (angle >= -math.pi / 4 && angle <= math.pi / 4) {
//     //         return Transform.rotate(
//     //           angle: math.pi, // Hướng lên trên
//     //           child: Icon(
//     //             Icons.arrow_left,
//     //             color: Colors.red,
//     //             size: 50,
//     //           ),
//     //         );
//     //       } else if (angle >= math.pi / 4 && angle <= 3 * math.pi / 4) {
//     //         return Transform.rotate(
//     //           angle: math.pi / 2, // Hướng sang trái
//     //           child: Icon(
//     //             Icons.arrow_left,
//     //             color: Colors.red,
//     //             size: 50,
//     //           ),
//     //         );
//     //       } else if (angle >= -3 * math.pi / 4 && angle <= -math.pi / 4) {
//     //         return Transform.rotate(
//     //           angle: -math.pi / 2, // Hướng sang phải
//     //           child: Icon(
//     //             Icons.arrow_left,
//     //             color: Colors.red,
//     //             size: 50,
//     //           ),
//     //         );
//     //       } else {
//     //         return Transform.rotate(
//     //           angle: 0, // Hướng xuống dưới
//     //           child: Icon(
//     //             Icons.arrow_left,
//     //             color: Colors.red,
//     //             size: 50,
//     //           ),
//     //         );
//     //       }
//     //     },
//     //   );
//     arrowMarkers.add(arrowMarker);
//   }
// }

void clearData() {
  instructions.clear();
  latLngPoints.clear();
  pointsListIntruction.clear();
  signPolylines.clear();
  arrowMarkers.clear();
  distance = "";
  time = "";
  currentIndex = 0;
}

void calculateAndDisplaySignPolyline() {
  double threshold = 0.00001; // Giá trị chênh lệch để tính xấp xỉ

  for (int i = 1; i < latLngPoints.length - 1; i++) {
    LatLng R1 = latLngPoints[i - 1];
    LatLng R2 = latLngPoints[i];
    LatLng R3 = latLngPoints[i + 1];

    for (LatLng instructionPoint in pointsListIntruction) {
      // Tính khoảng cách giữa R2 và điểm trong pointsListIntruction
      double distance = math.sqrt(
        math.pow(R2.latitude - instructionPoint.latitude, 2) +
            math.pow(R2.longitude - instructionPoint.longitude, 2),
      );

      if (distance < threshold) {
        LatLng S2 = R2;

        double s1Latitude = (R1.latitude + R2.latitude * 2) / 3;
        double s1Longitude = (R1.longitude + R2.longitude * 2) / 3;
        LatLng S1 = LatLng(s1Latitude, s1Longitude);

        double s3Latitude = (R2.latitude * 2 + R3.latitude) / 3;
        double s3Longitude = (R2.longitude * 2 + R3.longitude) / 3;
        LatLng S3 = LatLng(s3Latitude, s3Longitude);

        Polyline signPolyline = Polyline(
          points: [S1, S2, S3],
          color: Colors.red,
          strokeWidth: 7,
          borderStrokeWidth: 2,
          borderColor: Colors.black,
        );
        signPolylines.add(signPolyline);

        double angle =
            math.atan2(S3.latitude - S2.latitude, S3.longitude - S2.longitude);
        Marker arrowMarker = Marker(
          point: S3,
          width: 50,
          height: 50,
          builder: (context) {
            if (angle >= -math.pi / 4 && angle <= math.pi / 4) {
              return Transform.rotate(
                angle: math.pi,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              );
            } else if (angle >= math.pi / 4 && angle <= 3 * math.pi / 4) {
              return Transform.rotate(
                angle: math.pi / 2,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              );
            } else if (angle >= -3 * math.pi / 4 && angle <= -math.pi / 4) {
              return Transform.rotate(
                angle: -math.pi / 2,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Transform.rotate(
                angle: 0,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
        arrowMarkers.add(arrowMarker);
      }
    }
  }
}
