import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/atom_brands.dart';
import '../../data/atom_models.dart';
import '../../data/atom_sellers.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_catalogue_widgets.dart';
import '../../widgets/atom_select_field.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../info/atom_info_widgets.dart';
import 'atom_brand_widgets.dart';

/// A brand's page, as on the website (`app/brands/{slug or id}`): promos,
/// the store header with links, figures, featured products, then every
/// product a page at a time, by category, sorted and filtered on the server.
class AtomBrandScreen extends ConsumerStatefulWidget {
  const AtomBrandScreen({super.key, required this.brandKey, required this.title, this.logo = ''});

  /// Slug or id.
  final String brandKey;

  /// Shown in the header until the page loads.
  final String title;
  final String logo;

  @override
  ConsumerState<AtomBrandScreen> createState() => _AtomBrandScreenState();
}

class _AtomBrandScreenState extends ConsumerState<AtomBrandScreen> {
  static const _perPage = 20;

  BrandQuery _query = const BrandQuery();

  /// The first page of the first answer: header, figures, featured and
  /// categories (they don't change with the filters).
  BrandPage? _head;
  final List<ProductCard> _products = [];
  AtomPagination? _pagination;
  bool _loading = false;
  Object? _error;

  /// Bumped on every new filter; an answer for an older one is dropped.
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || _pagination?.hasMore != true)) return;
    final seq = reset ? ++_seq : _seq;
    final page = reset ? 1 : (_pagination?.nextPage ?? 1);
    setState(() {
      _loading = true;
      if (reset) {
        _error = null;
        _products.clear();
        _pagination = null;
      }
    });
    try {
      final result = await ref.read(atomBrandsApiProvider).page(widget.brandKey, _query, page: page, perPage: _perPage);
      if (!mounted || seq != _seq) return;
      setState(() {
        _head ??= result;
        _products.addAll(result.products);
        _pagination = result.pagination;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _apply(BrandQuery query) {
    _query = query;
    _load(reset: true);
  }

  Future<void> _refresh() async {
    _head = null;
    await _load(reset: true);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) _load();
    return false;
  }

  Future<void> _pickSort() async {
    final picked = await showAtomSearchSelect<ShopSort>(
      context,
      title: 'Sort by',
      searchHint: 'Search sort options',
      options: ShopSort.values,
      label: (s) => s.label,
      isSelected: (s) => s == _query.sort,
    );
    if (picked != null && picked != _query.sort) {
      _apply(BrandQuery(categoryId: _query.categoryId, sort: picked, atompayOnly: _query.atompayOnly, inStockOnly: _query.inStockOnly));
    }
  }

  void _share(BrandProfile b) {
    if (b.shareUrl.isEmpty) return;
    SharePlus.instance.share(ShareParams(text: '${b.storeTitle}\n${b.shareUrl}', subject: b.storeTitle));
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final head = _head;
    final q = _query;

    Widget padded(Widget child, {double top = 0}) => SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
          sliver: SliverToBoxAdapter(child: child),
        );

    // A brand that can't be shown at all (404): one message, no filters.
    if (head == null && _error != null) {
      return Scaffold(
        body: SafeArea(
          child: AtomPageWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.xl),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                ),
                const SizedBox(height: AtomSpace.lg),
                AtomErrorState(error: _error, onRetry: _refresh),
              ],
            ),
          ),
        ),
      );
    }

    final categories = head?.categories ?? const <BrandCategory>[];
    final featured = head?.featured ?? const <ProductCard>[];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.white,
        body: Column(
          children: [
            // The header's navy runs up behind the status bar (light icons).
            Container(color: AtomColors.ink, height: MediaQuery.paddingOf(context).top),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                child: AtomPageWidth(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: RefreshIndicator(
                      color: AtomColors.primary,
                      onRefresh: _refresh,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _BrandHeader(
                              gutter: gutter,
                              title: widget.title,
                              logo: widget.logo,
                              page: head,
                              onShare: head == null || head.brand.shareUrl.isEmpty ? null : () => _share(head.brand),
                            ),
                          ),
                          if (featured.isNotEmpty) ...[
                            padded(const AtomSectionHeader(title: 'Featured products'), top: AtomSpace.lg),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(top: AtomSpace.sm),
                                child: _ProductRow(products: featured, gutter: gutter),
                              ),
                            ),
                          ],
                          padded(const AtomSectionHeader(title: 'All products'), top: AtomSpace.lg),
                          if (categories.length >= 2)
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 42 + AtomSpace.sm,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, 0),
                                  itemCount: categories.length + 1,
                                  separatorBuilder: (_, _) => const SizedBox(width: AtomSpace.xs),
                                  itemBuilder: (_, i) {
                                    final c = i == 0 ? null : categories[i - 1];
                                    return AtomChoiceChip(
                                      label: c?.title ?? 'All',
                                      dark: true,
                                      selected: q.categoryId == c?.id,
                                      onTap: () => q.categoryId == c?.id
                                          ? null
                                          : _apply(BrandQuery(categoryId: c?.id, sort: q.sort, atompayOnly: q.atompayOnly, inStockOnly: q.inStockOnly)),
                                    );
                                  },
                                ),
                              ),
                            ),
                          padded(
                            Wrap(
                              spacing: AtomSpace.xs,
                              runSpacing: AtomSpace.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AtomButton(
                                  label: q.sort.label,
                                  icon: Icons.swap_vert_rounded,
                                  onPressed: _pickSort,
                                  variant: AtomButtonVariant.secondary,
                                  size: AtomButtonSize.small,
                                ),
                                AtomChoiceChip(
                                  label: 'AtomPay only',
                                  selected: q.atompayOnly,
                                  onTap: () => _apply(BrandQuery(categoryId: q.categoryId, sort: q.sort, atompayOnly: !q.atompayOnly, inStockOnly: q.inStockOnly)),
                                ),
                                AtomChoiceChip(
                                  label: 'In stock',
                                  selected: q.inStockOnly,
                                  onTap: () => _apply(BrandQuery(categoryId: q.categoryId, sort: q.sort, atompayOnly: q.atompayOnly, inStockOnly: !q.inStockOnly)),
                                ),
                              ],
                            ),
                            top: AtomSpace.sm,
                          ),
                          ..._grid(gutter, padded),
                          const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xl)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _grid(double gutter, Widget Function(Widget, {double top}) padded) {
    final total = _pagination?.total;
    if (_products.isEmpty) {
      if (_error != null) return [padded(AtomErrorState(error: _error, onRetry: () => _load(reset: true)), top: AtomSpace.md)];
      if (_loading || _pagination == null) {
        return [
          padded(
            const Row(
              children: [
                Expanded(child: AtomProductCardSkeleton()),
                SizedBox(width: AtomSpace.sm),
                Expanded(child: AtomProductCardSkeleton()),
              ],
            ),
            top: AtomSpace.md,
          ),
        ];
      }
      return [
        padded(
          AtomEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No products match',
            message: 'Try another category or clear the filters.',
            actionLabel: 'Custom order',
            actionIcon: Icons.calculate_outlined,
            onAction: () => AtomNav.customOrder(context),
          ),
          top: AtomSpace.md,
        ),
      ];
    }
    return [
      if (total != null)
        padded(
          Text('$total ${total == 1 ? 'product' : 'products'} · prices confirmed by the seller', style: AtomText.small.copyWith(color: AtomColors.body, fontSize: 13)),
          top: AtomSpace.md,
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, 0),
        sliver: AtomProductSliverGrid(products: _products, showCash: true, onTap: (p) => AtomNav.product(context, p.id)),
      ),
      if (_loading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AtomSpace.md),
            child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AtomColors.primary))),
          ),
        )
      else if (_error != null)
        padded(AtomErrorState(error: _error, onRetry: _load), top: AtomSpace.md),
    ];
  }
}

/// Navy header (canvas: "Brand page"): back and share, promos, logo, store
/// title, intro, links, and the three figures.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.gutter, required this.title, required this.logo, required this.page, required this.onShare});

  final double gutter;
  final String title;
  final String logo;

  /// Null while the first page loads.
  final BrandPage? page;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final b = page?.brand;
    final card = b?.card;
    final links = [
      if (b != null && b.website.isNotEmpty)
        _HeaderLink(icon: Icons.language_rounded, label: Uri.tryParse(b.website)?.host.replaceFirst('www.', '') ?? 'Website', onTap: () => atomOpenUrl(context, b.website)),
      if (b != null && b.supportEmail.isNotEmpty)
        _HeaderLink(icon: Icons.mail_outline_rounded, label: 'Email', onTap: () => atomOpenUrl(context, 'mailto:${b.supportEmail}')),
      if (b != null && b.supportPhone.isNotEmpty)
        _HeaderLink(icon: Icons.call_outlined, label: 'Call', onTap: () => atomOpenUrl(context, 'tel:${b.supportPhone.replaceAll(RegExp(r'[^0-9+]'), '')}')),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.lg),
      decoration: const BoxDecoration(color: AtomColors.ink, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', dark: true, onPressed: () => Navigator.of(context).maybePop()),
              const Spacer(),
              if (onShare != null) AtomIconButton(icon: Icons.ios_share_rounded, tooltip: 'Share', dark: true, onPressed: onShare),
            ],
          ),
          if (b != null && b.promos.isNotEmpty) ...[
            const SizedBox(height: AtomSpace.md),
            _Promos(promos: b.promos),
          ],
          const SizedBox(height: AtomSpace.md),
          Row(
            children: [
              BrandLogo(id: card?.id ?? 0, title: card?.title ?? title, logo: card?.logo ?? logo, initial: card?.initial, size: 84, radius: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(b?.storeTitle ?? title, style: AtomText.title.copyWith(fontSize: 22, color: AtomColors.white)),
                    ),
                    if (card == null || card.isPartner) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: AtomColors.amber),
                          const SizedBox(width: 4),
                          Flexible(child: Text('Official Brand Partner', style: AtomText.small.copyWith(color: AtomColors.amber, fontWeight: FontWeight.w800))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (b != null && b.intro.isNotEmpty) ...[
            const SizedBox(height: AtomSpace.sm),
            Text(b.intro, style: AtomText.body.copyWith(color: AtomColors.onDark)),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: AtomSpace.sm),
            Wrap(spacing: AtomSpace.xs, runSpacing: AtomSpace.xs, children: links),
          ],
          const SizedBox(height: AtomSpace.md),
          if (page == null)
            AtomSkeleton(height: 64, radius: 16)
          else
            _Stats(page: page!),
        ],
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AtomButton(label: label, icon: icon, onPressed: onTap, variant: AtomButtonVariant.light, size: AtomButtonSize.medium);
  }
}

/// Products · Categories · Month plans as three tiles.
class _Stats extends StatelessWidget {
  const _Stats({required this.page});

  final BrandPage page;

  @override
  Widget build(BuildContext context) {
    final p = page;
    Widget tile(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AtomSpace.sm, horizontal: AtomSpace.xs),
            decoration: BoxDecoration(color: AtomColors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(value, maxLines: 1, style: AtomText.heading.copyWith(color: AtomColors.white)),
                Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.small.copyWith(color: AtomColors.onDark)),
              ],
            ),
          ),
        );
    final plans = p.planMonths.isEmpty ? null : p.planMonths;
    return Semantics(
      label: '${p.productCount} products, ${p.categoryCount} categories${plans == null ? '' : ', $plans month plans'}',
      excludeSemantics: true,
      child: Row(
        children: [
          tile('${p.productCount}', p.productCount == 1 ? 'Product' : 'Products'),
          const SizedBox(width: AtomSpace.xs),
          tile('${p.categoryCount}', p.categoryCount == 1 ? 'Category' : 'Categories'),
          if (plans != null) ...[
            const SizedBox(width: AtomSpace.xs),
            tile(plans, 'Month plans'),
          ],
        ],
      ),
    );
  }
}

/// The brand's promos as a small swipeable carousel with dots.
class _Promos extends StatefulWidget {
  const _Promos({required this.promos});

  final List<BrandPromo> promos;

  @override
  State<_Promos> createState() => _PromosState();
}

class _PromosState extends State<_Promos> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promos = widget.promos;
    final scale = MediaQuery.textScalerOf(context);
    final height = 2 * AtomSpace.md + 24 + AtomSpace.xs + scale.scale(17) * 1.3 + scale.scale(14) * 1.5 * 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: promos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final p = promos[i];
              return Container(
                margin: const EdgeInsets.only(right: 2),
                padding: const EdgeInsets.all(AtomSpace.md),
                decoration: BoxDecoration(color: AtomColors.amber, borderRadius: BorderRadius.circular(AtomRadius.card)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.tag.isNotEmpty) AtomBadge(p.tag, tone: AtomTone.dark),
                    const SizedBox(height: AtomSpace.xs),
                    if (p.heading.isNotEmpty) Text(p.heading, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.subheading.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                    if (p.text.isNotEmpty) Text(p.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: AtomText.body.copyWith(color: AtomColors.ink)),
                  ],
                ),
              );
            },
          ),
        ),
        if (promos.length > 1) ...[
          const SizedBox(height: AtomSpace.xs),
          Semantics(
            label: 'Promo ${_page + 1} of ${promos.length}',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 0; i < promos.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AtomColors.amber : AtomColors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AtomRadius.pill),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Featured products, fixed-width cards built lazily.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.products, required this.gutter});

  final List<ProductCard> products;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final width = context.atomPick<double>(compact: 168, medium: 190, expanded: 210);
    return SizedBox(
      height: width / 1.25 + 128 * MediaQuery.textScalerOf(context).scale(1),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gutter),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AtomSpace.sm),
        itemBuilder: (_, i) => SizedBox(
          width: width,
          child: AtomProductCard(product: products[i], showCash: true, onTap: () => AtomNav.product(context, products[i].id)),
        ),
      ),
    );
  }
}
