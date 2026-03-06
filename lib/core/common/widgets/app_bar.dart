import 'package:atompro/core/common/utils/utils.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:flutter/material.dart';

AppBar buildAppBar(BuildContext context, Function() onMenuTap) {
  return AppBar(
    title: navLogo(),
    automaticallyImplyLeading: false,
    centerTitle: false,
    elevation: 1.5, // Adjust for shadow depth
    shadowColor: Colors.grey.shade100,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    actions: [
      // Profile Button with Circular Splash
      Material(
        color: Colors.transparent, // Keeps the background clear
        child: InkWell(
          onTap: () {
            AppNavigator.goToProfilePage();
          },
          customBorder: const CircleBorder(), // Forces the splash into a circle
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Padding for the touch target
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),

      // Menu Button with Circular Splash
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onMenuTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.menu, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8), // Final edge spacing
    ],
  );
}
