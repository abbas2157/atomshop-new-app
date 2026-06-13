import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/profile/view/seller_profile_screen.dart';
import 'package:atompro/features/seller/profile/viewmodel/seller_profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seller_gradient_header.dart';

/// Circular profile avatar for use in any [SellerGradientHeader] actions list.
/// Watches [sellerProfileBundleProvider] internally — shows the seller's photo
/// (or initials when no photo) and navigates to [SellerProfileScreen] on tap.
class SellerHeaderProfileButton extends StatelessWidget {
  const SellerHeaderProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final bundle = ref.watch(sellerProfileBundleProvider).asData?.value;
        return GestureDetector(
          onTap: () => ctx.pushSeller(const SellerProfileScreen()),
          child: SellerMonogram(
            name: bundle?.profile.name ?? '',
            imageUrl: bundle?.profile.profilePictureUrl,
            size: 32,
          ),
        );
      },
    );
  }
}
