import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_errors.dart';
import '../../data/atom_sellers.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_sellers_providers.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_surfaces.dart';
import '../info/atom_info_widgets.dart';

/// Round seller photo, or the business initial on a colour chosen from the id
/// (the same seller always gets the same colour).
class SellerAvatar extends StatelessWidget {
  const SellerAvatar({super.key, required this.seller, this.size = 52});

  final Seller seller;
  final double size;

  static const _tones = [
    (AtomColors.primarySoft, AtomColors.primary),
    (AtomColors.amberSoft, AtomColors.amberInk),
    (AtomColors.greenSoft, AtomColors.green),
    (AtomColors.violetSoft, AtomColors.violet),
    (AtomColors.tealSoft, AtomColors.teal),
    (AtomColors.roseSoft, AtomColors.rose),
  ];

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tones[seller.id.abs() % _tones.length];
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: bg,
          child: seller.picture.isNotEmpty
              ? AtomNetworkImage(seller.picture, semanticLabel: seller.name, placeholderIcon: Icons.storefront_outlined)
              : Center(child: Text(seller.initial, style: AtomText.heading.copyWith(fontSize: size * 0.4, color: fg))),
        ),
      ),
    );
  }
}

/// Verified (every seller in the directory), Top rated, Atomshop ships.
class SellerBadges extends StatelessWidget {
  const SellerBadges({super.key, required this.seller});

  final Seller seller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        const AtomBadge('Verified', tone: AtomTone.green, icon: Icons.verified_rounded),
        if (seller.topRated) const AtomBadge('Top rated', tone: AtomTone.amber, icon: Icons.star_rounded),
        if (seller.atomshopShips) const AtomBadge('Atomshop ships', tone: AtomTone.blue, icon: Icons.local_shipping_outlined),
      ],
    );
  }
}

/// "37 orders done · Member since May 2026".
String sellerFacts(Seller s) => [
      '${s.ordersDone} ${s.ordersDone == 1 ? 'order' : 'orders'} done',
      if (s.memberSinceLabel.isNotEmpty) 'Member since ${s.memberSinceLabel}',
    ].join(' · ');

/// A verified seller in the directory: badges, who they are, where, how many
/// orders, and how to reach them.
class SellerCard extends ConsumerWidget {
  const SellerCard({super.key, required this.seller});

  final Seller seller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = seller;
    return AtomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellerBadges(seller: s),
          const SizedBox(height: AtomSpace.sm),
          Row(
            children: [
              SellerAvatar(seller: s),
              const SizedBox(width: AtomSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AtomText.subheading),
                    if (s.businessType.isNotEmpty) Text(s.businessType, style: AtomText.small),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AtomSpace.sm),
          if (s.location.isNotEmpty)
            _Fact(icon: Icons.location_on_outlined, text: s.location),
          _Fact(icon: Icons.inventory_2_outlined, text: sellerFacts(s)),
          const SizedBox(height: AtomSpace.sm),
          Row(
            children: [
              if (s.whatsappUrl.isNotEmpty) ...[
                Expanded(
                  child: AtomButton(
                    label: 'Chat with seller',
                    icon: Icons.chat_outlined,
                    size: AtomButtonSize.small,
                    expand: true,
                    onPressed: () => atomOpenUrl(context, s.whatsappUrl),
                  ),
                ),
                const SizedBox(width: AtomSpace.xs),
              ],
              Expanded(
                child: AtomButton(
                  label: 'Shop now',
                  icon: Icons.storefront_outlined,
                  size: AtomButtonSize.small,
                  variant: AtomButtonVariant.secondary,
                  expand: true,
                  onPressed: () => AtomNav.toTab(context, ref, AtomTab.shop),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AtomColors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.small)),
        ],
      ),
    );
  }
}

/// Small card for the Home strip and the "Top rated" row of the Sellers
/// screen. Tapping it opens the directory.
class SellerTile extends StatelessWidget {
  const SellerTile({super.key, required this.seller, required this.onTap});

  final Seller seller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = seller;
    return AtomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AtomSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerAvatar(seller: s, size: 40),
              const Spacer(),
              if (s.topRated) const Icon(Icons.star_rounded, size: 18, color: AtomColors.amber),
              const Icon(Icons.verified_rounded, size: 18, color: AtomColors.green),
            ],
          ),
          const SizedBox(height: AtomSpace.xs),
          Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.label),
          if (s.location.isNotEmpty) Text(s.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.small),
          const Spacer(),
          Text('${s.ordersDone} ${s.ordersDone == 1 ? 'order' : 'orders'} done', maxLines: 1, style: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Horizontal row of [SellerTile]s, [height] tall, with [gutter] at the ends.
class SellerTileRow extends StatelessWidget {
  const SellerTileRow({super.key, required this.sellers, required this.onTap, this.gutter = 0});

  final List<Seller> sellers;
  final ValueChanged<Seller> onTap;
  final double gutter;

  static double heightFor(BuildContext context) => 132 + MediaQuery.textScalerOf(context).scale(14) * 2.4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightFor(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gutter),
        itemCount: sellers.length,
        separatorBuilder: (_, _) => const SizedBox(width: AtomSpace.sm),
        itemBuilder: (_, i) => SizedBox(width: 168, child: SellerTile(seller: sellers[i], onTap: () => onTap(sellers[i]))),
      ),
    );
  }
}

/// Home: "Top rated sellers" with "See all" → the Sellers screen. Shows
/// nothing while the server has no sellers endpoint yet or no top-rated
/// sellers, so Home never shows an error for it.
class HomeTopSellersStrip extends ConsumerWidget {
  const HomeTopSellersStrip({super.key, this.gutter = AtomSpace.gutter});

  /// Side padding of the header and the row (Home's gutter).
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(topRatedSellersProvider);
    if (value.hasError && (atomNotBuiltYet(value.error) || !value.hasValue)) {
      // Not deployed yet, or failed: Home carries on without the strip.
      return const SizedBox.shrink();
    }
    final sellers = value.value;
    // Nothing while loading either: before the API is deployed a skeleton
    // would flash and vanish on every launch.
    if (sellers == null || sellers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: AtomSectionHeader(
            title: 'Top rated sellers',
            subtitle: 'Verified sellers on Atomshop',
            actionLabel: 'See all',
            onAction: () => AtomNav.sellers(context),
          ),
        ),
        const SizedBox(height: AtomSpace.sm),
        SellerTileRow(sellers: sellers, gutter: gutter, onTap: (_) => AtomNav.sellers(context)),
        const SizedBox(height: AtomSpace.lg),
      ],
    );
  }
}
