// ============================================================
//  seller_sales_team_screen.dart  —  Design System v2
//
//  • List screen with member_type + status filters, debounced
//    search, pagination and member cards.
//  • Performance screen: profile card + 3 KPI cards + orders.
//
//  Add / Edit now lives in SellerSalesTeamFormScreen (pushed).
// ============================================================

import 'dart:async';

import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/sales_team/model/seller_sales_team_model.dart';
import 'package:atompro/features/seller/sales_team/view/seller_sales_team_form_screen.dart';
import 'package:atompro/features/seller/sales_team/viewmodel/seller_sales_team_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════
//  ENUM LABELS
// ═══════════════════════════════════════════════════════════

String _memberTypeLabel(String value) {
  switch (value) {
    case 'recovery':
      return 'Recovery Team';
    case 'sale':
      return 'Sales Team';
    default:
      return value;
  }
}

String _memberRoleLabel(String value) {
  switch (value) {
    case 'manager':
      return 'Manager';
    case 'sale-officer':
      return 'Sale Officer';
    case 'recovery-officer':
      return 'Recovery Officer';
    case 'verification-inquiry-officer':
      return 'Verification / Inquiry Officer';
    default:
      return value;
  }
}

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
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  int _page = 1;
  String _search = '';
  int _typeIndex = 0; // 0 All · 1 Sales · 2 Recovery
  int _statusIndex = 0; // 0 All · 1 Active · 2 Inactive

  SellerSalesTeamQuery get _query => SellerSalesTeamQuery(
        page: _page,
        memberType: switch (_typeIndex) {
          1 => 'sale',
          2 => 'recovery',
          _ => null,
        },
        status: switch (_statusIndex) {
          1 => 1,
          2 => 0,
          _ => null,
        },
        query: _search.trim().isEmpty ? null : _search.trim(),
      );

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _search = value;
        _page = 1;
      });
    });
  }

  void _setType(int index) => setState(() {
        _typeIndex = index;
        _page = 1;
      });

  void _setStatus(int index) => setState(() {
        _statusIndex = index;
        _page = 1;
      });

  Future<void> _openForm({SellerSalesTeamMember? existing}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SellerSalesTeamFormScreen(existing: existing),
      ),
    );
    if (changed == true) ref.invalidate(sellerSalesTeamProvider);
  }

  void _openPerformance(SellerSalesTeamMember member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerSalesTeamPerformanceScreen(member: member),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final state = ref.watch(sellerSalesTeamProvider(_query));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.canvas,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: SellerButton(
            label: 'Add Member',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () => _openForm(),
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
                const SellerNotificationBell(),
                const SellerHeaderProfileButton(),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerSalesTeamProvider(_query));
                  await ref.read(sellerSalesTeamProvider(_query).future);
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
                      onChanged: _onSearchChanged,
                    ),
                    const Gap.v(AppSpace.sm),
                    SellerSegmentedTabs(
                      labels: const ['All', 'Sales', 'Recovery'],
                      selectedIndex: _typeIndex,
                      onChanged: _setType,
                    ),
                    const Gap.v(AppSpace.xs),
                    SellerSegmentedTabs(
                      labels: const ['All', 'Active', 'Inactive'],
                      selectedIndex: _statusIndex,
                      onChanged: _setStatus,
                    ),
                    const Gap.v(AppSpace.md),
                    state.when(
                      loading: () =>
                          const SellerListSkeleton(count: 4, itemHeight: 180),
                      error: (error, _) => error is SellerPlanUpgradeException
                          ? SellerPlanGateState(exception: error)
                          : SellerErrorState(
                              message: _cleanError(error),
                              onRetry: () =>
                                  ref.invalidate(sellerSalesTeamProvider(_query)),
                            ),
                      data: (data) {
                        if (data.gate != null) {
                          return SellerPlanGateState(exception: data.gate!);
                        }
                        final members = data.members;
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
                                message: _hasFilters
                                    ? 'Try a different search or filter.'
                                    : 'Add your first team member to get started.',
                                actionLabel: _hasFilters ? null : 'Add Member',
                                onAction: _hasFilters ? null : () => _openForm(),
                              )
                            else
                              ...members.map(
                                (member) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpace.sm,
                                  ),
                                  child: _TeamMemberCard(
                                    member: member,
                                    onEdit: () =>
                                        _openForm(existing: member),
                                    onTap: () => _openPerformance(member),
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

  bool get _hasFilters =>
      _search.trim().isNotEmpty || _typeIndex != 0 || _statusIndex != 0;
}

// ═══════════════════════════════════════════════════════════
//  TEAM MEMBER CARD
// ═══════════════════════════════════════════════════════════

class _TeamMemberCard extends StatelessWidget {
  final SellerSalesTeamMember member;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _TeamMemberCard({
    required this.member,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final statusTone = member.active ? c.successTone : c.warningTone;
    final typeTone =
        member.memberType == 'recovery' ? c.violetTone : c.infoTone;
    final location = member.location;

    return SellerCard(
      padding: EdgeInsets.zero,
      accentEdge: statusTone.fg,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name + status ─────────────────────
            Row(
              children: [
                SellerIconBadge(
                  icon: Icons.person_rounded,
                  tone: c.accentTone,
                  size: 42,
                  iconSize: 22,
                ),
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
                        _memberRoleLabel(member.memberRole),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySm,
                      ),
                    ],
                  ),
                ),
                SellerStatusPill(
                  label: member.active ? 'Active' : 'Inactive',
                  tone: statusTone,
                ),
              ],
            ),
            const Gap.v(AppSpace.sm),
            Divider(color: c.divider, height: 1),
            const Gap.v(AppSpace.xs),

            // ── Type badge ────────────────────────────────
            Row(
              children: [
                SellerStatusPill(
                  label: _memberTypeLabel(member.memberType),
                  tone: typeTone,
                  showDot: false,
                ),
              ],
            ),
            const Gap.v(AppSpace.xs),

            // ── Location ──────────────────────────────────
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: location.isEmpty ? 'Location N/A' : location,
            ),
            const Gap.v(AppSpace.xxs + 1),

            // ── Phone ─────────────────────────────────────
            _InfoRow(
              icon: Icons.phone_outlined,
              label: member.user.phone,
            ),
            const Gap.v(AppSpace.md),

            // ── Actions ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SellerButton.secondary(
                    label: 'Performance',
                    icon: Icons.bar_chart_rounded,
                    onPressed: onTap,
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
//  PERFORMANCE SCREEN  (pushed as its own route — theme-scoped)
// ═══════════════════════════════════════════════════════════

class SellerSalesTeamPerformanceScreen extends ConsumerWidget {
  final SellerSalesTeamMember member;

  const SellerSalesTeamPerformanceScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userUuid = member.user.uuid;
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;
          final state =
              ref.watch(sellerSalesTeamPerformanceProvider(userUuid));

          return Scaffold(
            backgroundColor: c.canvas,
            body: Column(
              children: [
                SellerGradientHeader(
                  leading: SellerMonogram(name: member.user.name, size: 42),
                  title: member.user.name,
                  subtitle:
                      '${_memberTypeLabel(member.memberType)} · ${member.user.phone}',
                  actions: const [
                    SellerNotificationBell(),
                    SellerHeaderProfileButton(),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: c.accent,
                    backgroundColor: c.surface,
                    onRefresh: () async {
                      ref.invalidate(
                        sellerSalesTeamPerformanceProvider(userUuid),
                      );
                      await ref.read(
                        sellerSalesTeamPerformanceProvider(userUuid).future,
                      );
                    },
                    child: state.when(
                      loading: () => const SellerListSkeleton(
                        count: 6,
                        itemHeight: 64,
                      ),
                      error: (error, _) => error is SellerPlanUpgradeException
                          ? SellerPlanGateState(exception: error)
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: AppInsets.pageWithNav,
                              children: [
                                SellerErrorState(
                                  message: _cleanError(error),
                                  onRetry: () => ref.invalidate(
                                    sellerSalesTeamPerformanceProvider(userUuid),
                                  ),
                                ),
                              ],
                            ),
                      data: (g) => g.isGated
                          ? SellerPlanGateState(exception: g.gate!)
                          : _PerformanceBody(
                              performance: g.value!,
                            ),
                    ),
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

class _PerformanceBody extends StatelessWidget {
  final SellerSalesTeamPerformance performance;

  const _PerformanceBody({required this.performance});

  @override
  Widget build(BuildContext context) {
    final user = performance.user;
    final orders = performance.orders;
    final isRecovery = performance.isRecovery;

    final ordersLabel = isRecovery ? 'Total Recoveries' : 'Total Orders';
    final avg = orders.isEmpty
        ? 0
        : (performance.pageCollected / orders.length).round();

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: AppInsets.pageWithNav,
      children: [
        _ProfileCard(user: user),
        const Gap.v(AppSpace.md),

        // ── KPI cards ───────────────────────────────────────
        SellerGrid(
          children: [
            SellerKpiCard(
              label: ordersLabel,
              value: '${performance.ordersTotal}',
              icon: Icons.receipt_long_rounded,
              tone: context.sellerColors.accentTone,
            ),
            SellerKpiCard(
              label: 'Total Collected',
              value: _money(performance.pageCollected),
              icon: Icons.payments_rounded,
              tone: context.sellerColors.successTone,
              caption: 'this page',
            ),
          ],
        ),
        const Gap.v(AppSpace.sm),
        SellerKpiCard(
          label: 'Avg / Entry',
          value: _money(avg),
          icon: Icons.trending_up_rounded,
          tone: context.sellerColors.infoTone,
        ),
        const Gap.v(AppSpace.md),

        // ── Orders ──────────────────────────────────────────
        SellerSectionHeader(
          overline: 'Activity',
          title: isRecovery ? 'Recovery entries' : 'Orders',
        ),
        const Gap.v(AppSpace.sm),
        if (orders.isEmpty)
          const SellerEmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No entries yet',
            message: 'Orders handled by this member will appear here.',
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _OrderCard(order: order),
            ),
          ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final SellerPerformanceUser user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final location = [user.areaTitle, user.cityTitle]
        .where((e) => e.isNotEmpty && e != 'Not available')
        .join(', ');

    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerIconBadge(
                icon: Icons.badge_rounded,
                tone: c.accentTone,
                size: 46,
                iconSize: 24,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSm,
                    ),
                    const Gap.v(AppSpace.xxs),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySm,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              SellerStatusPill(
                label: _memberRoleLabel(user.memberRole),
                tone: c.infoTone,
                showDot: false,
              ),
              if (user.isAmos)
                SellerStatusPill(
                  label: 'AMOS',
                  tone: c.violetTone,
                  showDot: false,
                ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.xs),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: location.isEmpty ? 'Location N/A' : location,
          ),
          const Gap.v(AppSpace.xxs + 1),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined ${user.formattedJoined}',
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final SellerPerformanceOrder order;

  const _OrderCard({required this.order});

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
              Expanded(
                child: Text(
                  'Order #${order.orderId}',
                  style: text.titleSm,
                ),
              ),
              SellerStatusPill(label: order.status),
            ],
          ),
          const Gap.v(AppSpace.xs),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: order.customerPhone.isEmpty
                ? order.customerName
                : '${order.customerName} · ${order.customerPhone}',
          ),
          const Gap.v(AppSpace.xxs + 1),
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            label: order.prNumber.isEmpty
                ? order.productTitle
                : '${order.productTitle} · ${order.prNumber}',
          ),
          const Gap.v(AppSpace.xxs + 1),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: order.formattedDate,
          ),
          const Gap.v(AppSpace.sm),
          Divider(color: c.divider, height: 1),
          const Gap.v(AppSpace.xs),
          Row(
            children: [
              Expanded(
                child: _MoneyChip(
                  label: 'Deal',
                  value: order.formattedDeal,
                  tone: c.neutralTone,
                ),
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: _MoneyChip(
                  label: 'Collected',
                  value: order.formattedPrice,
                  tone: c.successTone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyChip extends StatelessWidget {
  final String label;
  final String value;
  final SellerTone tone;

  const _MoneyChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.caption.copyWith(color: tone.fg)),
          const Gap.v(AppSpace.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySm.copyWith(
              color: tone.fg,
              fontWeight: FontWeight.w800,
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

String _money(int value) {
  final t = value.toString();
  final b = StringBuffer();
  for (var i = 0; i < t.length; i++) {
    final r = t.length - i;
    b.write(t[i]);
    if (r > 1 && r % 3 == 1) b.write(',');
  }
  return 'Rs $b';
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
