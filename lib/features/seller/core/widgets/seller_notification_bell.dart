import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/notifications/view/seller_notifications_screen.dart';
import 'package:atompro/features/seller/notifications/viewmodel/seller_notifications_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seller_gradient_header.dart';

/// Bell icon with unread badge for use in any [SellerGradientHeader] actions list.
/// Watches [sellerNotificationsProvider] internally and navigates to the inbox on tap.
class SellerNotificationBell extends StatelessWidget {
  const SellerNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final count = ref.watch(sellerNotificationsProvider).unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            SellerHeaderIconButton(
              icon: Icons.notifications_outlined,
              tooltip: 'Notifications',
              onTap: () => ctx.pushSeller(const SellerNotificationsScreen()),
            ),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
        );
      },
    );
  }
}
