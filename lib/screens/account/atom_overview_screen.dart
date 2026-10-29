import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/atom_account.dart';
import '../../data/atom_auth.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../shell/atom_nav.dart';
import '../../shell/atom_shell.dart';
import '../../state/atom_account_providers.dart';
import '../../state/atom_session.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_button.dart';
import '../../widgets/atom_page.dart';
import '../../widgets/atom_states.dart';
import '../../widgets/atom_surfaces.dart';

/// Account overview (canvas: "Overview"): totals, the next installment,
/// verification and the AtomPay limit, all from the server.
class AtomOverviewScreen extends ConsumerWidget {
  const AtomOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(atomSessionProvider).value?.name ?? '';
    final summary = ref.watch(accountSummaryProvider);

    return AtomPage(
      title: 'Overview',
      subtitle: name.isEmpty ? null : 'Assalam-o-Alaikum, $name',
      onRefresh: () async {
        ref.invalidate(accountSummaryProvider);
        try {
          await ref.read(accountSummaryProvider.future);
        } catch (_) {
          // The page shows its own retry.
        }
      },
      children: [
        AtomAsync<AccountSummary>(
          value: summary,
          onRetry: () => ref.invalidate(accountSummaryProvider),
          loading: const Column(children: [
            AtomSkeleton(height: 150, radius: AtomRadius.card),
            SizedBox(height: AtomSpace.sm),
            AtomSkeleton(height: 120, radius: AtomRadius.card),
          ]),
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatsGrid(summary: s),
              if (s.nextDue != null) ...[
                const SizedBox(height: AtomSpace.sm),
                _NextDueCard(due: s.nextDue!),
              ],
              const SizedBox(height: AtomSpace.sm),
              _VerificationCard(summary: s),
              if (s.atompay.state != AtompayState.none) ...[
                const SizedBox(height: AtomSpace.sm),
                _AtompayLimitCard(atompay: s.atompay),
              ],
            ],
          ),
        ),
        const AtomGroupLabel('Quick actions'),
        const _QuickActions(),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});

  final AccountSummary summary;

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value, {Color? color}) => Expanded(
          child: AtomCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AtomText.small),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: AtomText.heading.copyWith(color: color))),
              ],
            ),
          ),
        );

    return Column(
      children: [
        Row(children: [
          tile('Total orders', '${summary.orders}'),
          const SizedBox(width: AtomSpace.xs),
          tile('Amount paid', AtomFormat.rupees(summary.paid)),
        ]),
        const SizedBox(height: AtomSpace.xs),
        Row(children: [
          tile('Active plans', '${summary.activePlans}'),
          const SizedBox(width: AtomSpace.xs),
          tile('Total unpaid', AtomFormat.rupees(summary.unpaid), color: summary.unpaid > 0 ? AtomColors.amberInk : null),
        ]),
      ],
    );
  }
}

class _NextDueCard extends ConsumerWidget {
  const _NextDueCard({required this.due});

  final NextDue due;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = [due.product, due.label].where((s) => s.isNotEmpty).join(' · ');
    return AtomCard(
      onTap: () => AtomNav.installments(context),
      borderColor: AtomColors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Next installment due', style: AtomText.label)),
              const AtomBadge('Unpaid', tone: AtomTone.amber),
            ],
          ),
          const SizedBox(height: AtomSpace.xs),
          Text(title, style: AtomText.body),
          Text(AtomFormat.rupees(due.amount), style: AtomText.title),
          if (due.date != null) Text('Due date ${AtomFormat.date(due.date)}', style: AtomText.small),
          const SizedBox(height: AtomSpace.xs),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 16, color: AtomColors.primary),
              const SizedBox(width: 6),
              Text('View schedule', style: AtomText.label.copyWith(color: AtomColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.summary});

  final AccountSummary summary;

  @override
  Widget build(BuildContext context) {
    final identity = switch (summary.identity) {
      'atompay' => 'AtomPay',
      'atomshop' => 'Atomshop',
      _ => 'Not yet',
    };
    Widget check(String label, String value, bool done) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 20, color: done ? AtomColors.green : AtomColors.placeholder),
              const SizedBox(width: AtomSpace.xs),
              Expanded(child: Text(label, style: AtomText.body)),
              Text(value, style: AtomText.label),
            ],
          ),
        );

    return AtomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Verification', style: AtomText.subheading)),
              summary.verified ? const AtomBadge('Verified', tone: AtomTone.green) : const AtomBadge('Not verified yet'),
            ],
          ),
          const SizedBox(height: AtomSpace.xs),
          // The account endpoint in use does not report these two checks;
          // "Not yet" would be wrong, so they show only when it does.
          if (AtomAuthApi.supportsExtendedProfile) ...[
            check('Identity and face', identity, summary.identity.isNotEmpty),
            check('Address visit', summary.addressVisitAt == null ? 'Not yet' : AtomFormat.date(summary.addressVisitAt), summary.addressVisitAt != null),
          ],
          check('CNIC on file', summary.cnicMasked.isEmpty ? 'Not yet' : summary.cnicMasked, summary.cnicMasked.isNotEmpty),
          const SizedBox(height: AtomSpace.xs),
          Text(
            summary.verified
                ? "Our team has verified your details. You're ready for your next plan."
                : 'A seller verifies your CNIC and address with your first order.',
            style: AtomText.small.copyWith(color: AtomColors.body),
          ),
        ],
      ),
    );
  }
}

class _AtompayLimitCard extends StatelessWidget {
  const _AtompayLimitCard({required this.atompay});

  final AtompayStatus atompay;

  @override
  Widget build(BuildContext context) {
    final approved = atompay.state == AtompayState.approved;
    final status = switch (atompay.state) {
      AtompayState.approved => atompay.conditional ? 'Approved with conditions' : 'Approved',
      AtompayState.pending => 'Under review',
      AtompayState.incomplete => 'Profile incomplete',
      AtompayState.rejected => 'Not approved',
      AtompayState.none => '',
    };
    final muted = AtomText.body.copyWith(fontSize: 13, color: AtomColors.onDark);
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(label, style: muted)),
            Text(value, style: AtomText.label.copyWith(color: AtomColors.white)),
          ]),
        );

    return Container(
      padding: const EdgeInsets.all(AtomSpace.md),
      decoration: BoxDecoration(color: AtomColors.ink, borderRadius: BorderRadius.circular(AtomRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AtomColors.amber, size: 20),
              const SizedBox(width: AtomSpace.xs),
              Expanded(child: Text('AtomPay limit', style: AtomText.subheading.copyWith(color: AtomColors.white))),
              AtomBadge(status, tone: approved ? AtomTone.green : AtomTone.amber),
            ],
          ),
          const SizedBox(height: AtomSpace.xs),
          if (approved) ...[
            if (atompay.available != null) line('Available to spend', AtomFormat.rupees(atompay.available)),
            if (atompay.limit != null) line('Approved limit', AtomFormat.rupees(atompay.limit)),
            if (atompay.maxMonthly != null) line('Max monthly installment', AtomFormat.rupees(atompay.maxMonthly)),
            if (atompay.months != null) line('AtomPay plan', '${atompay.months} months · 0% markup'),
          ] else
            Text(
              atompay.state == AtompayState.pending
                  ? 'AtomPay is reviewing your profile. You get a message when it is decided.'
                  : 'Complete your AtomPay profile on atompay.shop with the same phone number.',
              style: muted,
            ),
          if (!approved && atompay.url.isNotEmpty) ...[
            const SizedBox(height: AtomSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AtomButton(
                label: 'Open AtomPay',
                icon: Icons.open_in_new_rounded,
                variant: AtomButtonVariant.light,
                size: AtomButtonSize.small,
                onPressed: () => launchUrl(Uri.parse(atompay.url), mode: LaunchMode.externalApplication),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget action(String label, IconData icon, VoidCallback onTap) => Expanded(
          child: AtomButton(label: label, icon: icon, variant: AtomButtonVariant.secondary, size: AtomButtonSize.medium, expand: true, onPressed: onTap),
        );
    return Column(
      children: [
        Row(children: [
          action('Shop products', Icons.shopping_bag_outlined, () => AtomNav.toTab(context, ref, AtomTab.shop)),
          const SizedBox(width: AtomSpace.xs),
          action('Plan calculator', Icons.calculate_outlined, () => AtomNav.customOrder(context)),
        ]),
        const SizedBox(height: AtomSpace.xs),
        Row(children: [
          action('My orders', Icons.inventory_2_outlined, () => AtomNav.orders(context)),
          const SizedBox(width: AtomSpace.xs),
          action('Payments', Icons.credit_card_rounded, () => AtomNav.payments(context)),
        ]),
      ],
    );
  }
}
