import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import 'atom_info_widgets.dart';

/// Why Atomshop (canvas: "Why Atomshop"). Marketing copy from the design.
class AtomWhyScreen extends ConsumerWidget {
  const AtomWhyScreen({super.key});

  static const _reasons = [
    (Icons.credit_card_off_outlined, AtomColors.primarySoft, AtomColors.primary, 'No credit card needed', 'Start with a minimum 20% advance and a 3 to 12 month plan.'),
    (Icons.verified_user_outlined, AtomColors.greenSoft, AtomColors.green, 'Verified sellers near you', 'Every seller is verified in person before they can take an order.'),
    (Icons.calculate_outlined, AtomColors.violetSoft, AtomColors.violet, 'See the monthly amount first', 'Every product shows the advance, monthly amount and total before you order.'),
    (Icons.local_shipping_outlined, AtomColors.amberSoft, AtomColors.amberInk, 'Doorstep delivery in Lahore', 'A seller in your area delivers and sets up your plan at your door.'),
    (Icons.percent_rounded, AtomColors.greenSoft, AtomColors.green, '0% markup with AtomPay', 'On eligible products, pay in 3 months with no advance once your limit is approved.'),
    (Icons.notifications_active_outlined, AtomColors.primarySoft, AtomColors.primary, 'WhatsApp reminders', 'You get a WhatsApp reminder when an installment is due, so nothing slips.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtomPage(
      title: 'Why Atomshop',
      bottom: AtomButton(
        label: 'Start shopping',
        icon: Icons.shopping_bag_outlined,
        expand: true,
        onPressed: () => AtomNav.toTab(context, ref, AtomTab.shop),
      ),
      children: [
        const InfoEyebrow('Why Atomshop'),
        const SizedBox(height: 6),
        Text('Pay in steps, with people you can reach.', style: AtomText.title),
        const SizedBox(height: 6),
        Text('Modern installment shopping, simplified.', style: AtomText.body),
        const SizedBox(height: AtomSpace.lg),
        for (final (icon, bg, ink, title, body) in _reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: AtomSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: ink, size: 22),
                ),
                const SizedBox(width: AtomSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AtomText.subheading),
                      const SizedBox(height: 2),
                      Text(body, style: AtomText.body.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
