import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_errors.dart';
import '../../data/atom_sellers.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_delivery_area.dart';
import '../../state/atom_sellers_providers.dart';
import '../../utils/atom_format.dart';
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

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = atomInitialColours(seller.id);
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: bg,
          child: seller.image.isNotEmpty
              ? AtomNetworkImage(seller.image, semanticLabel: seller.name, placeholderIcon: Icons.storefront_outlined)
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
        if (seller.hasShop) const AtomBadge('Shop on Atomshop', tone: AtomTone.violet, icon: Icons.storefront_outlined),
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
/// orders, and how to reach them. A seller with a shop takes orders through
/// Atomshop (no WhatsApp): the card opens their shop.
class SellerCard extends StatelessWidget {
  const SellerCard({super.key, required this.seller});

  final Seller seller;

  @override
  Widget build(BuildContext context) {
    final s = seller;
    void profile() => AtomNav.sellerProfile(context, s);
    return AtomCard(
      onTap: profile,
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
              if (s.hasShop)
                Expanded(
                  child: AtomButton(label: 'Visit shop', icon: Icons.storefront_outlined, size: AtomButtonSize.small, expand: true, onPressed: profile),
                )
              else ...[
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
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    size: AtomButtonSize.small,
                    variant: AtomButtonVariant.secondary,
                    expand: true,
                    onPressed: profile,
                  ),
                ),
              ],
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
/// screen.
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
          const SizedBox(height: AtomSpace.xs),
          // A shop takes orders here; without one the profile is all there is.
          AtomButton(
            label: s.hasShop ? 'Shop now' : 'Profile',
            icon: s.hasShop ? Icons.storefront_outlined : Icons.person_outline_rounded,
            variant: s.hasShop ? AtomButtonVariant.primary : AtomButtonVariant.secondary,
            size: AtomButtonSize.small,
            expand: true,
            onPressed: onTap,
          ),
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

  /// Card padding, avatar, gaps and the button, plus the three text lines.
  static double heightFor(BuildContext context) => 132 + AtomSpace.xs + AtomSize.buttonSm + MediaQuery.textScalerOf(context).scale(14) * 2.4;

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
        SellerTileRow(sellers: sellers, gutter: gutter, onTap: (s) => AtomNav.sellerProfile(context, s)),
        const SizedBox(height: AtomSpace.lg),
      ],
    );
  }
}

/// "Only 2 left" / "In stock" / "Sold out" for a seller's item.
class SellerStockBadge extends StatelessWidget {
  const SellerStockBadge({super.key, required this.available});

  final int available;

  @override
  Widget build(BuildContext context) {
    if (available <= 0) return const AtomBadge('Sold out', tone: AtomTone.rose);
    if (available <= 2) return AtomBadge('Only $available left', tone: AtomTone.amber);
    return const AtomBadge('In stock', tone: AtomTone.green);
  }
}

/// A seller's item: picture, stock, brand · category, title, monthly and
/// cash price; with [showSeller], the seller's name under it (Home row).
class SellerItemCard extends StatelessWidget {
  const SellerItemCard({super.key, required this.item, required this.onTap, this.showSeller = false});

  final SellerItem item;
  final VoidCallback onTap;
  final bool showSeller;

  /// Height of the text block under the picture, for grids and rows:
  /// padding, brand line, a two-line title, price and cash lines (and the
  /// seller line), measured with the app font and the text scale.
  static double textHeight(BuildContext context, {bool showSeller = false}) {
    final s = MediaQuery.textScalerOf(context);
    final lines = s.scale(12) * 1.4 + s.scale(14) * 1.3 * 2 + s.scale(16) * 1.35 + s.scale(12) * 1.4 + (showSeller ? 6 + s.scale(12) * 1.4 : 0);
    return 2 * AtomSpace.sm + 2 + 6 + lines + 6;
  }

  @override
  Widget build(BuildContext context) {
    final i = item;
    final seller = i.seller;
    final kind = [i.brand, i.category].where((s) => s.isNotEmpty).join(' · ');
    return Semantics(
      button: true,
      label: [i.title, if (showSeller && seller != null) 'from ${seller.name}'].join(', '),
      child: AtomCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AtomColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(AtomSpace.sm),
                      child: AtomNetworkImage(i.photo, fit: BoxFit.contain, placeholderIcon: Icons.inventory_2_outlined),
                    ),
                  ),
                  Positioned(top: 10, left: 10, child: SellerStockBadge(available: i.available)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AtomSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kind.isNotEmpty) Text(kind, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.small),
                  const SizedBox(height: 2),
                  Text(i.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AtomText.label.copyWith(height: 1.3)),
                  const SizedBox(height: 6),
                  if (i.monthlyFrom != null)
                    Text.rich(TextSpan(children: [
                      TextSpan(text: AtomFormat.rupees(i.monthlyFrom), style: AtomText.amount),
                      TextSpan(text: '/mo', style: AtomText.small),
                    ]))
                  else
                    Text(AtomFormat.rupees(i.price), style: AtomText.amount),
                  if (i.monthlyFrom != null) Text('Cash ${AtomFormat.rupees(i.price)}', maxLines: 1, style: AtomText.small),
                  if (showSeller && seller != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: AtomColors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            seller.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtomText.small.copyWith(color: AtomColors.green, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lazily built grid of a seller's items (columns follow the width).
class SellerItemSliverGrid extends StatelessWidget {
  const SellerItemSliverGrid({super.key, required this.items, required this.onTap});

  final List<SellerItem> items;
  final ValueChanged<SellerItem> onTap;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = atomGridColumns(constraints.crossAxisExtent, minTileWidth: 165);
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AtomSpace.sm,
            crossAxisSpacing: AtomSpace.sm,
            mainAxisExtent: (constraints.crossAxisExtent - AtomSpace.sm * (columns - 1)) / columns / 1.25 + SellerItemCard.textHeight(context),
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => SellerItemCard(item: items[i], onTap: () => onTap(items[i])),
        );
      },
    );
  }
}

/// Horizontal row of [SellerItemCard]s, built lazily.
class SellerItemRow extends StatelessWidget {
  const SellerItemRow({super.key, required this.items, required this.onTap, this.gutter = 0, this.showSeller = false});

  final List<SellerItem> items;
  final ValueChanged<SellerItem> onTap;
  final double gutter;
  final bool showSeller;

  @override
  Widget build(BuildContext context) {
    final width = context.atomPick<double>(compact: 168, medium: 190, expanded: 210);
    return SizedBox(
      height: width / 1.25 + SellerItemCard.textHeight(context, showSeller: showSeller),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gutter),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AtomSpace.sm),
        itemBuilder: (_, i) => SizedBox(
          width: width,
          child: SellerItemCard(item: items[i], showSeller: showSeller, onTap: () => onTap(items[i])),
        ),
      ),
    );
  }
}

/// Home: "From sellers in {area}". Shows nothing without a saved area, while
/// loading, on error (the endpoint may not be live yet) or when no seller
/// near the buyer has stock, so Home never shows an error for it.
class HomeSellersNearRow extends ConsumerWidget {
  const HomeSellersNearRow({super.key, this.gutter = AtomSpace.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(deliveryAreaProvider).value;
    final items = ref.watch(sellersNearProvider).value?.products ?? const <SellerItem>[];
    if (area == null || items.isEmpty) return const SizedBox.shrink();
    final place = area.areaTitle.isNotEmpty ? area.areaTitle : 'your area';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: AtomSectionHeader(
            title: 'From sellers in $place',
            subtitle: 'Verified sellers who deliver to you',
            actionLabel: 'See all',
            onAction: () => AtomNav.sellers(context, cityId: area.cityId, areaId: area.areaId),
          ),
        ),
        const SizedBox(height: AtomSpace.sm),
        SellerItemRow(
          items: items,
          gutter: gutter,
          showSeller: true,
          onTap: (i) {
            final seller = i.seller;
            if (seller != null) AtomNav.sellerItem(context, seller.key, i.id);
          },
        ),
        const SizedBox(height: AtomSpace.lg),
      ],
    );
  }
}
