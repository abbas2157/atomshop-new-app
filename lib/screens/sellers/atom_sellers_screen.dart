import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_order.dart';
import '../../data/atom_sellers.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../state/atom_order_providers.dart';
import '../../state/atom_sellers_providers.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_select_field.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_seller_widgets.dart';

/// Verified sellers on Atomshop: top rated first (when nothing is filtered),
/// then every seller, a page at a time as the list scrolls. Filter by city
/// and area, search by business or owner name, top rated only, and sort.
class AtomSellersScreen extends ConsumerStatefulWidget {
  const AtomSellersScreen({super.key});

  @override
  ConsumerState<AtomSellersScreen> createState() => _AtomSellersScreenState();
}

class _AtomSellersScreenState extends ConsumerState<AtomSellersScreen> {
  static const _perPage = 15;

  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int? _cityId;
  int? _areaId;
  bool _topRatedOnly = false;
  SellerSort _sort = SellerSort.top;

  final List<Seller> _sellers = [];
  AtomPagination? _pagination;
  bool _loading = false;
  Object? _error;

  /// Bumped on every new search; an answer for an older one is dropped.
  int _seq = 0;

  bool get _filtered => _query.isNotEmpty || _cityId != null || _areaId != null || _topRatedOnly || _sort != SellerSort.top;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// First page for the current filters ([reset]), or the next page.
  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || _pagination?.hasMore != true)) return;
    final seq = reset ? ++_seq : _seq;
    final page = reset ? 1 : (_pagination?.nextPage ?? 1);
    setState(() {
      _loading = true;
      if (reset) {
        _error = null;
        _sellers.clear();
        _pagination = null;
      }
    });
    try {
      final result = await ref.read(atomSellersApiProvider).sellers(
            cityId: _cityId,
            areaId: _areaId,
            q: _query,
            topRated: _topRatedOnly,
            sort: _sort,
            page: page,
            perPage: _perPage,
          );
      if (!mounted || seq != _seq) return;
      setState(() {
        _sellers.addAll(result.sellers);
        _pagination = result.pagination;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = text.trim();
      if (q == _query) return;
      _query = q;
      _load(reset: true);
    });
  }

  void _apply(VoidCallback change) {
    setState(change);
    _load(reset: true);
  }

  Future<void> _refresh() async {
    ref.invalidate(topRatedSellersProvider);
    await _load(reset: true);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) _load();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final total = _pagination?.total;

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
              const AtomTopBar(title: 'Verified sellers', subtitle: 'Sellers on Atomshop, checked in person'),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: RefreshIndicator(
                    color: AtomColors.primary,
                    onRefresh: _refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        padded(AtomSearchField(controller: _search, hint: 'Search by business or owner name', onChanged: _onSearch), top: AtomSpace.xs),
                        padded(_PlaceFilters(cityId: _cityId, areaId: _areaId, onCity: (id) => _apply(() {
                              _cityId = id;
                              _areaId = null;
                            }), onArea: (id) => _apply(() => _areaId = id)), top: AtomSpace.sm),
                        padded(
                          Wrap(
                            spacing: AtomSpace.xs,
                            runSpacing: AtomSpace.xs,
                            children: [
                              AtomChoiceChip(label: 'Top rated only', selected: _topRatedOnly, onTap: () => _apply(() => _topRatedOnly = !_topRatedOnly)),
                              for (final s in SellerSort.values)
                                AtomChoiceChip(label: s.label, selected: _sort == s, onTap: () => _sort == s ? null : _apply(() => _sort = s)),
                            ],
                          ),
                          top: AtomSpace.sm,
                        ),
                        if (!_filtered) SliverToBoxAdapter(child: _TopRatedSection(gutter: gutter)),
                        padded(
                          Text(
                            total == null ? 'All verified sellers' : '$total verified ${total == 1 ? 'seller' : 'sellers'} on Atomshop',
                            style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800),
                          ),
                          top: AtomSpace.lg,
                        ),
                        ..._list(gutter),
                        const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xl)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _list(double gutter) {
    Widget pad(Widget child) => SliverPadding(padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, 0), sliver: SliverToBoxAdapter(child: child));

    if (_sellers.isEmpty) {
      if (_error != null) return [pad(AtomErrorState(error: _error, onRetry: () => _load(reset: true)))];
      if (_loading || _pagination == null) {
        return [
          for (var i = 0; i < 3; i++) pad(const AtomSkeleton(height: 200, radius: AtomRadius.card)),
        ];
      }
      return [
        pad(AtomEmptyState(
          icon: Icons.storefront_outlined,
          title: 'No sellers match',
          message: _filtered ? 'Try another area or clear the search.' : 'Verified sellers on Atomshop will show here.',
        )),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        sliver: SliverList.separated(
          itemCount: _sellers.length,
          separatorBuilder: (_, _) => const SizedBox(height: AtomSpace.sm),
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.only(top: i == 0 ? AtomSpace.sm : 0),
            child: SellerCard(seller: _sellers[i]),
          ),
        ),
      ),
      if (_loading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AtomSpace.md),
            child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AtomColors.primary))),
          ),
        )
      else if (_error != null)
        pad(AtomErrorState(error: _error, onRetry: _load)),
    ];
  }
}

/// City, then the area of that city (areas load after a city is picked).
class _PlaceFilters extends ConsumerWidget {
  const _PlaceFilters({required this.cityId, required this.areaId, required this.onCity, required this.onArea});

  final int? cityId;
  final int? areaId;
  final ValueChanged<int?> onCity;
  final ValueChanged<int?> onArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(citiesProvider);
    final city = cityId;
    final areas = city == null ? null : ref.watch(areasProvider(city));
    const any = AtomPlace(id: 0, title: '');

    String label(AtomPlace p, String all) => p.id == 0 ? all : p.title;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AtomSelectField<AtomPlace>(
            title: 'Choose a city',
            searchHint: 'Search cities',
            hint: 'Any city',
            options: [any, ...?cities.value],
            label: (p) => label(p, 'Any city'),
            selected: cities.value?.where((c) => c.id == city).firstOrNull,
            loading: cities.isLoading,
            failed: cities.hasError,
            onRetry: () => ref.invalidate(citiesProvider),
            onChanged: (c) => onCity(c.id == 0 ? null : c.id),
          ),
        ),
        const SizedBox(width: AtomSpace.xs),
        Expanded(
          child: AtomSelectField<AtomPlace>(
            title: 'Choose an area',
            searchHint: 'Search areas',
            hint: city == null ? 'City first' : 'Any area',
            options: [any, ...?areas?.value],
            label: (p) => label(p, 'Any area'),
            selected: areas?.value?.where((a) => a.id == areaId).firstOrNull,
            enabled: city != null,
            loading: areas?.isLoading ?? false,
            failed: areas?.hasError ?? false,
            onRetry: city == null ? null : () => ref.invalidate(areasProvider(city)),
            onChanged: (a) => onArea(a.id == 0 ? null : a.id),
          ),
        ),
      ],
    );
  }
}

/// "Top rated" row: only when nothing is filtered, and only when there are
/// top-rated sellers (no error shown here; the list below has its own).
class _TopRatedSection extends ConsumerWidget {
  const _TopRatedSection({required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellers = ref.watch(topRatedSellersProvider).value;
    if (sellers == null || sellers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AtomSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: const AtomSectionHeader(title: 'Top rated', subtitle: 'Most orders completed on Atomshop'),
          ),
          const SizedBox(height: AtomSpace.sm),
          SellerTileRow(
            sellers: sellers,
            gutter: gutter,
            onTap: (s) => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AtomSpace.md),
                  child: SellerCard(seller: s),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
