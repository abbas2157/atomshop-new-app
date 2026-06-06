// ============================================================
//  seller_instalments_screen.dart  —  Design System v2
//
//  Reskinned onto the Seller Design System: unified tokens,
//  SellerColors, SellerGradientHeader, SellerCard, SellerKpiCard,
//  SellerSegmentedTabs, SellerSearchField, SellerStatusPill, and
//  all state/skeleton components.  Business logic, providers,
//  model fields, pay-sheet flow and ledger-detail sheet are
//  100% preserved.
// ============================================================

import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:atompro/features/seller/instalments/viewmodel/seller_instalments_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Tab enum ─────────────────────────────────────────────────────────────
enum _StatusTab { all, unpaid, paid }

extension _StatusTabX on _StatusTab {
  String get label => switch (this) {
    _StatusTab.all => 'All',
    _StatusTab.unpaid => 'Unpaid',
    _StatusTab.paid => 'Paid',
  };

  String? get apiValue => switch (this) {
    _StatusTab.all => null,
    _StatusTab.unpaid => 'Unpaid',
    _StatusTab.paid => 'Paid',
  };
}

// ═══════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════
class SellerInstalmentsScreen extends ConsumerStatefulWidget {
  const SellerInstalmentsScreen({super.key});

  @override
  ConsumerState<SellerInstalmentsScreen> createState() =>
      _SellerInstalmentsScreenState();
}

class _SellerInstalmentsScreenState
    extends ConsumerState<SellerInstalmentsScreen> {
  _StatusTab _tab = _StatusTab.all;
  int _page = 1;
  String _search = '';
  final _searchCtrl = TextEditingController();

  SellerInstalmentsQuery get _query =>
      SellerInstalmentsQuery(page: _page, status: _tab.apiValue);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setTab(_StatusTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _page = 1;
    });
  }

  Future<void> _openTopupPdf() async {
    await _openRepositoryUrl(
      () => ref.read(sellerInstalmentsRepositoryProvider).getTopupPdfUrl(),
    );
  }

  Future<void> _openExport() async {
    try {
      final path = await ref
          .read(sellerInstalmentsRepositoryProvider)
          .getExportUrl(status: _tab.apiValue);
      await SellerFileService.openLocalFile(path);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  Future<void> _openInvoice(SellerInstalment item) async {
    if (item.order.uuid == 'Not available') {
      SnackbarService().showErrorSnackBar('Invoice is unavailable.');
      return;
    }
    await _openRepositoryUrl(
      () => ref
          .read(sellerInstalmentsRepositoryProvider)
          .getInvoiceUrl(item.order.uuid),
    );
  }

  Future<void> _openRepositoryUrl(Future<String> Function() loader) async {
    try {
      final url = await loader();
      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        SnackbarService().showErrorSnackBar('Unable to open link.');
      }
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  Future<void> _showPaymentSheet(SellerInstalment item) async {
    final dark = context.sellerIsDark;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: Builder(
          builder: (ctx) => _PayInstalmentSheet(item: item),
        ),
      ),
    );
    if (changed == true) {
      ref.invalidate(sellerInstalmentsProvider(_query));
    }
  }

  Future<void> _showOrderLedgerSheet(_InstalmentOrderGroup group) async {
    final dark = context.sellerIsDark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: Builder(
          builder: (ctx) => _OrderLedgerSheet(
            group: group,
            onPay: _showPaymentSheet,
            onInvoice: _openInvoice,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerInstalmentsProvider(_query));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            SellerGradientHeader(
              leading: SellerIconBadge(
                icon: Icons.payments_rounded,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.18),
                  border: Colors.white.withValues(alpha: 0.2),
                ),
                size: 44,
                iconSize: 22,
                radius: AppRadius.md,
              ),
              title: 'Instalments',
              subtitle: 'Track recovery and collect payments',
              actions: [
                SellerHeaderIconButton(
                  icon: Icons.download_outlined,
                  onTap: _openExport,
                  tooltip: 'Export instalments',
                ),
                SellerHeaderIconButton(
                  icon: Icons.picture_as_pdf_outlined,
                  onTap: _openTopupPdf,
                  tooltip: 'Top-up PDF',
                ),
              ],
            ),
            // ── Tab strip ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.md,
                AppSpace.md,
                AppSpace.xs,
              ),
              child: SellerSegmentedTabs(
                labels: _StatusTab.values.map((t) => t.label).toList(),
                selectedIndex: _tab.index,
                onChanged: (i) => _setTab(_StatusTab.values[i]),
              ),
            ),
            // ── Search ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.xs,
                AppSpace.md,
                AppSpace.xs,
              ),
              child: SellerSearchField(
                controller: _searchCtrl,
                hint: 'Search by month, product, order…',
                onChanged: (v) => setState(() => _search = v),
                onClear: () => setState(() => _search = ''),
              ),
            ),
            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerInstalmentsProvider(_query));
                  await ref.read(sellerInstalmentsProvider(_query).future);
                },
                child: state.when(
                  loading: () => const SellerListSkeleton(count: 5, itemHeight: 200),
                  error: (error, _) => SellerErrorState(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerInstalmentsProvider(_query)),
                  ),
                  data: (data) {
                    final items = _filter(data.instalments, _search);
                    final orderGroups = _groupByOrder(items, data.customers);
                    return ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: AppInsets.pageWithNav,
                      children: [
                        // KPI strip
                        _EvenGrid(
                          children: [
                            SellerKpiCard(
                              label: 'Paid',
                              value: data.formattedTotalPaid,
                              icon: Icons.check_circle_outline_rounded,
                              tone: c.successTone,
                            ),
                            SellerKpiCard(
                              label: 'Unpaid',
                              value: data.formattedTotalUnpaid,
                              icon: Icons.schedule_rounded,
                              tone: c.warningTone,
                            ),
                          ],
                        ),
                        const Gap.v(AppSpace.sm),
                        // Range strip
                        _RangeRow(
                          total: data.pagination.total,
                          from: data.pagination.from,
                          to: data.pagination.to,
                        ),
                        const Gap.v(AppSpace.sm),
                        // List
                        if (orderGroups.isEmpty)
                          const SellerEmptyState(
                            icon: Icons.payments_outlined,
                            title: 'No instalments found',
                            message:
                                'There are no records matching the current filter.',
                          )
                        else
                          for (final group in orderGroups) ...[
                            _OrderLedgerCard(
                              group: group,
                              onTap: () => _showOrderLedgerSheet(group),
                              onInvoice: () => _openInvoice(group.latest),
                            ),
                            const Gap.v(AppSpace.sm),
                          ],
                        // Pagination
                        _PaginationBar(
                          pagination: data.pagination,
                          onPrevious: data.pagination.hasPrevious
                              ? () => setState(() => _page--)
                              : null,
                          onNext: data.pagination.hasNext
                              ? () => setState(() => _page++)
                              : null,
                        ),
                      ],
                    );
                  },
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
//  RANGE ROW
// ═══════════════════════════════════════════════════════════
class _RangeRow extends StatelessWidget {
  final int total;
  final int? from;
  final int? to;

  const _RangeRow({
    required this.total,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final rangeText =
        total == 0 ? '0 records' : '${from ?? 0}–${to ?? 0} of $total';

    return SellerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.format_list_bulleted_rounded,
              size: 16, color: c.textTertiary),
          const Gap.h(AppSpace.xs),
          Expanded(child: Text('Records', style: text.bodyLg)),
          Text(rangeText, style: text.caption),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ORDER LEDGER CARD (list item)
// ═══════════════════════════════════════════════════════════
class _OrderLedgerCard extends StatelessWidget {
  final _InstalmentOrderGroup group;
  final VoidCallback onTap;
  final VoidCallback onInvoice;

  const _OrderLedgerCard({
    required this.group,
    required this.onTap,
    required this.onInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      accentEdge: SellerStatus.toneFor(group.statusLabel, c).fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.receipt_long_rounded,
                tone: SellerStatus.toneFor(group.statusLabel, c),
                size: 44,
                iconSize: 22,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${group.order.id}',
                      style: text.titleSm,
                    ),
                    const Gap.v(AppSpace.xxs),
                    Text(
                      group.order.productTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySm,
                    ),
                  ],
                ),
              ),
              const Gap.h(AppSpace.xs),
              SellerStatusPill(label: group.statusLabel),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.sm),
          // ── Info grid ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Customer',
                  value: group.customerName,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Next Due',
                  value: group.nextDue?.formattedDate ?? 'Cleared',
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Pending',
                  value: group.formattedPending,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _InfoTile(
                  icon: Icons.list_alt_rounded,
                  label: 'Ledger',
                  value: '${group.paidCount}/${group.items.length} paid',
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          // ── Actions ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SellerButton.secondary(
                  label: 'Invoice',
                  icon: Icons.picture_as_pdf_outlined,
                  size: SellerButtonSize.small,
                  onPressed: onInvoice,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: SellerButton(
                  label: 'Ledger',
                  icon: Icons.visibility_outlined,
                  size: SellerButtonSize.small,
                  onPressed: onTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  INSTALMENT CARD (inside ledger sheet)
// ═══════════════════════════════════════════════════════════
class _InstalmentCard extends StatelessWidget {
  final SellerInstalment item;
  final VoidCallback? onPay;
  final VoidCallback onInvoice;

  const _InstalmentCard({
    required this.item,
    required this.onPay,
    required this.onInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = SellerStatus.toneFor(item.status, c);

    return SellerCard(
      padding: const EdgeInsets.all(AppSpace.md),
      accentEdge: tone.fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.payments_rounded,
                tone: tone,
                size: 44,
                iconSize: 22,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.month, style: text.titleSm),
                    const Gap.v(AppSpace.xxs),
                    Text(
                      item.productTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySm,
                    ),
                  ],
                ),
              ),
              const Gap.h(AppSpace.xs),
              SellerStatusPill(label: item.status),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Due',
                  value: item.formattedPrice,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: item.formattedDate,
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: SellerButton.secondary(
                  label: 'Invoice',
                  icon: Icons.receipt_long_outlined,
                  size: SellerButtonSize.small,
                  onPressed: onInvoice,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: SellerButton(
                  label: item.paid ? 'Paid' : 'Pay',
                  icon: Icons.check_circle_outline_rounded,
                  size: SellerButtonSize.small,
                  onPressed: onPay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  INFO TILE (shared mini detail chip)
// ═══════════════════════════════════════════════════════════
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.accent),
          const Gap.h(AppSpace.xxs + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.caption),
                const Gap.v(1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSm.copyWith(color: c.textPrimary),
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
//  ORDER LEDGER SHEET
// ═══════════════════════════════════════════════════════════
class _OrderLedgerSheet extends StatelessWidget {
  final _InstalmentOrderGroup group;
  final Future<void> Function(SellerInstalment item) onPay;
  final Future<void> Function(SellerInstalment item) onInvoice;

  const _OrderLedgerSheet({
    required this.group,
    required this.onPay,
    required this.onInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Order #${group.order.id} Ledger',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order summary card
          SellerCard(
            color: context.sellerColors.surfaceAlt,
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.order.productTitle,
                    style: context.sellerText.titleSm),
                const Gap.v(AppSpace.xs),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Customer',
                        value: group.customerName,
                      ),
                    ),
                    const Gap.h(AppSpace.xs),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Deal',
                        value: group.order.formattedTotalDealPrice,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.sm),
          ...group.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: _InstalmentCard(
                item: item,
                onPay: item.canPay ? () => onPay(item) : null,
                onInvoice: () => onInvoice(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAY INSTALMENT SHEET
// ═══════════════════════════════════════════════════════════
class _PayInstalmentSheet extends ConsumerStatefulWidget {
  final SellerInstalment item;

  const _PayInstalmentSheet({required this.item});

  @override
  ConsumerState<_PayInstalmentSheet> createState() =>
      _PayInstalmentSheetState();
}

class _PayInstalmentSheetState extends ConsumerState<_PayInstalmentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  String _method = 'Cash';
  File? _receipt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.item.installmentPrice.toString(),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
    );
    if (picked == null) return;
    setState(() => _receipt = File(picked.path));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(sellerInstalmentsRepositoryProvider)
          .payInstalment(
            orderId: widget.item.orderId,
            instalmentPrice: _amount.text.trim(),
            paymentMethod: _method,
            receipt: _receipt,
          );
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar('Instalment paid.');
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return _SheetShell(
      title: 'Pay Instalment',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary
            SellerCard(
              color: c.surfaceAlt,
              elevated: false,
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
                    child: Text(
                      '${widget.item.month} • ${widget.item.productTitle}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLg,
                    ),
                  ),
                ],
              ),
            ),
            const Gap.v(AppSpace.sm),
            // Amount
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: TextFormField(
                controller: _amount,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = int.tryParse(value?.trim() ?? '') ?? 0;
                  if (amount <= 0) return 'Enter a valid amount';
                  return null;
                },
                style: text.body,
                decoration: _sheetInputDecoration(c, 'Instalment Amount'),
              ),
            ),
            // Method
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: _sheetInputDecoration(c, 'Payment Method'),
              style: text.body.copyWith(color: c.textPrimary),
              dropdownColor: c.surface,
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                DropdownMenuItem(value: 'EasyPaisa', child: Text('EasyPaisa')),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _method = value ?? _method),
            ),
            const Gap.v(AppSpace.sm),
            // Receipt picker
            SellerButton.secondary(
              label: _receipt == null ? 'Attach Receipt' : 'Receipt Added ✓',
              icon: Icons.image_outlined,
              onPressed: _saving ? null : _pickReceipt,
            ),
            const Gap.v(AppSpace.md),
            // Submit
            SellerButton(
              label: 'Submit Payment',
              icon: Icons.save_outlined,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SHEET SHELL — shared bottom sheet container
// ═══════════════════════════════════════════════════════════
class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.sheet,
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.lg + MediaQuery.of(context).padding.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
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
                Text(title, style: text.titleMd),
                const Gap.v(AppSpace.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGINATION BAR
// ═══════════════════════════════════════════════════════════
class _PaginationBar extends StatelessWidget {
  final SellerInstalmentsPagination pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (pagination.lastPage <= 1) return const SizedBox.shrink();

    final text = context.sellerText;
    final c = context.sellerColors;

    return Row(
      children: [
        Expanded(
          child: SellerButton.secondary(
            label: 'Previous',
            icon: Icons.chevron_left_rounded,
            size: SellerButtonSize.small,
            onPressed: onPrevious,
          ),
        ),
        const Gap.h(AppSpace.sm),
        Text(
          '${pagination.currentPage}/${pagination.lastPage}',
          style: text.labelSm.copyWith(color: c.textTertiary),
        ),
        const Gap.h(AppSpace.sm),
        Expanded(
          child: SellerButton.secondary(
            label: 'Next',
            trailingIcon: Icons.chevron_right_rounded,
            size: SellerButtonSize.small,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  EVEN GRID — 2-column equal-width layout helper
// ═══════════════════════════════════════════════════════════
class _EvenGrid extends StatelessWidget {
  final List<Widget> children;

  const _EvenGrid({required this.children});

  static const int columns = 2;

  static const double _spacing = AppSpace.sm;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var j = 0; j < columns; j++) {
        final index = i + j;
        cells.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
        if (j < columns - 1) cells.add(const Gap.h(_spacing));
      }
      if (rows.isNotEmpty) rows.add(const Gap.v(_spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// ═══════════════════════════════════════════════════════════
//  DATA HELPERS — grouping, formatting, filtering
// ═══════════════════════════════════════════════════════════

class _InstalmentOrderGroup {
  final SellerInstalmentOrder order;
  final String customerName;
  final List<SellerInstalment> items;

  const _InstalmentOrderGroup({
    required this.order,
    required this.customerName,
    required this.items,
  });

  SellerInstalment get latest => items.first;
  int get paidCount => items.where((item) => item.paid).length;
  int get pendingCount => items.length - paidCount;
  String get statusLabel => pendingCount == 0 ? 'Paid' : 'Unpaid';

  SellerInstalment? get nextDue {
    for (final item in items) {
      if (item.canPay) return item;
    }
    return null;
  }

  int get pendingAmount => items.fold<int>(0, (sum, item) {
    if (!item.canPay) return sum;
    final due = item.installmentPrice - item.installmentPaidPrice;
    return sum + (due > 0 ? due : item.installmentPrice);
  });

  String get formattedPending => _moneyAmount(pendingAmount);
}

List<_InstalmentOrderGroup> _groupByOrder(
  List<SellerInstalment> items,
  List<SellerInstalmentCustomer> customers,
) {
  final customerNames = {
    for (final customer in customers) customer.id: customer.name,
  };
  final groups = <int, List<SellerInstalment>>{};
  for (final item in items) {
    groups.putIfAbsent(item.orderId, () => <SellerInstalment>[]).add(item);
  }

  final orderGroups = groups.values.map((groupItems) {
    groupItems.sort((a, b) => a.installmentDate.compareTo(b.installmentDate));
    final first = groupItems.first;
    return _InstalmentOrderGroup(
      order: first.order,
      customerName: customerNames[first.userId] ?? 'Customer #${first.userId}',
      items: List.unmodifiable(groupItems),
    );
  }).toList();

  orderGroups.sort((a, b) {
    final aDue = a.nextDue?.installmentDate ?? a.latest.installmentDate;
    final bDue = b.nextDue?.installmentDate ?? b.latest.installmentDate;
    return aDue.compareTo(bDue);
  });
  return orderGroups;
}

String _moneyAmount(int amount) {
  final raw = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return 'Rs. ${buffer.toString()}';
}

List<SellerInstalment> _filter(
  List<SellerInstalment> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items
      .where((item) {
        return item.month.toLowerCase().contains(q) ||
            item.productTitle.toLowerCase().contains(q) ||
            item.status.toLowerCase().contains(q) ||
            item.orderId.toString().contains(q) ||
            item.order.productPrNumber.toLowerCase().contains(q);
      })
      .toList(growable: false);
}

String _cleanError(Object error) {
  final msg = error.toString().replaceFirst('Exception: ', '').trim();
  return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
}

InputDecoration _sheetInputDecoration(SellerColors c, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: c.textSecondary),
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
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.danger, width: 1.6),
    ),
  );
}
