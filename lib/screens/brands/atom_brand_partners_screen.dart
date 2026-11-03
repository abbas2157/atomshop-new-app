import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_brands.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_brand_providers.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import 'atom_brand_widgets.dart';

/// Every brand partner, most products first (`app/brand-partners`).
class AtomBrandPartnersScreen extends ConsumerWidget {
  const AtomBrandPartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = context.atomGutter;
    final value = ref.watch(brandPartnersProvider);
    // Logo + name + count + badges, with room for larger text.
    final tileHeight = 186 + 40 * MediaQuery.textScalerOf(context).scale(1);

    Widget padded(Widget child, {double top = 0}) => SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
          sliver: SliverToBoxAdapter(child: child),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: Column(
            children: [
              const AtomTopBar(title: 'Brand partners', subtitle: 'Official brand stores on Atomshop'),
              Expanded(
                child: RefreshIndicator(
                  color: AtomColors.primary,
                  onRefresh: () async {
                    ref.invalidate(brandPartnersProvider);
                    await ref.read(brandPartnersProvider.future).catchError((_) => const <BrandPartner>[]);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      padded(
                        const AtomNotice(
                          icon: Icons.verified_user_outlined,
                          text: 'Brands list their own products here: genuine stock and brand warranty, on monthly installments.',
                        ),
                        top: AtomSpace.xs,
                      ),
                      ...value.when(
                        skipLoadingOnRefresh: true,
                        loading: () => [
                          padded(
                            Row(
                              children: [
                                Expanded(child: AtomSkeleton(height: tileHeight, radius: AtomRadius.card)),
                                const SizedBox(width: AtomSpace.sm),
                                Expanded(child: AtomSkeleton(height: tileHeight, radius: AtomRadius.card)),
                              ],
                            ),
                            top: AtomSpace.md,
                          ),
                        ],
                        error: (e, _) => [padded(AtomErrorState(error: e, onRetry: () => ref.invalidate(brandPartnersProvider)), top: AtomSpace.md)],
                        data: (brands) => brands.isEmpty
                            ? [
                                padded(
                                  const AtomEmptyState(icon: Icons.storefront_outlined, title: 'No brand partners yet', message: 'Official brand stores will show here.'),
                                  top: AtomSpace.md,
                                ),
                              ]
                            : [
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, 0),
                                  sliver: SliverLayoutBuilder(
                                    builder: (context, constraints) => SliverGrid.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: atomGridColumns(constraints.crossAxisExtent, minTileWidth: 160),
                                        mainAxisSpacing: AtomSpace.sm,
                                        crossAxisSpacing: AtomSpace.sm,
                                        mainAxisExtent: tileHeight,
                                      ),
                                      itemCount: brands.length,
                                      itemBuilder: (_, i) => BrandPartnerCard(brand: brands[i], onTap: () => AtomNav.brandPartner(context, brands[i])),
                                    ),
                                  ),
                                ),
                              ],
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xl)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
