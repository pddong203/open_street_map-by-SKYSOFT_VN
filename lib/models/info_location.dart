class InfoLocation {
  final String displayname;
  final double lat;
  final double lon;

  InfoLocation({
    required this.displayname,
    required this.lat,
    required this.lon,
  });

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
