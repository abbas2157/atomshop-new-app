import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/leads/model/seller_leads_model.dart';
import 'package:atompro/features/seller/leads/repository/seller_leads_repository.dart';
import 'package:atompro/features/seller/leads/viewmodel/seller_leads_viewmodel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class _L {
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
  static const info = Color(0xFF06B6D4);
}

class SellerLeadsScreen extends ConsumerStatefulWidget {
  const SellerLeadsScreen({super.key});

  @override
  ConsumerState<SellerLeadsScreen> createState() => _SellerLeadsScreenState();
}

class _SellerLeadsScreenState extends ConsumerState<SellerLeadsScreen> {
  SellerLeadScope _scope = SellerLeadScope.mine;
  String? _status;
  int _page = 1;
  String _search = '';
  final _searchCtrl = TextEditingController();

  SellerLeadsQuery get _query =>
      SellerLeadsQuery(scope: _scope, page: _page, status: _status);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setScope(SellerLeadScope scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _status = null;
      _page = 1;
    });
  }

  void _setStatus(String? status) {
    setState(() {
      _status = status;
      _page = 1;
    });
  }

  Future<void> _showStatusSheet(SellerLead lead) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeadStatusSheet(lead: lead),
    );
    if (changed == true) ref.invalidate(sellerLeadsBundleProvider(_query));
  }

  Future<void> _showCustomOrderSheet(SellerLead lead) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeadCustomOrderSheet(lead: lead),
    );
    if (changed == true) ref.invalidate(sellerLeadsBundleProvider(_query));
  }

  Future<void> _importLeads() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );
      final path = picked?.files.single.path;
      if (path == null) return;
      await ref.read(sellerLeadsRepositoryProvider).importLeads(File(path));
      ref.invalidate(sellerLeadsBundleProvider(_query));
      SnackbarService().showSuccessSnackBar('Leads imported.');
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  Future<void> _openImportSample() async {
    try {
      final path = await ref
          .read(sellerLeadsRepositoryProvider)
          .downloadImportSample();
      await SellerFileService.openLocalFile(path);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerLeadsBundleProvider(_query));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _L.bg,
        body: SafeArea(
          child: RefreshIndicator(
            color: _L.brand,
            onRefresh: () async {
              ref.invalidate(sellerLeadsBundleProvider(_query));
              await ref.read(sellerLeadsBundleProvider(_query).future);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 118),
              children: [
                _Header(
                  state: state,
                  onImport: _importLeads,
                  onSample: _openImportSample,
                ),
                const SizedBox(height: 14),
                _ScopeTabs(selected: _scope, onChanged: _setScope),
                const SizedBox(height: 12),
                state.maybeWhen(
                  data: (bundle) => _StatusChips(
                    selected: _status,
                    counts: bundle.statusCounts,
                    onChanged: _setStatus,
                  ),
                  orElse: () => _StatusChips(
                    selected: _status,
                    counts: const {},
                    onChanged: _setStatus,
                  ),
                ),
                const SizedBox(height: 12),
                _SearchBox(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 14),
                state.when(
                  loading: () => const _LeadSkeleton(),
                  error: (error, _) => _ErrorCard(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerLeadsBundleProvider(_query)),
                  ),
                  data: (bundle) {
                    final leads = _filter(bundle.leads.leads, _search);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RangeStrip(
                          total: bundle.leads.pagination.total,
                          from: bundle.leads.pagination.from,
                          to: bundle.leads.pagination.to,
                          label: _scope.label,
                        ),
                        const SizedBox(height: 12),
                        if (leads.isEmpty)
                          const _EmptyState()
                        else
                          ...leads.map(
                            (lead) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _LeadCard(
                                lead: lead,
                                onStatus: () => _showStatusSheet(lead),
                                onCustomOrder: () =>
                                    _showCustomOrderSheet(lead),
                              ),
                            ),
                          ),
                        _PaginationBar(
                          pagination: bundle.leads.pagination,
                          onPrevious: bundle.leads.pagination.hasPrevious
                              ? () => setState(() => _page--)
                              : null,
                          onNext: bundle.leads.pagination.hasNext
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
  final AsyncValue<SellerLeadsBundle> state;
  final VoidCallback onImport;
  final VoidCallback onSample;

  const _Header({
    required this.state,
    required this.onImport,
    required this.onSample,
  });

  @override
  Widget build(BuildContext context) {
    final count = state.asData?.value.newLeadsCount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_L.brandDark, _L.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _L.brand.withValues(alpha: 0.24),
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
              Icons.trending_up_rounded,
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
                  'Leads',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  count == null ? 'Manage sales pipeline' : '$count new leads',
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
            tooltip: 'Sample file',
            icon: Icons.download_outlined,
            onTap: onSample,
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            tooltip: 'Import leads',
            icon: Icons.upload_file_outlined,
            onTap: onImport,
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

class _ScopeTabs extends StatelessWidget {
  final SellerLeadScope selected;
  final ValueChanged<SellerLeadScope> onChanged;

  const _ScopeTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _L.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _L.border),
      ),
      child: Row(
        children: SellerLeadScope.values.map((scope) {
          final active = selected == scope;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(scope),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? _L.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  scope.shortLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : _L.muted,
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

class _StatusChips extends StatelessWidget {
  final String? selected;
  final Map<String, int> counts;
  final ValueChanged<String?> onChanged;

  const _StatusChips({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = <String?>[null, ...sellerLeadStatuses];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final active = selected == status;
          final label = status ?? 'All';
          final count = status == null ? null : counts[status];
          return ChoiceChip(
            selected: active,
            label: Text(count == null ? label : '$label $count'),
            onSelected: (_) => onChanged(status),
            selectedColor: _L.brand,
            labelStyle: TextStyle(
              color: active ? Colors.white : _L.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            side: const BorderSide(color: _L.border),
            backgroundColor: _L.surface,
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: statuses.length,
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
      decoration: InputDecoration(
        hintText: 'Search current page by name, phone, product',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: _L.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _L.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _L.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _L.brand, width: 1.4),
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final SellerLead lead;
  final VoidCallback onStatus;
  final VoidCallback onCustomOrder;

  const _LeadCard({
    required this.lead,
    required this.onStatus,
    required this.onCustomOrder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(lead.status);
    return Container(
      decoration: BoxDecoration(
        color: _L.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _L.border),
      ),
      // ClipRRect keeps the left strip within the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status-colored left accent strip
              Container(width: 4, color: colors.fg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + Status ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _L.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(label: lead.status, fg: colors.fg, bg: colors.bg),
            ],
          ),
          const SizedBox(height: 4),

          // ── Product title with label ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 13,
                color: _L.muted,
              ),
              const SizedBox(width: 4),
              const Text(
                'Product: ',
                style: TextStyle(
                  color: _L.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  lead.productTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _L.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _L.border),
          const SizedBox(height: 10),

          // ── Location ────────────────────────────────────────────────────
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: lead.location.isEmpty ? 'Location N/A' : lead.location,
          ),
          const SizedBox(height: 5),

          // ── Phone ───────────────────────────────────────────────────────
          _InfoRow(icon: Icons.phone_outlined, label: lead.phone),
          const SizedBox(height: 5),

          // ── Portal + Date ───────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.language_outlined, size: 13, color: _L.muted),
              const SizedBox(width: 4),
              Text(
                lead.portal,
                style: const TextStyle(
                  color: _L.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: _L.muted,
              ),
              const SizedBox(width: 4),
              Text(
                lead.formattedCreatedAt,
                style: const TextStyle(
                  color: _L.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Actions ─────────────────────────────────────────────────────
          if (!lead.status.toLowerCase().contains('custom'))
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStatus,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _L.brand,
                      side: const BorderSide(color: _L.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCustomOrder,
                    icon: const Icon(Icons.add_shopping_cart_outlined, size: 15),
                    label: const Text('Order'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _L.brand,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _L.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _L.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeadStatusSheet extends ConsumerStatefulWidget {
  final SellerLead lead;

  const _LeadStatusSheet({required this.lead});

  @override
  ConsumerState<_LeadStatusSheet> createState() => _LeadStatusSheetState();
}

class _LeadStatusSheetState extends ConsumerState<_LeadStatusSheet> {
  final _formKey = GlobalKey<FormState>();
  final _comments = TextEditingController();
  final _reason = TextEditingController();
  late String _status;
  bool _saving = false;

  bool get _isLost => _status == 'Lost';

  @override
  void initState() {
    super.initState();
    _status = sellerLeadStatuses.contains(widget.lead.status)
        ? widget.lead.status
        : sellerLeadStatuses.first;
  }

  @override
  void dispose() {
    _comments.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(sellerLeadsRepositoryProvider).updateLead(
            leadId: widget.lead.id,
            status: _status,
            reason: _isLost ? _reason.text.trim() : null,
            comments: _comments.text.trim().isEmpty
                ? null
                : _comments.text.trim(),
          );
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar('Lead updated successfully.');
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
      title: 'Update Lead Status',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: _sheetDecoration('Status'),
              items: sellerLeadStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value ?? _status),
            ),
            // Reason — only visible when status is Lost
            if (_isLost) ...[
              const SizedBox(height: 12),
              _SheetTextField(
                controller: _reason,
                label: 'Reason for Loss',
                enabled: !_saving,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a reason.'
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            _SheetTextField(
              controller: _comments,
              label: 'Comments (optional)',
              enabled: !_saving,
              maxLines: 3,
            ),
            _SheetButton(
              label: 'Save Status',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadCustomOrderSheet extends ConsumerStatefulWidget {
  final SellerLead lead;

  const _LeadCustomOrderSheet({required this.lead});

  @override
  ConsumerState<_LeadCustomOrderSheet> createState() =>
      _LeadCustomOrderSheetState();
}

class _LeadCustomOrderSheetState extends ConsumerState<_LeadCustomOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _productPrice = TextEditingController();
  final _advancePrice = TextEditingController();

  // Payload: user_type = "auth" | "guest"
  String _userType = 'auth';
  int _tenure = 6;
  double _monthlyPct = 4.0;

  // 0.1 → 6.0 in 0.1 steps (60 values), rounded to 1 decimal to avoid float drift
  static final List<double> _markupValues = List.generate(
    60,
    (i) => double.parse(((i + 1) * 0.1).toStringAsFixed(1)),
  );

  List<SellerLeadLookup> _cities = [];
  List<SellerLeadLookup> _areas = [];
  SellerLeadLookup? _city;
  SellerLeadLookup? _area;

  bool _loadingLookups = true;
  bool _loadingAreas = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final cities =
          await ref.read(sellerLeadsRepositoryProvider).getCities();
      if (!mounted) return;

      SellerLeadLookup? autoCity;
      if (widget.lead.cityId > 0) {
        try {
          autoCity = cities.firstWhere((c) => c.id == widget.lead.cityId);
        } catch (_) {}
      }

      setState(() {
        _cities = cities;
        _city = autoCity;
        _loadingLookups = false;
      });

      if (autoCity != null) {
        await _onCityChanged(autoCity,
            autoSelectAreaId: widget.lead.areaId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLookups = false);
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  Future<void> _onCityChanged(
    SellerLeadLookup? city, {
    int autoSelectAreaId = 0,
  }) async {
    setState(() {
      _city = city;
      _area = null;
      _areas = [];
      _loadingAreas = city != null;
    });
    if (city == null) return;
    try {
      final areas = await ref
          .read(sellerLeadsRepositoryProvider)
          .getAreasByCity(city.id);
      if (!mounted) return;
      SellerLeadLookup? autoArea;
      if (autoSelectAreaId > 0) {
        try {
          autoArea = areas.firstWhere((a) => a.id == autoSelectAreaId);
        } catch (_) {}
      }
      setState(() {
        _areas = areas;
        _area = autoArea;
        _loadingAreas = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  @override
  void dispose() {
    _productPrice.dispose();
    _advancePrice.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_city == null) {
      SnackbarService().showErrorSnackBar('Please select a city.');
      return;
    }
    if (_area == null) {
      SnackbarService().showErrorSnackBar('Please select an area.');
      return;
    }

    final productPrice = int.tryParse(_productPrice.text.trim()) ?? 0;
    final advancePrice = int.tryParse(_advancePrice.text.trim()) ?? 0;

    if (advancePrice >= productPrice) {
      SnackbarService().showErrorSnackBar(
          'Advance price must be less than product price.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(sellerLeadsRepositoryProvider).convertLeadToCustomOrder(
            leadId: widget.lead.id,
            userType: _userType,
            cityId: _city!.id,
            areaId: _area!.id,
            productPrice: productPrice,
            advancePrice: advancePrice,
            totalDealPrice: productPrice, // not sent but required by signature
            perMonthPercentage: _monthlyPct,
            installments: _tenure,
          );
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar(
          'Custom order created from lead.');
      Navigator.pop(context, true);
    } catch (e) {
      SnackbarService().showErrorSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _section(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 14, color: _L.brand),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: _L.brand,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loadingLookups) {
      return _SheetShell(
        title: 'Convert to Custom Order',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(color: _L.brand)),
        ),
      );
    }

    return _SheetShell(
      title: 'Convert to Custom Order',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Lead info ─────────────────────────────────────
            _LeadSummary(lead: widget.lead),
            const SizedBox(height: 20),

            // ── Customer Type ────────────────────────────────
            _section('Customer Type', Icons.person_outline_rounded),
            Row(
              children: [
                _TypeChip(
                  label: 'Registered',
                  icon: Icons.verified_user_outlined,
                  selected: _userType == 'auth',
                  onTap: _saving
                      ? null
                      : () => setState(() => _userType = 'auth'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Guest',
                  icon: Icons.person_outline_rounded,
                  selected: _userType == 'guest',
                  onTap: _saving
                      ? null
                      : () => setState(() => _userType = 'guest'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Location ──────────────────────────────────────
            _section('Location', Icons.location_on_outlined),

            // ── City (searchable) ────────────────────────────
            DropdownSearch<SellerLeadLookup>(
              items: (filter, _) => _cities
                  .where((c) =>
                      c.title.toLowerCase().contains(filter.toLowerCase()))
                  .toList(),
              selectedItem: _city,
              itemAsString: (c) => c.title,
              compareFn: (a, b) => a.id == b.id,
              enabled: !_saving,
              onSelected: (v) => _onCityChanged(v),
              validator: (v) => v == null ? 'Select a city.' : null,
              decoratorProps: DropDownDecoratorProps(
                decoration: _sheetDecoration('City *'),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: const TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search city…',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                  ),
                ),
                itemBuilder: (_, item, isSelected, x) => ListTile(
                  dense: true,
                  selected: isSelected,
                  title: Text(item.title,
                      overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                constraints: const BoxConstraints(maxHeight: 300),
              ),
            ),
            const SizedBox(height: 12),

            // ── Area (searchable, loads after city) ───────────
            if (_loadingAreas)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _L.brand),
                    ),
                    SizedBox(width: 8),
                    Text('Loading areas…',
                        style: TextStyle(color: _L.muted, fontSize: 12)),
                  ],
                ),
              )
            else
              DropdownSearch<SellerLeadLookup>(
                items: (filter, _) => _areas
                    .where((a) =>
                        a.title.toLowerCase().contains(filter.toLowerCase()))
                    .toList(),
                selectedItem: _area,
                itemAsString: (a) => a.title,
                compareFn: (a, b) => a.id == b.id,
                enabled: !_saving && _city != null,
                onSelected: (v) => setState(() => _area = v),
                validator: (v) => v == null ? 'Select an area.' : null,
                decoratorProps: DropDownDecoratorProps(
                  decoration: _sheetDecoration(
                    _city == null ? 'Area (select city first)' : 'Area *',
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search area…',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                    ),
                  ),
                  itemBuilder: (_, item, isSelected, x) => ListTile(
                    dense: true,
                    selected: isSelected,
                    title: Text(item.title,
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                ),
              ),
            const SizedBox(height: 20),

            // ── Pricing ───────────────────────────────────────
            _section('Pricing (PKR)', Icons.payments_outlined),
            Row(
              children: [
                Expanded(
                  child: _SheetTextField(
                    controller: _productPrice,
                    label: 'Product Price *',
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    validator: _positiveNumber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetTextField(
                    controller: _advancePrice,
                    label: 'Advance Price *',
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    validator: _positiveNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Plan ─────────────────────────────────────────
            _section('Installment Plan', Icons.calendar_today_outlined),
            DropdownButtonFormField<double>(
              initialValue:
                  _markupValues.contains(_monthlyPct) ? _monthlyPct : 4.0,
              decoration: _sheetDecoration('Monthly Markup %'),
              items: _markupValues
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child:
                            Text('${v % 1 == 0 ? v.toInt() : v}%'),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _monthlyPct = v ?? _monthlyPct),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tenure',
                  style: TextStyle(
                    color: _L.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _L.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_tenure months',
                    style: const TextStyle(
                      color: _L.brand,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _tenure.toDouble(),
              min: 3,
              max: 36,
              divisions: 33,
              label: '$_tenure mo.',
              activeColor: _L.brand,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _tenure = v.round()),
            ),
            const SizedBox(height: 18),

            _SheetButton(
              label: 'Create Custom Order',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _L.brand
                : _L.brand.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _L.brand
                  : _L.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? Colors.white : _L.brand),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _L.brand,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small label above a slider/section

class _LeadSummary extends StatelessWidget {
  final SellerLead lead;

  const _LeadSummary({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _L.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _L.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_search_outlined, color: _L.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${lead.fullName} • ${lead.productTitle}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _L.text,
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
          color: _L.surface,
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
                      color: _L.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: _L.text),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: 'Go back',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _L.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: _L.muted),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.maxLines = 1,
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
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
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
          backgroundColor: _L.brand,
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

class _RangeStrip extends StatelessWidget {
  final String label;
  final int total;
  final int? from;
  final int? to;

  const _RangeStrip({
    required this.label,
    required this.total,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _L.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _L.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _L.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            total == 0 ? '0 leads' : '${from ?? 0}-${to ?? 0} of $total',
            style: const TextStyle(
              color: _L.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final SellerLeadsPagination pagination;
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
              color: _L.muted,
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

class _LeadSkeleton extends StatelessWidget {
  const _LeadSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 190,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _L.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _L.border),
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
        color: _L.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _L.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _L.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _L.text, fontWeight: FontWeight.w700),
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
        color: _L.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _L.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_outlined, color: _L.muted, size: 32),
          SizedBox(height: 10),
          Text(
            'No leads found.',
            style: TextStyle(color: _L.text, fontWeight: FontWeight.w900),
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
    fillColor: _L.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _L.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _L.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _L.brand, width: 1.4),
    ),
  );
}

String? _positiveNumber(String? value) {
  final number = num.tryParse(value?.trim() ?? '') ?? 0;
  if (number <= 0) return 'Enter a valid number';
  return null;
}

List<SellerLead> _filter(List<SellerLead> leads, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return leads;
  return leads
      .where((lead) {
        return lead.fullName.toLowerCase().contains(q) ||
            lead.phone.toLowerCase().contains(q) ||
            lead.productTitle.toLowerCase().contains(q) ||
            lead.status.toLowerCase().contains(q);
      })
      .toList(growable: false);
}

({Color fg, Color bg}) _statusColors(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('won')) {
    return (fg: _L.success, bg: _L.success.withValues(alpha: 0.12));
  }
  if (lower.contains('lost') || lower.contains('no response')) {
    return (fg: _L.danger, bg: _L.danger.withValues(alpha: 0.12));
  }
  if (lower.contains('follow')) {
    return (fg: _L.warning, bg: _L.warning.withValues(alpha: 0.12));
  }
  if (lower.contains('contact')) {
    return (fg: _L.info, bg: _L.info.withValues(alpha: 0.12));
  }
  return (fg: _L.brand, bg: _L.brand.withValues(alpha: 0.12));
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
