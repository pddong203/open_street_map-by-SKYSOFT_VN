import 'package:skysoft/global/field.dart';

class InfoLocation {
  final String displayname;
  final double lat;
  final double lon;

  InfoLocation({
    required this.displayname,
    required this.lat,
    required this.lon,
  });

  factory InfoLocation.fromJson(Map<String, dynamic> json) {
    String displayname = json[fdisplayName];
    double lat = double.parse(json[flat]);
    double lon = double.parse(json[flon]);

    InfoLocation model =
        InfoLocation(displayname: displayname, lat: lat, lon: lon);
    return model;
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
