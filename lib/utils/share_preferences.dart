import 'package:shared_preferences/shared_preferences.dart';

void saveHomeAddress(String address, double latitude, double longitude) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('home_address', address);
  prefs.setDouble('home_latitude', latitude);
  prefs.setDouble('home_longitude', longitude);
}

void saveWorkAddress(String address, double latitude, double longitude) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('work_address', address);
  prefs.setDouble('work_latitude', latitude);
  prefs.setDouble('work_longitude', longitude);
}
