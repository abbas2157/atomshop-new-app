import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/atom_models.dart';
import '../../data/atom_product_detail.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';

/// Product page with the plan builder (canvas: "Product and plan").
///
/// Months, advance and the AtomPay figures are looked up in the server's
/// `plan` block; the page never works out a money figure itself.
class AtomProductScreen extends ConsumerWidget {
  const AtomProductScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(productDetailProvider(productId));
    return value.when(
      skipLoadingOnRefresh: true,
      data: (product) => _ProductView(product: product),
      loading: () => const _ProductSkeleton(),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: error is ProductNotFound
              ? AtomEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'This product is no longer available',
                  message: 'It may have sold out or been taken down. Similar products are in the shop.',
                  actionLabel: 'Back to shop',
                  actionIcon: Icons.grid_view_rounded,
                  onAction: () => AtomNav.toTab(context, ref, AtomTab.shop),
                )
              : AtomErrorState(error: error, onRetry: () => ref.invalidate(productDetailProvider(productId))),
        ),
      ),
    );
  }
}

class _ProductView extends ConsumerStatefulWidget {
  const _ProductView({required this.product});

  final ProductDetail product;

  @override
  ConsumerState<_ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends ConsumerState<_ProductView> {
  late StorageOption? _storage;
  late ColourOption? _colour;
  PayMode _mode = PayMode.installment;
  late int _months;
  late int _advance;

  ProductDetail get _p => widget.product;
  ProductPlan get _plan => _p.plan;
  int get _price => _p.priceFor(_storage);

  @override
  void initState() {
    super.initState();
    _storage = _p.storages.firstOrNull;
    _colour = _p.colours.firstOrNull;

    // The months checkout accepts, 6 selected first as on the website.
    final months = _plan.months;
    _months = months.contains(6) ? 6 : (months.firstOrNull ?? 6);

    final advances = _plan.advanceChoices;
    _advance = advances.contains(_plan.minAdvancePercent) ? _plan.minAdvancePercent : (advances.firstOrNull ?? _plan.minAdvancePercent);
  }

  /// Figures for the selected storage's price, looked up, never worked out.
  PlanQuote? get _quote => _plan.quote(price: _price, advancePercent: _advance, months: _months);
  AtompayQuote? get _atompay => _plan.atompayFor(_price);

  /// Shares the product with its monthly figure (from the server) and its
  /// website link when the server sends one.
  void _share() {
    final monthly = _plan.monthlyFrom;
    final lines = [
      '${_p.title} on Atomshop',
      [if (monthly != null) 'From ${AtomFormat.rupees(monthly)}/month on installments', 'Cash ${AtomFormat.rupees(_price)}'].join(', or '),
      if (_p.webUrl.isNotEmpty) _p.webUrl,
    ];
    SharePlus.instance.share(ShareParams(text: lines.join('\n'), subject: _p.title));
  }

  void _order() {
    final choice = ProductOrderChoice(
      product: _p,
      mode: _mode,
      price: _price,
      storage: _storage,
      colour: _colour,
      quote: _mode == PayMode.installment ? _quote : null,
      atompay: _mode == PayMode.atompay ? _atompay : null,
    );
    AtomNav.order(context, choice);
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    final config = ref.watch(appConfigProvider).value;
    final quote = _quote;
    final atompay = _atompay;

    final (ctaSub, ctaAmount, ctaLabel, ctaIcon) = switch (_mode) {
      PayMode.installment => ('Advance due today', quote?.advance, 'Order on installments', Icons.calendar_month_rounded),
      PayMode.atompay => ('Per month, ${atompay?.months} months', atompay?.monthly, 'Buy with AtomPay', Icons.bolt_rounded),
      PayMode.cash => ('Payable today', _price, 'Buy now', Icons.shopping_bag_outlined),
    };

    Widget section(Widget child, {double top = AtomSpace.md}) => Padding(padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0), child: child);

    return Scaffold(
      body: AtomPageWidth(
        child: AtomStatusBarBacking(child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Gallery(pictures: _p.gallery, title: _p.title, onShare: _share)),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  section(_TitleBlock(product: _p, price: _price), top: AtomSpace.md + 2),
                  if (!_p.inStock)
                    section(
                      const AtomNotice(
                        icon: Icons.inventory_2_outlined,
                        text: 'Sold out for now. A verified seller on Atomshop can source it for you with a custom order.',
                      ),
                      top: AtomSpace.sm,
                    ),
                  if (_p.storages.length > 1) ...[
                    section(Text('Choose storage', style: AtomText.label)),
                    section(
                      Wrap(spacing: AtomSpace.xs, runSpacing: AtomSpace.xs, children: [
                        for (final s in _p.storages) AtomChoiceChip(label: s.title, selected: s.id == _storage?.id, onTap: () => setState(() => _storage = s)),
                      ]),
                      top: AtomSpace.xs,
                    ),
                  ],
                  if (_p.colours.length > 1) ...[
                    section(Text('Choose colour', style: AtomText.label)),
                    section(
                      Wrap(spacing: AtomSpace.xs, runSpacing: AtomSpace.xs, children: [
                        for (final c in _p.colours) AtomChoiceChip(label: c.title, selected: c.id == _colour?.id, onTap: () => setState(() => _colour = c)),
                      ]),
                      top: AtomSpace.xs,
                    ),
                  ],
                  section(_planCard(quote, atompay, config), top: AtomSpace.lg),
                  section(_DeliveryNote(area: config?.deliveryArea), top: AtomSpace.lg),
                  section(
                    AtomButton(
                      label: 'Not sure? Ask Atom',
                      icon: Icons.auto_awesome_rounded,
                      variant: AtomButtonVariant.secondary,
                      size: AtomButtonSize.medium,
                      expand: true,
                      onPressed: () => AtomNav.toTab(context, ref, AtomTab.askAtom),
                    ),
                    top: AtomSpace.sm,
                  ),
                  if (_p.shortDescription.isNotEmpty || _p.longDescription.isNotEmpty)
                    section(_Details(short: _p.shortDescription, long: _p.longDescription), top: AtomSpace.lg),
                  const SizedBox(height: AtomSpace.lg),
                ],
              ),
            ),
          ],
        )),
      ),
      // Sold out: no order; a custom order can still source it.
      bottomNavigationBar: _p.inStock
          ? _CtaBar(
              sub: ctaSub,
              amount: ctaAmount,
              label: ctaLabel,
              icon: ctaIcon,
              onPressed: ctaAmount == null ? null : _order,
            )
          : _CtaBar(
              sub: '',
              amount: null,
              label: 'Ask for a custom order',
              icon: Icons.calculate_outlined,
              onPressed: () => AtomNav.customOrder(context),
            ),
    );
  }

  Widget _planCard(PlanQuote? quote, AtompayQuote? atompay, AppConfig? config) {
    final tabs = <PayMode, String>{
      PayMode.installment: 'Installment',
      if (_plan.atompay) PayMode.atompay: 'AtomPay',
      PayMode.cash: 'Cash',
    };

    final body = switch (_mode) {
      PayMode.installment => _InstallmentPlan(
          months: _plan.months,
          advances: _plan.advanceChoices,
          selectedMonths: _months,
          selectedAdvance: _advance,
          quote: quote,
          onMonths: (m) => setState(() => _months = m),
          onAdvance: (a) => setState(() => _advance = a),
        ),
      PayMode.atompay => _AtompayPlan(quote: atompay, feePercent: config?.atompayFeePercent),
      PayMode.cash => _CashPlan(price: _price),
    };

    return AtomCard(
      radius: AtomRadius.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'How do you want to pay',
            child: AtomSegmented<PayMode>(items: tabs, value: _mode, onChanged: (m) => setState(() => _mode = m)),
          ),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.product, required this.price});

  final ProductDetail product;
  final int price;

  @override
  Widget build(BuildContext context) {
    final brand = product.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.plan.atompay) ...[
          const AtomBadge('AtomPay eligible', tone: AtomTone.green),
          const SizedBox(height: AtomSpace.xs),
        ],
        if (brand != null && brand.title.isNotEmpty)
          Semantics(
            link: true,
            child: InkWell(
              onTap: () => AtomNav.brand(context, brand),
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 32),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(brand.title, style: AtomText.label.copyWith(fontSize: 13, color: AtomColors.primary)),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AtomColors.primary),
                  ],
                ),
              ),
            ),
          ),
        Semantics(header: true, child: Text(product.title, style: AtomText.title.copyWith(fontSize: 22))),
        const SizedBox(height: AtomSpace.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Cash price', style: AtomText.small.copyWith(fontSize: 13)),
            const SizedBox(width: AtomSpace.xs),
            Flexible(child: Text(AtomFormat.rupees(price), style: AtomText.heading.copyWith(fontSize: 20))),
          ],
        ),
      ],
    );
  }
}

class _InstallmentPlan extends StatelessWidget {
  const _InstallmentPlan({
    required this.months,
    required this.advances,
    required this.selectedMonths,
    required this.selectedAdvance,
    required this.quote,
    required this.onMonths,
    required this.onAdvance,
  });

  final List<int> months;
  final List<int> advances;
  final int selectedMonths;
  final int selectedAdvance;
  final PlanQuote? quote;
  final ValueChanged<int> onMonths;
  final ValueChanged<int> onAdvance;

  @override
  Widget build(BuildContext context) {
    // Up to four choices share the row equally (as designed); a longer list
    // (the admin can offer 3 to 12 months) wraps instead.
    Widget chips(List<int> values, int selected, String Function(int) label, ValueChanged<int> onTap) {
      final children = [for (final v in values) AtomChoiceChip(label: label(v), selected: v == selected, onTap: () => onTap(v))];
      if (values.length > 4) return Wrap(spacing: 6, runSpacing: 6, children: children);
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.7 / MediaQuery.textScalerOf(context).scale(1),
        children: children,
      );
    }

    final q = quote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Months', style: AtomText.small.copyWith(fontSize: 13, color: AtomColors.body, fontWeight: FontWeight.w700)),
        const SizedBox(height: AtomSpace.xs),
        chips(months, selectedMonths, (m) => '$m mo', onMonths),
        const SizedBox(height: 14),
        Text('Advance', style: AtomText.small.copyWith(fontSize: 13, color: AtomColors.body, fontWeight: FontWeight.w700)),
        const SizedBox(height: AtomSpace.xs),
        chips(advances, selectedAdvance, (a) => '$a%', onAdvance),
        const SizedBox(height: 14),
        if (q == null)
          Text('Plan figures for this option are not available. Contact us and a seller confirms the plan.', style: AtomText.body.copyWith(fontSize: 13))
        else
          _SummaryBox(
            headline: 'Per month for ${q.months} months',
            amount: q.monthly,
            lines: [
              ('Advance (due today)', AtomFormat.rupees(q.advance)),
              ('Financed amount', AtomFormat.rupees(q.financed)),
              ('Total payable', AtomFormat.rupees(q.total)),
            ],
          ),
        const SizedBox(height: AtomSpace.sm),
        Text('Estimate only. A verified seller confirms the final plan.', style: AtomText.small),
      ],
    );
  }
}

class _AtompayPlan extends StatelessWidget {
  const _AtompayPlan({required this.quote, required this.feePercent});

  final AtompayQuote? quote;
  final num? feePercent;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (q != null) AtomBadge('${q.months} months', tone: AtomTone.green),
          const AtomBadge('No advance', tone: AtomTone.green),
          const AtomBadge('0% markup', tone: AtomTone.green),
        ]),
        const SizedBox(height: AtomSpace.sm),
        if (q == null)
          Text('AtomPay figures for this option are not available. Choose another storage or pay on installments.', style: AtomText.body.copyWith(fontSize: 13))
        else
          _SummaryBox(
            headline: 'Per month for ${q.months} months',
            amount: q.monthly,
            lines: [
              if (q.lastMonthly != q.monthly) ('Last month', AtomFormat.rupees(q.lastMonthly)),
              ('Total payable', AtomFormat.rupees(q.total)),
              (feePercent == null ? 'Processing fee' : 'Processing fee ($feePercent%)', AtomFormat.rupees(q.processingFee)),
              ('Delivery charges', 'Confirmed at delivery'),
            ],
          ),
        const SizedBox(height: AtomSpace.sm),
        Text('Requires an approved AtomPay limit. AtomPay reviews and approves this plan.', style: AtomText.small),
      ],
    );
  }
}

class _CashPlan extends StatelessWidget {
  const _CashPlan({required this.price});

  final int price;

  static const _points = ['One payment, no markup added', 'Delivery with order tracking', 'Official brand warranty where the brand provides one'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pay in full. Fastest route to delivery.', style: AtomText.body),
        const SizedBox(height: AtomSpace.xs),
        for (final point in _points)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: AtomColors.greenSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 14, color: AtomColors.green),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(point, style: AtomText.body.copyWith(color: AtomColors.ink))),
              ],
            ),
          ),
        const SizedBox(height: AtomSpace.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 14),
          decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Expanded(child: Text('Payable today', style: AtomText.small.copyWith(fontSize: 13, color: AtomColors.body, fontWeight: FontWeight.w700))),
              Text(AtomFormat.rupees(price), style: AtomText.heading.copyWith(fontSize: 22)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dark figures box shared by the installment and AtomPay tabs.
class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.headline, required this.amount, required this.lines});

  final String headline;
  final int amount;
  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) {
    final muted = AtomText.body.copyWith(fontSize: 13, color: AtomColors.onDark);
    return Container(
      padding: const EdgeInsets.all(AtomSpace.md),
      decoration: BoxDecoration(color: AtomColors.ink, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(headline, style: muted)),
              Text(AtomFormat.rupees(amount), style: AtomText.title.copyWith(color: AtomColors.white)),
            ],
          ),
          Divider(height: 20, color: AtomColors.white.withValues(alpha: 0.14)),
          for (final (label, value) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: muted)),
                  Text(value, style: AtomText.label.copyWith(fontSize: 13, color: AtomColors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryNote extends StatelessWidget {
  const _DeliveryNote({required this.area});

  final String? area;

  @override
  Widget build(BuildContext context) {
    final a = area;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AtomColors.white, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_shipping_outlined, size: 20, color: AtomColors.primary),
          ),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A verified seller nearby delivers', style: AtomText.label),
                if (a != null && a.isNotEmpty) Text('Delivery in $a only', style: AtomText.body.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Short description, and the long one behind "Read more".
class _Details extends StatefulWidget {
  const _Details({required this.short, required this.long});

  final String short;
  final String long;

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    // The long description usually repeats the short one: show the short
    // text only when there is no long one.
    final hasLong = widget.long.isNotEmpty;
    final short = hasLong ? '' : widget.short;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this product', style: AtomText.heading),
        const SizedBox(height: AtomSpace.xs),
        if (short.isNotEmpty) Text(short, style: AtomText.body),
        if (hasLong) ...[

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Text(widget.long, maxLines: _open ? null : 4, overflow: _open ? null : TextOverflow.fade, style: AtomText.body),
          ),
          AtomButton(
            label: _open ? 'Show less' : 'Read more',
            icon: _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            variant: AtomButtonVariant.text,
            size: AtomButtonSize.small,
            onPressed: () => setState(() => _open = !_open),
          ),
        ],
      ],
    );
  }
}

class _CtaBar extends StatelessWidget {
  const _CtaBar({required this.sub, required this.amount, required this.label, required this.icon, required this.onPressed});

  final String sub;
  final int? amount;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AtomColors.white, border: Border(top: BorderSide(color: AtomColors.line))),
      child: SafeArea(
        top: false,
        child: AtomPageWidth(
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.atomGutter, AtomSpace.sm, context.atomGutter, AtomSpace.sm),
            child: Row(
              children: [
                if (amount != null) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub, style: AtomText.small),
                      Text(AtomFormat.rupees(amount), style: AtomText.heading),
                    ],
                  ),
                  const SizedBox(width: AtomSpace.sm),
                ],
                Expanded(child: AtomButton(label: label, icon: icon, onPressed: onPressed, expand: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Swipeable pictures with dots, back button on top.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.pictures, required this.title, required this.onShare});

  final List<String> pictures;
  final String title;
  final VoidCallback onShare;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pictures = widget.pictures;
    final height = context.atomPick<double>(compact: 300, medium: 380, expanded: 420) + MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: height,
      child: ColoredBox(
        color: AtomColors.surface,
        child: Stack(
          children: [
            Positioned.fill(
              top: MediaQuery.paddingOf(context).top + 56,
              bottom: 28,
              child: pictures.isEmpty
                  ? const Icon(Icons.smartphone_outlined, size: 96, color: AtomColors.placeholder)
                  : PageView.builder(
                      controller: _controller,
                      itemCount: pictures.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AtomSpace.lg),
                        child: AtomNetworkImage(
                          pictures[i],
                          fit: BoxFit.contain,
                          semanticLabel: '${widget.title}, picture ${i + 1} of ${pictures.length}',
                          placeholderIcon: Icons.smartphone_outlined,
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + AtomSpace.sm,
              left: context.atomGutter,
              child: AtomIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + AtomSpace.sm,
              right: context.atomGutter,
              child: AtomIconButton(icon: Icons.share_outlined, tooltip: 'Share product', onPressed: widget.onShare),
            ),
            if (pictures.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pictures.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index ? AtomColors.primary : AtomColors.line2,
                            borderRadius: BorderRadius.circular(AtomRadius.pill),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();

  @override
  Widget build(BuildContext context) {
    final gutter = context.atomGutter;
    return Scaffold(
      appBar: AppBar(),
      body: AtomPageWidth(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          children: const [
            AtomSkeleton(height: 260, radius: AtomRadius.hero),
            SizedBox(height: AtomSpace.md),
            AtomSkeleton(width: 80, height: 12),
            SizedBox(height: AtomSpace.xs),
            AtomSkeleton(height: 24),
            SizedBox(height: AtomSpace.xs),
            AtomSkeleton(width: 160, height: 20),
            SizedBox(height: AtomSpace.lg),
            AtomSkeleton(height: 280, radius: AtomRadius.hero),
          ],
        ),
      ),
    );
  }
}
