import 'package:flutter/material.dart';

import '../../data/atom_design_content.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../widgets/atom_button.dart';

/// Home sections that are fixed content in the design: delivery area link,
/// Brand Partner card, the Atom ecosystem and the help links.

/// "Choose your delivery area ▾" above the search pill.
class HomeDeliveryAreaLink extends StatelessWidget {
  const HomeDeliveryAreaLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AtomRadius.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AtomColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Choose your delivery area',
                    style: AtomText.small.copyWith(fontSize: 13, color: AtomColors.body, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AtomColors.body),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "For brands · Become a Brand Partner" with the counter photo.
class HomeBrandPartnerCard extends StatelessWidget {
  const HomeBrandPartnerCard({super.key, required this.onApply, required this.onGetApp});

  final VoidCallback onApply;
  final VoidCallback onGetApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AtomColors.line),
        borderRadius: BorderRadius.circular(AtomRadius.hero),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LayoutBuilder(
                  builder: (context, c) => Image.asset(
                    'assets/images/brand-partner.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.4),
                    cacheWidth: (c.maxWidth * MediaQuery.devicePixelRatioOf(context)).round(),
                    semanticLabel: 'A brand partner serving a customer at a phone counter',
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
                    decoration: BoxDecoration(color: AtomColors.white, borderRadius: BorderRadius.circular(AtomRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/app-atombrand.png', width: 20, height: 20, excludeFromSemantics: true),
                        const SizedBox(width: 6),
                        Text(
                          'AtomBrand',
                          style: AtomText.small.copyWith(color: AtomColors.ink, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AtomSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('FOR BRANDS', style: AtomText.eyebrow),
                const SizedBox(height: AtomSpace.xs),
                Text('Become a Brand Partner', style: AtomText.heading.copyWith(fontSize: 19)),
                const SizedBox(height: AtomSpace.xs),
                Text(
                  'Run your storefront, stock, orders and bulk quotes on Atomshop, all from the AtomBrand app.',
                  style: AtomText.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: AtomSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: AtomButton(label: 'Apply now', icon: Icons.description_outlined, onPressed: onApply, size: AtomButtonSize.medium, expand: true),
                    ),
                    const SizedBox(width: AtomSpace.xs),
                    Expanded(
                      child: AtomButton(
                        label: 'Get the app',
                        icon: Icons.download_rounded,
                        onPressed: onGetApp,
                        size: AtomButtonSize.medium,
                        variant: AtomButtonVariant.secondary,
                        expand: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "The Atom ecosystem · One account. Four connected apps."
class HomeEcosystemCard extends StatelessWidget {
  const HomeEcosystemCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtomSpace.gutter),
      decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.hero)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('THE ATOM ECOSYSTEM', style: AtomText.eyebrow),
          const SizedBox(height: 4),
          Text('One account. Four connected apps.', style: AtomText.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 14),
          // Two apps per row, both cards as tall as the taller one.
          for (var i = 0; i < designApps.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _AppTile(app: designApps[i], onTap: onOpen)),
                  const SizedBox(width: 10),
                  Expanded(child: i + 1 < designApps.length ? _AppTile(app: designApps[i + 1], onTap: onOpen) : const SizedBox.shrink()),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          AtomButton(
            label: 'Explore the ecosystem',
            icon: Icons.grid_view_rounded,
            onPressed: onOpen,
            variant: AtomButtonVariant.secondary,
            size: AtomButtonSize.medium,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app, required this.onTap});

  final DesignApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: app.name,
      child: Material(
        color: AtomColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AtomColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AtomSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(app.logo, width: 40, height: 40, fit: BoxFit.contain, excludeFromSemantics: true),
                const SizedBox(height: 6),
                Text(app.name, style: AtomText.label.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(app.body, style: AtomText.small.copyWith(color: AtomColors.body, height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// About · Why · Contact · FAQs, two per row.
class HomeHelpLinks extends StatelessWidget {
  const HomeHelpLinks({super.key, required this.onAbout, required this.onWhy, required this.onContact, required this.onFaqs});

  final VoidCallback onAbout;
  final VoidCallback onWhy;
  final VoidCallback onContact;
  final VoidCallback onFaqs;

  @override
  Widget build(BuildContext context) {
    Widget link(String label, IconData icon, VoidCallback onTap) => Expanded(
      child: Semantics(
        button: true,
        child: Material(
          color: AtomColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: AtomColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label, overflow: TextOverflow.ellipsis, style: AtomText.label.copyWith(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            link('About us', Icons.info_outline_rounded, onAbout),
            const SizedBox(width: AtomSpace.xs),
            link('Why Atomshop', Icons.star_outline_rounded, onWhy),
          ],
        ),
        const SizedBox(height: AtomSpace.xs),
        Row(
          children: [
            link('Contact us', Icons.chat_bubble_outline_rounded, onContact),
            const SizedBox(width: AtomSpace.xs),
            link('FAQs', Icons.help_outline_rounded, onFaqs),
          ],
        ),
      ],
    );
  }
}
