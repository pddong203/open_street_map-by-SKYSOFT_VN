import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget placeholderImageWidget() {
    // PC SẼ ĐỂ ẨN MẤT ẢNH LOGO SKYSOFT CÒN MOBILE + TABLET VẪN HIỆN LOGO
    return Container(
      width: 250,
      height: 56,
      color: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      leading: Builder(
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.menu,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
          );
        },
      ),
      // Add an image to the AppBar
      title: CachedNetworkImage(
        imageUrl: 'https://tracking.skysoft.vn/img/skysoft_logo.png',
        fit: BoxFit.fitHeight,
        width: 250,
        height: 56,
        errorWidget: (context, url, error) => placeholderImageWidget(),
      ),
      centerTitle: true,
    );
  }
}
