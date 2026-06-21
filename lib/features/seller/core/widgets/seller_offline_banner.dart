import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerOfflineBanner extends ConsumerWidget {
  const SellerOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: online
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs + 2,
              ),
              color: const Color(0xFFD32F2F),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

bool sellerIsOffline(WidgetRef ref) => !ref.watch(connectivityProvider);
