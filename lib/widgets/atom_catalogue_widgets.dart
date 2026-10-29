import 'package:flutter/material.dart';

import '../data/atom_models.dart';
import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import '../responsive/atom_responsive.dart';
import '../utils/atom_format.dart';
import 'atom_network_image.dart';
import 'atom_states.dart';
import 'atom_surfaces.dart';

/// Product card used in every list: picture, brand, title, "from Rs. X/mo",
/// optional cash price and AtomPay / tag badges. Width comes from the parent
/// (grid cell or fixed-width carousel), so it works at any screen size.
class AtomProductCard extends StatelessWidget {
  const AtomProductCard({super.key, required this.product, required this.onTap, this.tag, this.showCash = false});

  final ProductCard product;
  final VoidCallback onTap;

  /// Dark corner tag, e.g. "Hot".
  final String? tag;
  final bool showCash;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${product.brand} ${product.title}',
      excludeSemantics: false,
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
                      child: AtomNetworkImage(product.picture, fit: BoxFit.contain, placeholderIcon: Icons.smartphone_outlined),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (!product.inStock) const AtomBadge('Sold out', tone: AtomTone.rose),
                        if (tag != null && product.inStock) AtomBadge(tag!, tone: AtomTone.dark),
                        if (product.atompay && product.inStock) const AtomBadge('AtomPay', tone: AtomTone.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AtomSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand.isNotEmpty) Text(product.brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.small),
                  const SizedBox(height: 2),
                  Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AtomText.label.copyWith(height: 1.3)),
                  const SizedBox(height: 6),
                  if (product.monthlyFrom != null)
                    Text.rich(TextSpan(children: [
                      TextSpan(text: AtomFormat.rupees(product.monthlyFrom), style: AtomText.amount),
                      TextSpan(text: '/mo', style: AtomText.small),
                    ]))
                  else
                    Text('Price on request', style: AtomText.small),
                  if (showCash && product.cashPrice != null) Text('Cash ${AtomFormat.rupees(product.cashPrice)}', style: AtomText.small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder shaped like [AtomProductCard].
class AtomProductCardSkeleton extends StatelessWidget {
  const AtomProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AtomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 1.25, child: AtomSkeleton(radius: 0)),
          Padding(
            padding: EdgeInsets.all(AtomSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [AtomSkeleton(width: 60, height: 10), SizedBox(height: 8), AtomSkeleton(height: 14), SizedBox(height: 8), AtomSkeleton(width: 90, height: 16)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lazily built product grid as a sliver. Columns follow the available width
/// (2 on phones, 3–5 on tablets), and only visible cards are built, so a long
/// category stays light on memory.
class AtomProductSliverGrid extends StatelessWidget {
  const AtomProductSliverGrid({super.key, required this.products, required this.onTap, this.showCash = false});

  final List<ProductCard> products;
  final ValueChanged<ProductCard> onTap;
  final bool showCash;

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
            // Picture (1/1.25 of width) + text block. Generous so larger
            // text sizes never overflow.
            mainAxisExtent: (constraints.crossAxisExtent - AtomSpace.sm * (columns - 1)) / columns / 1.25 + (showCash ? 128 : 112) * MediaQuery.textScalerOf(context).scale(1),
          ),
          itemCount: products.length,
          itemBuilder: (context, i) => AtomProductCard(product: products[i], showCash: showCash, onTap: () => onTap(products[i])),
        );
      },
    );
  }
}

/// Round category tile: picture from admin, icon fallback.
class AtomCategoryTile extends StatelessWidget {
  const AtomCategoryTile({super.key, required this.item, required this.onTap, this.size = 66});

  final CatalogueItem item;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtomRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: SizedBox.square(
                  dimension: size,
                  child: ColoredBox(
                    color: AtomColors.primarySoft,
                    child: AtomNetworkImage(item.picture, placeholderIcon: Icons.category_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(item.title, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: AtomText.small.copyWith(color: AtomColors.ink, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category tile from the design: icon in a soft blue circle, label under
/// it. [size] 66 on Home, 84 in the Shop tab.
class AtomDesignCategoryTile extends StatelessWidget {
  const AtomDesignCategoryTile({super.key, required this.icon, required this.label, required this.onTap, this.size = 66, this.bold = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtomRadius.card),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(color: AtomColors.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, size: size * 0.43, color: AtomColors.primary),
            ),
            SizedBox(height: bold ? 10 : 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: bold
                  ? AtomText.label.copyWith(fontWeight: FontWeight.w800)
                  : AtomText.small.copyWith(color: AtomColors.ink, fontWeight: FontWeight.w700, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand logo tile for horizontal strips.
class AtomBrandTile extends StatelessWidget {
  const AtomBrandTile({super.key, required this.item, required this.onTap});

  final CatalogueItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 64,
      child: AtomCard(
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        radius: 18,
        child: item.picture.isEmpty
            ? Center(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.label))
            : AtomNetworkImage(item.picture, fit: BoxFit.contain, semanticLabel: item.title, placeholderIcon: Icons.storefront_outlined),
      ),
    );
  }
}
