import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_sellers.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_surfaces.dart';

/// After ordering a seller's item: what was sent, the 48-hour hold, and
/// what happens next. Back goes home, not to the filled form.
class AtomStockOrderPlacedScreen extends ConsumerWidget {
  const AtomStockOrderPlacedScreen({super.key, required this.receipt});

  final StockOrderReceipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = receipt;
    final gutter = context.atomGutter;
    final seller = r.sellerName.isEmpty ? 'The seller' : r.sellerName;
    void home() => AtomNav.toTab(context, ref, AtomTab.home);

    final steps = [
      ('$seller confirms', 'Within ${r.heldHours} hours, by phone'),
      ('They verify your details', 'Keep your CNIC ready'),
      ('Delivered to your door', r.installment ? 'Pay the advance to the seller on delivery' : 'Pay the seller on delivery'),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: Scaffold(
        body: SafeArea(
          child: AtomPageWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, AtomSpace.xl + AtomSpace.md, gutter, AtomSpace.lg),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(color: AtomColors.greenSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 44, color: AtomColors.green),
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text('Order sent to $seller', textAlign: TextAlign.center, style: AtomText.title.copyWith(fontSize: 24)),
                ),
                const SizedBox(height: AtomSpace.xs),
                Text(
                  '$seller holds one unit for you for ${r.heldHours} hours while they confirm your order and verify your details. You pay the seller on delivery.',
                  textAlign: TextAlign.center,
                  style: AtomText.body.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 22),
                AtomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(r.product, style: AtomText.label.copyWith(fontWeight: FontWeight.w800)),
                      if (r.id > 0) Text('Order #${r.id}', style: AtomText.small),
                      const Divider(height: AtomSpace.lg),
                      if (r.installment) ...[
                        AtomInfoRow('Plan', '${r.months} months'),
                        AtomInfoRow('Advance on delivery', AtomFormat.rupees(r.advance)),
                        AtomInfoRow('Monthly', AtomFormat.rupees(r.monthly)),
                      ] else
                        const AtomInfoRow('Payment', 'Cash on delivery'),
                      AtomInfoRow('Total', AtomFormat.rupees(r.total), strong: true, valueColor: AtomColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: AtomSpace.lg),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: i == 0 ? AtomColors.primary : AtomColors.primarySoft, shape: BoxShape.circle),
                          child: Text('${i + 1}', style: AtomText.small.copyWith(fontWeight: FontWeight.w800, color: i == 0 ? AtomColors.white : AtomColors.primary)),
                        ),
                        const SizedBox(width: AtomSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Text(steps[i].$1, style: AtomText.label), Text(steps[i].$2, style: AtomText.small)],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AtomSpace.md),
                AtomButton(label: 'Keep shopping', icon: Icons.home_outlined, expand: true, onPressed: home),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
