import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_models.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_surfaces.dart';
import 'atom_info_widgets.dart';

/// Atom ecosystem (canvas: "Atom ecosystem"). Store links come from the
/// server config; a store button shows only when the link is set.
class AtomAppsScreen extends ConsumerWidget {
  const AtomAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider).value;
    final gutter = context.atomGutter;
    final brandApp = config?.storeLinks['atombrand']?['android'] ?? '';
    final sellerLinks = atomSellerLinks(config);
    final sellerApply = atomSellerApplyUrl(config);

    // Light status-bar icons over the dark header.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.ink,
        body: SafeArea(
          child: AtomPageWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.xl),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', dark: true, onPressed: () => Navigator.of(context).maybePop()),
                ),
                const SizedBox(height: AtomSpace.lg),
                const InfoEyebrow('The Atom ecosystem', color: AtomColors.amber),
                const SizedBox(height: 6),
                Semantics(
                  header: true,
                  child: Text('One account. Four connected apps.', style: AtomText.title.copyWith(color: AtomColors.white)),
                ),
                const SizedBox(height: AtomSpace.xs),
                Text(
                  'One login and one data layer behind every app. Limits, routing and reminders are decided in one place, so each app knows what the others just did.',
                  style: AtomText.body.copyWith(color: AtomColors.onDark),
                ),
                const SizedBox(height: AtomSpace.lg),
                const _AppCard(
                  logo: 'assets/images/app-atomshop.png',
                  audience: 'For shoppers',
                  name: 'Atomshop',
                  body: 'Buy anything on installments and track every payment.',
                  here: true,
                ),
                _AppCard(
                  logo: 'assets/images/app-atompay.png',
                  audience: 'For financing',
                  name: 'AtomPay',
                  body: 'Your purchase limit, KYC and 3-month 0% markup plans on eligible products. Same login as Atomshop.',
                  links: config?.storeLinks['atompay'],
                ),
                _AppCard(
                  logo: 'assets/images/app-atomseller.png',
                  audience: 'For local sellers',
                  name: 'Atom Seller',
                  body: 'Leads from your own area, deals, guarantors and collections on a phone.',
                  features: const [
                    (Icons.location_on_outlined, 'Leads from customers in your own area'),
                    (Icons.handshake_outlined, 'Close deals and add guarantors'),
                    (Icons.payments_outlined, 'Track every collection on your phone'),
                  ],
                  links: sellerLinks,
                  applyLabel: 'Become a seller',
                  applyUrl: sellerApply,
                ),
                _AppCard(
                  logo: 'assets/images/app-atombrand.png',
                  audience: 'For brands',
                  name: 'AtomBrand',
                  body: 'Brands run their storefront, stock, orders and bulk quotes on Atomshop.',
                  links: config?.storeLinks['atombrand'],
                ),
                AtomCard(
                  radius: AtomRadius.hero,
                  borderColor: null,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/brand-partner.jpg',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.4),
                          cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
                          semanticLabel: 'A brand partner serving a customer at a phone counter',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AtomSpace.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Become a Brand Partner', style: AtomText.heading),
                            const SizedBox(height: 4),
                            Text('Sell your brand on Atomshop with verified sellers across your area.', style: AtomText.body),
                            const SizedBox(height: AtomSpace.md),
                            AtomButton(
                              label: 'Apply as a Brand Partner',
                              icon: Icons.description_outlined,
                              expand: true,
                              onPressed: () => atomOpenUrl(context, brandApp.isNotEmpty ? brandApp : 'https://atomshop.pk/brand-partners'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AtomSpace.md),
                Container(
                  padding: const EdgeInsets.all(AtomSpace.md),
                  decoration: BoxDecoration(
                    color: AtomColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AtomRadius.card),
                    border: Border.all(color: AtomColors.white.withValues(alpha: 0.14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart by design', style: AtomText.subheading.copyWith(color: AtomColors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Limits, routing and reminders run today. Risk prediction, CNIC reading and demand insights are next.',
                        style: AtomText.body.copyWith(fontSize: 13, color: AtomColors.onDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({
    required this.logo,
    required this.audience,
    required this.name,
    required this.body,
    this.here = false,
    this.features = const [],
    this.links,
    this.applyLabel = '',
    this.applyUrl = '',
  });

  /// The app's logo (design asset).
  final String logo;
  final String audience;
  final String name;
  final String body;
  final bool here;

  /// What the app does, one line each with an icon.
  final List<(IconData, String)> features;

  /// android / ios store links from the config.
  final Map<String, String?>? links;

  /// Sign-up on the website ("Become a seller"); hidden when empty.
  final String applyLabel;
  final String applyUrl;

  @override
  Widget build(BuildContext context) {
    final android = links?['android'] ?? '';
    final ios = links?['ios'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AtomSpace.sm),
      child: AtomCard(
        radius: AtomRadius.hero,
        borderColor: null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(logo, width: 44, height: 44, fit: BoxFit.contain, excludeFromSemantics: true),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audience,
                        style: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w800),
                      ),
                      Text(name, style: AtomText.heading),
                    ],
                  ),
                ),
                if (here) const AtomBadge('You are here', tone: AtomTone.green),
              ],
            ),
            const SizedBox(height: AtomSpace.xs),
            Text(body, style: AtomText.body),
            for (final (icon, text) in features) ...[
              const SizedBox(height: AtomSpace.xs),
              Row(
                children: [
                  Icon(icon, size: 18, color: AtomColors.primary),
                  const SizedBox(width: AtomSpace.xs),
                  Expanded(child: Text(text, style: AtomText.body.copyWith(fontSize: 13, color: AtomColors.ink))),
                ],
              ),
            ],
            if (!here && (android.isNotEmpty || ios.isNotEmpty || applyUrl.isNotEmpty)) ...[
              const SizedBox(height: AtomSpace.sm),
              Wrap(
                spacing: AtomSpace.xs,
                runSpacing: AtomSpace.xs,
                children: [
                  if (applyUrl.isNotEmpty)
                    AtomButton(
                      label: applyLabel,
                      icon: Icons.storefront_outlined,
                      size: AtomButtonSize.small,
                      onPressed: () => atomOpenUrl(context, applyUrl),
                    ),
                  if (android.isNotEmpty)
                    AtomButton(
                      label: 'Google Play',
                      icon: Icons.play_arrow_rounded,
                      variant: AtomButtonVariant.dark,
                      size: AtomButtonSize.small,
                      onPressed: () => atomOpenUrl(context, android),
                    ),
                  if (ios.isNotEmpty)
                    AtomButton(
                      label: 'App Store',
                      icon: Icons.download_rounded,
                      variant: AtomButtonVariant.secondary,
                      size: AtomButtonSize.small,
                      onPressed: () => atomOpenUrl(context, ios),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Atom Seller's store links. Until the config sends its own
/// (`apps.atomseller`), they are Atomshop's, as on the website's apps and
/// Smart Seller pages.
Map<String, String?>? atomSellerLinks(AppConfig? config) {
  final own = config?.storeLinks['atomseller'];
  final hasOwn = (own?['android'] ?? '').isNotEmpty || (own?['ios'] ?? '').isNotEmpty;
  return hasOwn ? own : config?.storeLinks['atomshop'];
}

/// The seller sign-up form on the website (Smart Seller page).
String atomSellerApplyUrl(AppConfig? config) => config?.pages['smart-seller'] ?? 'https://atomshop.pk/smart-seller#apply';
