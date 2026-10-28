import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_models.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_catalogue_widgets.dart';
import '../../widgets/atom_network_image.dart';
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

/// Products of one category or one brand (canvas: "Shop" and "Brand page").
///
/// Search, the brand (or category) chips, sort and the AtomPay filter all
/// work on the list already loaded; nothing is refetched while filtering.
class AtomProductListScreen extends ConsumerStatefulWidget {
  const AtomProductListScreen.category(this.item, {super.key}) : isBrand = false;

  const AtomProductListScreen.brand(this.item, {super.key}) : isBrand = true;

  final CatalogueItem item;
  final bool isBrand;

  @override
  ConsumerState<AtomProductListScreen> createState() => _AtomProductListScreenState();
}

class _AtomProductListScreenState extends ConsumerState<AtomProductListScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// Brand name on a category list, category name on a brand page.
  String? _group;
  _Sort _sort = _Sort.newest;
  bool _atompayOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  FutureProvider<List<ProductCard>> get _provider =>
      widget.isBrand ? brandProductsProvider(widget.item.id) : categoryProductsProvider(widget.item.id);

  String _groupOf(ProductCard p) => widget.isBrand ? p.category : p.brand;

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
    final picked = await showModalBottomSheet<_Sort>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AtomSpace.gutter, 0, AtomSpace.gutter, AtomSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sort by', style: AtomText.heading),
              const SizedBox(height: AtomSpace.sm),
              for (final s in _Sort.values) ...[
                AtomChoiceChip(label: s.label, selected: s == _sort, onTap: () => Navigator.of(context).pop(s)),
                const SizedBox(height: AtomSpace.xs),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final value = ref.watch(_provider);
    final all = value.value ?? const <ProductCard>[];
    final groups = {for (final p in all) _groupOf(p)}.where((g) => g.isNotEmpty).toList()..sort();
    final products = _apply(all);
    Widget padded(Widget child, {double top = 0}) =>
        SliverPadding(padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0), sliver: SliverToBoxAdapter(child: child));

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
              slivers: [
                widget.isBrand
                    ? SliverToBoxAdapter(child: _BrandHeader(item: widget.item, gutter: gutter))
                    : padded(_CategoryHeader(title: widget.item.title), top: AtomSpace.sm),
                padded(
                  AtomSearchField(controller: _search, hint: 'Search in ${widget.item.title}', onChanged: (q) => setState(() => _query = q)),
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
                          return AtomChoiceChip(label: g ?? 'All', dark: true, selected: _group == g, onTap: () => setState(() => _group = g));
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
                      AtomChoiceChip(label: 'AtomPay only', selected: _atompayOnly, onTap: () => setState(() => _atompayOnly = !_atompayOnly)),
                    ],
                  ),
                  top: AtomSpace.sm,
                ),
                ...value.when(
                  skipLoadingOnRefresh: true,
                  loading: () => [
                    padded(
                      const Row(children: [Expanded(child: AtomProductCardSkeleton()), SizedBox(width: AtomSpace.sm), Expanded(child: AtomProductCardSkeleton())]),
                      top: AtomSpace.md,
                    ),
                  ],
                  error: (_, _) => [padded(AtomErrorState(onRetry: () => ref.invalidate(_provider)), top: AtomSpace.md)],
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
                            sliver: AtomProductSliverGrid(products: products, showCash: true, onTap: (p) => AtomNav.product(context, p.id)),
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
              Semantics(header: true, child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.heading.copyWith(fontSize: 20))),
              Text('On easy monthly installments', style: AtomText.small),
            ],
          ),
        ),
        AtomIconButton(icon: Icons.auto_awesome_rounded, tooltip: 'Ask Atom', onPressed: () => AtomNav.toTab(context, ref, AtomTab.askAtom)),
      ],
    );
  }
}

/// Dark brand header with the logo (canvas: "Brand page").
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.item, required this.gutter});

  final CatalogueItem item;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.lg),
      decoration: const BoxDecoration(
        color: AtomColors.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', dark: true, onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(height: AtomSpace.md),
          Row(
            children: [
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(AtomSpace.sm),
                decoration: BoxDecoration(color: AtomColors.white, borderRadius: BorderRadius.circular(22)),
                child: item.picture.isEmpty
                    ? Center(child: Text(item.title.isEmpty ? '?' : item.title[0].toUpperCase(), style: AtomText.title.copyWith(color: AtomColors.primary)))
                    : AtomNetworkImage(item.picture, fit: BoxFit.contain, semanticLabel: '${item.title} logo', placeholderIcon: Icons.storefront_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(item.title, style: AtomText.title.copyWith(color: AtomColors.white))),
                    const SizedBox(height: 4),
                    Text('On easy monthly installments', style: AtomText.body.copyWith(color: AtomColors.onDark)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
