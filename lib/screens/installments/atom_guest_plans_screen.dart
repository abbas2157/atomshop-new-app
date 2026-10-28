import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_surfaces.dart';

/// Installments tab for guests (canvas: "Installments · guest").
class AtomGuestPlansScreen extends ConsumerWidget {
  const AtomGuestPlansScreen({super.key});

  static const _steps = [
    'Pick a product, the advance and the number of months.',
    'A verified seller near you confirms and delivers.',
    'Pay month by month. Every payment shows up here.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = context.atomGutter;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, AtomSpace.md, gutter, AtomSpace.xl),
            children: [
              Semantics(header: true, child: Text('Installments', style: AtomText.title)),
              const SizedBox(height: AtomSpace.md),
              Container(
                padding: const EdgeInsets.all(AtomSpace.lg),
                decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.hero)),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: AtomColors.primarySoft, borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.calendar_month_rounded, color: AtomColors.primary, size: 28),
                    ),
                    const SizedBox(height: AtomSpace.sm),
                    Text('Your installments live here', textAlign: TextAlign.center, style: AtomText.heading),
                    const SizedBox(height: AtomSpace.xxs),
                    Text(
                      "Sign in to see every due date, what you've paid, receipts and reminders.",
                      textAlign: TextAlign.center,
                      style: AtomText.body,
                    ),
                    const SizedBox(height: AtomSpace.md),
                    AtomButton(label: 'Sign in', icon: Icons.login_rounded, expand: true, onPressed: () => AtomNav.signIn(context)),
                    const SizedBox(height: AtomSpace.xs),
                    AtomButton(
                      label: 'Create account',
                      icon: Icons.person_add_alt_1_outlined,
                      variant: AtomButtonVariant.secondary,
                      expand: true,
                      onPressed: () => AtomNav.register(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AtomSpace.sm),
              AtomCard(
                onTap: () => AtomNav.forgotPassword(context),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AtomColors.amberSoft, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.lock_outline_rounded, color: AtomColors.amberInk, size: 20),
                    ),
                    const SizedBox(width: AtomSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ordered as a guest?', style: AtomText.label),
                          Text('Your order is saved to your phone number. Set a password with that number to see it.', style: AtomText.small.copyWith(color: AtomColors.body)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AtomColors.placeholder),
                  ],
                ),
              ),
              const SizedBox(height: AtomSpace.lg),
              Text('How installments work', style: AtomText.subheading.copyWith(fontWeight: FontWeight.w800)),
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
              const SizedBox(height: AtomSpace.sm),
              AtomButton(
                label: 'Browse products',
                icon: Icons.shopping_bag_outlined,
                variant: AtomButtonVariant.secondary,
                expand: true,
                onPressed: () => AtomNav.toTab(context, ref, AtomTab.shop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
