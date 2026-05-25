import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/instalments/model/seller_instalments_model.dart';
import 'package:atompro/features/seller/instalments/repository/seller_instalments_repository.dart';
import 'package:atompro/features/seller/instalments/viewmodel/seller_instalments_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class _I {
  static const bg = Color(0xFFF4F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFE);
  static const brand = Color(0xFF3B5BDB);
  static const brandDark = Color(0xFF1A2980);
  static const text = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E8F5);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

class SellerInstalmentsScreen extends ConsumerStatefulWidget {
  const SellerInstalmentsScreen({super.key});

  @override
  ConsumerState<SellerInstalmentsScreen> createState() =>
      _SellerInstalmentsScreenState();
}

class _SellerInstalmentsScreenState
    extends ConsumerState<SellerInstalmentsScreen> {
  String? _status;
  int _page = 1;
  String _search = '';
  final _searchCtrl = TextEditingController();

  SellerInstalmentsQuery get _query =>
      SellerInstalmentsQuery(page: _page, status: _status);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setStatus(String? status) {
    if (_status == status) return;
    setState(() {
      _status = status;
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
          .getExportUrl(status: _status);
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
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayInstalmentSheet(item: item),
    );
    if (changed == true) {
      ref.invalidate(sellerInstalmentsProvider(_query));
    }
  }

  Future<void> _showOrderLedgerSheet(_InstalmentOrderGroup group) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderLedgerSheet(
        group: group,
        onPay: _showPaymentSheet,
        onInvoice: _openInvoice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerInstalmentsProvider(_query));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _I.bg,
        body: SafeArea(
          child: RefreshIndicator(
            color: _I.brand,
            onRefresh: () async {
              ref.invalidate(sellerInstalmentsProvider(_query));
              await ref.read(sellerInstalmentsProvider(_query).future);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 118),
              children: [
                _Header(onTopup: _openTopupPdf, onExport: _openExport),
                const SizedBox(height: 14),
                _StatusTabs(selected: _status, onChanged: _setStatus),
                const SizedBox(height: 12),
                _SearchBox(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 14),
                state.when(
                  loading: () => const _InstalmentSkeleton(),
                  error: (error, _) => _ErrorCard(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerInstalmentsProvider(_query)),
                  ),
                  data: (data) {
                    final items = _filter(data.instalments, _search);
                    final orderGroups = _groupByOrder(items, data.customers);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TotalsStrip(data: data),
                        const SizedBox(height: 12),
                        _RangeStrip(
                          total: data.pagination.total,
                          from: data.pagination.from,
                          to: data.pagination.to,
                        ),
                        const SizedBox(height: 12),
                        if (orderGroups.isEmpty)
                          const _EmptyState()
                        else
                          ...orderGroups.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OrderLedgerCard(
                                group: group,
                                onTap: () => _showOrderLedgerSheet(group),
                                onInvoice: () => _openInvoice(group.latest),
                              ),
                            ),
                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onTopup;
  final VoidCallback onExport;

  const _Header({required this.onTopup, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_I.brandDark, _I.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _I.brand.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instalments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Track recovery and collect payments',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            tooltip: 'Export instalments',
            icon: Icons.download_outlined,
            onTap: onExport,
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            tooltip: 'Top-up PDF',
            icon: Icons.picture_as_pdf_outlined,
            onTap: onTopup,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _StatusTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = <String?>[null, 'Unpaid', 'Paid'];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: Row(
        children: options.map((status) {
          final active = selected == status;
          final label = status ?? 'All';
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(status),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? _I.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : _I.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search current page by month, product, order',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: _I.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _I.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _I.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _I.brand, width: 1.4),
        ),
      ),
    );
  }
}

class _TotalsStrip extends StatelessWidget {
  final SellerInstalmentsResponse data;

  const _TotalsStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TotalCard(
            label: 'Paid',
            value: data.formattedTotalPaid,
            color: _I.success,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TotalCard(
            label: 'Unpaid',
            value: data.formattedTotalUnpaid,
            color: _I.warning,
            icon: Icons.schedule_outlined,
          ),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TotalCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _I.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _I.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeStrip extends StatelessWidget {
  final int total;
  final int? from;
  final int? to;

  const _RangeStrip({
    required this.total,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Records',
              style: TextStyle(
                color: _I.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}-${to ?? 0} of $total',
            style: const TextStyle(
              color: _I.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final colors = _statusColors(group.statusLabel);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _I.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _I.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.receipt_long_outlined, color: colors.fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${group.order.id}',
                        style: const TextStyle(
                          color: _I.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.order.productTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _I.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: group.statusLabel,
                  fg: colors.fg,
                  bg: colors.bg,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _MiniInfo(
                    label: 'Customer',
                    value: group.customerName,
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniInfo(
                    label: 'Next Due',
                    value: group.nextDue?.formattedDate ?? 'Cleared',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniInfo(
                    label: 'Pending',
                    value: group.formattedPending,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniInfo(
                    label: 'Ledger',
                    value: '${group.paidCount}/${group.items.length} paid',
                    icon: Icons.list_alt_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onInvoice,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                    label: const Text('Invoice'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _I.brand,
                      side: const BorderSide(color: _I.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 17),
                    label: const Text('Ledger'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _I.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
    final colors = _statusColors(item.status);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _I.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.payments_outlined, color: colors.fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.month,
                      style: const TextStyle(
                        color: _I.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.productTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _I.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: item.status, fg: colors.fg, bg: colors.bg),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Due',
                  value: item.formattedPrice,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInfo(
                  label: 'Date',
                  value: item.formattedDate,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onInvoice,
                  icon: const Icon(Icons.receipt_long_outlined, size: 17),
                  label: const Text('Invoice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _I.brand,
                    side: const BorderSide(color: _I.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPay,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 17,
                  ),
                  label: Text(item.paid ? 'Paid' : 'Pay'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _I.brand,
                    disabledBackgroundColor: _I.success.withValues(alpha: 0.2),
                    disabledForegroundColor: _I.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _I.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _I.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _I.brand),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _I.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _I.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _I.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _I.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.order.productTitle,
                  style: const TextStyle(
                    color: _I.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfo(
                        label: 'Customer',
                        value: group.customerName,
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniInfo(
                        label: 'Deal',
                        value: group.order.formattedTotalDealPrice,
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...group.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
    return _SheetShell(
      title: 'Pay Instalment',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _PaymentSummary(item: widget.item),
            const SizedBox(height: 12),
            _SheetTextField(
              controller: _amount,
              label: 'Instalment Amount',
              enabled: !_saving,
              keyboardType: TextInputType.number,
              validator: (value) {
                final amount = int.tryParse(value?.trim() ?? '') ?? 0;
                if (amount <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: _sheetDecoration('Payment Method'),
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickReceipt,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _receipt == null ? 'Attach Receipt' : 'Receipt Added',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: _I.brand,
                side: const BorderSide(color: _I.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SheetButton(
              label: 'Submit Payment',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final SellerInstalment item;

  const _PaymentSummary({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _I.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _I.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: _I.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${item.month} • ${item.productTitle}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _I.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: _I.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _I.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: _I.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        decoration: _sheetDecoration(label),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: _I.brand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _StatusPill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Previous'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '${pagination.currentPage}/${pagination.lastPage}',
            style: const TextStyle(
              color: _I.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Next'),
          ),
        ),
      ],
    );
  }
}

class _InstalmentSkeleton extends StatelessWidget {
  const _InstalmentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 178,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _I.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _I.border),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _I.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _I.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _I.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.payments_outlined, color: _I.muted, size: 32),
          SizedBox(height: 10),
          Text(
            'No instalments found.',
            style: TextStyle(color: _I.text, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

InputDecoration _sheetDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _I.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _I.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _I.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _I.brand, width: 1.4),
    ),
  );
}

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

List<SellerInstalment> _filter(List<SellerInstalment> items, String query) {
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

({Color fg, Color bg}) _statusColors(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('paid') && !lower.contains('unpaid')) {
    return (fg: _I.success, bg: _I.success.withValues(alpha: 0.12));
  }
  if (lower.contains('unpaid') || lower.contains('pending')) {
    return (fg: _I.warning, bg: _I.warning.withValues(alpha: 0.12));
  }
  if (lower.contains('cancel') || lower.contains('lost')) {
    return (fg: _I.danger, bg: _I.danger.withValues(alpha: 0.12));
  }
  return (fg: _I.brand, bg: _I.brand.withValues(alpha: 0.12));
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
