import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/atom_account.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_session.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_surfaces.dart';
import '../account/atom_outbox_screen.dart';

/// After a custom order is saved: what the server stored and what happens
/// next. Back goes home, never to the filled form.
class AtomCustomPlacedScreen extends ConsumerWidget {
  const AtomCustomPlacedScreen({super.key, required this.placed, required this.phone, this.queued = false});

  final CustomOrderPlaced placed;
  final String phone;

  /// Saved on the phone (offline): [placed] is the plan worked out in the
  /// app, and the order is sent once the connection is back.
  final bool queued;

  static const _steps = [
    'A seller on Atomshop calls you within 24 hours to confirm the product and plan.',
    'Keep your CNIC ready: an agent verifies your address, usually within 24 to 48 hours.',
    'Delivery in 4 to 6 working days once verification passes. Then pay monthly and see every installment in your account.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = placed;
    final signedIn = ref.watch(atomSignedInProvider);
    void home() => AtomNav.toTab(context, ref, AtomTab.home);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: Scaffold(
        body: SafeArea(
          child: AtomPageWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(context.atomGutter, AtomSpace.xl + AtomSpace.md, context.atomGutter, AtomSpace.lg),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(color: queued ? AtomColors.amberSoft : AtomColors.greenSoft, shape: BoxShape.circle),
                    child: Icon(queued ? Icons.schedule_send_rounded : Icons.check_rounded, size: 44, color: queued ? AtomColors.amberInk : AtomColors.green),
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  header: true,
                  child: Text(queued ? 'Custom order saved' : 'Custom order placed', textAlign: TextAlign.center, style: AtomText.title.copyWith(fontSize: 26)),
                ),
                const SizedBox(height: AtomSpace.xs),
                Text(
                  queued
                      ? "You're offline, so your order is saved on this phone. It is sent to verified sellers as soon as you're back online."
                      : 'Your order has been sent to verified sellers${p.area.isEmpty ? '' : ' in ${p.area}'}. A seller will call you to confirm the price and plan.',
                  textAlign: TextAlign.center,
                  style: AtomText.body.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 22),
                AtomCard(
                  radius: 22,
                  child: Column(
                    children: [
                      if (p.orderId.isNotEmpty) AtomInfoRow('Order ID', '#${p.orderId}', strong: true),
                      AtomInfoRow('Product', p.product),
                      AtomInfoRow('Plan', '${p.months} months · ${AtomFormat.rupees(p.monthly)}/mo'),
                      AtomInfoRow('Advance', AtomFormat.rupees(p.advance)),
                      AtomInfoRow('Total deal amount', AtomFormat.rupees(p.total)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('What happens next', style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AtomSpace.sm),
                for (var i = 0; i < _steps.length; i++)
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
                        Expanded(child: Text(_steps[i], style: AtomText.body)),
                      ],
                    ),
                  ),
                const SizedBox(height: AtomSpace.md),
                if (queued)
                  AtomButton(
                    label: 'See what is waiting to send',
                    icon: Icons.schedule_send_rounded,
                    expand: true,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AtomOutboxScreen())),
                  )
                else if (signedIn)
                  AtomButton(
                    label: 'Track my custom orders',
                    icon: Icons.inventory_2_outlined,
                    expand: true,
                    onPressed: () {
                      AtomNav.toTab(context, ref, AtomTab.account);
                      AtomNav.customOrders(context);
                    },
                  )
                else
                  AtomButton(
                    label: 'Set a password to track it',
                    icon: Icons.lock_outline_rounded,
                    expand: true,
                    // The order is saved to this phone's account: a code sets its password.
                    onPressed: () => AtomNav.forgotPassword(context, login: phone),
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
