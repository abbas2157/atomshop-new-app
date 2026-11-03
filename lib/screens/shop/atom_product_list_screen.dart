import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_models.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../widgets/atom_select_field.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_catalogue_widgets.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';

enum _Sort { newest, lowestMonthly, highestMonthly }

extension on _Sort {
  String get label => switch (this) {
    _Sort.newest => 'Newest',
    _Sort.lowestMonthly => 'Lowest monthly',
    _Sort.highestMonthly => 'Highest monthly',
  };
}

/// Products of one category (canvas: "Shop"). Brands have their own page
/// (`AtomBrandScreen`).
///
/// Search, the brand chips, sort and the AtomPay filter all work on the
/// list already loaded; nothing is refetched while filtering.
class AtomProductListScreen extends ConsumerStatefulWidget {
  const AtomProductListScreen.category(this.item, {super.key});

  final CatalogueItem item;

  @override
  ConsumerState<AtomProductListScreen> createState() => _AtomProductListScreenState();
}

class _AtomProductListScreenState extends ConsumerState<AtomProductListScreen> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';

  /// Cards shown so far; grows by [_pageSize] near the end of the list.
  int _shown = _pageSize;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 500) _showMore();
    });
  }

  void _showMore() {
    final total = _apply(ref.read(_provider).value ?? const <ProductCard>[]).length;
    if (_shown < total) setState(() => _shown += _pageSize);
  }

  /// A filter change starts again at the first page.
  void _filtered(VoidCallback change) => setState(() {
    change();
    _shown = _pageSize;
  });

  /// Brand name on a category list, category name on a brand page.
  String? _group;
  _Sort _sort = _Sort.newest;
  bool _atompayOnly = false;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  FutureProvider<List<ProductCard>> get _provider => categoryProductsProvider(widget.item.id);

  String _groupOf(ProductCard p) => p.brand;

  List<ProductCard> _apply(List<ProductCard> all) {
    final q = _query.trim().toLowerCase();
    final out = all.where((p) {
      if (_atompayOnly && !p.atompay) return false;
      if (_group != null && _groupOf(p) != _group) return false;
      if (q.isNotEmpty && !'${p.brand} ${p.title}'.toLowerCase().contains(q)) return false;
      return true;
    }).toList();

    // Products without a monthly figure go last either way.
    int byMonthly(ProductCard a, ProductCard b, int sign) {
      final x = a.monthlyFrom, y = b.monthlyFrom;
      if (x == null) return y == null ? 0 : 1;
      if (y == null) return -1;
      return sign * x.compareTo(y);
    }

    switch (_sort) {
      case _Sort.newest:
        break; // The API already sends newest first.
      case _Sort.lowestMonthly:
        out.sort((a, b) => byMonthly(a, b, 1));
      case _Sort.highestMonthly:
        out.sort((a, b) => byMonthly(a, b, -1));
    }
    return out;
  }

  void _customOrder() => AtomNav.customOrder(context);

  Future<void> _pickSort() async {
    final picked = await showAtomSearchSelect<_Sort>(
      context,
      title: 'Sort by',
      searchHint: 'Search sort options',
      options: _Sort.values,
      label: (s) => s.label,
      isSelected: (s) => s == _sort,
    );
    if (picked != null) _filtered(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final value = ref.watch(_provider);
    final all = value.value ?? const <ProductCard>[];
    final groups = {for (final p in all) _groupOf(p)}.where((g) => g.isNotEmpty).toList()..sort();
    final products = _apply(all);
    final page = products.take(_shown).toList(growable: false);
    Widget padded(Widget child, {double top = 0}) => SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
      sliver: SliverToBoxAdapter(child: child),
    );

    return Scaffold(
      backgroundColor: AtomColors.white,
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: RefreshIndicator(
            color: AtomColors.primary,
            onRefresh: () async {
              ref.invalidate(_provider);
              await ref.read(_provider.future).catchError((_) => const <ProductCard>[]);
            },
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                padded(_CategoryHeader(title: widget.item.title), top: AtomSpace.sm),
                padded(
                  AtomSearchField(controller: _search, hint: 'Search in ${widget.item.title}', onChanged: (q) => _filtered(() => _query = q)),
                  top: AtomSpace.md,
                ),
                if (groups.length > 1)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 42 + AtomSpace.sm,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, 0),
                        itemCount: groups.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: AtomSpace.xs),
                        itemBuilder: (_, i) {
                          final g = i == 0 ? null : groups[i - 1];
                          return AtomChoiceChip(label: g ?? 'All', dark: true, selected: _group == g, onTap: () => _filtered(() => _group = g));
                        },
                      ),
                    ),
                  ),
                padded(
                  Row(
                    children: [
                      Expanded(
                        child: AtomButton(
                          label: _sort.label,
                          icon: Icons.swap_vert_rounded,
                          onPressed: _pickSort,
                          variant: AtomButtonVariant.secondary,
                          size: AtomButtonSize.small,
                          expand: true,
                        ),
                      ),
                      const SizedBox(width: AtomSpace.xs),
                      AtomChoiceChip(label: 'AtomPay only', selected: _atompayOnly, onTap: () => _filtered(() => _atompayOnly = !_atompayOnly)),
                    ],
                  ),
                  top: AtomSpace.sm,
                ),
                ...value.when(
                  skipLoadingOnRefresh: true,
                  loading: () => [
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
                  ],
                  error: (e, _) => [
                    padded(
                      AtomErrorState(error: e, onRetry: () => ref.invalidate(_provider)),
                      top: AtomSpace.md,
                    ),
                  ],
                  data: (_) => products.isEmpty
                      ? [
                          padded(
                            AtomEmptyState(
                              icon: Icons.search_off_rounded,
                              title: all.isEmpty ? 'No products here yet' : 'No products match',
                              message: 'Place a custom order and a seller on Atomshop sources it for you.',
                              actionLabel: 'Custom order',
                              actionIcon: Icons.calculate_outlined,
                              onAction: _customOrder,
                            ),
                            top: AtomSpace.md,
                          ),
                        ]
                      : [
                          padded(
                            Text(
                              '${products.length} ${products.length == 1 ? 'product' : 'products'} · prices confirmed by the seller',
                              style: AtomText.small.copyWith(color: AtomColors.body, fontSize: 13),
                            ),
                            top: AtomSpace.md,
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, 0),
                            sliver: AtomProductSliverGrid(products: page, showCash: true, onTap: (p) => AtomNav.product(context, p.id)),
                          ),
                          if (page.length < products.length)
                            padded(
                              Center(
                                child: AtomButton(
                                  label: 'Show more (${products.length - page.length} left)',
                                  icon: Icons.expand_more_rounded,
                                  variant: AtomButtonVariant.secondary,
                                  size: AtomButtonSize.small,
                                  onPressed: _showMore,
                                ),
                              ),
                              top: AtomSpace.md,
                            ),
                          padded(
                            AtomLinkCard(
                              icon: Icons.add_rounded,
                              title: "Can't find your model?",
                              message: 'Place a custom order or make an offer',
                              onTap: _customOrder,
                            ),
                            top: AtomSpace.md,
                          ),
                        ],
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

class _CategoryHeader extends ConsumerWidget {
  const _CategoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(width: AtomSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.heading.copyWith(fontSize: 20)),
              ),
              Text('On easy monthly installments', style: AtomText.small),
            ],
          ),
        ),
        AtomIconButton(icon: Icons.auto_awesome_rounded, tooltip: 'Ask Atom', onPressed: () => AtomNav.toTab(context, ref, AtomTab.askAtom)),
      ],
    );
  }
}
