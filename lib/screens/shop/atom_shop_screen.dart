import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_models.dart';
import '../../data/atom_shop.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_catalogue_widgets.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';

/// Shop tab: Brand Partner products from `GET api/products`, page by page,
/// with search, filters and sort (server TRD 2026-10-29-app-shop-api).
///
/// Any change to the query starts again at page 1; an answer for an older
/// query is dropped, so typing fast never shows stale results.
class AtomShopScreen extends ConsumerStatefulWidget {
  const AtomShopScreen({super.key});

  @override
  ConsumerState<AtomShopScreen> createState() => _AtomShopScreenState();
}

class _AtomShopScreenState extends ConsumerState<AtomShopScreen> {
  static const _perPage = 20;

  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  ShopQuery _query = const ShopQuery();
  final _products = <ProductCard>[];
  ShopPagination? _pagination;

  /// The whole catalogue for the filter sheet, kept from the first answer.
  ShopFilters _filters = ShopFilters.none;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  Object? _moreError;

  /// Bumped on every new query; answers for an older one are ignored.
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = _scroll.position;
    if (p.pixels > p.maxScrollExtent - 600) _loadMore();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
      _moreError = null;
    });
    try {
      final page = await ref.read(atomShopApiProvider).page(_query, perPage: _perPage);
      if (!mounted || seq != _seq) return;
      setState(() {
        _products
          ..clear()
          ..addAll(page.products);
        _pagination = page.pagination;
        if (!page.filters.isEmpty) _filters = page.filters;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final p = _pagination;
    if (_loading || _loadingMore || p == null || !p.hasMore) return;
    final seq = _seq;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final page = await ref.read(atomShopApiProvider).page(_query, page: p.currentPage + 1, perPage: _perPage);
      if (!mounted || seq != _seq) return;
      setState(() {
        final seen = {for (final x in _products) x.id};
        _products.addAll(page.products.where((x) => !seen.contains(x.id)));
        _pagination = page.pagination;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _moreError = e;
        _loadingMore = false;
      });
    }
  }

  void _apply(ShopQuery q) {
    if (q == _query) return;
    _query = q;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _load();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _apply(_query.copyWith(q: text)));
  }

  Future<void> _openFilters() async {
    final picked = await showModalBottomSheet<ShopQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AtomColors.white,
      builder: (_) => _FilterSheet(filters: _filters, query: _query),
    );
    if (picked != null) _apply(picked);
  }

  String _optionTitle(List<ShopFilterOption> options, int id) => options.where((o) => o.id == id).firstOrNull?.title ?? '#$id';

  /// Applied filters as removable chips.
  List<(String, ShopQuery)> get _chips {
    final q = _query;
    return [
      for (final id in q.categoryIds) (_optionTitle(_filters.categories, id), q.copyWith(categoryIds: {...q.categoryIds}..remove(id))),
      for (final id in q.brandIds) (_optionTitle(_filters.brands, id), q.copyWith(brandIds: {...q.brandIds}..remove(id))),
      if (q.minPrice != null || q.maxPrice != null)
        (
          '${AtomFormat.rupees(q.minPrice ?? _filters.minPrice ?? 0)} – ${AtomFormat.rupees(q.maxPrice ?? _filters.maxPrice ?? 0)}',
          q.copyWith(minPrice: () => null, maxPrice: () => null),
        ),
      if (q.atompay) ('AtomPay only', q.copyWith(atompay: false)),
      if (q.inStock) ('In stock only', q.copyWith(inStock: false)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final total = _pagination?.total ?? _products.length;
    final canFilter = !_filters.isEmpty;
    final chips = _chips;
    Widget padded(Widget child, {double top = 0}) => SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
          sliver: SliverToBoxAdapter(child: child),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: RefreshIndicator(
            color: AtomColors.primary,
            onRefresh: _load,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                padded(Semantics(header: true, child: Text('Shop', style: AtomText.title)), top: AtomSpace.md),
                padded(
                  Text('Products from verified sellers and Brand Partners on Atomshop', style: AtomText.small),
                  top: 4,
                ),
                padded(AtomSearchField(controller: _search, hint: 'Search products, brands, categories', onChanged: _onSearch), top: AtomSpace.sm),
                if (canFilter)
                  padded(
                    Row(
                      children: [
                        Expanded(
                          child: AtomButton(
                            label: _query.filterCount == 0 ? 'Filters' : 'Filters · ${_query.filterCount}',
                            icon: Icons.tune_rounded,
                            variant: AtomButtonVariant.secondary,
                            size: AtomButtonSize.small,
                            expand: true,
                            onPressed: _openFilters,
                          ),
                        ),
                        const SizedBox(width: AtomSpace.xs),
                        Expanded(
                          child: AtomButton(
                            label: _query.sort.label,
                            icon: Icons.swap_vert_rounded,
                            variant: AtomButtonVariant.secondary,
                            size: AtomButtonSize.small,
                            expand: true,
                            onPressed: _openFilters,
                          ),
                        ),
                      ],
                    ),
                    top: AtomSpace.sm,
                  ),
                if (chips.isNotEmpty)
                  padded(
                    Wrap(
                      spacing: AtomSpace.xs,
                      runSpacing: AtomSpace.xs,
                      children: [
                        for (final (label, without) in chips) _RemovableChip(label: label, onRemove: () => _apply(without)),
                        _RemovableChip(label: 'Clear all', onRemove: () => _apply(ShopQuery(q: _query.q, sort: _query.sort)), strong: true),
                      ],
                    ),
                    top: AtomSpace.sm,
                  ),
                if (_loading && _products.isEmpty)
                  padded(
                    const Column(
                      children: [
                        Row(children: [Expanded(child: AtomProductCardSkeleton()), SizedBox(width: AtomSpace.sm), Expanded(child: AtomProductCardSkeleton())]),
                        SizedBox(height: AtomSpace.sm),
                        Row(children: [Expanded(child: AtomProductCardSkeleton()), SizedBox(width: AtomSpace.sm), Expanded(child: AtomProductCardSkeleton())]),
                      ],
                    ),
                    top: AtomSpace.md,
                  )
                else if (_error != null && _products.isEmpty)
                  padded(AtomErrorState(error: _error, onRetry: _load), top: AtomSpace.md)
                else if (_products.isEmpty)
                  padded(
                    AtomEmptyState(
                      icon: Icons.search_off_rounded,
                      title: _query.isEmpty ? 'No products yet' : 'No products match',
                      message: _query.isEmpty
                          ? 'Place a custom order and a verified seller on Atomshop sources it for you.'
                          : 'Try other words or fewer filters, or place a custom order and a seller sources it.',
                      actionLabel: 'Custom order',
                      actionIcon: Icons.calculate_outlined,
                      onAction: () => AtomNav.customOrder(context),
                    ),
                    top: AtomSpace.md,
                  )
                else ...[
                  padded(
                    Text(
                      '$total ${total == 1 ? 'product' : 'products'} · prices confirmed by the seller',
                      style: AtomText.small.copyWith(color: AtomColors.body, fontSize: 13),
                    ),
                    top: AtomSpace.md,
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, 0),
                    sliver: AtomProductSliverGrid(products: _products, showCash: true, onTap: (p) => AtomNav.product(context, p.id)),
                  ),
                  if (_loadingMore)
                    padded(const Center(child: Padding(padding: EdgeInsets.all(AtomSpace.md), child: CircularProgressIndicator(strokeWidth: 2))), top: AtomSpace.sm)
                  else if (_moreError != null)
                    padded(
                      Center(
                        child: AtomButton(
                          label: 'Load more',
                          icon: Icons.refresh_rounded,
                          variant: AtomButtonVariant.secondary,
                          size: AtomButtonSize.small,
                          onPressed: _loadMore,
                        ),
                      ),
                      top: AtomSpace.md,
                    ),
                  padded(
                    AtomLinkCard(
                      icon: Icons.add_rounded,
                      title: "Can't find your model?",
                      message: 'Place a custom order or make an offer',
                      onTap: () => AtomNav.customOrder(context),
                    ),
                    top: AtomSpace.md,
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xl)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pill with a close icon that removes one applied filter.
class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove, this.strong = false});

  final String label;
  final VoidCallback onRemove;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: strong ? label : 'Remove $label',
      excludeSemantics: true,
      child: Material(
        color: strong ? AtomColors.white : AtomColors.primarySoft,
        shape: StadiumBorder(side: BorderSide(color: strong ? AtomColors.line2 : AtomColors.primarySoft)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onRemove,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(strong ? Icons.clear_all_rounded : Icons.close_rounded, size: 16, color: AtomColors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filters and sort, applied together with "Show results".
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filters, required this.query});

  final ShopFilters filters;
  final ShopQuery query;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ShopQuery _draft = widget.query;

  int get _min => widget.filters.minPrice ?? 0;
  int get _max => widget.filters.maxPrice ?? 0;

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: AtomSpace.md, bottom: AtomSpace.xs),
        child: Semantics(header: true, child: Text(title, style: AtomText.label)),
      );

  Widget _options(List<ShopFilterOption> options, Set<int> selected, ValueChanged<Set<int>> onChanged) => Wrap(
        spacing: AtomSpace.xs,
        runSpacing: AtomSpace.xs,
        children: [
          for (final o in options)
            AtomChoiceChip(
              label: '${o.title} (${o.count})',
              selected: selected.contains(o.id),
              onTap: () => onChanged(selected.contains(o.id) ? ({...selected}..remove(o.id)) : {...selected, o.id}),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final f = widget.filters;
    final hasPrice = _max > _min;
    final lo = (_draft.minPrice ?? _min).clamp(_min, _max).toDouble();
    final hi = (_draft.maxPrice ?? _max).clamp(_min, _max).toDouble();
    final sorts = f.sorts.isEmpty ? ShopSort.values : f.sorts;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.atomGutter, 0, context.atomGutter, AtomSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter and sort', style: AtomText.heading),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section('Sort by'),
                    Wrap(
                      spacing: AtomSpace.xs,
                      runSpacing: AtomSpace.xs,
                      children: [
                        for (final s in sorts) AtomChoiceChip(label: s.label, selected: _draft.sort == s, onTap: () => setState(() => _draft = _draft.copyWith(sort: s))),
                      ],
                    ),
                    if (f.categories.isNotEmpty) ...[
                      _section('Categories'),
                      _options(f.categories, _draft.categoryIds, (v) => setState(() => _draft = _draft.copyWith(categoryIds: v))),
                    ],
                    if (f.brands.isNotEmpty) ...[
                      _section('Brands'),
                      _options(f.brands, _draft.brandIds, (v) => setState(() => _draft = _draft.copyWith(brandIds: v))),
                    ],
                    if (hasPrice) ...[
                      _section('Price'),
                      Text('${AtomFormat.rupees(lo.round())} – ${AtomFormat.rupees(hi.round())}', style: AtomText.body),
                      RangeSlider(
                        min: _min.toDouble(),
                        max: _max.toDouble(),
                        values: RangeValues(lo, hi),
                        activeColor: AtomColors.primary,
                        onChanged: (v) => setState(() {
                          final from = v.start.round(), to = v.end.round();
                          _draft = _draft.copyWith(
                            minPrice: () => from <= _min ? null : from,
                            maxPrice: () => to >= _max ? null : to,
                          );
                        }),
                      ),
                    ],
                    _section('Show'),
                    Wrap(
                      spacing: AtomSpace.xs,
                      runSpacing: AtomSpace.xs,
                      children: [
                        AtomChoiceChip(label: 'AtomPay only', selected: _draft.atompay, onTap: () => setState(() => _draft = _draft.copyWith(atompay: !_draft.atompay))),
                        AtomChoiceChip(label: 'In stock only', selected: _draft.inStock, onTap: () => setState(() => _draft = _draft.copyWith(inStock: !_draft.inStock))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AtomSpace.md),
            Row(
              children: [
                Expanded(
                  child: AtomButton(
                    label: 'Reset',
                    icon: Icons.restart_alt_rounded,
                    variant: AtomButtonVariant.secondary,
                    expand: true,
                    onPressed: () => setState(() => _draft = ShopQuery(q: widget.query.q)),
                  ),
                ),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: AtomButton(
                    label: 'Show results',
                    icon: Icons.check_rounded,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(_draft),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
