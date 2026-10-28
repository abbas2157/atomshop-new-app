import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/atom_account.dart';
import '../../data/atom_auth.dart';
import '../../data/atom_http.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../responsive/atom_responsive.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_session.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';
import '../../widgets/atom_text_field.dart';
import 'atom_account_widgets.dart';

/// Account tab, signed in (canvas: "Account menu · signed in").
class AtomAccountScreen extends ConsumerWidget {
  const AtomAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = context.atomGutter;
    final me = ref.watch(meProvider);
    final summary = ref.watch(accountSummaryProvider);
    final s = summary.value;

    Future<void> refresh() async {
      refreshAccount(ref);
      try {
        await ref.read(accountSummaryProvider.future);
      } catch (_) {
        // The cards show their own retry.
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AtomPageWidth(
          child: RefreshIndicator(
            color: AtomColors.primary,
            onRefresh: refresh,
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AtomSpace.xl),
              children: [
                const AccountTabHeader(title: 'Account'),
                const SizedBox(height: AtomSpace.xs),
                AtomAsync<AtomUser>(
                  value: me,
                  compactError: true,
                  onRetry: () => ref.invalidate(meProvider),
                  loading: const AtomSkeleton(height: 84, radius: AtomRadius.card),
                  data: (user) => _ProfileCard(user: user),
                ),
                const SizedBox(height: AtomSpace.sm),
                AtomAsync<AccountSummary>(
                  value: summary,
                  compactError: true,
                  onRetry: () => ref.invalidate(accountSummaryProvider),
                  loading: const AtomSkeleton(height: 84, radius: AtomRadius.card),
                  data: (s) => Column(
                    children: [
                      _Stats(summary: s),
                      if (s.atompay.state != AtompayState.none) ...[
                        const SizedBox(height: AtomSpace.sm),
                        _AtompayCard(atompay: s.atompay),
                      ],
                    ],
                  ),
                ),
                AccountMenuGroup(
                  title: 'My shopping',
                  rows: [
                    AccountMenuRow(Icons.dashboard_outlined, 'Overview', () => AtomNav.overview(context)),
                    AccountMenuRow(Icons.calendar_month_rounded, 'Installments', () => AtomNav.toTab(context, ref, AtomTab.installments),
                        count: s?.activePlans ?? 0),
                    AccountMenuRow(Icons.receipt_long_outlined, 'Payment history', () => AtomNav.payments(context)),
                    AccountMenuRow(Icons.inventory_2_outlined, 'My orders', () => AtomNav.orders(context)),
                    AccountMenuRow(Icons.add_circle_outline_rounded, 'Custom orders and offers', () => AtomNav.customOrders(context)),
                    AccountMenuRow(Icons.notifications_none_rounded, 'Notifications', () => AtomNav.notifications(context),
                        count: s?.unreadNotifications ?? 0),
                  ],
                ),
                AccountMenuGroup(
                  title: 'Profile and security',
                  rows: [
                    AccountMenuRow(Icons.person_outline_rounded, 'Profile and verification', () => AtomNav.profile(context)),
                    AccountMenuRow(Icons.place_outlined, 'City and area', () => AtomNav.location(context)),
                    AccountMenuRow(Icons.lock_outline_rounded, 'Change password', () => AtomNav.changePassword(context)),
                    AccountMenuRow(Icons.delete_outline_rounded, 'Delete account', () => _deleteAccount(context, ref)),
                  ],
                ),
                AccountMenuGroup(title: 'Help and info', rows: helpRows(context)),
                const SizedBox(height: AtomSpace.lg),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _signOut(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text('Sign out', style: AtomText.label.copyWith(color: AtomColors.rose)),
                    style: TextButton.styleFrom(foregroundColor: AtomColors.rose, minimumSize: const Size(44, 44)),
                  ),
                ),
                const AccountVersionFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can keep browsing and ordering as a guest.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AtomColors.rose),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(atomSessionProvider.notifier).signOut();
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final deleted = await showDialog<bool>(context: context, builder: (_) => const _DeleteAccountDialog());
    if (deleted == true) {
      await ref.read(atomSessionProvider.notifier).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your account has been deleted.')));
      }
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AtomUser user;

  @override
  Widget build(BuildContext context) {
    final line = [user.phone, user.place].where((s) => s.isNotEmpty).join(' · ');
    return AtomCard(
      onTap: () => AtomNav.profile(context),
      child: Row(
        children: [
          AccountAvatar(user: user),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.subheading),
                if (line.isNotEmpty) Text(line, maxLines: 2, overflow: TextOverflow.ellipsis, style: AtomText.small.copyWith(color: AtomColors.body)),
                if (user.verified) ...[
                  const SizedBox(height: 6),
                  const AtomBadge('Verified', tone: AtomTone.green, icon: Icons.check_rounded),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AtomColors.placeholder),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.summary});

  final AccountSummary summary;

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label, VoidCallback onTap) => Expanded(
          child: AtomCard(
            onTap: onTap,
            color: AtomColors.surface,
            borderColor: null,
            padding: const EdgeInsets.symmetric(horizontal: AtomSpace.sm, vertical: 14),
            child: Column(
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AtomText.heading)),
                const SizedBox(height: 2),
                Text(label, textAlign: TextAlign.center, maxLines: 2, style: AtomText.small),
              ],
            ),
          ),
        );

    return Consumer(
      builder: (context, ref, _) => Row(
        children: [
          tile('${summary.orders}', summary.orders == 1 ? 'Order' : 'Orders', () => AtomNav.orders(context)),
          const SizedBox(width: AtomSpace.xs),
          tile('${summary.activePlans}', summary.activePlans == 1 ? 'Active plan' : 'Active plans', () => AtomNav.toTab(context, ref, AtomTab.installments)),
          const SizedBox(width: AtomSpace.xs),
          tile(AtomFormat.amount(summary.paid), 'Rs. paid', () => AtomNav.payments(context)),
        ],
      ),
    );
  }
}

/// Dark AtomPay card: the limit when approved, else where the application stands.
class _AtompayCard extends StatelessWidget {
  const _AtompayCard({required this.atompay});

  final AtompayStatus atompay;

  @override
  Widget build(BuildContext context) {
    final (status, line) = switch (atompay.state) {
      AtompayState.approved => (
          atompay.conditional ? 'Approved with conditions' : 'Approved',
          atompay.available != null ? '${AtomFormat.rupees(atompay.available)} available' : 'Limit ${AtomFormat.rupees(atompay.limit)}',
        ),
      AtompayState.pending => ('Under review', 'AtomPay is reviewing your profile'),
      AtompayState.incomplete => ('Profile incomplete', 'Finish your AtomPay profile to get a limit'),
      AtompayState.rejected => ('Not approved', 'Your AtomPay application was not approved'),
      AtompayState.none => ('', ''),
    };
    final open = atompay.state == AtompayState.approved ? () => AtomNav.overview(context) : (atompay.url.isEmpty ? null : () => _open(atompay.url));

    return AtomCard(
      onTap: open,
      color: AtomColors.ink,
      borderColor: null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AtomColors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AtomColors.amber, size: 20),
          ),
          const SizedBox(width: AtomSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AtomPay limit · $status', style: AtomText.small.copyWith(color: AtomColors.onDark)),
                Text(line, style: AtomText.subheading.copyWith(color: AtomColors.white)),
              ],
            ),
          ),
          if (open != null) Icon(atompay.state == AtompayState.approved ? Icons.chevron_right_rounded : Icons.open_in_new_rounded, color: AtomColors.white),
        ],
      ),
    );
  }

  static Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Asks for the password, then deletes the account on the server.
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(atomAuthApiProvider).deleteAccount(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = atomMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This deletes your Atomshop and AtomPay sign-in. Orders and payments already made stay on record, as the law requires.',
              style: AtomText.body,
            ),
            const SizedBox(height: AtomSpace.md),
            AtomPasswordField(controller: _password, onSubmitted: _delete),
            if (_error != null) ...[
              const SizedBox(height: AtomSpace.xs),
              Text(_error!, style: AtomText.small.copyWith(color: AtomColors.rose)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        AtomButton(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          size: AtomButtonSize.small,
          variant: AtomButtonVariant.dark,
          loading: _busy,
          onPressed: _busy ? null : _delete,
        ),
      ],
    );
  }
}
