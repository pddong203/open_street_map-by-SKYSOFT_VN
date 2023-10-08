import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skysoft/models/info_location.dart';
import 'package:skysoft/services/api.dart';

/**
 * Đây là nội dung hiển thị khi bấm vào home
 * 
 * 
 */

Widget SearchHome(bool isHomePress) {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<InfoLocation> _infoLocationList = [];
  List<InfoLocation> _options = <InfoLocation>[];
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Text(
              'Search for a location:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter a location...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[300],
              ),
              onFieldSubmitted: (String value) async {
                List<dynamic> result = await repNameLocation(value);
                _options = result.map((e) => InfoLocation.fromJson(e)).toList();
                setState(
                  () {},
                );
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_options[index].displayname),
                    onTap: () {
                      if (isHomePress) {
                        String selectedAddress = _options[index].displayname;
                        double? latitude = _options[index].lat;
                        double? longitude = _options[index].lon;
                        showSaveHomeAddressDialog(
                            context, selectedAddress, latitude, longitude);
                      } else {
                        String selectedAddress = _options[index].displayname;
                        double? latitude = _options[index].lat;
                        double? longitude = _options[index].lon;
                        showSaveWorkAddressDialog(
                            context, selectedAddress, latitude, longitude);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

// hiển thị popup
void showSaveHomeAddressDialog(
    BuildContext context, String address, double latitude, double longitude) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: const Text(
          'Save Home Address',
          style: TextStyle(color: Colors.pinkAccent),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to save this address as your home?',
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              saveHomeAddress(
                  address, latitude, longitude); // Lưu địa chỉ và tọa độ
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context).pop(); // Đóng dialog
              // showHomeAddress();
              // handleHomeButton();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Yes'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('No'),
          ),
        ],
      );
    },
  );
}

void showSaveWorkAddressDialog(
    BuildContext context, String address, double latitude, double longitude) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white, // Màu nền nhạt hơn
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Đặt bo tròn viền
        ),
        title: const Text(
          'Save Work Address',
          style: TextStyle(color: Colors.brown), // Đặt màu cho tiêu đề
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to save this address as your work?',
              style: TextStyle(color: Colors.black), // Đặt màu cho nội dung
            ),
            SizedBox(height: 16), // Khoảng cách giữa nội dung và nút
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              saveWorkAddress(address, latitude, longitude); // Lưu địa chỉ
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context).pop(); // Đóng dialog
              // showWorkAddress();
              // _searchController.clear();
              // _options.clear();
              // handleWorkButton(); // Xử lý hành động của nút Work Address
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Màu nền nút
            ),
            child: const Text('Yes'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Màu nền nút
            ),
            child: const Text('No'),
          ),
        ],
      );
    },
  );
}

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
