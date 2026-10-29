import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_design_content.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_catalogue_widgets.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';

/// Product search ("Search phones, ACs, bikes…" on Home). Searches names,
/// brands and categories on the server as you type (after a short pause).
class AtomSearchScreen extends ConsumerStatefulWidget {
  const AtomSearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<AtomSearchScreen> createState() => _AtomSearchScreenState();
}

class _AtomSearchScreenState extends ConsumerState<AtomSearchScreen> {
  static const _minLength = 2;

  late final _controller = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  late String _query = widget.initialQuery.trim();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final searching = _query.length >= _minLength;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.sm),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: AtomSpace.sm),
                      Expanded(
                        child: Semantics(
                          label: 'Search products',
                          child: AtomSearchField(controller: _controller, hint: 'Search phones, ACs, bikes…', onChanged: _onChanged, autofocus: widget.initialQuery.isEmpty),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!searching) ..._suggestions(gutter) else ..._results(gutter),
            ],
          ),
        ),
      ),
    );
  }

  /// Before typing: jump straight into a category.
  List<Widget> _suggestions(double gutter) => [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, AtomSpace.xs),
          sliver: SliverToBoxAdapter(child: Text('Browse a category', style: AtomText.subheading)),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: AtomSpace.xs,
              runSpacing: AtomSpace.xs,
              children: [
                for (final c in designCategories) AtomChoiceChip(label: c.label, selected: false, onTap: () => AtomNav.category(context, c.item)),
              ],
            ),
          ),
        ),
      ];

  List<Widget> _results(double gutter) {
    final value = ref.watch(productSearchProvider(_query));
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, AtomSpace.sm, gutter, 0),
          sliver: const SliverToBoxAdapter(
            child: Row(children: [Expanded(child: AtomProductCardSkeleton()), SizedBox(width: AtomSpace.sm), Expanded(child: AtomProductCardSkeleton())]),
          ),
        ),
      ],
      error: (e, _) => [SliverToBoxAdapter(child: AtomErrorState(error: e, onRetry: () => ref.invalidate(productSearchProvider(_query))))],
      data: (products) => products.isEmpty
          ? [
              SliverToBoxAdapter(
                child: AtomEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No match for "$_query"',
                  message: 'Sellers on Atomshop can source it: place a custom order or make an offer.',
                  actionLabel: 'Custom order',
                  actionIcon: Icons.calculate_outlined,
                  onAction: () => AtomNav.customOrder(context),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: AtomButton(
                      label: 'Make an offer',
                      icon: Icons.chat_bubble_outline_rounded,
                      variant: AtomButtonVariant.text,
                      onPressed: () => AtomNav.makeOffer(context),
                    ),
                  ),
                ),
              ),
            ]
          : [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xs, gutter, AtomSpace.sm),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${products.length} ${products.length == 1 ? 'product' : 'products'} for "$_query"',
                    style: AtomText.small.copyWith(color: AtomColors.body, fontSize: 13),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: AtomProductSliverGrid(products: products, onTap: (p) => AtomNav.product(context, p.id)),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, AtomSpace.xl),
                sliver: SliverToBoxAdapter(
                  child: AtomLinkCard(
                    icon: Icons.add_rounded,
                    title: "Can't find your model?",
                    message: 'Place a custom order or make an offer',
                    onTap: () => AtomNav.customOrder(context),
                  ),
                ),
              ),
            ],
    );
  }
}
