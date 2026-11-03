import 'package:flutter/material.dart';

import '../../data/atom_brands.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_surfaces.dart';

/// A brand's logo on a rounded square, or its initial on a colour chosen
/// from its id when there is no logo.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.id, required this.title, required this.logo, this.initial, this.size = 72, this.radius = 20});

  final int id;
  final String title;
  final String logo;
  final String? initial;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = logo.isEmpty ? atomInitialColours(id) : (AtomColors.white, AtomColors.ink);
    final letter = initial ?? (title.isEmpty ? '?' : title.substring(0, 1).toUpperCase());
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(logo.isEmpty ? 0 : size * 0.12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius), border: logo.isEmpty ? null : Border.all(color: AtomColors.line)),
      child: logo.isEmpty
          ? Center(child: Text(letter, style: AtomText.title.copyWith(fontSize: size * 0.42, color: fg)))
          : AtomNetworkImage(logo, fit: BoxFit.contain, semanticLabel: '$title logo', placeholderIcon: Icons.storefront_outlined),
    );
  }
}

/// A brand partner in a grid: logo, name, product count, badges.
class BrandPartnerCard extends StatelessWidget {
  const BrandPartnerCard({super.key, required this.brand, required this.onTap});

  final BrandPartner brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = brand;
    final count = b.listedCount;
    return AtomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandLogo(id: b.id, title: b.title, logo: b.logo, initial: b.initial),
          const SizedBox(height: 10),
          Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.subheading),
          Text(
            count == null || count <= 0 ? 'On installments' : '$count ${count == 1 ? 'product' : 'products'}',
            maxLines: 1,
            style: AtomText.small,
          ),
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (b.isPartner) const AtomBadge('Partner', tone: AtomTone.amber, icon: Icons.verified_rounded),
              if (b.atompayWholeBrand) const AtomBadge('All AtomPay', tone: AtomTone.green),
            ],
          ),
        ],
      ),
    );
  }
}
