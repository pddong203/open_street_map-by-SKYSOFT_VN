import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skysoft/models/info_location.dart';
import 'package:skysoft/services/api.dart';
import 'package:skysoft/widgets/modal_content/search_home.dart';
import 'package:skysoft/widgets/save_marker_list_popup.dart';

/**
 * Đây là nội dung hiển thị của search full screen
 * 
 * 
 */

Widget SearchFullScreen(
    BuildContext context, String homeAddress, String workAddress) {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<InfoLocation> _infoLocationList = [];

  return Container(
    margin: const EdgeInsets.all(10),
    child: Column(
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

        // Container 1 - Search TextFormField
        TextFormField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Where to ?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
            suffixIcon: const Icon(Icons.mic, color: Colors.red),
            filled: true,
            fillColor: Colors.grey[300],
          ),
          onFieldSubmitted: (String value) async {
            List<dynamic> result = await repNameLocation(value);
            _infoLocationList =
                result.map((e) => InfoLocation.fromJson(e)).toList();
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
            // showSearchFullScreen();
          },
        ),
        Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.1, // Reduced the height to make the buttons smaller
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 14,
                          itemBuilder: (context, index) {
                            List<IconData> buttonIcons = [
                              Icons.bookmark,
                              Icons.local_parking,
                              Icons.ev_station,
                              Icons.local_gas_station,
                              Icons.fastfood,
                              Icons.local_cafe,
                              Icons.shopping_cart,
                              Icons.medication,
                              Icons.store,
                              Icons.local_hospital,
                              Icons.hotel,
                              Icons.park,
                              Icons.garage,
                              Icons.more_horiz,
                            ];

                            List<String> buttonTexts = [
                              'Saved',
                              'Parking',
                              'Electric',
                              'Gas',
                              'Food',
                              'Coffee',
                              'Shopping',
                              'Pharmacies',
                              'Grocery',
                              'Hospital ',
                              'Hotel',
                              'Parks',
                              'Garages',
                              'More',
                            ];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal:
                                      4.0), // Reduced horizontal padding
                              child: SizedBox(
                                width:
                                    70, // Reduced the width to make the buttons smaller
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (index == 0) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (context) {
                                          return const SavedMarkersList();
                                        },
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.all(
                                        6.0), // Reduced padding inside the button
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          12.0), // Slightly reduced the border radius
                                      side: const BorderSide(
                                        color: Colors.grey,
                                        width:
                                            0.2, // Set the border width to 1.0 pixel
                                      ),
                                    ),
                                    elevation:
                                        0.0, // Set the elevation to 0.0 to remove the shadow
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        buttonIcons[index],
                                        size: 20.0, // Reduced icon size
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(
                                          height:
                                              1.0), // Reduced gap between icon and text
                                      Flexible(
                                        child: Text(
                                          buttonTexts[index],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 11.0, // Reduced text size
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines:
                                              1, // Ensures the text stays in one line
                                          overflow: TextOverflow
                                              .ellipsis, // Truncate with ellipsis if overflowed
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Container 4 - Another Additional Container
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.home,
                      color: Colors.pink,
                    ),
                    title: const Text(
                      'Home',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      homeAddress,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return SearchHome(true);
                        },
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.work,
                      color: Colors.brown,
                    ),
                    title: const Text(
                      'Work',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      workAddress,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return SearchHome(false);
                        },
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: const ListTile(
                    leading: Icon(
                      Icons.calendar_month,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      'Connect calendar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Sync your calendar for route planning',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _infoLocationList.isNotEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _infoLocationList.length > 20
                            ? 20
                            : _infoLocationList.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom:
                                    BorderSide(color: Colors.black, width: 0.1),
                              ),
                            ),
                            child: ListTile(
                              title: Text(_infoLocationList[index].displayname),
                              onTap: () {
                                _focusNode.unfocus();
                                // widget.showMarkerOnMap(LatLng(
                                //     _infoLocationList[index].lat,
                                //     _infoLocationList[index].lon));
                                // _infoLocationList.clear();
                                // _searchController.clear();
                                // setState(() {});
                                // Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : Container()
          ],
        ),
      ],
    ),
  );
}
