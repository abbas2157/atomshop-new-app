import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../state/atom_catalogue_providers.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_custom_details_screen.dart';
import 'atom_custom_plan_screen.dart';
import 'atom_custom_shared.dart';

/// Custom order, step 1 (canvas: "Custom order · 1 Calculator"): any
/// product from any shop. The monthly figure is worked out a moment after
/// the customer stops typing, with the server's own formula, so it works
/// offline too ([AtomAccountApi.customQuote]).
class AtomCustomOrderScreen extends ConsumerStatefulWidget {
  const AtomCustomOrderScreen({super.key});

  @override
  ConsumerState<AtomCustomOrderScreen> createState() => _AtomCustomOrderScreenState();
}

class _AtomCustomOrderScreenState extends ConsumerState<AtomCustomOrderScreen> {
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _advance = TextEditingController();
  final _reference = TextEditingController();
  int? _months;
  Timer? _debounce;

  CustomQuote? _quote;

  /// The inputs [_quote] was asked for; a quote only counts while they match.
  String _quoteKey = '';
  String? _error;
  String? _priceError;
  String? _advanceError;
  bool _loading = false;
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    _price.dispose();
    _advance.dispose();
    _reference.dispose();
    super.dispose();
  }

  int _digits(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  String get _key => '${_digits(_price)}|${_digits(_advance)}|$_months|${_reference.text.trim()}';

  void _changed() {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 500), _fetch);
  }

  Future<void> _fetch() async {
    final price = _digits(_price);
    final advance = _digits(_advance);
    final months = _months;
    if (price <= 0 || _advance.text.trim().isEmpty || months == null) {
      setState(() {
        _quote = null;
        _error = null;
        _priceError = null;
        _advanceError = null;
        _loading = false;
      });
      return;
    }
    final key = _key;
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final quote = await ref.read(atomAccountApiProvider).customQuote(
            price: price,
            advance: advance,
            months: months,
            referenceCode: _reference.text.trim(),
            minAdvancePercent: ref.read(appConfigProvider).value?.minAdvancePercent ?? 20,
          );
      if (!mounted || seq != _seq) return;
      setState(() {
        _quote = quote;
        _quoteKey = key;
        _error = null;
        _priceError = null;
        _advanceError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _quote = null;
        _loading = false;
        if (e is AtomApiException && e.statusCode == 422) {
          _priceError = e.fieldError('price');
          _advanceError = e.fieldError('advance');
          _error = _priceError == null && _advanceError == null ? e.message : null;
        } else {
          _error = atomMessage(e);
        }
      });
    }
  }

  bool get _ready => _quote != null && _quoteKey == _key && _title.text.trim().isNotEmpty && !_loading;

  void _next() {
    final quote = _quote;
    if (quote == null) return;
    final draft = CustomDraft(
      title: _title.text.trim(),
      price: quote.price,
      advance: quote.advance,
      months: quote.months,
      referenceCode: _reference.text.trim(),
    );
    // No server quote yet (total 0): straight to the details; the server
    // works out the plan when the order is sent.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => quote.total > 0 ? AtomCustomPlanScreen(draft: draft, quote: quote) : AtomCustomDetailsScreen(draft: draft, quote: quote),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final offered = ref.watch(appConfigProvider).value?.months ?? const [3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    if (_months == null && offered.isNotEmpty) {
      _months = offered.contains(12) ? 12 : offered.last;
    }
    final quote = _quote;
    final fresh = quote != null && _quoteKey == _key;
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)];

    return AtomPage(
      title: 'Custom order',
      subtitle: 'Order any product, from any shop',
      bottom: AtomButton(
        label: AtomAccountApi.hasCustomQuote ? 'Calculate plan' : 'Continue',
        icon: AtomAccountApi.hasCustomQuote ? Icons.calculate_outlined : Icons.arrow_forward_rounded,
        expand: true,
        onPressed: _ready ? _next : null,
      ),
      children: [
        const SizedBox(height: AtomSpace.xs),
        const CustomSteps(current: 1),
        const SizedBox(height: AtomSpace.md),
        AtomTextField(
          label: 'Product title',
          controller: _title,
          hint: 'e.g. Honda CD 70 2026',
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AtomTextField(
                label: 'Product price',
                controller: _price,
                hint: '0',
                keyboardType: TextInputType.number,
                inputFormatters: digitsOnly,
                prefix: const _RsPrefix(),
                onChanged: (_) => _changed(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AtomTextField(
                label: 'Advance',
                controller: _advance,
                hint: '0',
                keyboardType: TextInputType.number,
                inputFormatters: digitsOnly,
                prefix: const _RsPrefix(),
                onChanged: (_) => _changed(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_priceError != null) Text(_priceError!, style: AtomText.small.copyWith(color: AtomColors.rose)),
        if (_advanceError != null) Text(_advanceError!, style: AtomText.small.copyWith(color: AtomColors.rose)),
        if (_priceError == null && _advanceError == null)
          Text(
            fresh ? 'Minimum advance is 20%: ${AtomFormat.rupees(quote.minAdvance)}' : 'Minimum advance is 20% of the price.',
            style: AtomText.small,
          ),
        const SizedBox(height: 14),
        Text('Installment months', style: AtomText.label),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.25 / MediaQuery.textScalerOf(context).scale(1),
          children: [
            for (final m in offered)
              AtomChoiceChip(
                label: '$m',
                selected: m == _months,
                onTap: () {
                  _months = m;
                  _changed();
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        AtomTextField(
          label: 'Supplier reference code',
          optional: true,
          controller: _reference,
          hint: 'e.g. ATOM-SUP-1234',
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => _changed(),
        ),
        if (fresh && quote.referenceValid != null && quote.referenceMessage.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(quote.referenceMessage, style: AtomText.small.copyWith(color: quote.referenceValid! ? AtomColors.green : AtomColors.rose)),
        ],
        const SizedBox(height: AtomSpace.md),
        _EstimateBox(quote: fresh ? quote : null, months: _months, loading: _loading),
        if (_error != null) ...[
          const SizedBox(height: AtomSpace.xs),
          Text(_error!, style: AtomText.small.copyWith(color: AtomColors.rose)),
        ],
        const SizedBox(height: AtomSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: AtomButton(
            label: 'Not sure of the price? Make an offer',
            icon: Icons.chat_bubble_outline_rounded,
            variant: AtomButtonVariant.text,
            size: AtomButtonSize.small,
            onPressed: () => AtomNav.makeOffer(context),
          ),
        ),
      ],
    );
  }
}

class _RsPrefix extends StatelessWidget {
  const _RsPrefix();

  @override
  Widget build(BuildContext context) => Center(widthFactor: 1, child: Padding(padding: const EdgeInsets.only(left: 14, right: 6), child: Text('Rs.', style: AtomText.label)));
}

class _EstimateBox extends StatelessWidget {
  const _EstimateBox({required this.quote, required this.months, required this.loading});

  final CustomQuote? quote;
  final int? months;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    final muted = AtomText.small.copyWith(color: AtomColors.onDark);
    return Semantics(
      liveRegion: true,
      child: AtomCard(
        color: AtomColors.ink,
        borderColor: null,
        radius: 18,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q != null && q.total == 0 ? 'Your monthly plan' : 'Estimated monthly${months == null ? '' : ' · $months months'}', style: muted),
                  const SizedBox(height: 4),
                  if (loading && q == null)
                    const SizedBox(height: 30, width: 30, child: Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, color: AtomColors.white)))
                  else if (q != null && q.total == 0)
                    Text('Worked out when you send the order. A seller then calls to confirm it.', style: AtomText.body.copyWith(color: AtomColors.white))
                  else
                    Text(q == null ? 'Rs. —' : AtomFormat.rupees(q.monthly), style: AtomText.title.copyWith(color: AtomColors.white)),
                ],
              ),
            ),
            if (q != null && q.total == 0)
              const SizedBox.shrink()
            else if (q != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${q.sourcingFeePercent}% sourcing fee', style: muted),
                  Text('Total ${AtomFormat.rupees(q.total)}', style: muted),
                ],
              )
            else
              Text('Enter the price and advance', style: muted),
          ],
        ),
      ),
    );
  }
}
