import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/info_location.dart';

final TextEditingController _searchController = TextEditingController();
final FocusNode focusNode = FocusNode();
List<InfoLocation> _options = <InfoLocation>[];

void handleWorkButton() async {
  // setState(() {
  //   isSavingHomeAddress = false;
  //   isSavingWorkAddress = true;
  // });
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedWorkAddress = prefs.getString('work_address');
  if (savedWorkAddress != null) {
    // ignore: use_build_context_synchronously

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Work Address',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade400, // Thay đổi màu sắc
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey, // Thay đổi màu sắc
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  savedWorkAddress,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // handleSavedWorkAddress(savedWorkAddress);
                      },
                      // ignore: sort_child_properties_last
                      child: const Text(
                        'Use This Address',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.brown.shade400, // Thay đổi màu sắc
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red, // Thay đổi màu sắc
                      ),
                      onPressed: () {
                        // showDeleteWorkConfirmationDialog(savedWorkAddress);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  } else {
    _searchController.clear();
    _options.clear();
  }
}
