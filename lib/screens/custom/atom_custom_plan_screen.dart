import 'package:flutter/material.dart';

import '../../data/atom_account.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_surfaces.dart';
import 'atom_custom_details_screen.dart';
import 'atom_custom_shared.dart';

/// Custom order, step 2 (canvas: "Plan review"): the server's quote laid
/// out as a summary and a month-by-month schedule.
class AtomCustomPlanScreen extends StatelessWidget {
  const AtomCustomPlanScreen({super.key, required this.draft, required this.quote});

  final CustomDraft draft;
  final CustomQuote quote;

  static String _ordinal(int n) {
    final suffix = (n % 100 >= 11 && n % 100 <= 13) ? 'th' : switch (n % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
    return '$n$suffix month';
  }

  @override
  Widget build(BuildContext context) {
    final q = quote;
    final shown = q.months.clamp(0, 6);
    final more = q.months - shown;
    final muted = AtomText.body.copyWith(fontSize: 13, color: AtomColors.onDark);

    Widget line(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: muted)),
              Text(value, style: AtomText.label.copyWith(fontSize: 13, color: AtomColors.white, fontWeight: strong ? FontWeight.w800 : FontWeight.w700)),
            ],
          ),
        );

    Widget row(String no, String month, String amount, {bool header = false}) {
      final style = header ? AtomText.small.copyWith(fontWeight: FontWeight.w800) : AtomText.body.copyWith(color: AtomColors.ink);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: header ? AtomColors.surface : null,
          border: header ? null : const Border(top: BorderSide(color: AtomColors.line)),
        ),
        child: Row(
          children: [
            SizedBox(width: 36, child: Text(no, style: style)),
            Expanded(child: Text(month, style: style)),
            Text(amount, style: header ? style : AtomText.label),
          ],
        ),
      );
    }

    return AtomPage(
      title: 'Plan review',
      trailing: AtomButton(
        label: 'Edit',
        icon: Icons.edit_outlined,
        variant: AtomButtonVariant.secondary,
        size: AtomButtonSize.small,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: AtomButton(
        label: 'Proceed to details',
        icon: Icons.arrow_forward_rounded,
        iconAfter: true,
        expand: true,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AtomCustomDetailsScreen(draft: draft, quote: quote))),
      ),
      children: [
        const SizedBox(height: AtomSpace.xs),
        const CustomSteps(current: 2),
        const SizedBox(height: AtomSpace.md),
        AtomCard(
          color: AtomColors.ink,
          borderColor: null,
          radius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Summary for ', style: muted),
                TextSpan(text: draft.title, style: AtomText.label.copyWith(fontSize: 13, color: AtomColors.white)),
              ])),
              const SizedBox(height: AtomSpace.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: Text('Monthly plan · ${q.months} months', style: muted)),
                  Text(AtomFormat.rupees(q.monthly), style: AtomText.title.copyWith(color: AtomColors.white)),
                ],
              ),
              Divider(height: 20, color: AtomColors.white.withValues(alpha: 0.14)),
              line('Product price', AtomFormat.rupees(q.price)),
              line('Advance', AtomFormat.rupees(q.advance)),
              line('Total markup amount', AtomFormat.rupees(q.markup)),
              line('Sourcing fee (${q.sourcingFeePercent}%)', AtomFormat.rupees(q.sourcingFee)),
              line('Total deal amount', AtomFormat.rupees(q.total), strong: true),
            ],
          ),
        ),
        const AtomGroupLabel('Installment schedule'),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AtomRadius.card), border: Border.all(color: AtomColors.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row('No.', 'Month', 'Amount', header: true),
              row('0', 'Advance', AtomFormat.rupees(q.advance)),
              for (var i = 1; i <= shown; i++) row('$i', _ordinal(i), AtomFormat.rupees(q.monthly)),
              if (more > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: AtomColors.line))),
                  child: Text('+ $more more ${more == 1 ? 'month' : 'months'} of ${AtomFormat.rupees(q.monthly)}', style: AtomText.small),
                ),
            ],
          ),
        ),
        const SizedBox(height: AtomSpace.sm),
        Text('Estimate only. A verified seller confirms the final plan.', style: AtomText.small),
      ],
    );
  }
}
