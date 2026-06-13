import 'package:atompro/core/common/utils/utils.dart';
import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/routes/app_route_constants.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:atompro/features/customer/notifications/viewmodel/customer_notifications_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

AppBar buildAppBar(
  BuildContext context,
  Function() onMenuTap,
  bool showBackButton, {
  bool showMenuButton = false,
  bool showNotificationBell = false,
}) {
  return AppBar(
    title: Row(
      children: [
        if (showBackButton)
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: ColorPalette.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        navLogo(),
      ],
    ),
    automaticallyImplyLeading: false,
    centerTitle: false,
    elevation: 1.5,
    shadowColor: Colors.grey.shade100,
    backgroundColor: ColorPalette.surface,
    surfaceTintColor: ColorPalette.surface,
    actions: [
      if (showNotificationBell)
        Consumer(
          builder: (ctx, ref, _) {
            final count =
                ref.watch(customerNotificationsProvider).unreadCount;
            return GestureDetector(
              onTap: () => AppNavigator.pushNamed(AppRoutes.notifications),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 26,
                      color: ColorPalette.textPrimary,
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      if (showMenuButton)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onMenuTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: ColorPalette.surfaceGray,
                child:
                    Icon(Icons.menu, color: ColorPalette.textPrimary, size: 20),
              ),
            ),
          ),
        ),
      const SizedBox(width: 8),
    ],
  );
}
