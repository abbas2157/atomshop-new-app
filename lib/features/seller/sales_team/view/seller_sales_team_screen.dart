// ============================================================
//  seller_sales_team_screen.dart  —  Design System v2
//
//  Full reskin onto the Seller Design System. All business
//  logic, providers, validators, async/nav calls and model
//  fields are preserved unchanged.
// ============================================================

import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/sales_team/model/seller_sales_team_model.dart';
import 'package:atompro/features/seller/sales_team/repository/seller_sales_team_repository.dart';
import 'package:atompro/features/seller/sales_team/viewmodel/seller_sales_team_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════
//  MAIN LIST SCREEN
// ═══════════════════════════════════════════════════════════

class SellerSalesTeamScreen extends ConsumerStatefulWidget {
  const SellerSalesTeamScreen({super.key});

  @override
  ConsumerState<SellerSalesTeamScreen> createState() =>
      _SellerSalesTeamScreenState();
}

class _SellerSalesTeamScreenState extends ConsumerState<SellerSalesTeamScreen> {
  int _page = 1;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddSheet() async {
    final dark = context.sellerIsDark;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: const _TeamMemberSheet(),
      ),
    );
    if (changed == true) ref.invalidate(sellerSalesTeamProvider(_page));
  }

  Future<void> _showEditSheet(SellerSalesTeamMember member) async {
    final dark = context.sellerIsDark;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: dark ? SellerTheme.dark : SellerTheme.light,
        child: _TeamMemberEditLoader(member: member),
      ),
    );
    if (changed == true) ref.invalidate(sellerSalesTeamProvider(_page));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerSalesTeamProvider(_page));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.canvas,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: SellerButton(
            label: 'Add Member',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: _showAddSheet,
            expand: false,
            size: SellerButtonSize.regular,
          ),
        ),
        body: Column(
          children: [
            SellerGradientHeader(
              leading: SellerIconBadge(
                icon: Icons.groups_2_rounded,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.18),
                  border: Colors.white.withValues(alpha: 0.25),
                ),
                size: 46,
                iconSize: 24,
                radius: AppRadius.md,
              ),
              title: 'Sales Team',
              subtitle: 'Manage field sales and recovery members',
              actions: [
                SellerHeaderIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: () => ref.invalidate(sellerSalesTeamProvider(_page)),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerSalesTeamProvider(_page));
                  await ref.read(sellerSalesTeamProvider(_page).future);
                },
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: AppInsets.pageWithNav,
                  children: [
                    SellerSearchField(
                      controller: _searchCtrl,
                      hint: 'Search by name, phone, email, role',
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const Gap.v(AppSpace.md),
                    state.when(
                      loading: () => const SellerListSkeleton(count: 4, itemHeight: 180),
                      error: (error, _) => SellerErrorState(
                        message: _cleanError(error),
                        onRetry: () =>
                            ref.invalidate(sellerSalesTeamProvider(_page)),
                      ),
                      data: (data) {
                        final members = _filter(data.members, _search);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _RangeStrip(
                              total: data.pagination.total,
                              from: data.pagination.from,
                              to: data.pagination.to,
                            ),
                            const Gap.v(AppSpace.sm),
                            if (members.isEmpty)
                              SellerEmptyState(
                                icon: Icons.groups_2_rounded,
                                title: 'No team members found',
                                message: _search.isNotEmpty
                                    ? 'Try a different search term.'
                                    : 'Add your first team member to get started.',
                                actionLabel: _search.isEmpty ? 'Add Member' : null,
                                onAction: _search.isEmpty ? _showAddSheet : null,
                              )
                            else
                              ...members.map(
                                (member) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpace.sm,
                                  ),
                                  child: _TeamMemberCard(
                                    member: member,
                                    onEdit: () => _showEditSheet(member),
                                    onPerformance: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SellerSalesTeamPerformanceScreen(
                                              member: member,
                                            ),
                                      ),
                                    ),
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
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PERFORMANCE SCREEN  (pushed as its own route — theme-scoped)
// ═══════════════════════════════════════════════════════════

class SellerSalesTeamPerformanceScreen extends ConsumerWidget {
  final SellerSalesTeamMember member;

  const SellerSalesTeamPerformanceScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          final state =
              ref.watch(sellerSalesTeamPerformanceProvider(member.uuid));

          return Scaffold(
            backgroundColor: c.canvas,
            body: Column(
              children: [
                SellerGradientHeader(
                  leading: SellerMonogram(name: member.user.name, size: 42),
                  title: member.user.name,
                  subtitle:
                      '${member.memberType} · ${member.user.phone}',
                  actions: [
                    SellerHeaderIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: () => ref.invalidate(
                        sellerSalesTeamPerformanceProvider(member.uuid),
                      ),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                Expanded(
                  child: state.when(
                    loading: () => const SellerListSkeleton(count: 6, itemHeight: 52),
                    error: (error, _) => SafeArea(
                      child: SellerErrorState(
                        message: _cleanError(error),
                        onRetry: () => ref.invalidate(
                          sellerSalesTeamPerformanceProvider(member.uuid),
                        ),
                      ),
                    ),
                    data: (performance) {
                      if (performance.metrics.isEmpty) {
                        return const SellerEmptyState(
                          icon: Icons.bar_chart_rounded,
                          title: 'No performance data found',
                          message:
                              'Performance metrics will appear here once available.',
                        );
                      }
                      return ListView(
                        padding: AppInsets.pageWithNav,
                        children: [
                          _MemberInfoCard(member: member),
                          const Gap.v(AppSpace.md),
                          const SellerSectionHeader(
                            overline: 'Analytics',
                            title: 'Performance metrics',
                          ),
                          const Gap.v(AppSpace.sm),
                          _MetricsCard(metrics: performance.metrics),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TEAM MEMBER CARD
// ═══════════════════════════════════════════════════════════

class _TeamMemberCard extends StatelessWidget {
  final SellerSalesTeamMember member;
  final VoidCallback onEdit;
  final VoidCallback onPerformance;

  const _TeamMemberCard({
    required this.member,
    required this.onEdit,
    required this.onPerformance,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone =
        member.active ? c.successTone : c.warningTone;
    final location = member.location;

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
            // ── Avatar + name + status ─────────────────────
            Row(
              children: [
                SellerMonogram(name: member.user.name, size: 42),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSm,
                      ),
                      const Gap.v(AppSpace.xxs),
                      Text(
                        member.user.phone,
                        style: text.bodySm,
                      ),
                    ],
                  ),
                ),
                SellerStatusPill(
                  label: member.active ? 'Active' : 'Inactive',
                  tone: tone,
                ),
              ],
            ),
            const Gap.v(AppSpace.sm),
            Divider(color: c.divider, height: 1),
            const Gap.v(AppSpace.xs),

            // ── Location ──────────────────────────────────
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: location.isEmpty ? 'Location N/A' : location,
            ),
            const Gap.v(AppSpace.xxs + 1),

            // ── Role + type ───────────────────────────────
            _InfoRow(
              icon: Icons.badge_outlined,
              label: '${member.memberRole} · ${member.memberType}',
            ),
            const Gap.v(AppSpace.xxs + 1),

            // ── Date ─────────────────────────────────────
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: member.formattedCreatedAt,
            ),
            const Gap.v(AppSpace.md),

            // ── Actions ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SellerButton.secondary(
                    label: 'Performance',
                    icon: Icons.bar_chart_rounded,
                    onPressed: onPerformance,
                    size: SellerButtonSize.small,
                  ),
                ),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: SellerButton(
                    label: 'Edit',
                    icon: Icons.edit_rounded,
                    onPressed: onEdit,
                    size: SellerButtonSize.small,
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
        Icon(icon, size: 14, color: c.textTertiary),
        const Gap.h(AppSpace.xxs + 2),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySm,
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
    final text = context.sellerText;
    final c = context.sellerColors;
    return SellerCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.people_rounded, size: 16, color: c.accent),
          const Gap.h(AppSpace.xs),
          Expanded(
            child: Text('Team Members', style: text.titleSm),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}–${to ?? 0} of $total',
            style: text.caption.copyWith(fontWeight: FontWeight.w700),
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
  final SellerSalesTeamPagination pagination;
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
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: SellerButton.secondary(
              label: 'Previous',
              icon: Icons.chevron_left_rounded,
              onPressed: onPrevious,
              size: SellerButtonSize.small,
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
              size: SellerButtonSize.small,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PERFORMANCE SCREEN — member info card + metrics
// ═══════════════════════════════════════════════════════════

class _MemberInfoCard extends StatelessWidget {
  final SellerSalesTeamMember member;

  const _MemberInfoCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    final c = context.sellerColors;
    final tone = member.active ? c.successTone : c.warningTone;
    return SellerCard(
      child: Row(
        children: [
          SellerIconBadge(
            icon: Icons.badge_rounded,
            tone: tone,
            size: 44,
            iconSize: 22,
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.memberRole} · ${member.memberType}',
                  style: text.bodySm,
                ),
                const Gap.v(AppSpace.xxs),
                Text(member.user.email, style: text.caption),
              ],
            ),
          ),
          SellerStatusPill(
            label: member.active ? 'Active' : 'Inactive',
            tone: tone,
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final Map<String, String> metrics;

  const _MetricsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final entries = metrics.entries.toList();
    return SellerCard(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(color: context.sellerColors.divider, height: 1),
            SellerDataRow(
              label: entries[i].key,
              value: entries[i].value,
              emphasize: i == 0,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ADD / EDIT SHEET
// ═══════════════════════════════════════════════════════════

class _TeamMemberEditLoader extends ConsumerWidget {
  final SellerSalesTeamMember member;

  const _TeamMemberEditLoader({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final state = ref.watch(sellerSalesTeamEditProvider(member.uuid));
    return state.when(
      loading: () => _SheetShell(
        title: 'Edit Team Member',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
          child: Center(
            child: CircularProgressIndicator(color: c.accent, strokeWidth: 2.5),
          ),
        ),
      ),
      error: (error, _) => _SheetShell(
        title: 'Edit Team Member',
        child: SellerErrorState(
          message: _cleanError(error),
          onRetry: () =>
              ref.invalidate(sellerSalesTeamEditProvider(member.uuid)),
        ),
      ),
      data: (data) => _TeamMemberSheet(member: data.member),
    );
  }
}

class _TeamMemberSheet extends ConsumerStatefulWidget {
  final SellerSalesTeamMember? member;

  const _TeamMemberSheet({this.member});

  @override
  ConsumerState<_TeamMemberSheet> createState() => _TeamMemberSheetState();
}

class _TeamMemberSheetState extends ConsumerState<_TeamMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _cityId;
  late final TextEditingController _areaId;
  String _memberType = 'sales';
  bool _active = true;
  bool _saving = false;

  bool get _editing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _name = TextEditingController(text: member?.user.name ?? '');
    _email = TextEditingController(text: member?.user.email ?? '');
    _phone = TextEditingController(text: member?.user.phone ?? '');
    _cityId = TextEditingController(text: (member?.cityId ?? 1).toString());
    _areaId = TextEditingController(text: (member?.areaId ?? 1).toString());
    _memberType = member?.memberType == 'recovery' ? 'recovery' : 'sales';
    _active = member?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _cityId.dispose();
    _areaId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(sellerSalesTeamRepositoryProvider);
      if (_editing) {
        await repo.updateMember(
          memberUuid: widget.member!.uuid,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          memberType: _memberType,
          cityId: _cityId.text.trim(),
          areaId: _areaId.text.trim(),
          active: _active,
        );
      } else {
        await repo.storeMember(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          memberType: _memberType,
          cityId: _cityId.text.trim(),
          areaId: _areaId.text.trim(),
          active: _active,
        );
      }
      if (!mounted) return;
      SnackbarService().showSuccessSnackBar(
        _editing ? 'Team member updated.' : 'Team member added.',
      );
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
      title: _editing ? 'Edit Team Member' : 'Add Team Member',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetField(
              controller: _name,
              label: 'Name',
              enabled: !_saving,
              validator: _required,
              c: c,
            ),
            _SheetField(
              controller: _email,
              label: 'Email',
              enabled: !_saving && !_editing,
              keyboardType: TextInputType.emailAddress,
              validator: _editing ? null : _emailValidator,
              c: c,
            ),
            _SheetField(
              controller: _phone,
              label: 'Phone',
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              validator: _phoneValidator,
              c: c,
            ),
            // Member type dropdown
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: DropdownButtonFormField<String>(
                initialValue: _memberType,
                decoration: _fieldDecoration('Member Type', c),
                dropdownColor: c.surface,
                style: text.body,
                items: [
                  DropdownMenuItem(
                    value: 'sales',
                    child: Text('Sales', style: text.body),
                  ),
                  DropdownMenuItem(
                    value: 'recovery',
                    child: Text('Recovery', style: text.body),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) =>
                          setState(() => _memberType = value ?? _memberType),
              ),
            ),
            _SheetField(
              controller: _cityId,
              label: 'City ID',
              enabled: !_saving,
              keyboardType: TextInputType.number,
              validator: _required,
              c: c,
            ),
            _SheetField(
              controller: _areaId,
              label: 'Area ID',
              enabled: !_saving,
              keyboardType: TextInputType.number,
              validator: _required,
              c: c,
            ),
            // Active toggle
            Container(
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: c.border),
              ),
              child: SwitchListTile.adaptive(
                value: _active,
                onChanged:
                    _saving ? null : (value) => setState(() => _active = value),
                title: Text('Active', style: text.body.copyWith(fontWeight: FontWeight.w700)),
                activeTrackColor: c.accent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                ),
              ),
            ),
            SellerButton(
              label: _editing ? 'Update Member' : 'Save Member',
              icon: Icons.save_rounded,
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
//  SHEET SHELL
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
          border: Border.all(color: c.border),
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

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final SellerColors c;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.c,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        style: context.sellerText.body,
        cursorColor: c.accent,
        decoration: _fieldDecoration(label, c),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════

InputDecoration _fieldDecoration(String label, SellerColors c) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      fontFamily: 'Roboto',
      color: c.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
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
    disabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: c.border.withValues(alpha: 0.5)),
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

List<SellerSalesTeamMember> _filter(
  List<SellerSalesTeamMember> members,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return members;
  return members
      .where((member) {
        return member.user.name.toLowerCase().contains(q) ||
            member.user.email.toLowerCase().contains(q) ||
            member.user.phone.toLowerCase().contains(q) ||
            member.memberType.toLowerCase().contains(q) ||
            member.memberRole.toLowerCase().contains(q);
      })
      .toList(growable: false);
}

String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Required';
  return null;
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Required';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
    return 'Enter a valid email';
  }
  return null;
}

String? _phoneValidator(String? value) {
  final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.length < 10) return 'Enter a valid phone number';
  return null;
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
