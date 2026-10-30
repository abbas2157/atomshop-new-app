import 'dart:async';

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
import '../../state/atom_delivery_area.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../state/atom_session.dart';
import '../../widgets/atom_auto_scroll_row.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_catalogue_widgets.dart';
import '../../widgets/atom_logo.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../info/atom_apps_screen.dart';
import '../info/atom_info_widgets.dart';
import '../sellers/atom_seller_widgets.dart';
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
                  HomeHeader(
                    signedIn: signedIn,
                    onSignIn: () => AtomNav.signIn(context),
                    // Notifications belong to an account; guests are asked to sign in.
                    onNotifications: () => signedIn ? AtomNav.notifications(context) : AtomNav.signIn(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xs)),
                padded(HomeDeliveryAreaLink(
                  area: ref.watch(deliveryAreaProvider).value?.label ?? '',
                  onTap: () => AtomNav.location(context),
                )),
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
                padded(AtomSectionHeader(title: 'Our brand partners', subtitle: 'Official brands selling on Atomshop', actionLabel: 'Shop all', onAction: goShop)),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.sm)),
                SliverToBoxAdapter(
                  child: _BrandsRow(gutter: gutter, onOpen: (b) => AtomNav.brand(context, b)),
                ),
                gap,
                // Verified sellers on Atomshop; shows nothing until the
                // sellers API is live or when there are none.
                SliverToBoxAdapter(child: HomeTopSellersStrip(gutter: gutter)),
                padded(const AtomSectionHeader(title: 'Top picks', subtitle: 'Chosen by the Atomshop team')),
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.sm)),
                _TopPicksGrid(gutter: gutter, onOpen: (p) => _openProduct(context, p)),
                gap,
                padded(_OrderAnythingRow(onCustomOrder: () => AtomNav.customOrder(context), onMakeOffer: () => AtomNav.makeOffer(context))),
                gap,
                padded(HomePartnerCard.pay(onApply: () => atomOpenUrl(context, atomPayAppUrl(ref.read(appConfigProvider).value)), onGetApp: () => AtomNav.apps(context))),
                gap,
                padded(HomePartnerCard.brand(onApply: () => AtomNav.apps(context), onGetApp: () => AtomNav.apps(context))),
                gap,
                padded(HomePartnerCard.seller(onApply: () => atomOpenUrl(context, atomSellerApplyUrl(ref.read(appConfigProvider).value)), onGetApp: () => AtomNav.apps(context))),
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

/// Home top bar: logo, bell, and Sign in for guests.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.signedIn, required this.onSignIn, required this.onNotifications});

  final bool signedIn;
  final VoidCallback onSignIn;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AtomSpace.sm),
      child: Row(
        children: [
          // The logo shrinks to fit (never under the buttons) and always
          // keeps a gap before them, at any phone width or text size.
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AtomLogo(height: 34),
            ),
          ),
          const SizedBox(width: AtomSpace.sm),
          AtomIconButton(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', onPressed: onNotifications),
          if (!signedIn) ...[
            const SizedBox(width: AtomSpace.xs),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.1,
              child: AtomButton(label: 'Sign in', icon: Icons.login_rounded, onPressed: onSignIn, size: AtomButtonSize.small),
            ),
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

    // Skeletons stay still; loaded cards drift slowly.
    Widget row(int count, Widget Function(int) item, {bool auto = true}) => AtomAutoScrollRow(
      height: height,
      itemWidth: cardWidth,
      gutter: gutter,
      spacing: AtomSpace.sm,
      autoScroll: auto,
      itemCount: count,
      itemBuilder: (_, i) => item(i),
    );

    return AtomAsync<List<ProductCard>>(
      value: ref.watch(featuredProductsProvider),
      onRetry: () => ref.invalidate(featuredProductsProvider),
      compactError: true,
      loading: row(3, (_) => const AtomProductCardSkeleton(), auto: false),
      data: (products) => products.isEmpty
          ? const SizedBox.shrink()
          : row(products.length, (i) => AtomProductCard(product: products[i], tag: 'Hot', onTap: () => onOpen(products[i]))),
    );
  }
}

/// Brand partners as detailed cards, two to a page. Unlike "Hot right
/// now" (a slow drift) this pages: it turns every few seconds, with dots.
class _BrandsRow extends ConsumerWidget {
  const _BrandsRow({required this.gutter, required this.onOpen});

  final double gutter;
  final ValueChanged<CatalogueItem> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = MediaQuery.textScalerOf(context);
    // Padding + logo box + gaps + name, badge and count lines + button.
    final height = 2 * AtomSpace.sm + 76 + 3 * AtomSpace.xs + scale.scale(15) * 1.3 + scale.scale(12) * 1.4 * 2 + AtomSpace.xxs + AtomSize.buttonSm + AtomSpace.xs;

    return AtomAsync<List<CatalogueItem>>(
      value: ref.watch(homeBrandsProvider),
      onRetry: () => ref.invalidate(homeBrandsProvider),
      compactError: true,
      loading: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: Row(
          children: [
            Expanded(child: AtomSkeleton(height: height, radius: AtomRadius.card)),
            const SizedBox(width: AtomSpace.sm),
            Expanded(child: AtomSkeleton(height: height, radius: AtomRadius.card)),
          ],
        ),
      ),
      data: (brands) => brands.isEmpty
          ? const SizedBox.shrink()
          : _BrandPager(brands: brands, height: height, gutter: gutter, onOpen: onOpen),
    );
  }
}

class _BrandPager extends StatefulWidget {
  const _BrandPager({required this.brands, required this.height, required this.gutter, required this.onOpen});

  final List<CatalogueItem> brands;
  final double height;
  final double gutter;
  final ValueChanged<CatalogueItem> onOpen;

  @override
  State<_BrandPager> createState() => _BrandPagerState();
}

class _BrandPagerState extends State<_BrandPager> {
  static const _perPage = 2;
  static const _interval = Duration(seconds: 4);

  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  int get _pages => (widget.brands.length / _perPage).ceil();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (_pages < 2 || MediaQuery.disableAnimationsOf(context)) return;
    _timer = Timer(_interval, () {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % _pages, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brands = widget.brands;
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              // Hold still while the customer swipes; count again after.
              if (n is ScrollStartNotification && n.dragDetails != null) _timer?.cancel();
              if (n is ScrollEndNotification) _schedule();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, page) => Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.gutter),
                child: Row(
                  children: [
                    for (var k = 0; k < _perPage; k++) ...[
                      if (k > 0) const SizedBox(width: AtomSpace.sm),
                      Expanded(
                        child: page * _perPage + k < brands.length
                            ? _BrandPartnerTile(
                                brand: brands[page * _perPage + k],
                                onTap: () => widget.onOpen(brands[page * _perPage + k]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_pages > 1) ...[
          const SizedBox(height: AtomSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pages; i++)
                Semantics(
                  button: true,
                  label: 'Brands page ${i + 1} of $_pages',
                  selected: i == _page,
                  child: GestureDetector(
                    onTap: () => _controller.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? AtomColors.primary : AtomColors.line2,
                          borderRadius: BorderRadius.circular(AtomRadius.pill),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BrandPartnerTile extends StatelessWidget {
  const _BrandPartnerTile({required this.brand, required this.onTap});

  final CatalogueItem brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = brand.productCount;
    return AtomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AtomSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: AtomSpace.sm),
            decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.input)),
            child: brand.picture.isEmpty
                ? Center(child: Text(brand.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.subheading))
                : AtomNetworkImage(brand.picture, fit: BoxFit.contain, semanticLabel: brand.title, placeholderIcon: Icons.storefront_outlined),
          ),
          const SizedBox(height: AtomSpace.xs),
          Text(brand.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.subheading),
          const SizedBox(height: AtomSpace.xxs),
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 14, color: AtomColors.primary),
              const SizedBox(width: AtomSpace.xxs),
              Flexible(
                child: Text(
                  'Official partner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Text(
            count == null || count <= 0 ? 'On installments' : '$count ${count == 1 ? 'product' : 'products'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtomText.small,
          ),
          const Spacer(),
          AtomButton(
            label: 'Shop now',
            icon: Icons.arrow_forward_rounded,
            onPressed: onTap,
            variant: AtomButtonVariant.secondary,
            size: AtomButtonSize.small,
            expand: true,
          ),
        ],
      ),
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
        error: (e, _) => SliverToBoxAdapter(child: AtomErrorState(error: e, onRetry: () => ref.invalidate(topPicksProvider))),
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
