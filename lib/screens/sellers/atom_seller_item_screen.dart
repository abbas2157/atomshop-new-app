import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/atom_http.dart';
import '../../data/atom_sellers.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_delivery_area.dart';
import '../../state/atom_order_providers.dart';
import '../../state/atom_sellers_providers.dart';
import '../../utils/atom_format.dart';
import '../../utils/atom_validators.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_leave_guard.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_seller_widgets.dart';

/// One item from a seller's shop (`app/sellers/{seller}/products/{id}`):
/// variants, monthly or cash, the seller's plan worked out live, and the
/// order form when the seller delivers to the buyer's area.
class AtomSellerItemScreen extends ConsumerStatefulWidget {
  const AtomSellerItemScreen({super.key, required this.sellerKey, required this.itemId});

  final String sellerKey;
  final int itemId;

  @override
  ConsumerState<AtomSellerItemScreen> createState() => _AtomSellerItemScreenState();
}

class _AtomSellerItemScreenState extends ConsumerState<AtomSellerItemScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  /// The buyer's picks; null means the default (first in-stock variant,
  /// the seller's default advance and months).
  int? _variantId;
  bool _installment = true;
  int? _advance;
  int? _months;
  bool _sending = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    ref.read(orderPrefillProvider.future).then((p) {
      if (!mounted) return;
      void fill(TextEditingController c, String v) {
        if (c.text.isEmpty && v.isNotEmpty) c.text = v;
      }

      fill(_name, p.name);
      fill(_phone, p.phone);
      fill(_email, p.email);
      fill(_address, p.address);
      // Filling in from the account is not the customer typing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dirty) setState(() => _dirty = false);
      });
    }).ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  SellerVariant? _variantOf(SellerItem item) {
    final variants = item.variants;
    if (variants.isEmpty) return null;
    return variants.where((v) => v.stockVariantId == _variantId).firstOrNull ?? variants.where((v) => v.available > 0).firstOrNull ?? variants.first;
  }

  Future<void> _submit(SellerItemPage page, SellerVariant variant, DeliveryArea area, SellerTerms? terms) async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final plan = _installment ? terms : null;

    setState(() => _sending = true);
    try {
      final receipt = await ref.read(atomSellersApiProvider).order(
            sellerName: page.seller.name,
            stockVariantId: variant.stockVariantId,
            areaId: area.areaId,
            installment: plan != null,
            months: plan == null ? null : (_months ?? plan.defaultMonths),
            advancePercent: plan == null ? null : (_advance ?? plan.defaultAdvance),
            fullName: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            address: _address.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(sellerItemProvider);
      ref.invalidate(sellerProfileProvider);
      ref.invalidate(sellersNearProvider);
      AtomNav.stockOrderPlaced(context, receipt);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(atomMessage(e))));
      // Sold out or out of area: show the seller's current stock.
      if (e is AtomApiException && e.statusCode == 422 && e.data.isEmpty) ref.invalidate(sellerItemProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final area = ref.watch(deliveryAreaProvider).value;
    final key = (widget.sellerKey, widget.itemId, area?.areaId);
    final value = ref.watch(sellerItemProvider(key));
    final page = value.value;

    if (page == null) {
      return AtomPage(
        title: 'Seller product',
        children: [
          if (value.hasError)
            AtomErrorState(error: value.error, onRetry: () => ref.invalidate(sellerItemProvider(key)))
          else ...[
            const AtomSkeleton(height: 260, radius: AtomRadius.card),
            const SizedBox(height: AtomSpace.md),
            const AtomSkeleton(height: 22),
            const SizedBox(height: AtomSpace.xs),
            const AtomSkeleton(width: 160, height: 14),
          ],
        ],
      );
    }

    final item = page.item;
    final terms = page.terms;
    final variant = _variantOf(item);
    final price = variant?.price ?? item.price;
    final available = variant?.available ?? 0;
    final installment = _installment && terms != null;
    final quote = terms?.quote(price: price, advancePercent: _advance ?? terms.defaultAdvance, months: _months ?? terms.defaultMonths);
    final canOrder = area != null && page.deliversToArea == true && variant != null && available > 0;

    Widget section(List<Widget> children) => Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: AtomLeaveGuard(
            dirty: _dirty,
            child: Form(
              key: _form,
              onChanged: () {
                if (!_dirty) setState(() => _dirty = true);
              },
              child: RefreshIndicator(
                color: AtomColors.primary,
                onRefresh: () async {
                  ref.invalidate(sellerItemProvider(key));
                  await ref.read(sellerItemProvider(key).future).then<void>((_) {}).catchError((_) {});
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AtomSpace.xl),
                  children: [
                    section([
                      const SizedBox(height: AtomSpace.sm),
                      Row(
                        children: [
                          AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                          const Spacer(),
                          if (item.url.isNotEmpty)
                            AtomIconButton(
                              icon: Icons.ios_share_rounded,
                              tooltip: 'Share',
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(text: '${item.title} from ${page.seller.name} on Atomshop\n${item.url}', subject: item.title),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AtomSpace.sm),
                      AspectRatio(
                        aspectRatio: 1.3,
                        child: Container(
                          padding: const EdgeInsets.all(AtomSpace.lg),
                          decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.hero)),
                          child: AtomNetworkImage(item.photo, fit: BoxFit.contain, semanticLabel: item.title, placeholderIcon: Icons.inventory_2_outlined),
                        ),
                      ),
                      const SizedBox(height: AtomSpace.sm),
                      _SellerStrip(seller: page.seller),
                      const SizedBox(height: AtomSpace.md),
                      Semantics(header: true, child: Text(item.title, style: AtomText.title.copyWith(fontSize: 22))),
                      if ([item.brand, item.category].any((s) => s.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text([item.brand, item.category].where((s) => s.isNotEmpty).join(' · '), style: AtomText.small),
                        ),
                      const SizedBox(height: AtomSpace.xs),
                      Align(alignment: Alignment.centerLeft, child: SellerStockBadge(available: available)),
                      const SizedBox(height: AtomSpace.sm),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: AtomSpace.xs,
                        children: [
                          if (quote != null)
                            Text.rich(TextSpan(children: [
                              TextSpan(text: AtomFormat.rupees(quote.monthly), style: AtomText.title.copyWith(color: AtomColors.primary)),
                              TextSpan(text: '/month', style: AtomText.small),
                            ])),
                          Text(quote != null ? 'or ${AtomFormat.rupees(price)} cash' : AtomFormat.rupees(price),
                              style: quote != null ? AtomText.body : AtomText.title.copyWith(color: AtomColors.primary)),
                        ],
                      ),
                      if (item.variants.length > 1) ...[
                        const SizedBox(height: AtomSpace.md),
                        Text('Options', style: AtomText.label),
                        const SizedBox(height: AtomSpace.xs),
                        Wrap(
                          spacing: AtomSpace.xs,
                          runSpacing: AtomSpace.xs,
                          children: [
                            for (final v in item.variants)
                              AtomChoiceChip(
                                label: '${v.name} · ${AtomFormat.rupees(v.price)}${v.available <= 0 ? ' · sold out' : ''}',
                                selected: v.stockVariantId == variant?.stockVariantId,
                                onTap: () => setState(() => _variantId = v.stockVariantId),
                              ),
                          ],
                        ),
                      ],
                      if (terms != null && quote != null) ...[
                        const SizedBox(height: AtomSpace.lg),
                        AtomSegmented<bool>(
                          items: const {true: 'Monthly', false: 'Pay cash'},
                          value: installment,
                          onChanged: (v) => setState(() => _installment = v),
                        ),
                        const SizedBox(height: AtomSpace.md),
                        if (installment)
                          _PlanPicker(
                            terms: terms,
                            quote: quote,
                            advance: _advance ?? terms.defaultAdvance,
                            months: _months ?? terms.defaultMonths,
                            onAdvance: (a) => setState(() => _advance = a),
                            onMonths: (m) => setState(() => _months = m),
                          )
                        else
                          AtomCard(
                            color: AtomColors.surface,
                            borderColor: null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AtomInfoRow('Pay on delivery', AtomFormat.rupees(price), strong: true, valueColor: AtomColors.primary),
                                Text('No advance and no monthly payments.', style: AtomText.small),
                              ],
                            ),
                          ),
                      ],
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: AtomSpace.lg),
                        Text('About this product', style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: AtomSpace.xxs),
                        Text(item.description, style: AtomText.body),
                      ],
                      const SizedBox(height: AtomSpace.lg),
                      _OrderSection(
                        page: page,
                        area: area,
                        soldOut: variant == null || available <= 0,
                        form: canOrder ? _fields() : null,
                      ),
                    ]),
                    if (page.more.isNotEmpty) ...[
                      const SizedBox(height: AtomSpace.lg),
                      section([AtomSectionHeader(title: 'More from ${page.seller.name}')]),
                      const SizedBox(height: AtomSpace.sm),
                      SellerItemRow(items: page.more, gutter: gutter, onTap: (i) => AtomNav.sellerItem(context, widget.sellerKey, i.id)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: !canOrder
          ? null
          : AtomBottomBar(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: installment
                          ? [
                              Text('Advance ${AtomFormat.rupees(quote!.advance)}', style: AtomText.small),
                              Text('${AtomFormat.rupees(quote.monthly)}/mo', style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
                            ]
                          : [
                              Text('Pay on delivery', style: AtomText.small),
                              Text(AtomFormat.rupees(price), style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
                            ],
                    ),
                  ),
                  const SizedBox(width: AtomSpace.sm),
                  AtomButton(
                    label: 'Place order',
                    icon: Icons.send_rounded,
                    loading: _sending,
                    onPressed: _sending ? null : () => _submit(page, variant, area, terms),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _fields() {
    final area = ref.read(deliveryAreaProvider).value;
    final place = area == null || area.areaTitle.isEmpty ? '' : ' in ${area.areaTitle}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomTextField(
          label: 'Full name',
          controller: _name,
          hint: 'As on your CNIC',
          autofillHints: const [AutofillHints.name],
          textCapitalization: TextCapitalization.words,
          validator: validatePersonName,
        ),
        const SizedBox(height: 14),
        AtomTextField(
          label: 'Phone number',
          controller: _phone,
          hint: '03001234567',
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(20)],
          validator: validatePhone,
        ),
        const SizedBox(height: 14),
        AtomTextField(
          label: 'Email',
          optional: true,
          controller: _email,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: validateOptionalEmail,
        ),
        const SizedBox(height: 14),
        AtomTextField(
          label: 'Delivery address$place',
          controller: _address,
          hint: 'House, street and block',
          maxLines: 2,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.fullStreetAddress],
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Enter your delivery address.';
            if (t.length > 500) return 'Keep the address under 500 characters.';
            return null;
          },
        ),
      ],
    );
  }
}

/// Logo, name and "Verified seller · see all products".
class _SellerStrip extends StatelessWidget {
  const _SellerStrip({required this.seller});

  final Seller seller;

  @override
  Widget build(BuildContext context) {
    return AtomCard(
      onTap: () => AtomNav.sellerProfile(context, seller),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SellerAvatar(seller: seller, size: 40),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seller.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.label),
                Text('Verified seller · see all products', maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.small.copyWith(color: AtomColors.green)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AtomColors.placeholder),
        ],
      ),
    );
  }
}

/// Advance and month chips from the seller's terms, and the plan box.
class _PlanPicker extends StatelessWidget {
  const _PlanPicker({
    required this.terms,
    required this.quote,
    required this.advance,
    required this.months,
    required this.onAdvance,
    required this.onMonths,
  });

  final SellerTerms terms;
  final SellerPlanQuote quote;
  final int advance;
  final int months;
  final ValueChanged<int> onAdvance;
  final ValueChanged<int> onMonths;

  @override
  Widget build(BuildContext context) {
    Widget chips(List<int> values, int selected, String Function(int) label, ValueChanged<int> onTap) => Wrap(
          spacing: AtomSpace.xs,
          runSpacing: AtomSpace.xs,
          children: [for (final v in values) AtomChoiceChip(label: label(v), selected: v == selected, onTap: () => onTap(v))],
        );
    final onDark = AtomText.body.copyWith(fontSize: 13, color: AtomColors.onDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Advance', style: AtomText.label),
        const SizedBox(height: AtomSpace.xs),
        chips(terms.advance, advance, (v) => '$v%', onAdvance),
        const SizedBox(height: AtomSpace.md),
        Text('Months', style: AtomText.label),
        const SizedBox(height: AtomSpace.xs),
        chips(terms.months, months, (v) => '$v', onMonths),
        const SizedBox(height: AtomSpace.md),
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AtomColors.ink, borderRadius: BorderRadius.circular(AtomRadius.card)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('You pay each month', style: onDark),
                Text.rich(TextSpan(children: [
                  TextSpan(text: AtomFormat.rupees(quote.monthly), style: AtomText.title.copyWith(fontSize: 28, color: AtomColors.white)),
                  TextSpan(text: '  × ${quote.months}', style: AtomText.label.copyWith(color: AtomColors.onDark)),
                ])),
                const Divider(height: AtomSpace.lg, color: Color(0x24FFFFFF)),
                _DarkRow('Advance on delivery ($advance%)', AtomFormat.rupees(quote.advance)),
                _DarkRow('Markup (${terms.rateLabel})', AtomFormat.rupees(quote.markup)),
                _DarkRow('Total', AtomFormat.rupees(quote.total), highlight: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkRow extends StatelessWidget {
  const _DarkRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AtomText.body.copyWith(fontSize: 13, color: AtomColors.onDark))),
          Text(value, style: AtomText.label.copyWith(color: highlight ? AtomColors.amber : AtomColors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Where the order form goes: the form when the seller delivers to the
/// buyer's area; otherwise why not, and what to do instead.
class _OrderSection extends StatelessWidget {
  const _OrderSection({required this.page, required this.area, required this.soldOut, required this.form});

  final SellerItemPage page;
  final DeliveryArea? area;
  final bool soldOut;

  /// The fields, when the buyer can order.
  final Widget? form;

  @override
  Widget build(BuildContext context) {
    final seller = page.seller.name;
    final a = area;
    final place = a == null || a.areaTitle.isEmpty ? 'your area' : a.areaTitle;

    if (soldOut) {
      return AtomNotice(
        tone: AtomNoticeTone.rose,
        icon: Icons.inventory_2_outlined,
        text: "This option is sold out at $seller right now. Pick another option or see the seller's other products.",
      );
    }
    if (a == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Where should it be delivered?', style: AtomText.heading),
          const SizedBox(height: AtomSpace.xxs),
          Text('Sellers deliver only to their own areas. Choose yours to order from $seller.', style: AtomText.body),
          const SizedBox(height: AtomSpace.sm),
          AtomButton(label: 'Choose your area', icon: Icons.location_on_outlined, expand: true, onPressed: () => AtomNav.location(context)),
        ],
      );
    }
    if (page.deliversToArea != true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomNotice(
            tone: AtomNoticeTone.rose,
            icon: Icons.local_shipping_outlined,
            title: "$seller doesn't deliver to $place yet",
            text: 'Other verified sellers may have this in stock near you.',
          ),
          const SizedBox(height: AtomSpace.sm),
          AtomButton(
            label: 'Sellers in $place',
            icon: Icons.storefront_outlined,
            expand: true,
            onPressed: () => AtomNav.sellers(context, cityId: a.cityId, areaId: a.areaId),
          ),
          const SizedBox(height: AtomSpace.xs),
          AtomButton(
            label: 'Change area',
            icon: Icons.location_on_outlined,
            variant: AtomButtonVariant.secondary,
            expand: true,
            onPressed: () => AtomNav.location(context),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your details', style: AtomText.heading),
        const SizedBox(height: AtomSpace.sm),
        Container(
          padding: const EdgeInsets.only(left: AtomSpace.sm),
          decoration: BoxDecoration(color: AtomColors.greenSoft, borderRadius: BorderRadius.circular(AtomRadius.input)),
          child: Row(
            children: [
              const Icon(Icons.check_rounded, size: 20, color: AtomColors.green),
              const SizedBox(width: AtomSpace.xs),
              Expanded(child: Text('Delivers to ${a.label}', style: AtomText.label.copyWith(color: AtomColors.green))),
              TextButton(
                onPressed: () => AtomNav.location(context),
                style: TextButton.styleFrom(foregroundColor: AtomColors.green, minimumSize: const Size(44, 44)),
                child: Text('Change', style: AtomText.label.copyWith(fontSize: 13, color: AtomColors.green)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AtomSpace.md),
        ?form,
        const SizedBox(height: AtomSpace.md),
        AtomNotice(
          icon: Icons.schedule_rounded,
          text: '$seller holds one unit for you for 48 hours while they confirm your order and verify your details. You pay the seller on delivery.',
        ),
      ],
    );
  }
}
