// ============================================================
//  seller_leads_screen.dart  —  v2 (Design System)
//
//  Rebuilt on the Seller Design System: unified tokens, colour
//  extension (light + dark), shared component library. All
//  business logic — providers, validators, city/area cascade,
//  pricing guards, convert-to-custom-order, import/download —
//  is 100% preserved.
// ============================================================
import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/leads/model/seller_leads_model.dart';
import 'package:atompro/features/seller/leads/repository/seller_leads_repository.dart';
import 'package:atompro/features/seller/leads/viewmodel/seller_leads_viewmodel.dart';
import 'package:dropdown_search/dropdown_search.dart';
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

  // Stable query instance. A getter that allocated a fresh SellerLeadsQuery on
  // every build handed the provider family a new key each rebuild, creating a
  // brand-new provider (and a fresh network fetch) every frame — an infinite
  // loop, since the screen rebuilds whenever the wrapping AnimatedTheme ticks.
  // Recompute it only when scope/page/status actually change.
  SellerLeadsQuery _query = const SellerLeadsQuery();

  void _syncQuery() {
    _query = SellerLeadsQuery(scope: _scope, page: _page, status: _status);
  }

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
      _syncQuery();
    });
  }

  void _setStatus(int chipIndex) {
    // index 0 = "All" (null status), index 1..N = statuses
    final statuses = <String?>[null, ...sellerLeadStatuses];
    final chosen = statuses[chipIndex];
    setState(() {
      _status = chosen;
      _page = 1;
      _syncQuery();
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

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerLeadsBundleProvider(_query));

    // Watch both base-scope providers (no filters) to show totals on tab badges.
    final mineTotal = ref
        .watch(sellerLeadsBundleProvider(
            const SellerLeadsQuery(scope: SellerLeadScope.mine)))
        .asData
        ?.value
        .leads
        .pagination
        .total;
    final otherTotal = ref
        .watch(sellerLeadsBundleProvider(
            const SellerLeadsQuery(scope: SellerLeadScope.other)))
        .asData
        ?.value
        .leads
        .pagination
        .total;

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
              const SellerNotificationBell(),
              const SellerHeaderProfileButton(),
            ],
          ),

          const SellerOfflineBanner(),

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
              counts: [mineTotal, otherTotal],
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
                error: (error, _) => error is SellerPlanUpgradeException
                    ? SellerPlanGateState(exception: error)
                    : ListView(
                        padding: AppInsets.pageWithNav,
                        children: [
                          SellerErrorState(
                            message: _cleanError(error),
                            onRetry: () => ref.invalidate(
                              sellerLeadsBundleProvider(_query),
                            ),
                          ),
                        ],
                      ),
                data: (bundle) {
                  // Plan gate is carried as data (see viewmodel) to avoid an
                  // AsyncError refetch loop.
                  if (bundle.gate != null) {
                    return SellerPlanGateState(exception: bundle.gate!);
                  }
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
                            onShare: () => _shareLeadOnWhatsApp(lead),
                          ),
                          const Gap.v(AppSpace.sm),
                        ],

                      // ── Pagination ──────────────────────────────────────
                      SellerPaginationBar(
                        currentPage: bundle.leads.pagination.currentPage,
                        lastPage: bundle.leads.pagination.lastPage,
                        onPage: (p) => setState(() {
                          _page = p;
                          _syncQuery();
                        }),
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
  final VoidCallback onShare;

  const _LeadCard({
    required this.lead,
    required this.onStatus,
    required this.onCustomOrder,
    required this.onShare,
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
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ─────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerIconBadge(
                  icon: Icons.inventory_2_outlined,
                  tone: tone,
                  size: 38,
                  iconSize: 18,
                ),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.productTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSm,
                      ),
                      const Gap.v(2),
                      if (lead.location.isNotEmpty) ...[
                        const Gap.v(2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 11, color: c.textTertiary),
                            const Gap.h(2),
                            Flexible(
                              child: Text(
                                lead.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.caption
                                    .copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap.h(AppSpace.xs),
                SellerStatusPill(label: lead.status, dense: true),
              ],
            ),

            const Gap.v(AppSpace.sm),
            Divider(height: 1, color: c.divider),
            const Gap.v(AppSpace.sm),

            // ── Contact box ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs + 2,
              ),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: AppRadius.brSm,
              ),
              child: Row(
                children: [
                  SellerIconBadge(
                    icon: Icons.person_outline_rounded,
                    tone: c.accentTone,
                    size: 32,
                    iconSize: 16,
                    radius: AppRadius.sm,
                  ),
                  const Gap.h(AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLg
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Gap.v(2),
                        Row(
                          children: [
                            Text(lead.phone, style: text.caption),
                            if (lead.availableOnWhatsapp) ...[
                              const Gap.h(AppSpace.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.successSurface,
                                  borderRadius: AppRadius.brPill,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_rounded,
                                        size: 10, color: c.success),
                                    const SizedBox(width: 3),
                                    Text(
                                      'WhatsApp',
                                      style: text.caption.copyWith(
                                        color: c.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // ── Call / WhatsApp ────────────────────────────────────
                  const Gap.h(AppSpace.xs),
                  _LeadIconBtn(
                    icon: const Icon(Icons.call_outlined, size: 15),
                    color: c.accent,
                    onTap: () => _launchCall(lead.phone),
                  ),
                  if (lead.availableOnWhatsapp) ...[
                    const Gap.h(6),
                    _LeadIconBtn(
                      icon: SvgPicture.string(
                        _kWhatsAppSvg,
                        width: 15,
                        height: 15,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF25D366),
                          BlendMode.srcIn,
                        ),
                      ),
                      color: const Color(0xFF25D366),
                      onTap: () => _launchWhatsApp(lead.phone),
                    ),
                  ],
                ],
              ),
            ),

            const Gap.v(AppSpace.xs),

            // ── Meta row ──────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(lead.formattedCreatedAt, style: text.caption),
                const Gap.h(AppSpace.xs),
                Icon(Icons.language_outlined, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(lead.portal, style: text.caption),
                if (lead.lastSeenLabel.isNotEmpty) ...[
                  const Gap.h(AppSpace.xs),
                  Icon(Icons.visibility_outlined, size: 13, color: c.textTertiary),
                  const Gap.h(AppSpace.xxs),
                  Text(lead.lastSeenLabel, style: text.caption),
                ],
              ],
            ),

            const Gap.v(AppSpace.sm),

            // ── Actions ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _LeadActionBtn.outline(
                  label: 'Share',
                  icon: Icons.share_outlined,
                  onTap: onShare,
                  c: c,
                ),
                const Gap.h(AppSpace.xs),
                _LeadActionBtn.outline(
                  label: 'Status',
                  icon: Icons.edit_outlined,
                  onTap: onStatus,
                  c: c,
                ),
                const Gap.h(AppSpace.xs),
                _LeadActionBtn.filled(
                  label: 'Create Order',
                  icon: Icons.add_shopping_cart_outlined,
                  onTap: onCustomOrder,
                  c: c,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lead small action button ──────────────────────────────────────────────────
class _LeadActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final SellerColors c;
  final bool _filled;

  const _LeadActionBtn.outline({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.c,
  }) : _filled = false;

  const _LeadActionBtn.filled({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.c,
  }) : _filled = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _filled ? c.accent : Colors.transparent,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: _filled ? c.accent : c.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: _filled ? c.onAccent : c.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _filled ? c.onAccent : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lead icon button ──────────────────────────────────────────────────────────
class _LeadIconBtn extends StatelessWidget {
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  const _LeadIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

// ── WhatsApp share helper ─────────────────────────────────────────────────────
Future<void> _shareLeadOnWhatsApp(SellerLead lead) async {
  final buf = StringBuffer();
  buf.writeln('🔥 *Lead: ${lead.productTitle}*');
  buf.writeln('');
  buf.writeln('👤 *Name:* ${lead.fullName}');
  buf.writeln('📞 *Phone:* ${lead.phone}');
  buf.writeln('📍 *Location:* ${lead.location.isNotEmpty ? lead.location : "—"}');
  buf.writeln('🏷 *Status:* ${lead.status}');
  buf.writeln('🗓 *Date:* ${lead.formattedCreatedAt}');
  if (lead.reason.isNotEmpty && lead.reason != 'Not available') {
    buf.writeln('📝 *Reason:* ${lead.reason}');
  }
  final text = Uri.encodeComponent(buf.toString());
  try {
    await launchUrl(
      Uri.parse('https://wa.me/?text=$text'),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {}
}

// ── Contact launch helpers ────────────────────────────────────────────────────
Future<void> _launchCall(String phone) async {
  try {
    await launchUrl(Uri(scheme: 'tel', path: phone.trim()));
  } catch (_) {}
}

Future<void> _launchWhatsApp(String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
  final wa = digits.startsWith('92')
      ? digits
      : digits.startsWith('0')
          ? '92${digits.substring(1)}'
          : digits;
  try {
    await launchUrl(
      Uri.parse('whatsapp://send?phone=$wa'),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    try {
      await launchUrl(
        Uri.parse('https://wa.me/$wa'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
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
          Expanded(child: Text(label, style: text.titleSm)),
          Text(
            total == 0 ? '0 leads' : '${from ?? 0}–${to ?? 0} of $total',
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
      await ref
          .read(sellerLeadsRepositoryProvider)
          .updateLead(
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
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: text.body),
                    ),
                  )
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
        'Advance price must be less than product price.',
      );
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
          child: Center(child: CircularProgressIndicator(color: c.accent)),
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
                  .where(
                    (c) => c.title.toLowerCase().contains(filter.toLowerCase()),
                  )
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
                  title: Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
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
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    ),
                    const Gap.h(AppSpace.xs),
                    Text('Loading areas…', style: text.bodySm),
                  ],
                ),
              )
            else
              DropdownSearch<SellerLeadLookup>(
                items: (filter, _) => _areas
                    .where(
                      (a) =>
                          a.title.toLowerCase().contains(filter.toLowerCase()),
                    )
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
                    title: Text(
                      item.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
              initialValue: _markupValues.contains(_monthlyPct)
                  ? _monthlyPct
                  : 4.0,
              decoration: _sheetDecoration('Monthly Markup %', c),
              dropdownColor: c.surface,
              style: text.body,
              items: _markupValues
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        '${v % 1 == 0 ? v.toInt() : v}%',
                        style: text.body,
                      ),
                    ),
                  )
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
                    Expanded(child: Text(title, style: text.titleMd)),
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
            border: Border.all(color: selected ? c.accent : c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? c.onAccent : c.accent),
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

const _kWhatsAppSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
</svg>
''';

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
