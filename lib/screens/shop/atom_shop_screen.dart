import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_design_content.dart';
import '../../data/atom_models.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../widgets/atom_catalogue_widgets.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';

enum _ShopView { categories, brands }

/// Shop tab (canvas: "All categories" / "All brands"). Every active category
/// and brand, with a search box that filters the open list as you type.
class AtomShopScreen extends ConsumerStatefulWidget {
  const AtomShopScreen({super.key});

  @override
  ConsumerState<AtomShopScreen> createState() => _AtomShopScreenState();
}

class _AtomShopScreenState extends ConsumerState<AtomShopScreen> {
  final _search = TextEditingController();
  _ShopView _view = _ShopView.categories;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CatalogueItem> _filter(List<CatalogueItem> items) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ? items : items.where((i) => i.title.toLowerCase().contains(q)).toList(growable: false);
  }

  void _customOrder() => AtomNav.customOrder(context);

  /// Categories are the design's fixed list; only brands come from the server.
  Future<void> _refresh() async {
    if (_view == _ShopView.categories) return;
    ref.invalidate(allBrandsProvider);
    await ref.read(allBrandsProvider.future).catchError((_) => const <CatalogueItem>[]);
  }

  List<DesignCategory> get _categories {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return designCategories;
    return designCategories.where((c) => c.label.toLowerCase().contains(q) || c.shortLabel.toLowerCase().contains(q)).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final brands = _view == _ShopView.brands ? ref.watch(allBrandsProvider) : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: RefreshIndicator(
            color: AtomColors.primary,
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, AtomSpace.sm),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(header: true, child: Text('Shop', style: AtomText.title)),
                        const SizedBox(height: AtomSpace.sm),
                        AtomSearchField(
                          controller: _search,
                          hint: _view == _ShopView.categories ? 'Search categories' : 'Search brands',
                          onChanged: (q) => setState(() => _query = q),
                        ),
                        const SizedBox(height: AtomSpace.sm),
                        AtomSegmented<_ShopView>(
                          items: const {_ShopView.categories: 'Categories', _ShopView.brands: 'Brands'},
                          value: _view,
                          onChanged: (v) => setState(() => _view = v),
                        ),
                      ],
                    ),
                  ),
                ),
                // The box filters categories and brands; products are a tap away.
                if (_query.trim().length >= 2)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AtomSpace.sm),
                    sliver: SliverToBoxAdapter(
                      child: AtomLinkCard(
                        icon: Icons.search_rounded,
                        title: 'Search products for "${_query.trim()}"',
                        message: 'Phones, ACs, bikes and more by name or brand',
                        onTap: () => AtomNav.search(context, query: _query.trim()),
                      ),
                    ),
                  ),
                if (brands == null)
                  ..._categoryResults(gutter)
                else
                  ...brands.when(
                    skipLoadingOnRefresh: true,
                    data: (items) => _brandResults(_filter(items), gutter),
                    loading: () => [_loading(gutter)],
                    error: (_, _) => [SliverFillRemaining(hasScrollBody: false, child: AtomErrorState(onRetry: () => ref.invalidate(allBrandsProvider)))],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(double gutter) => SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, AtomSpace.xl),
      sliver: SliverToBoxAdapter(
        child: AtomLinkCard(
          icon: Icons.add_rounded,
          title: 'Not in the list?',
          message: 'Order anything from any shop on installments',
          onTap: _customOrder,
        ),
      ),
    );

  Widget _noMatch() => SliverToBoxAdapter(
        child: AtomEmptyState(
            icon: Icons.search_off_rounded,
            title: _query.isEmpty ? 'Nothing here yet' : 'No match for "${_query.trim()}"',
            message: 'Place a custom order and a seller on Atomshop sources it for you.',
            actionLabel: 'Custom order',
            actionIcon: Icons.calculate_outlined,
            onAction: _customOrder,
          ),
      );

  List<Widget> _categoryResults(double gutter) {
    final items = _categories;
    if (items.isEmpty) return [_noMatch()];
    return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter, vertical: AtomSpace.xs),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) => SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: atomGridColumns(constraints.crossAxisExtent, minTileWidth: 160),
                mainAxisSpacing: AtomSpace.sm,
                crossAxisSpacing: AtomSpace.sm,
                mainAxisExtent: 150 * MediaQuery.textScalerOf(context).scale(1),
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _CategoryCard(category: items[i], onTap: () => AtomNav.category(context, items[i].item)),
            ),
          ),
        ),
        _footer(gutter),
      ];
  }

  List<Widget> _brandResults(List<CatalogueItem> items, double gutter) {
    if (items.isEmpty) return [_noMatch()];
    final sorted = [...items]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, 0),
        sliver: SliverToBoxAdapter(child: Text('All brands A–Z', style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800))),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, 0),
        sliver: SliverList.separated(
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: AtomSpace.xs),
          itemBuilder: (context, i) => _BrandRow(item: sorted[i], onTap: () => AtomNav.brand(context, sorted[i])),
        ),
      ),
      _footer(gutter),
    ];
  }

  Widget _loading(double gutter) => SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: AtomSpace.xs),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: AtomSpace.sm, crossAxisSpacing: AtomSpace.sm, mainAxisExtent: 150),
          itemCount: 6,
          itemBuilder: (_, _) => const AtomSkeleton(radius: 22),
        ),
      );
}

/// Shop tab category card from the design: 84 px icon circle and label.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final DesignCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The whole card is the tap target; the tile inside only draws.
    return Semantics(
      button: true,
      label: category.label,
      excludeSemantics: true,
      child: AtomCard(
        onTap: onTap,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: AtomSpace.sm, vertical: AtomSpace.md),
        child: Center(
          child: IgnorePointer(child: AtomDesignCategoryTile(icon: category.icon, label: category.label, size: 84, bold: true, onTap: onTap)),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.item, required this.onTap});

  final CatalogueItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = item.title.isEmpty ? '?' : item.title[0].toUpperCase();
    return Semantics(
      button: true,
      label: item.title,
      excludeSemantics: true,
      child: AtomCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: item.picture.isEmpty
                  ? Text(initial, style: AtomText.subheading.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w800))
                  : Padding(padding: const EdgeInsets.all(4), child: AtomNetworkImage(item.picture, fit: BoxFit.contain, placeholderIcon: Icons.storefront_outlined)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.label.copyWith(fontSize: 15))),
            const Icon(Icons.chevron_right_rounded, color: AtomColors.placeholder),
          ],
        ),
      ),
    );
  }
}
