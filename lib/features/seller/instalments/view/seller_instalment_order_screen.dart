// ============================================================
//  seller_instalment_order_screen.dart  —  Order Ledger
//
//  Full per-order instalment ledger: order/customer summary,
//  recovery progress, transaction ledger, and the Record
//  Payment flow that hands off into the client-rendered
//  invoice once a payment succeeds.
// ============================================================

import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:atompro/features/seller/instalments/view/seller_instalment_invoice_screen.dart';
import 'package:atompro/features/seller/instalments/view/seller_instalments_screen.dart'
    show orderStatusTone;
import 'package:atompro/features/seller/instalments/viewmodel/seller_instalments_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ═══════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════
class SellerInstalmentOrderScreen extends ConsumerWidget {
  final int orderId;

  const SellerInstalmentOrderScreen({super.key, required this.orderId});

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    SellerInstalmentOrderDetail detail,
  ) async {
    final nextDue = detail.nextInstalment;
    if (nextDue == null) return;

    final dark = context.sellerIsDark;
    final result = await showModalBottomSheet<_RecordPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: _RecordPaymentSheet(orderId: orderId, nextDue: nextDue),
      ),
    );
    if (result == null || !context.mounted) return;

    ref.invalidate(sellerInstalmentOrderDetailProvider(orderId));
    ref.invalidate(sellerInstalmentsListProvider);

    SnackbarService().showSuccessSnackBar('Instalment paid successfully.');

    try {
      final invoiceData = await ref.read(
        sellerInstalmentInvoiceDataProvider(nextDue.id).future,
      );
      if (!context.mounted) return;
      await context.pushSeller(
        SellerInstalmentInvoiceScreen(
          instalmentId: nextDue.id,
          invoiceData: invoiceData,
          paymentDate: result.paymentDate,
          referenceNo: result.referenceNo,
          notes: result.notes,
        ),
      );
    } catch (_) {
      // Invoice fetch is best-effort right after payment — the ledger has
      // already refreshed, so the seller can still record the receipt was
      // accepted even if the invoice couldn't be opened immediately.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final state = ref.watch(sellerInstalmentOrderDetailProvider(orderId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Column(
          children: [
            state.maybeWhen(
              data: (detail) => SellerGradientHeader(
                title: detail.order.formattedOrderNo,
                subtitle: detail.order.user.name,
                actions: [
                  SellerStatusPill(
                    label: detail.orderStatus,
                    tone: orderStatusTone(detail.orderStatus, c),
                  ),
                ],
              ),
              orElse: () => const SellerGradientHeader(title: 'Order Ledger'),
            ),
            Expanded(
              child: state.when(
                loading: () =>
                    const SellerListSkeleton(count: 5, itemHeight: 120),
                error: (error, _) => SellerErrorState(
                  message: _cleanError(error),
                  onRetry: () => ref.invalidate(
                    sellerInstalmentOrderDetailProvider(orderId),
                  ),
                ),
                data: (detail) => RefreshIndicator(
                  color: c.accent,
                  backgroundColor: c.surface,
                  onRefresh: () async {
                    ref.invalidate(sellerInstalmentOrderDetailProvider(orderId));
                    await ref.read(
                      sellerInstalmentOrderDetailProvider(orderId).future,
                    );
                  },
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: AppInsets.pageWithNav,
                    children: [
                      _RecoveryCard(detail: detail),
                      const Gap.v(AppSpace.sm),
                      _OrderInfoCard(order: detail.order),
                      const Gap.v(AppSpace.sm),
                      _CustomerInfoCard(user: detail.order.user),
                      const Gap.v(AppSpace.sm),
                      SellerSectionHeader(title: 'Transaction Ledger'),
                      const Gap.v(AppSpace.xs),
                      _LedgerCard(entries: detail.ledger),
                      const Gap.v(AppSpace.md),
                      if (detail.nextInstalment != null &&
                          detail.orderStatus.toLowerCase() != 'completed')
                        SellerButton(
                          label:
                              'Record Payment • ${detail.nextInstalment!.formattedPrice}',
                          icon: Icons.payments_rounded,
                          onPressed: () =>
                              _recordPayment(context, ref, detail),
                        )
                      else
                        const SellerEmptyState(
                          icon: Icons.verified_rounded,
                          title: 'All Instalments Cleared',
                          message:
                              'This order has been fully recovered — no more dues remain.',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  RECOVERY SUMMARY CARD
// ═══════════════════════════════════════════════════════════
class _RecoveryCard extends StatelessWidget {
  final SellerInstalmentOrderDetail detail;

  const _RecoveryCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = orderStatusTone(detail.orderStatus, c);
    final nextDue = detail.nextInstalment;

    return SellerCard(
      accentEdge: tone.fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  label: 'Total Paid',
                  value: detail.formattedTotalPaid,
                  color: c.successTone.fg,
                ),
              ),
              Container(width: 1, height: 34, color: c.divider),
              Expanded(
                child: _StatBlock(
                  label: 'Remaining',
                  value: detail.formattedRemaining,
                  color: c.dangerTone.fg,
                ),
              ),
              Container(width: 1, height: 34, color: c.divider),
              Expanded(
                child: _StatBlock(
                  label: 'Progress',
                  value: '${detail.progressPct}%',
                  color: c.accent,
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          SellerProgressBar(value: detail.progressFraction, color: tone.fg),
          if (nextDue != null) ...[
            const Gap.v(AppSpace.sm),
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: AppRadius.brSm,
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, size: 16, color: c.accent),
                  const Gap.h(AppSpace.xs),
                  Expanded(
                    child: Text(
                      'Next due ${nextDue.formattedPrice} on ${nextDue.formattedDate}',
                      style: text.bodySm,
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
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBlock({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Column(
      children: [
        Text(
          value,
          style: text.titleSm.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        const Gap.v(2),
        Text(label, style: text.caption),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ORDER INFO CARD
// ═══════════════════════════════════════════════════════════
class _OrderInfoCard extends StatelessWidget {
  final SellerInstalmentOrderFull order;

  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.product.title, style: text.titleSm),
              ),
              Text(order.formattedOrderNo, style: text.caption),
            ],
          ),
          const Divider(height: AppSpace.md),
          SellerDataRow(label: 'Total Deal Price', value: order.formattedTotalDealPrice, emphasize: true),
          SellerDataRow(label: 'Advance Paid', value: order.formattedAdvancePrice),
          SellerDataRow(label: 'Tenure', value: '${order.tenure} months'),
          SellerDataRow(label: 'Monthly Instalment', value: order.formattedMonthlyInstalment),
          SellerDataRow(label: 'Order Date', value: order.createdAt),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CUSTOMER INFO CARD
// ═══════════════════════════════════════════════════════════
class _CustomerInfoCard extends StatelessWidget {
  final SellerInstalmentUser user;

  const _CustomerInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    final customer = user.customer;

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.person_outline_rounded,
                size: 38,
                iconSize: 19,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: text.titleSm),
                    Text(user.phone, style: text.bodySm),
                  ],
                ),
              ),
            ],
          ),
          if (customer != null) ...[
            const Divider(height: AppSpace.md),
            SellerDataRow(label: 'CNIC', value: customer.cnicNo),
            SellerDataRow(label: 'Alternate Phone', value: customer.alternatePhone),
            SellerDataRow(label: 'City / Area', value: '${customer.city} • ${customer.area}'),
            SellerDataRow(label: 'Address', value: customer.address),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LEDGER CARD — list of transaction rows with running balance
// ═══════════════════════════════════════════════════════════
class _LedgerCard extends StatelessWidget {
  final List<SellerLedgerEntry> entries;

  const _LedgerCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SellerEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No ledger entries',
        message: 'Transactions for this order will appear here.',
      );
    }

    return SellerCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _LedgerRow(entry: entries[i]),
            if (i != entries.length - 1)
              Divider(height: 1, color: context.sellerColors.divider),
          ],
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final SellerLedgerEntry entry;

  const _LedgerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = entry.overdue
        ? c.dangerTone
        : entry.paid
            ? c.successTone
            : c.infoTone;
    final label = entry.overdue ? 'Overdue' : (entry.paid ? 'Paid' : 'Pending');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.desc,
                  style: text.bodySm.copyWith(fontWeight: FontWeight.w700),
                ),
                const Gap.v(2),
                Text(entry.date, style: text.caption),
                if (entry.rowType.isNotEmpty || entry.paymentMethod != null) ...[
                  const Gap.v(2),
                  SellerStatusPill(label: label, tone: tone, dense: true),
                ],
              ],
            ),
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (entry.debit > 0)
                  Text(
                    '- ${entry.formattedDebit}',
                    style: text.bodySm.copyWith(
                      color: c.dangerTone.fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (entry.credit > 0)
                  Text(
                    '+ ${entry.formattedCredit}',
                    style: text.bodySm.copyWith(
                      color: c.successTone.fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const Gap.v(2),
                Text(
                  'Bal. ${entry.formattedBalance}',
                  style: text.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  RECORD PAYMENT SHEET
// ═══════════════════════════════════════════════════════════

/// Client-only fields the spec requires on the invoice but that the server
/// does not accept on `POST /seller-app/instalment/pay` — captured locally
/// and threaded through to the Invoice screen after a successful payment.
class _RecordPaymentResult {
  final DateTime paymentDate;
  final String referenceNo;
  final String notes;

  const _RecordPaymentResult({
    required this.paymentDate,
    required this.referenceNo,
    required this.notes,
  });
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final int orderId;
  final SellerInstalmentRow nextDue;

  const _RecordPaymentSheet({required this.orderId, required this.nextDue});

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  static const _methods = ['By Hand', 'JazzCash', 'Easypaisa', 'Bank'];

  late final TextEditingController _amountCtrl;
  late final TextEditingController _referenceCtrl;
  late final TextEditingController _notesCtrl;
  String? _method;
  File? _receipt;
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.nextDue.installmentPrice.toString(),
    );
    _referenceCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
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

  Future<void> _pickDate() async {
    final c = context.sellerColors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: c.accent,
                onPrimary: c.onAccent,
                surface: c.surface,
                onSurface: c.textPrimary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      SnackbarService().showErrorSnackBar('Enter a valid instalment amount.');
      return;
    }
    if (_method == null) {
      SnackbarService().showErrorSnackBar('Please select a payment method.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(sellerInstalmentsRepositoryProvider).payInstalment(
            orderId: widget.orderId,
            instalmentPrice: amount.toString(),
            paymentMethod: _method!,
            receipt: _receipt,
          );
      if (!mounted) return;
      Navigator.pop(
        context,
        _RecordPaymentResult(
          paymentDate: _paymentDate,
          referenceNo: _referenceCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final nextDue = widget.nextDue;

    return _PaySheetShell(
      title: 'Record Payment',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: AppRadius.brSm,
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                SellerIconBadge(
                  icon: Icons.receipt_long_rounded,
                  tone: c.accentTone,
                  size: 38,
                  iconSize: 19,
                ),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${nextDue.month} • ${nextDue.type}',
                        style: text.bodyLg.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Gap.v(2),
                      Text(
                        'Due ${nextDue.formattedPrice} on ${nextDue.formattedDate}',
                        style: text.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.md),
          Text('Amount collected', style: text.label),
          const Gap.v(AppSpace.xs),
          _PayDecimalField(
            controller: _amountCtrl,
            label: 'Instalment amount',
            enabled: !_saving,
          ),
          const Gap.v(AppSpace.md),
          Text('Payment method', style: text.label),
          const Gap.v(AppSpace.xs),
          _PayMethodChips(
            methods: _methods,
            selected: _method,
            enabled: !_saving,
            onChanged: (m) => setState(() => _method = m),
          ),
          const Gap.v(AppSpace.md),
          Text('Payment date', style: text.label),
          const Gap.v(AppSpace.xs),
          InkWell(
            onTap: _saving ? null : _pickDate,
            borderRadius: AppRadius.brMd,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm + 2,
              ),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: c.accent),
                  const Gap.h(AppSpace.xs),
                  Text(_formatDate(_paymentDate), style: text.bodySm),
                ],
              ),
            ),
          ),
          const Gap.v(AppSpace.md),
          Text('Reference no. (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          TextField(
            controller: _referenceCtrl,
            enabled: !_saving,
            style: text.body,
            cursorColor: c.accent,
            decoration: _payInputDecoration(context, 'Transaction / reference no.'),
          ),
          const Gap.v(AppSpace.md),
          Text('Notes (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          TextField(
            controller: _notesCtrl,
            enabled: !_saving,
            maxLines: 3,
            style: text.body,
            cursorColor: c.accent,
            decoration: _payInputDecoration(context, 'Add a note for this payment'),
          ),
          const Gap.v(AppSpace.md),
          Text('Receipt (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _PayReceiptPicker(
            receipt: _receipt,
            onPick: _saving ? () {} : _pickReceipt,
            onClear: () => setState(() => _receipt = null),
          ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Confirm Payment',
            icon: Icons.payments_rounded,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

// ═══════════════════════════════════════════════════════════
//  SHARED SHEET WIDGETS — mirrors the Customer Details pay sheet
// ═══════════════════════════════════════════════════════════
class _PaySheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _PaySheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpace.sm,
        right: AppSpace.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.sm,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.lg,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brXl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: text.titleMd)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  ),
                ],
              ),
              const Gap.v(AppSpace.xs),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PayMethodChips extends StatelessWidget {
  final List<String> methods;
  final String? selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _PayMethodChips({
    required this.methods,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: methods.map((m) {
        final isSelected = m == selected;
        return GestureDetector(
          onTap: enabled ? () => onChanged(m) : null,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected ? c.accent : c.surface,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: isSelected ? c.accent : c.border),
            ),
            child: Text(
              m,
              style: text.labelSm.copyWith(
                color: isSelected ? c.onAccent : c.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _PayDecimalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;

  const _PayDecimalField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: text.body,
      cursorColor: c.accent,
      decoration: _payInputDecoration(context, label),
    );
  }
}

class _PayReceiptPicker extends StatelessWidget {
  final File? receipt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _PayReceiptPicker({
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
              'Upload image',
              style: text.bodySm.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _payInputDecoration(BuildContext context, String label) {
  final c = context.sellerColors;
  final text = context.sellerText;
  return InputDecoration(
    labelText: label,
    labelStyle: text.bodySm,
    floatingLabelStyle: text.labelSm.copyWith(color: c.accent),
    filled: true,
    fillColor: c.surfaceAlt,
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
  );
}

// ═══════════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════════
String _cleanError(Object error) {
  final msg = error.toString().replaceFirst('Exception: ', '').trim();
  return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
}
