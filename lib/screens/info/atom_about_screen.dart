import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_photo_hero.dart';
import 'atom_info_widgets.dart';

/// About us (canvas: "About us"). Marketing copy from the design.
class AtomAboutScreen extends ConsumerWidget {
  const AtomAboutScreen({super.key});

  static const _timeline = [
    ('Jan 2025', 'Atomshop.pk platform built', 'An installment marketplace with custom orders, plus the Smart Seller program.'),
    ('Mar 2026', 'New Atomshop mobile app', 'Customer shopping in one app.'),
    ('May 2026', 'Seller subscriptions', 'Plans for local sellers who run their business on Atomshop.'),
    ('Aug 2026', 'Brand Partner portal', 'Brands run their own storefront, stock and orders.'),
    ('Sep 2026', 'AtomPay', 'KYC, a purchase limit and 3-month 0% markup plans on eligible products.'),
    ('Oct 2026', 'AtomBrand mobile app', 'A mobile app for Brand Partners.'),
    ('Next', 'Atom Intelligence', 'Risk prediction, CNIC reading and demand insights.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtomPage(
      title: 'About us',
      hero: const AtomPhotoHero(
        asset: 'assets/images/slide-verified-sellers.jpg',
        alt: 'The Atomshop team reviewing orders on a tablet',
        eyebrow: 'About us',
        title: 'Where affordability meets opportunity',
        height: 260,
        alignment: Alignment(0.44, -0.2),
        textWidthFactor: 0.52,
      ),
      bottom: Row(
        children: [
          Expanded(
            child: AtomButton(
              label: 'Shop now',
              icon: Icons.shopping_bag_outlined,
              expand: true,
              onPressed: () => AtomNav.toTab(context, ref, AtomTab.shop),
            ),
          ),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: AtomButton(
              label: 'Contact us',
              icon: Icons.chat_bubble_outline_rounded,
              expand: true,
              variant: AtomButtonVariant.secondary,
              onPressed: () => AtomNav.contact(context),
            ),
          ),
        ],
      ),
      children: [
        const InfoEyebrow('Our story'),
        const SizedBox(height: 4),
        Text('More than a marketplace', style: AtomText.heading),
        const SizedBox(height: AtomSpace.xs),
        Text(
          'Atomshop is a platform where verified local sellers and brands run their installment business. '
          'Shoppers get the products they need and pay in steps, with people they can reach.',
          style: AtomText.body,
        ),
        const SizedBox(height: AtomSpace.md),
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Pillar('Our vision', 'Access to everyday products for every household.', AtomColors.primarySoft, AtomColors.primary)),
              SizedBox(width: AtomSpace.sm),
              Expanded(child: _Pillar('Our mission', 'Tools that let every local entrepreneur sell on installments.', AtomColors.amberSoft, AtomColors.amberInk)),
            ],
          ),
        ),
        const SizedBox(height: AtomSpace.lg),
        Text('How the ecosystem grew', style: AtomText.heading),
        const SizedBox(height: AtomSpace.sm),
        for (var i = 0; i < _timeline.length; i++) _TimelineRow(entry: _timeline[i], last: i == _timeline.length - 1),
      ],
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar(this.label, this.text, this.bg, this.ink);

  final String label;
  final String text;
  final Color bg;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtomSpace.md),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AtomRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AtomText.eyebrow.copyWith(color: ink)),
          const SizedBox(height: 6),
          Text(text, style: AtomText.label.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last});

  final (String, String, String) entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (date, title, body) = entry;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: last ? null : AtomColors.primary,
                    shape: BoxShape.circle,
                    border: last ? Border.all(color: AtomColors.amber, width: 2.5) : null,
                  ),
                ),
                if (!last) Expanded(child: Container(width: 2, color: AtomColors.line)),
              ],
            ),
          ),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AtomSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w800)),
                  Text(title, style: AtomText.label),
                  if (body.isNotEmpty) Text(body, style: AtomText.body.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
