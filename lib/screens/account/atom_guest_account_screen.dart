import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_outbox.dart';
import '../../widgets/atom_button.dart';
import 'atom_account_widgets.dart';

/// Account tab for guests (canvas: "Account · guest"): a sign-in card, the
/// things a guest can do without an account, and help pages.
class AtomGuestAccountScreen extends ConsumerWidget {
  const AtomGuestAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = context.atomGutter;
    final waiting = ref.watch(outboxProvider).length;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AtomSpace.xl),
            children: [
              const AccountTabHeader(title: 'Account', pill: 'Guest'),
              const SizedBox(height: AtomSpace.xs),
              const _SignInCard(),
              AccountMenuGroup(
                title: 'Shop without signing in',
                rows: [
                  AccountMenuRow(Icons.grid_view_rounded, 'Shop by category', () => AtomNav.toTab(context, ref, AtomTab.shop)),
                  AccountMenuRow(Icons.sell_outlined, 'All brands', () => AtomNav.toTab(context, ref, AtomTab.shop)),
                  AccountMenuRow(Icons.calculate_outlined, 'Custom order', () => AtomNav.customOrder(context)),
                  AccountMenuRow(Icons.chat_bubble_outline_rounded, 'Make an offer', () => AtomNav.makeOffer(context)),
                  AccountMenuRow(Icons.auto_awesome_rounded, 'Ask Atom', () => AtomNav.toTab(context, ref, AtomTab.askAtom)),
                  AccountMenuRow(Icons.place_outlined, 'Delivery area', () => AtomNav.location(context)),
                  if (waiting > 0) AccountMenuRow(Icons.schedule_send_rounded, 'Waiting to send', () => AtomNav.outbox(context), count: waiting),
                ],
              ),
              AccountMenuGroup(title: 'Help and info', rows: helpRows(context)),
              const SizedBox(height: AtomSpace.md),
              const AccountVersionFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtomSpace.md + 2),
      decoration: BoxDecoration(color: AtomColors.ink, borderRadius: BorderRadius.circular(AtomRadius.hero)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The round Atomshop mark on a white disc.
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AtomColors.white, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/images/app-atomshop.png', fit: BoxFit.contain, excludeFromSemantics: true),
            ),
          ),
          const SizedBox(height: AtomSpace.sm),
          Text('Sign in to track your orders and installments', style: AtomText.heading.copyWith(color: AtomColors.white)),
          const SizedBox(height: 6),
          Text(
            "You can browse and place orders as a guest. Sign in to see due dates, receipts and your AtomPay limit.",
            style: AtomText.body.copyWith(color: AtomColors.onDark),
          ),
          const SizedBox(height: AtomSpace.md),
          Row(
            children: [
              Expanded(
                child: AtomButton(
                  label: 'Sign in',
                  icon: Icons.login_rounded,
                  variant: AtomButtonVariant.light,
                  size: AtomButtonSize.medium,
                  expand: true,
                  onPressed: () => AtomNav.signIn(context),
                ),
              ),
              const SizedBox(width: AtomSpace.sm),
              Expanded(
                child: _OutlinedOnDark(label: 'Sign up', icon: Icons.person_add_alt_1_rounded, onTap: () => AtomNav.register(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pill with a light outline on the dark card.
class _OutlinedOnDark extends StatelessWidget {
  const _OutlinedOnDark({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: AtomColors.white.withValues(alpha: 0.35))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AtomSize.button),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: AtomColors.white),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.button.copyWith(fontSize: 14, color: AtomColors.white))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
