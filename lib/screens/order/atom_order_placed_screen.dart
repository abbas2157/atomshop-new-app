import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/atom_order.dart';
import '../../data/atom_product_detail.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_session.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_surfaces.dart';

/// Step 3 (canvas: "Order placed"): what the server saved and what happens
/// next, in the website's words. Back goes home, not to the filled form.
class AtomOrderPlacedScreen extends ConsumerWidget {
  const AtomOrderPlacedScreen({super.key, required this.receipt});

  final OrderReceipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = receipt;
    final signedIn = ref.watch(atomSignedInProvider);
    final gutter = context.atomGutter;
    void home() => AtomNav.toTab(context, ref, AtomTab.home);

    final lead = switch (r.mode) {
      PayMode.atompay => 'AtomPay reviews your order. Complete your AtomPay profile with the same phone number to get it approved.',
      _ => 'Your order has been sent to verified sellers${r.area.isEmpty ? '' : ' in ${r.area}'}. A seller will call you to confirm ${r.mode == PayMode.cash ? 'your order' : 'the plan'}.',
    };
    final steps = switch (r.mode) {
      PayMode.atompay => [
          'Complete your AtomPay profile on atompay.shop with ${r.phone.isEmpty ? 'the same phone number' : r.phone}.',
          'AtomPay reviews it and confirms the order with you.',
          'Delivery once approved, then three monthly payments.',
        ],
      _ => [
          'A seller calls you within 24 hours to confirm the product${r.mode == PayMode.cash ? '' : ' and plan'}.',
          'Keep your CNIC ready: an agent verifies your address, usually within 24 to 48 hours.',
          r.mode == PayMode.cash
              ? 'Delivery in 4 to 6 working days once verification passes.'
              : 'Delivery in 4 to 6 working days once verification passes. Then pay monthly and see every installment in your account.',
        ],
    };
    final product = [r.product, if (r.storage.isNotEmpty) r.storage].join(' · ');
    final plan = switch (r.mode) {
      PayMode.installment => '${r.months} months · ${AtomFormat.rupees(r.monthly)}/mo',
      PayMode.atompay => '${r.months} months · ${AtomFormat.rupees(r.monthly)}/mo · no advance',
      PayMode.cash => 'Pay in full',
    };

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
                Semantics(header: true, child: Text('Order placed', textAlign: TextAlign.center, style: AtomText.title.copyWith(fontSize: 26))),
                const SizedBox(height: AtomSpace.xs),
                Text(lead, textAlign: TextAlign.center, style: AtomText.body.copyWith(fontSize: 15)),
                const SizedBox(height: 22),
                AtomCard(
                  radius: 22,
                  child: Column(
                    children: [
                      _Line('Order ID', '#${r.id}', strong: true),
                      _Line('Product', product),
                      if (r.colour.isNotEmpty) _Line('Colour', r.colour),
                      _Line('Plan', plan),
                      if (r.mode == PayMode.installment) _Line('Advance', AtomFormat.rupees(r.advance)),
                      _Line(r.mode == PayMode.installment ? 'Total deal amount' : 'Total', AtomFormat.rupees(r.total)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('What happens next', style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AtomSpace.sm),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AtomSpace.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AtomColors.primarySoft, shape: BoxShape.circle),
                          child: Text('${i + 1}', style: AtomText.small.copyWith(color: AtomColors.primary, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: AtomSpace.sm),
                        Expanded(child: Text(steps[i], style: AtomText.body)),
                      ],
                    ),
                  ),
                const SizedBox(height: AtomSpace.md),
                if (r.mode == PayMode.atompay && r.atompayUrl.isNotEmpty) ...[
                  AtomButton(
                    label: 'Complete AtomPay profile',
                    icon: Icons.open_in_new_rounded,
                    expand: true,
                    onPressed: () => launchUrl(Uri.parse(r.atompayUrl), mode: LaunchMode.externalApplication),
                  ),
                  const SizedBox(height: 10),
                ],
                if (signedIn)
                  AtomButton(
                    label: 'View my orders',
                    icon: Icons.inventory_2_outlined,
                    expand: true,
                    variant: r.mode == PayMode.atompay ? AtomButtonVariant.secondary : AtomButtonVariant.primary,
                    onPressed: () {
                      AtomNav.toTab(context, ref, AtomTab.account);
                      AtomNav.orders(context);
                    },
                  )
                else
                  AtomButton(
                    label: 'Set a password to track it',
                    icon: Icons.lock_outline_rounded,
                    expand: true,
                    variant: r.mode == PayMode.atompay ? AtomButtonVariant.secondary : AtomButtonVariant.primary,
                    // The order is on the account for this phone: a code sets its password.
                    onPressed: () => AtomNav.forgotPassword(context, login: r.phone),
                  ),
                const SizedBox(height: 10),
                AtomButton(label: 'Keep shopping', icon: Icons.shopping_bag_outlined, expand: true, variant: AtomButtonVariant.text, onPressed: home),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AtomText.body),
          const SizedBox(width: AtomSpace.md),
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: AtomText.label.copyWith(fontWeight: strong ? FontWeight.w800 : FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
