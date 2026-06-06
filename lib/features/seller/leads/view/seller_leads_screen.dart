// ============================================================
//  seller_leads_screen.dart  —  v2 (Design System)
//
//  Rebuilt on the Seller Design System: unified tokens, colour
//  extension (light + dark), shared component library. All
//  business logic — providers, validators, city/area cascade,
//  pricing guards, convert-to-custom-order, import/download —
//  is 100% preserved.
// ============================================================

import 'dart:io';

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/core/services/seller_file_service.dart';
import 'package:atompro/features/seller/leads/model/seller_leads_model.dart';
import 'package:atompro/features/seller/leads/repository/seller_leads_repository.dart';
import 'package:atompro/features/seller/leads/viewmodel/seller_leads_viewmodel.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void _setScope(int index) {
    final scope = SellerLeadScope.values[index];
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _status = null;
      _page = 1;
    });
  }

  void _setStatus(int chipIndex) {
    // index 0 = "All" (null status), index 1..N = statuses
    final statuses = <String?>[null, ...sellerLeadStatuses];
    final chosen = statuses[chipIndex];
    setState(() {
      _status = chosen;
      _page = 1;
    });
  }

  Future<void> _showStatusSheet(SellerLead lead) async {
    final isDark = context.sellerIsDark;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: isDark ? SellerTheme.dark : SellerTheme.light,
        child: _LeadStatusSheet(lead: lead),
      ),
    );
    if (changed == true) ref.invalidate(sellerLeadsBundleProvider(_query));
  }

  Future<void> _showCustomOrderSheet(SellerLead lead) async {
    final isDark = context.sellerIsDark;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: isDark ? SellerTheme.dark : SellerTheme.light,
        child: _LeadCustomOrderSheet(lead: lead),
      ),
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
    final c = context.sellerColors;
    final state = ref.watch(sellerLeadsBundleProvider(_query));

    // Derive new leads count from the loaded state (null while loading)
    final newLeadsCount = state.asData?.value.newLeadsCount;

    // Build filter chips list (All + each status)
    final statusList = <String?>[null, ...sellerLeadStatuses];
    final statusCounts = state.asData?.value.statusCounts ?? const {};
    final chips = statusList.map((s) {
      final label = s ?? 'All';
      final count = s == null ? null : statusCounts[s];
      return SellerChipData(label, count: count);
    }).toList();

    final selectedChipIndex = statusList.indexOf(_status);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────────
          SellerGradientHeader(
            leading: SellerIconBadge(
              icon: Icons.trending_up_rounded,
              tone: SellerTone(
                fg: Colors.white,
                bg: Colors.white.withValues(alpha: 0.16),
                border: Colors.white.withValues(alpha: 0.18),
              ),
              size: 44,
              iconSize: 24,
            ),
            title: 'Leads',
            subtitle: newLeadsCount == null
                ? 'Manage sales pipeline'
                : '$newLeadsCount new leads',
            actions: [
              SellerHeaderIconButton(
                icon: Icons.download_outlined,
                onTap: _openImportSample,
                tooltip: 'Sample file',
              ),
              SellerHeaderIconButton(
                icon: Icons.upload_file_outlined,
                onTap: _importLeads,
                tooltip: 'Import leads',
              ),
            ],
          ),

          // ── Controls row (scope tabs, filter chips, search) ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.md,
              AppSpace.md,
              AppSpace.sm,
            ),
            child: SellerSegmentedTabs(
              labels: SellerLeadScope.values.map((s) => s.shortLabel).toList(),
              selectedIndex: _scope.index,
              onChanged: _setScope,
            ),
          ),
          SellerFilterChips(
            chips: chips,
            selectedIndex: selectedChipIndex < 0 ? 0 : selectedChipIndex,
            onSelected: _setStatus,
            padding: AppInsets.pageH,
          ),
          const Gap.v(AppSpace.sm),
          Padding(
            padding: AppInsets.pageH,
            child: SellerSearchField(
              controller: _searchCtrl,
              hint: 'Search by name, phone, or product',
              onChanged: (v) => setState(() => _search = v),
              onClear: () => setState(() => _search = ''),
            ),
          ),
          const Gap.v(AppSpace.sm),

          // ── Main content ────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: c.accent,
              backgroundColor: c.surface,
              onRefresh: () async {
                ref.invalidate(sellerLeadsBundleProvider(_query));
                await ref.read(sellerLeadsBundleProvider(_query).future);
              },
              child: state.when(
                loading: () => SellerListSkeleton(count: 4, itemHeight: 200),
                error: (error, _) => ListView(
                  padding: AppInsets.pageWithNav,
                  children: [
                    SellerErrorState(
                      message: _cleanError(error),
                      onRetry: () =>
                          ref.invalidate(sellerLeadsBundleProvider(_query)),
                    ),
                  ],
                ),
                data: (bundle) {
                  final leads = _filter(bundle.leads.leads, _search);
                  return ListView(
                    padding: AppInsets.pageWithNav,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      // ── Range strip ─────────────────────────────────────
                      _RangeStrip(
                        total: bundle.leads.pagination.total,
                        from: bundle.leads.pagination.from,
                        to: bundle.leads.pagination.to,
                        label: _scope.label,
                      ),
                      const Gap.v(AppSpace.sm),

                      // ── Leads list ──────────────────────────────────────
                      if (leads.isEmpty)
                        SellerEmptyState(
                          icon: Icons.person_search_outlined,
                          title: 'No leads found',
                          message:
                              'Try adjusting the filters or importing leads.',
                        )
                      else
                        for (final lead in leads) ...[
                          _LeadCard(
                            lead: lead,
                            onStatus: () => _showStatusSheet(lead),
                            onCustomOrder: () => _showCustomOrderSheet(lead),
                          ),
                          const Gap.v(AppSpace.sm),
                        ],

                      // ── Pagination ──────────────────────────────────────
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
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LEAD CARD
// ═══════════════════════════════════════════════════════════
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
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = SellerStatus.toneFor(lead.status, c);

    return SellerCard(
      padding: EdgeInsets.zero,
      accentEdge: tone.fg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.md,
          AppSpace.md,
          AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name + Status ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSm,
                  ),
                ),
                const Gap.h(AppSpace.xs),
                SellerStatusPill(label: lead.status, dense: true),
              ],
            ),
            const Gap.v(AppSpace.xxs),

<<<<<<< HEAD
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
=======
            // ── Product ───────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text('Product: ', style: text.bodySm),
                Expanded(
                  child: Text(
                    lead.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySm.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const Gap.v(AppSpace.sm),
            Divider(height: 1, color: c.divider),
            const Gap.v(AppSpace.sm),

            // ── Location ──────────────────────────────────────────────────
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: lead.location.isEmpty ? 'Location N/A' : lead.location,
            ),
            const Gap.v(AppSpace.xxs),

            // ── Phone ──────────────────────────────────────────────────────
            _InfoRow(icon: Icons.phone_outlined, label: lead.phone),
            const Gap.v(AppSpace.xxs),

            // ── Portal + Date ──────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.language_outlined, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(lead.portal, style: text.caption),
                const Gap.h(AppSpace.sm),
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(lead.formattedCreatedAt, style: text.caption),
              ],
            ),

            const Gap.v(AppSpace.md),

            // ── Actions ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SellerButton.secondary(
                    label: 'Status',
                    icon: Icons.edit_outlined,
                    onPressed: onStatus,
                  ),
                ),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: SellerButton(
                    label: 'Order',
                    icon: Icons.add_shopping_cart_outlined,
                    onPressed: onCustomOrder,
                  ),
>>>>>>> main
                ),
              ],
            ),
          ],
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
    final c = context.sellerColors;
    final text = context.sellerText;
    return Row(
      children: [
        Icon(icon, size: 13, color: c.textTertiary),
        const Gap.h(AppSpace.xxs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySm.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  RANGE STRIP
// ═══════════════════════════════════════════════════════════
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
    final c = context.sellerColors;
    final text = context.sellerText;
    return SellerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      elevated: false,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.titleSm,
            ),
          ),
          Text(
            total == 0
                ? '0 leads'
                : '${from ?? 0}–${to ?? 0} of $total',
            style: text.bodySm.copyWith(color: c.accent),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGINATION BAR
// ═══════════════════════════════════════════════════════════
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
    final text = context.sellerText;
    final c = context.sellerColors;
    return Row(
      children: [
        Expanded(
          child: SellerButton.secondary(
            label: 'Previous',
            icon: Icons.chevron_left_rounded,
            onPressed: onPrevious,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          child: Text(
            '${pagination.currentPage} / ${pagination.lastPage}',
            style: text.labelSm.copyWith(color: c.textSecondary),
          ),
        ),
        Expanded(
          child: SellerButton.secondary(
            label: 'Next',
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STATUS UPDATE SHEET
// ═══════════════════════════════════════════════════════════
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
    final c = context.sellerColors;
    final text = context.sellerText;

    return _SheetShell(
      title: 'Update Lead Status',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status dropdown ─────────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: _sheetDecoration('Status', c),
              dropdownColor: c.surface,
              style: text.body,
              items: sellerLeadStatuses
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: text.body),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value ?? _status),
            ),

            // ── Reason (only when Lost) ─────────────────────────────────
            if (_isLost) ...[
              const Gap.v(AppSpace.sm),
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
            const Gap.v(AppSpace.sm),

            // ── Comments ────────────────────────────────────────────────
            _SheetTextField(
              controller: _comments,
              label: 'Comments (optional)',
              enabled: !_saving,
              maxLines: 3,
            ),
            const Gap.v(AppSpace.md),

            // ── Save ─────────────────────────────────────────────────────
            SellerButton(
              label: 'Save Status',
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
//  CONVERT TO CUSTOM ORDER SHEET
// ═══════════════════════════════════════════════════════════
class _LeadCustomOrderSheet extends ConsumerStatefulWidget {
  final SellerLead lead;

  const _LeadCustomOrderSheet({required this.lead});

  @override
  ConsumerState<_LeadCustomOrderSheet> createState() =>
      _LeadCustomOrderSheetState();
}

class _LeadCustomOrderSheetState
    extends ConsumerState<_LeadCustomOrderSheet> {
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
      final cities = await ref.read(sellerLeadsRepositoryProvider).getCities();
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
        await _onCityChanged(autoCity, autoSelectAreaId: widget.lead.areaId);
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
      await ref
          .read(sellerLeadsRepositoryProvider)
          .convertLeadToCustomOrder(
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
      SnackbarService().showSuccessSnackBar('Custom order created from lead.');
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

    if (_loadingLookups) {
      return _SheetShell(
        title: 'Convert to Custom Order',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
          child: Center(
            child: CircularProgressIndicator(color: c.accent),
          ),
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
            // ── Lead summary ─────────────────────────────────────────────
            _LeadSummary(lead: widget.lead),
            const Gap.v(AppSpace.lg),

            // ── Customer type ────────────────────────────────────────────
            _SheetSectionHeader(
              icon: Icons.person_outline_rounded,
              title: 'Customer Type',
            ),
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
                const Gap.h(AppSpace.sm),
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
            const Gap.v(AppSpace.lg),

            // ── Location ─────────────────────────────────────────────────
            _SheetSectionHeader(
              icon: Icons.location_on_outlined,
              title: 'Location',
            ),

            // City (searchable)
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
                decoration: _sheetDecoration('City *', c),
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
            const Gap.v(AppSpace.sm),

            // Area (searchable, loads after city)
            if (_loadingAreas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.accent),
                    ),
                    const Gap.h(AppSpace.xs),
                    Text('Loading areas…', style: text.bodySm),
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
                    c,
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
            const Gap.v(AppSpace.lg),

            // ── Pricing ──────────────────────────────────────────────────
            _SheetSectionHeader(
              icon: Icons.payments_outlined,
              title: 'Pricing (PKR)',
            ),
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
                const Gap.h(AppSpace.sm),
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
            const Gap.v(AppSpace.lg),

            // ── Installment plan ──────────────────────────────────────────
            _SheetSectionHeader(
              icon: Icons.calendar_today_outlined,
              title: 'Installment Plan',
            ),
            DropdownButtonFormField<double>(
              initialValue:
                  _markupValues.contains(_monthlyPct) ? _monthlyPct : 4.0,
              decoration: _sheetDecoration('Monthly Markup %', c),
              dropdownColor: c.surface,
              style: text.body,
              items: _markupValues
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          '${v % 1 == 0 ? v.toInt() : v}%',
                          style: text.body,
                        ),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _monthlyPct = v ?? _monthlyPct),
            ),
            const Gap.v(AppSpace.md),

            // ── Tenure slider ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tenure', style: text.label),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentSurface,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    '$_tenure months',
                    style: text.labelSm.copyWith(color: c.accent),
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
              activeColor: c.accent,
              inactiveColor: c.surfaceMuted,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _tenure = v.round()),
            ),
            const Gap.v(AppSpace.md),

            // ── Submit ───────────────────────────────────────────────────
            SellerButton(
              label: 'Create Custom Order',
              icon: Icons.add_shopping_cart_outlined,
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
//  SHARED SHEET COMPONENTS
// ═══════════════════════════════════════════════════════════

/// Frosted sheet container shared by status + convert-to-order sheets.
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
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.lg,
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

                // Title row with back + close
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: c.textPrimary,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: 'Go back',
                    ),
                    const Gap.h(AppSpace.xs),
                    Expanded(
                      child: Text(title, style: text.titleMd),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: c.textTertiary,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const Gap.v(AppSpace.sm),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small overline row that labels a sheet section.
class _SheetSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SheetSectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.accent),
          const Gap.h(AppSpace.xs - 2),
          Text(
            title.toUpperCase(),
            style: text.overline.copyWith(color: c.accent),
          ),
        ],
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
    final c = context.sellerColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        validator: validator,
        decoration: _sheetDecoration(label, c),
      ),
    );
  }
}

/// Customer-type selector chip (Registered / Guest).
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
    final c = context.sellerColors;
    final text = context.sellerText;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm - 2),
          decoration: BoxDecoration(
            color: selected ? c.accent : c.accentSurface,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: selected ? c.accent : c.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? c.onAccent : c.accent,
              ),
              const Gap.h(AppSpace.xs - 2),
              Text(
                label,
                style: text.labelSm.copyWith(
                  color: selected ? c.onAccent : c.accent,
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

/// Compact lead info card shown at the top of the convert-to-order sheet.
class _LeadSummary extends StatelessWidget {
  final SellerLead lead;

  const _LeadSummary({required this.lead});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return SellerCard(
      color: c.surfaceAlt,
      elevated: false,
      child: Row(
        children: [
          SellerIconBadge(
            icon: Icons.person_search_outlined,
            tone: c.accentTone,
            size: 38,
            iconSize: 20,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Text(
              '${lead.fullName} • ${lead.productTitle}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySm.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════

InputDecoration _sheetDecoration(String label, SellerColors c) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: c.surfaceAlt,
    labelStyle: TextStyle(color: c.textSecondary),
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

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
