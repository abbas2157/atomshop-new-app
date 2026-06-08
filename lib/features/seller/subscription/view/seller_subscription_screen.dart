import 'dart:io';

import 'package:atompro/core/routes/app_navigator.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/auth/viewmodel/seller_auth_viewmodel.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/subscription/model/seller_subscription_model.dart';
import 'package:atompro/features/seller/subscription/repository/seller_subscription_repository.dart';
import 'package:atompro/features/seller/subscription/viewmodel/seller_subscription_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class SellerSubscriptionScreen extends ConsumerWidget {
  /// When true, the screen is shown as the dashboard "lock" gate (no bottom
  /// nav): a lock banner is shown and the only escape hatches are switch-to-
  /// customer and log out.
  final bool locked;

  /// When [locked], distinguishes the two lock reasons (payment under review
  /// vs. no payment submitted yet).
  final bool underReview;

  const SellerSubscriptionScreen({
    super.key,
    this.locked = false,
    this.underReview = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final state = ref.watch(sellerSubscriptionProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _HeaderGlyph(icon: Icons.workspace_premium_rounded),
            title: 'Subscription',
            subtitle: locked ? 'Activate your dashboard' : 'Your plan & payments',
            automaticallyImplyLeading: !locked,
            actions: locked
                ? [
                    SellerHeaderPill(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Customer',
                      onTap: AppNavigator.goToCustomerMode,
                    ),
                    SellerHeaderIconButton(
                      icon: Icons.logout_rounded,
                      tooltip: 'Log out',
                      onTap: () =>
                          ref.read(sellerAuthViewModelProvider.notifier).logout(),
                    ),
                  ]
                : [
                    SellerHeaderIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Refresh',
                      onTap: () => ref.invalidate(sellerSubscriptionProvider),
                    ),
                  ],
          ),
          Expanded(
            child: state.when(
              loading: () => const SellerListSkeleton(),
              error: (e, _) => SellerErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(sellerSubscriptionProvider),
              ),
              data: (data) => RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerSubscriptionProvider);
                  await ref.read(sellerSubscriptionProvider.future);
                },
                child: data.hasActivePlan && data.plan != null
                    ? _Body(
                        data: data,
                        plan: data.plan!,
                        locked: locked,
                        underReview: underReview,
                      )
                    : ListView(
                        padding: AppInsets.pageWithNav,
                        children: const [
                          Gap.v(AppSpace.xxl),
                          SellerEmptyState(
                            icon: Icons.workspace_premium_rounded,
                            title: 'No active plan',
                            message:
                                'You don\'t have a subscription plan yet. '
                                'Please contact the admin to get one assigned.',
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final SellerSubscriptionData data;
  final SellerPlan plan;
  final bool locked;
  final bool underReview;
  const _Body({
    required this.data,
    required this.plan,
    this.locked = false,
    this.underReview = false,
  });

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref, {
    required String type,
    required int amount,
  }) async {
    final ok = await _showPaymentSheet(
      context,
      type: type,
      amount: amount,
    );
    if (ok == true) ref.invalidate(sellerSubscriptionProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commission = data.commission;
    final showCommission = commission != null && plan.hasCommissionRate;

    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        if (locked) ...[
          _LockBanner(underReview: underReview),
          const Gap.v(AppSpace.md),
        ],
        _PlanCard(plan: plan),
        const Gap.v(AppSpace.md),
        _MonthlyPayButton(
          action: plan.monthly,
          onPay: () =>
              _pay(context, ref, type: 'monthly', amount: plan.monthly.amount),
        ),
        if (showCommission) ...[
          const Gap.v(AppSpace.lg),
          const SellerSectionHeader(
            overline: 'Sales commission',
            title: 'Commission summary',
          ),
          const Gap.v(AppSpace.sm),
          _CommissionCard(
            summary: commission,
            action: plan.commissionAction,
            onPay: () => _pay(
              context,
              ref,
              type: 'commission',
              amount: plan.commissionAction.amount,
            ),
          ),
        ],
        const Gap.v(AppSpace.lg),
        SellerSectionHeader(
          title: 'Payment history',
          overline: '${data.payments.length} records',
        ),
        const Gap.v(AppSpace.sm),
        if (data.payments.isEmpty)
          SellerCard(
            child: Text('No payments yet', style: context.sellerText.bodySm),
          )
        else
          ...data.payments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: _PaymentRow(payment: p),
              )),
      ],
    );
  }
}

// ── Lock banner (dashboard gate) ───────────────────────────────────────────
class _LockBanner extends StatelessWidget {
  final bool underReview;
  const _LockBanner({required this.underReview});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = underReview ? c.infoTone : c.warningTone;

    final urdu = underReview
        ? 'آپ کی ادائیگی زیرِ جائزہ ہے۔ ایڈمن کی تصدیق کے بعد رسائی دی جائے گی۔'
        : 'آپ کا پلان فعال ہے۔ ڈیش بورڈ تک رسائی کے لیے پہلی ادائیگی جمع کروائیں۔';
    final english = underReview
        ? 'Your payment is under review. Dashboard access will be granted once the admin confirms it.'
        : 'Your plan is active. Submit your first payment to unlock the dashboard.';

    return SellerCard(
      color: tone.bg,
      borderColor: tone.border,
      elevated: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SellerIconBadge(
            icon: underReview
                ? Icons.hourglass_top_rounded
                : Icons.lock_rounded,
            tone: tone,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    urdu,
                    style: text.bodyLg.copyWith(
                      color: tone.fg,
                      fontWeight: FontWeight.w700,
                      height: 1.6,
                    ),
                  ),
                ),
                const Gap.v(AppSpace.xs),
                Text(english, style: text.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final SellerPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.workspace_premium_rounded,
                tone: c.accentTone,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.planLabel, style: text.titleMd),
                    const Gap.v(2),
                    Text('Status: ${plan.status}', style: text.bodySm),
                  ],
                ),
              ),
              SellerStatusPill(label: plan.status),
            ],
          ),
          const Gap.v(AppSpace.md),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.xs),
          SellerDataRow(
            label: 'Monthly price',
            value: plan.formattedMonthlyPrice,
            emphasize: true,
          ),
          if (plan.hasCommissionRate)
            SellerDataRow(
              label: 'Sales commission',
              value: plan.commissionRateLabel,
            ),
          SellerDataRow(label: 'Start date', value: plan.formattedStartDate),
          SellerDataRow(label: 'End date', value: plan.endDateLabel),
          const Gap.v(AppSpace.sm),
          Text('Included features', style: text.overline),
          const Gap.v(AppSpace.xs),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              if (plan.featureFinancial)
                const _FeatureChip(label: 'Financial Management'),
              if (plan.featureMarketing)
                const _FeatureChip(label: 'Marketing & Sales'),
              if (!plan.featureFinancial && !plan.featureMarketing)
                const _FeatureChip(label: 'Standard access'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: c.accentSurface,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: c.accent),
          const Gap.h(AppSpace.xs - 2),
          Text(
            label,
            style: text.labelSm.copyWith(color: c.accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Monthly pay button (state-driven) ──────────────────────────────────────
class _MonthlyPayButton extends StatelessWidget {
  final SellerPaymentAction action;
  final VoidCallback onPay;
  const _MonthlyPayButton({required this.action, required this.onPay});

  @override
  Widget build(BuildContext context) {
    if (action.canPay) {
      return Column(
        children: [
          SellerButton(
            label: 'Pay Monthly — ${action.formattedAmount}',
            icon: Icons.payments_rounded,
            onPressed: onPay,
          ),
          if (action.unpaidMonths > 1) ...[
            const Gap.v(AppSpace.xs),
            Text(
              '${action.unpaidMonths} months unpaid',
              style: context.sellerText.caption.copyWith(
                color: context.sellerColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      );
    }
    return SellerButton(
      label: action.isPending
          ? 'Payment Pending Confirmation'
          : 'All Payments Up to Date',
      icon: action.isPending
          ? Icons.hourglass_top_rounded
          : Icons.check_circle_rounded,
      variant: SellerButtonVariant.secondary,
      onPressed: null,
    );
  }
}

// ── Commission card ─────────────────────────────────────────────────────────
class _CommissionCard extends StatelessWidget {
  final SellerCommissionSummary summary;
  final SellerPaymentAction action;
  final VoidCallback onPay;

  const _CommissionCard({
    required this.summary,
    required this.action,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SellerDataRow(label: 'Commission rate', value: summary.rateLabel),
          SellerDataRow(label: 'Total sales', value: summary.formattedTotalSales),
          SellerDataRow(label: 'Commission accrued', value: summary.formattedAccrued),
          SellerDataRow(label: 'Commission received', value: summary.formattedPaid),
          Divider(color: c.divider, height: AppSpace.lg),
          SellerDataRow(
            label: 'Still owed',
            value: summary.formattedPending,
            emphasize: true,
          ),
          if (action.canPay) ...[
            const Gap.v(AppSpace.sm),
            SellerButton(
              label: 'Pay Commission — ${action.formattedAmount}',
              icon: Icons.percent_rounded,
              onPressed: onPay,
            ),
          ] else if (action.isPending) ...[
            const Gap.v(AppSpace.sm),
            const SellerButton(
              label: 'Payment Pending Confirmation',
              icon: Icons.hourglass_top_rounded,
              variant: SellerButtonVariant.secondary,
              onPressed: null,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Payment history row ──────────────────────────────────────────────────
class _PaymentRow extends StatelessWidget {
  final SellerSubscriptionPayment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerIconBadge(
                icon: payment.isMonthly
                    ? Icons.calendar_month_rounded
                    : Icons.percent_rounded,
                tone: payment.isMonthly ? c.infoTone : c.violetTone,
                size: 38,
                iconSize: 18,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${payment.typeLabel} · ${payment.month}',
                      style: text.titleSm,
                    ),
                    const Gap.v(2),
                    Text(
                      '${payment.paymentMethod} · ${payment.formattedSubmittedAt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySm,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(payment.formattedAmount, style: text.titleSm),
                  const Gap.v(AppSpace.xs - 2),
                  SellerStatusPill(label: payment.statusLabel, dense: true),
                ],
              ),
            ],
          ),
          if (payment.hasNotes) ...[
            const Gap.v(AppSpace.xs),
            Text(payment.notes!, style: text.caption),
          ],
          if (payment.hasReceipt) ...[
            const Gap.v(AppSpace.xs),
            GestureDetector(
              onTap: () => _openReceipt(payment.receipt!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 15, color: c.accent),
                  const Gap.h(AppSpace.xs - 2),
                  Text(
                    'View receipt',
                    style: text.labelSm.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReceipt(String url) async {
    try {
      await SellerFileService.openExternalUrl(url);
    } catch (e) {
      SnackbarService().showErrorSnackBar('Unable to open receipt.');
    }
  }
}

class _HeaderGlyph extends StatelessWidget {
  final IconData icon;
  const _HeaderGlyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PAYMENT SHEET
// ═══════════════════════════════════════════════════════════════════════════
Future<bool?> _showPaymentSheet(
  BuildContext context, {
  required String type,
  required int amount,
}) {
  final dark = context.sellerIsDark;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _PaymentSheet(type: type, amount: amount),
    ),
  );
}

class _PaymentSheet extends ConsumerStatefulWidget {
  final String type;
  final int amount;
  const _PaymentSheet({required this.type, required this.amount});

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  static const _methods = ['Bank Transfer', 'JazzCash', 'EasyPaisa', 'Cash'];
  String _method = _methods.first;
  final _notesController = TextEditingController();
  File? _receipt;
  bool _submitting = false;

  bool get _isMonthly => widget.type == 'monthly';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null) return;
    setState(() => _receipt = File(picked.path));
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(sellerSubscriptionRepositoryProvider).submitPayment(
            paymentType: widget.type,
            paymentMethod: _method,
            receipt: _receipt,
            notes: _notesController.text,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      SnackbarService().showSuccessSnackBar(
        'Payment submitted. Admin will confirm shortly.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      SnackbarService().showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String _money(int v) {
    final t = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      final r = t.length - i;
      b.write(t[i]);
      if (r > 1 && r % 3 == 1) b.write(',');
    }
    return 'Rs $b';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.sheet),
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: AppRadius.brPill,
                ),
              ),
            ),
            const Gap.v(AppSpace.md),
            Text(
              _isMonthly ? 'Pay monthly subscription' : 'Pay commission',
              style: text.titleMd,
            ),
            const Gap.v(AppSpace.xs),
            // Amount (read-only, server-enforced)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: c.accentSurface,
                borderRadius: AppRadius.brMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount due', style: text.caption),
                  const Gap.v(2),
                  Text(_money(widget.amount), style: text.metric.copyWith(color: c.accent)),
                ],
              ),
            ),
            const Gap.v(AppSpace.lg),
            Text('Payment method', style: text.label),
            const Gap.v(AppSpace.xs),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: _methods.map((m) {
                final selected = m == _method;
                return GestureDetector(
                  onTap: _submitting ? null : () => setState(() => _method = m),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? c.accent : c.surface,
                      borderRadius: AppRadius.brPill,
                      border: Border.all(
                        color: selected ? c.accent : c.border,
                      ),
                    ),
                    child: Text(
                      m,
                      style: text.labelSm.copyWith(
                        color: selected ? c.onAccent : c.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap.v(AppSpace.lg),
            Text('Receipt (optional)', style: text.label),
            const Gap.v(AppSpace.xs),
            _ReceiptPicker(
              receipt: _receipt,
              onPick: _submitting ? () {} : _pickReceipt,
              onClear: () => setState(() => _receipt = null),
            ),
            const Gap.v(AppSpace.lg),
            Text('Notes (optional)', style: text.label),
            const Gap.v(AppSpace.xs),
            TextField(
              controller: _notesController,
              enabled: !_submitting,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              style: text.body,
              cursorColor: c.accent,
              decoration: InputDecoration(
                hintText: 'e.g. transaction ID',
                hintStyle: text.body.copyWith(color: c.textTertiary),
                filled: true,
                fillColor: c.surfaceAlt,
                counterText: '',
                contentPadding: const EdgeInsets.all(AppSpace.md),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brMd,
                  borderSide: BorderSide(color: c.accent, width: 1.6),
                ),
              ),
            ),
            const Gap.v(AppSpace.lg),
            SellerButton(
              label: 'Submit payment',
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptPicker extends StatelessWidget {
  final File? receipt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ReceiptPicker({
    required this.receipt,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    if (receipt != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.brSm,
            child: Image.file(
              receipt!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Text(
              receipt!.path.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySm,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
            onPressed: onClear,
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: c.accent, size: 22),
            const Gap.v(AppSpace.xs - 2),
            Text(
              'Upload receipt screenshot',
              style: text.bodySm.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
