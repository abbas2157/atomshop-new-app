import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/atom_sellers.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_delivery_area.dart';
import '../../state/atom_sellers_providers.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_select_field.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import '../info/atom_info_widgets.dart';
import 'atom_seller_widgets.dart';

/// A verified seller's profile (`app/sellers/{slug or id}`): who they are,
/// whether they deliver to the buyer's area, their own installment plan,
/// and, for a seller with a shop, their products with search and filters.
///
/// No phone or WhatsApp for a seller with a shop: orders go through
/// Atomshop.
class AtomSellerProfileScreen extends ConsumerStatefulWidget {
  const AtomSellerProfileScreen({super.key, required this.sellerKey, this.seller});

  final String sellerKey;

  /// The card the buyer tapped, shown until the profile loads.
  final Seller? seller;

  @override
  ConsumerState<AtomSellerProfileScreen> createState() => _AtomSellerProfileScreenState();
}

class _AtomSellerProfileScreenState extends ConsumerState<AtomSellerProfileScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _q = '';
  SellerFilterOption? _category;
  SellerFilterOption? _brand;
  ShopSort _sort = ShopSort.latest;

  /// The last profile that loaded, so the header stays while filters reload.
  SellerProfile? _last;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted && text.trim() != _q) setState(() => _q = text.trim());
    });
  }

  Future<void> _pick(String title, List<SellerFilterOption> options, SellerFilterOption? current, ValueChanged<SellerFilterOption?> onPicked) async {
    const all = SellerFilterOption(0, '');
    final picked = await showAtomSearchSelect<SellerFilterOption>(
      context,
      title: title,
      searchHint: 'Search',
      options: [all, ...options],
      label: (o) => o.id == 0 ? 'All' : o.title,
      isSelected: (o) => o.id == (current?.id ?? 0),
    );
    if (picked != null) setState(() => onPicked(picked.id == 0 ? null : picked));
  }

  Future<void> _pickSort() async {
    final picked = await showAtomSearchSelect<ShopSort>(
      context,
      title: 'Sort by',
      searchHint: 'Search sort options',
      options: ShopSort.values,
      label: (s) => s.label,
      isSelected: (s) => s == _sort,
    );
    if (picked != null) setState(() => _sort = picked);
  }

  void _showAreas(SellerProfile p, int? myArea) => showAtomSearchSelect<SellerPlace>(
        context,
        title: 'Delivers to ${p.areaCount} ${p.areaCount == 1 ? 'area' : 'areas'}',
        searchHint: 'Search areas',
        options: p.areas,
        label: (a) => a.title,
        isSelected: (a) => a.id == myArea,
      );

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final area = ref.watch(deliveryAreaProvider).value;
    final query = SellerProfileQuery(key: widget.sellerKey, areaId: area?.areaId, q: _q, categoryId: _category?.id, brandId: _brand?.id, sort: _sort);
    final value = ref.watch(sellerProfileProvider(query));
    final profile = value.value ?? _last;
    if (value.value != null) _last = value.value;
    final seller = profile?.seller ?? widget.seller;

    Widget padded(Widget child, {double top = 0}) => SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
          sliver: SliverToBoxAdapter(child: child),
        );

    // Nothing to show yet and it failed (unknown seller, offline).
    if (profile == null && value.hasError) {
      return AtomPage(
        title: widget.seller?.name ?? 'Seller',
        children: [AtomErrorState(error: value.error, onRetry: () => ref.invalidate(sellerProfileProvider(query)))],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: RefreshIndicator(
            color: AtomColors.primary,
            onRefresh: () async {
              ref.invalidate(sellerProfileProvider(query));
              await ref.read(sellerProfileProvider(query).future).then<void>((_) {}).catchError((_) {});
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                padded(
                  Row(
                    children: [
                      AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                      const Spacer(),
                      if (seller != null && seller.shareUrl.isNotEmpty)
                        AtomIconButton(
                          icon: Icons.ios_share_rounded,
                          tooltip: 'Share',
                          onPressed: () => SharePlus.instance.share(ShareParams(text: '${seller.name} on Atomshop\n${seller.shareUrl}', subject: seller.name)),
                        ),
                    ],
                  ),
                  top: AtomSpace.sm,
                ),
                if (seller != null) padded(_Header(seller: seller), top: AtomSpace.sm),
                if (profile == null)
                  padded(const AtomSkeleton(height: 220, radius: AtomRadius.card), top: AtomSpace.md)
                else ...[
                  if (profile.seller.hasShop) padded(_DeliveryLine(profile: profile, area: area), top: AtomSpace.md),
                  padded(_Stats(profile: profile), top: AtomSpace.sm),
                  if (profile.seller.about.isNotEmpty) ...[
                    padded(Text('About', style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)), top: AtomSpace.lg),
                    padded(Text(profile.seller.about, style: AtomText.body), top: AtomSpace.xxs),
                  ],
                  if (profile.terms != null) padded(_TermsCard(terms: profile.terms!), top: AtomSpace.md),
                  if (profile.areas.isNotEmpty)
                    padded(
                      AtomLinkCard(
                        icon: Icons.location_on_outlined,
                        title: 'Delivers to ${profile.areaCount} ${profile.areaCount == 1 ? 'area' : 'areas'}',
                        message: profile.areas.take(3).map((a) => a.title).join(', ') + (profile.areaCount > 3 ? ', …' : ''),
                        onTap: () => _showAreas(profile, area?.areaId),
                      ),
                      top: AtomSpace.sm,
                    ),
                  if (profile.seller.hasShop)
                    ..._products(gutter, padded, profile, value)
                  else
                    padded(_NoShop(seller: profile.seller), top: AtomSpace.lg),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: AtomSpace.xl)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _products(double gutter, Widget Function(Widget, {double top}) padded, SellerProfile profile, AsyncValue<SellerProfile> value) {
    final filtered = _q.isNotEmpty || _category != null || _brand != null;
    final fresh = value.value;
    // Natural widths, wrapping when they don't fit: "Category" never truncates.
    Widget filterButton(String label, IconData icon, VoidCallback onTap) =>
        AtomButton(label: label, icon: icon, onPressed: onTap, variant: AtomButtonVariant.secondary, size: AtomButtonSize.medium);

    return [
      padded(const AtomSectionHeader(title: 'Products'), top: AtomSpace.lg),
      padded(AtomSearchField(controller: _search, hint: "Search ${profile.seller.name}'s products", onChanged: _onSearch), top: AtomSpace.sm),
      padded(
        Wrap(
          spacing: AtomSpace.xs,
          runSpacing: AtomSpace.xs,
          children: [
            if (profile.categories.length > 1)
              filterButton(_category?.title ?? 'Category', Icons.category_outlined, () => _pick('Category', profile.categories, _category, (o) => _category = o)),
            if (profile.brands.length > 1) filterButton(_brand?.title ?? 'Brand', Icons.sell_outlined, () => _pick('Brand', profile.brands, _brand, (o) => _brand = o)),
            filterButton(_sort.label, Icons.swap_vert_rounded, _pickSort),
          ],
        ),
        top: AtomSpace.sm,
      ),
      if (value.hasError && fresh == null)
        padded(AtomErrorState(error: value.error, onRetry: () => ref.invalidate(sellerProfileProvider)), top: AtomSpace.md)
      else if (fresh == null)
        padded(
          const Row(
            children: [
              Expanded(child: AtomSkeleton(height: 240, radius: AtomRadius.card)),
              SizedBox(width: AtomSpace.sm),
              Expanded(child: AtomSkeleton(height: 240, radius: AtomRadius.card)),
            ],
          ),
          top: AtomSpace.md,
        )
      else if (fresh.products.isEmpty)
        padded(
          AtomEmptyState(
            icon: Icons.search_off_rounded,
            title: filtered ? 'No products match' : 'No products right now',
            message: filtered ? 'Try another search or clear the filters.' : '${fresh.seller.name} has nothing in stock at the moment.',
          ),
          top: AtomSpace.md,
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, 0),
          sliver: SellerItemSliverGrid(items: fresh.products, onTap: (i) => AtomNav.sellerItem(context, fresh.seller.key, i.id)),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.seller});

  final Seller seller;

  @override
  Widget build(BuildContext context) {
    final s = seller;
    final line = [s.businessType, s.location].where((t) => t.isNotEmpty).join(' · ');
    return Row(
      children: [
        SellerAvatar(seller: s, size: 76),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(s.name, style: AtomText.title.copyWith(fontSize: 22))),
              if (line.isNotEmpty) Text(line, style: AtomText.small),
              const SizedBox(height: AtomSpace.xs),
              SellerBadges(seller: s),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Delivers to {area}", "Doesn't deliver to {area} yet", or a prompt to
/// choose an area. Change opens the delivery area screen.
class _DeliveryLine extends StatelessWidget {
  const _DeliveryLine({required this.profile, required this.area});

  final SellerProfile profile;
  final DeliveryArea? area;

  @override
  Widget build(BuildContext context) {
    final a = area;
    if (a == null) {
      return AtomLinkCard(
        icon: Icons.location_on_outlined,
        title: 'Choose your delivery area',
        message: 'See if ${profile.seller.name} delivers to you',
        onTap: () => AtomNav.location(context),
      );
    }
    final place = a.areaTitle.isNotEmpty ? a.areaTitle : 'your area';
    final yes = profile.deliversToArea == true;
    final (bg, fg) = yes ? (AtomColors.greenSoft, AtomColors.green) : (AtomColors.roseSoft, AtomColors.rose);
    return Container(
      padding: const EdgeInsets.only(left: AtomSpace.sm),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AtomRadius.input)),
      child: Row(
        children: [
          Icon(yes ? Icons.check_rounded : Icons.local_shipping_outlined, size: 20, color: fg),
          const SizedBox(width: AtomSpace.xs),
          Expanded(
            child: Text(yes ? 'Delivers to $place' : "Doesn't deliver to $place yet", style: AtomText.label.copyWith(color: fg)),
          ),
          TextButton(
            onPressed: () => AtomNav.location(context),
            style: TextButton.styleFrom(foregroundColor: fg, minimumSize: const Size(44, 44)),
            child: Text('Change', style: AtomText.label.copyWith(fontSize: 13, color: fg)),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.profile});

  final SellerProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    Widget tile(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AtomSpace.sm, horizontal: 6),
            decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.small),
              ],
            ),
          ),
        );
    final since = p.seller.memberSinceLabel;
    return Row(
      children: [
        if (p.seller.hasShop) ...[tile('${p.productCount}', p.productCount == 1 ? 'Product' : 'Products'), const SizedBox(width: AtomSpace.xs)],
        tile('${p.dealsDone}', 'Deals done'),
        if (since.isNotEmpty) ...[const SizedBox(width: AtomSpace.xs), tile(since, 'Member since')],
        if (p.areaCount > 0) ...[const SizedBox(width: AtomSpace.xs), tile('${p.areaCount}', p.areaCount == 1 ? 'Area' : 'Areas')],
      ],
    );
  }
}

/// The seller's own plan: markup, months, advance.
class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.terms});

  final SellerTerms terms;

  @override
  Widget build(BuildContext context) {
    final t = terms;
    final months = t.months.length == 1 ? '${t.months.first}' : '${t.months.sublist(0, t.months.length - 1).join(', ')} or ${t.months.last}';
    final advance = t.advance.length == 1 ? '${t.advance.first}%' : '${t.advance.first}–${t.advance.last}%';
    return AtomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AtomColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.calendar_month_outlined, size: 18, color: AtomColors.primary),
              ),
              const SizedBox(width: AtomSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("This seller's installment plan", style: AtomText.label.copyWith(fontWeight: FontWeight.w800)),
                    Text('Set by the seller, paid to the seller', style: AtomText.small),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AtomSpace.lg),
          AtomInfoRow('Markup', t.rateLabel),
          AtomInfoRow('Months', months),
          AtomInfoRow('Advance', advance),
        ],
      ),
    );
  }
}

/// A seller without a shop: nothing to order here; chat if they allow it.
class _NoShop extends StatelessWidget {
  const _NoShop({required this.seller});

  final Seller seller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomNotice(text: "${seller.name} doesn't list products on Atomshop yet. Order any product from the Shop and a verified seller in your area delivers it."),
        if (seller.whatsappUrl.isNotEmpty) ...[
          const SizedBox(height: AtomSpace.sm),
          AtomButton(label: 'Chat with seller', icon: Icons.chat_outlined, expand: true, onPressed: () => atomOpenUrl(context, seller.whatsappUrl)),
        ],
      ],
    );
  }
}
