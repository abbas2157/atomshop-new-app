import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_design_content.dart';
import '../../data/atom_models.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_session.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_catalogue_widgets.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import 'atom_home_hero.dart';
import 'atom_home_sections.dart';

/// App v2 home (canvas: "Home · guest"). Every section is admin-driven and
/// loads independently: a slow or failing row shows its own skeleton or
/// retry without blocking the others.
class AtomHomeScreen extends ConsumerWidget {
  const AtomHomeScreen({super.key});

  void _openProduct(BuildContext context, ProductCard p) => AtomNav.product(context, p.id);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = context.atomGutter;
    final signedIn = ref.watch(atomSignedInProvider);
    void goShop() => ref.read(atomTabProvider.notifier).select(AtomTab.shop);

    Widget padded(Widget child) => SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      sliver: SliverToBoxAdapter(child: child),
    );
    const gap = SliverToBoxAdapter(child: SizedBox(height: AtomSpace.lg));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AtomColors.primary,
          onRefresh: () => refreshHome(ref),
          child: AtomPageWidth(
            child: CustomScrollView(
              // Rows outside the viewport are not built until scrolled to.
              scrollCacheExtent: const ScrollCacheExtent.pixels(400),
              slivers: [
                padded(
                  _Header(
                    signedIn: signedIn,
                    onSignIn: () => AtomNav.signIn(context),
                    // Notifications belong to an account; guests are asked to sign in.
                    onNotifications: () => signedIn ? AtomNav.notifications(context) : AtomNav.signIn(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xs)),
                padded(HomeDeliveryAreaLink(onTap: () => AtomNav.location(context))),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xs)),
                padded(_SearchPill(onTap: () => AtomNav.search(context))),
                gap,
                padded(AtomHomeHero(slides: designSlides, onAction: (a) => a == SlideAction.why ? AtomNav.why(context) : goShop())),
                gap,
                padded(_AskAtomCard(onTap: () => ref.read(atomTabProvider.notifier).select(AtomTab.askAtom))),
                if (!signedIn) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.sm)),
                  padded(_SignInCard(onSignIn: () => AtomNav.signIn(context))),
                ],
                gap,
                padded(AtomSectionHeader(title: 'Shop by category', actionLabel: 'View all', onAction: goShop)),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.sm)),
                padded(_CategoriesGrid(onOpen: (c) => AtomNav.category(context, c.item))),
                gap,
                padded(
                  AtomSectionHeader(
                    title: 'Hot right now',
                    leading: const Icon(Icons.local_fire_department_rounded, color: AtomColors.amber),
                    actionLabel: 'See all',
                    onAction: goShop,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.sm)),
                SliverToBoxAdapter(
                  child: _FeaturedRow(gutter: gutter, onOpen: (p) => _openProduct(context, p)),
                ),
                gap,
                padded(AtomSectionHeader(title: 'Top brands on installments', actionLabel: 'All brands', onAction: goShop)),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.sm)),
                SliverToBoxAdapter(
                  child: _BrandsRow(gutter: gutter, onOpen: (b) => AtomNav.brand(context, b)),
                ),
                gap,
                padded(const AtomSectionHeader(title: 'Top picks', subtitle: 'Chosen by the Atomshop team')),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.sm)),
                _TopPicksGrid(gutter: gutter, onOpen: (p) => _openProduct(context, p)),
                gap,
                padded(_OrderAnythingRow(onCustomOrder: () => AtomNav.customOrder(context), onMakeOffer: () => AtomNav.makeOffer(context))),
                gap,
                padded(HomeBrandPartnerCard(onApply: () => AtomNav.apps(context), onGetApp: () => AtomNav.apps(context))),
                gap,
                padded(HomeEcosystemCard(onOpen: () => AtomNav.apps(context))),
                gap,
                padded(
                  HomeHelpLinks(
                    onAbout: () => AtomNav.about(context),
                    onWhy: () => AtomNav.why(context),
                    onContact: () => AtomNav.contact(context),
                    onFaqs: () => AtomNav.faqs(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xl)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.signedIn, required this.onSignIn, required this.onNotifications});

  final bool signedIn;
  final VoidCallback onSignIn;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AtomSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/nav-logo.png',
                height: 36,
                cacheHeight: (36 * MediaQuery.devicePixelRatioOf(context)).round(),
                semanticLabel: 'Atomshop.pk, pay in steps',
              ),
            ),
          ),
          AtomIconButton(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', onPressed: onNotifications),
          if (!signedIn) ...[
            const SizedBox(width: AtomSpace.xs),
            AtomButton(label: 'Sign in', icon: Icons.login_rounded, onPressed: onSignIn, size: AtomButtonSize.medium),
          ],
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search products',
      child: AtomCard(
        onTap: onTap,
        color: AtomColors.surface,
        radius: AtomRadius.pill,
        padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AtomColors.body, size: 20),
            const SizedBox(width: AtomSpace.xs),
            Text('Search phones, ACs, bikes…', style: AtomText.body.copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _AskAtomCard extends StatelessWidget {
  const _AskAtomCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AtomCard(
      onTap: onTap,
      color: AtomColors.ink,
      borderColor: null,
      padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AtomColors.amber, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AtomColors.ink, size: 20),
          ),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tell Atom what you want to buy', style: AtomText.subheading.copyWith(color: AtomColors.white)),
                Text('"iPhone 16 in 6 months"', style: AtomText.small.copyWith(color: AtomColors.onDark)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: AtomColors.white, size: 20),
        ],
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return AtomCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AtomColors.primarySoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_month_rounded, color: AtomColors.primary, size: 20),
          ),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Already ordered?', style: AtomText.label),
                Text('Sign in to track your installments', style: AtomText.small.copyWith(color: AtomColors.body)),
              ],
            ),
          ),
          AtomButton(label: 'Sign in', icon: Icons.login_rounded, onPressed: onSignIn, size: AtomButtonSize.small, variant: AtomButtonVariant.secondary),
        ],
      ),
    );
  }
}

/// The design's eight categories (fixed for now, [designCategories]).
class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.onOpen});

  final ValueChanged<DesignCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: designCategories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.atomPick(compact: 4, medium: 4, expanded: 8),
        mainAxisSpacing: 14,
        crossAxisSpacing: AtomSpace.xs,
        // 66 px circle + 6 px gap + two lines of 12 px text that grow with
        // the text size.
        mainAxisExtent: 66 + 6 + MediaQuery.textScalerOf(context).scale(12) * 1.25 * 2 + 4,
      ),
      itemBuilder: (_, i) =>
          AtomDesignCategoryTile(icon: designCategories[i].icon, label: designCategories[i].shortLabel, onTap: () => onOpen(designCategories[i])),
    );
  }
}

/// Horizontal product row: fixed-width cards, built lazily as they scroll in.
class _FeaturedRow extends ConsumerWidget {
  const _FeaturedRow({required this.gutter, required this.onOpen});

  final double gutter;
  final ValueChanged<ProductCard> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardWidth = context.atomPick<double>(compact: 168, medium: 190, expanded: 210);
    final height = cardWidth / 1.25 + 112 * MediaQuery.textScalerOf(context).scale(1);

    Widget row(int count, Widget Function(int) item) => SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gutter),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: AtomSpace.sm),
        itemBuilder: (_, i) => SizedBox(width: cardWidth, child: item(i)),
      ),
    );

    return AtomAsync<List<ProductCard>>(
      value: ref.watch(featuredProductsProvider),
      onRetry: () => ref.invalidate(featuredProductsProvider),
      compactError: true,
      loading: row(3, (_) => const AtomProductCardSkeleton()),
      data: (products) => products.isEmpty
          ? const SizedBox.shrink()
          : row(products.length, (i) => AtomProductCard(product: products[i], tag: 'Hot', onTap: () => onOpen(products[i]))),
    );
  }
}

class _BrandsRow extends ConsumerWidget {
  const _BrandsRow({required this.gutter, required this.onOpen});

  final double gutter;
  final ValueChanged<CatalogueItem> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget row(int count, Widget Function(int) item) => SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gutter),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => item(i),
      ),
    );

    return AtomAsync<List<CatalogueItem>>(
      value: ref.watch(homeBrandsProvider),
      onRetry: () => ref.invalidate(homeBrandsProvider),
      compactError: true,
      loading: row(5, (_) => const AtomSkeleton(width: 96, height: 64, radius: 18)),
      data: (brands) => row(brands.length, (i) => AtomBrandTile(item: brands[i], onTap: () => onOpen(brands[i]))),
    );
  }
}

/// Top picks as a lazily built sliver grid (columns follow the width).
class _TopPicksGrid extends ConsumerWidget {
  const _TopPicksGrid({required this.gutter, required this.onOpen});

  final double gutter;
  final ValueChanged<ProductCard> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(topPicksProvider);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      sliver: value.when(
        skipLoadingOnRefresh: true,
        data: (products) => AtomProductSliverGrid(products: products, onTap: onOpen),
        loading: () => SliverToBoxAdapter(
          child: Row(
            children: const [
              Expanded(child: AtomProductCardSkeleton()),
              SizedBox(width: AtomSpace.sm),
              Expanded(child: AtomProductCardSkeleton()),
            ],
          ),
        ),
        error: (_, _) => SliverToBoxAdapter(child: AtomErrorState(onRetry: () => ref.invalidate(topPicksProvider))),
      ),
    );
  }
}

class _OrderAnythingRow extends StatelessWidget {
  const _OrderAnythingRow({required this.onCustomOrder, required this.onMakeOffer});

  final VoidCallback onCustomOrder;
  final VoidCallback onMakeOffer;

  @override
  Widget build(BuildContext context) {
    Widget tile(String title, String body, IconData icon, Color bg, Color ink, VoidCallback onTap) => Expanded(
      child: AtomCard(
        onTap: onTap,
        color: bg,
        borderColor: null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AtomColors.white, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: ink, size: 20),
            ),
            const SizedBox(height: AtomSpace.xs),
            Text(title, style: AtomText.subheading),
            const SizedBox(height: 4),
            Text(body, style: AtomText.small.copyWith(color: ink, height: 1.45)),
          ],
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile(
            'Custom order',
            'Know the price? Order anything from any shop and plan it.',
            Icons.calculate_outlined,
            AtomColors.primarySoft,
            AtomColors.primaryDark,
            onCustomOrder,
          ),
          const SizedBox(width: AtomSpace.sm),
          tile(
            'Make an offer',
            'Not sure of the price? Tell us and a seller calls you.',
            Icons.chat_bubble_outline_rounded,
            AtomColors.amberSoft,
            AtomColors.amberInk,
            onMakeOffer,
          ),
        ],
      ),
    );
  }
}
