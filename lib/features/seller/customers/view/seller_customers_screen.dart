import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/view/seller_customer_details_screen.dart';
import 'package:atompro/features/seller/customers/view/seller_customer_form_screen.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerCustomersScreen extends ConsumerStatefulWidget {
  const SellerCustomersScreen({super.key});

  @override
  ConsumerState<SellerCustomersScreen> createState() =>
      _SellerCustomersScreenState();
}

class _SellerCustomersScreenState extends ConsumerState<SellerCustomersScreen> {
  SellerCustomerScope _scope = SellerCustomerScope.mine;
  int _page = 1;
  String _search = '';
  final _searchCtrl = TextEditingController();

  SellerCustomersQuery get _query =>
      SellerCustomersQuery(scope: _scope, page: _page);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddCustomerSheet() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SellerCustomerFormScreen()),
    );
    ref.invalidate(sellerCustomersProvider(_query));
    ref.invalidate(sellerCustomersNotificationCountProvider);
  }

  /// Only "My" and "Other" scopes are shown ("All" is dropped).
  static const _visibleScopes = <SellerCustomerScope>[
    SellerCustomerScope.mine,
    SellerCustomerScope.other,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final state = ref.watch(sellerCustomersProvider(_query));
    final notificationState = ref.watch(
      sellerCustomersNotificationCountProvider,
    );

    final notifCount = notificationState.asData?.value;
    final subtitle = notifCount == null
        ? 'Manage seller customer records'
        : '$notifCount new customer notifications';

    // Map scope → index within the 2-item visible list (My / Other).
    final scopeIndex = _visibleScopes.indexOf(_scope);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.canvas,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────────────────────
            SellerGradientHeader(
              leading: SellerIconBadge(
                icon: Icons.groups_2_outlined,
                tone: SellerTone(
                  fg: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.16),
                  border: Colors.white.withValues(alpha: 0.20),
                ),
                size: 48,
                iconSize: 26,
                radius: AppRadius.lg,
              ),
              title: 'Customers',
              subtitle: subtitle,
              actions: [
                SellerHeaderIconButton(
                  icon: Icons.person_add_alt_1_outlined,
                  onTap: _showAddCustomerSheet,
                  tooltip: 'Add customer',
                ),
              ],
            ),
            // ── Search + scope ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.md,
                AppSpace.md,
                AppSpace.xs,
              ),
              child: SellerSearchField(
                controller: _searchCtrl,
                hint: 'Search by name, phone, CNIC…',
                onChanged: (v) => setState(() {
                  _search = v;
                  _page = 1;
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.xs,
                AppSpace.md,
                AppSpace.xs,
              ),
              child: SellerSegmentedTabs(
                labels: _visibleScopes.map((s) => s.shortLabel).toList(),
                selectedIndex: scopeIndex < 0 ? 0 : scopeIndex,
                onChanged: (i) => setState(() {
                  _scope = _visibleScopes[i];
                  _page = 1;
                  _search = '';
                  _searchCtrl.clear();
                }),
              ),
            ),
            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerCustomersProvider(_query));
                  ref.invalidate(sellerCustomersNotificationCountProvider);
                  await ref.read(sellerCustomersProvider(_query).future);
                },
                child: state.when(
                  loading: () => const SellerListSkeleton(),
                  error: (error, _) => SellerErrorState(
                    message: _cleanError(error),
                    onRetry: () =>
                        ref.invalidate(sellerCustomersProvider(_query)),
                  ),
                  data: (data) {
                    final customers = _filter(data.customers, _search);
                    return ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: AppInsets.pageWithNav,
                      children: [
                        // Summary strip
                        _SummaryStrip(
                          label: _scope.label,
                          total: data.pagination.total,
                          from: data.pagination.from,
                          to: data.pagination.to,
                        ),
                        const Gap.v(AppSpace.sm),
                        // Customer list or empty
                        if (customers.isEmpty)
                          SellerEmptyState(
                            icon: Icons.person_search_outlined,
                            title: 'No customers found',
                            message: _search.isNotEmpty
                                ? 'Try a different search term.'
                                : 'Add your first customer to get started.',
                          )
                        else
                          ...customers.map(
                            (customer) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpace.sm,
                              ),
                              child: _CustomerCard(
                                customer: customer,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SellerCustomerDetailsScreen(
                                      customerUuid: customer.uuid,
                                      initialCustomer: customer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Pagination
                        _PaginationBar(
                          pagination: data.pagination,
                          text: text,
                          c: c,
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

// ── Summary strip ─────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final String label;
  final int total;
  final int? from;
  final int? to;

  const _SummaryStrip({
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.titleSm,
            ),
          ),
          Text(
            total == 0 ? '0 records' : '${from ?? 0}–${to ?? 0} of $total',
            style: text.caption.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer card ─────────────────────────────────────────────────────────────
class _CustomerCard extends StatelessWidget {
  final SellerCustomer customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final verified = customer.verified;
    final location = customer.profile.location;

    return SellerCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      accentEdge: verified ? c.success : c.warning,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.sm,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name + avatar + status pill ─────────────────────────────
            Row(
              children: [
                SellerMonogram(name: customer.name, size: 40),
                const Gap.h(AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSm,
                      ),
                      const Gap.v(AppSpace.xxs),
                      Text(
                        customer.phone,
                        style: text.bodySm,
                      ),
                    ],
                  ),
                ),
                SellerStatusPill(
                  label: verified ? 'Verified' : 'Pending',
                  tone: verified ? c.successTone : c.warningTone,
                ),
              ],
            ),
            const Gap.v(AppSpace.xs),
            Divider(color: c.divider, height: 1),
            const Gap.v(AppSpace.xs),
            // ── Location & address ──────────────────────────────────────
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: location.isEmpty ? 'Location N/A' : location,
            ),
            const Gap.v(AppSpace.xxs + 1),
            _InfoRow(
              icon: Icons.home_outlined,
              label: customer.profile.address,
            ),
            const Gap.v(AppSpace.xxs + 1),
            // ── Joined + date ────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.public_outlined, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(
                  customer.joinedThrough,
                  style: text.caption,
                ),
                const Gap.h(AppSpace.xs),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: c.textTertiary,
                ),
                const Gap.h(AppSpace.xxs),
                Text(
                  customer.formattedCreatedAt,
                  style: text.caption,
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: c.textTertiary,
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
            style: text.bodySm.copyWith(color: c.textPrimary),
          ),
        ),
      ],
    );
  }
}

// ── Pagination bar ────────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final SellerCustomersPagination pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final SellerTextTheme text;
  final SellerColors c;

  const _PaginationBar({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
    required this.text,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    if (pagination.lastPage <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: SellerButton.secondary(
              label: 'Previous',
              icon: Icons.chevron_left_rounded,
              onPressed: onPrevious,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
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
      ),
    );
  }
}

// ── Pure business-logic helpers (unchanged) ───────────────────────────────────
List<SellerCustomer> _filter(List<SellerCustomer> customers, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return customers;
  return customers
      .where((customer) {
        return customer.name.toLowerCase().contains(q) ||
            customer.phone.toLowerCase().contains(q) ||
            customer.email.toLowerCase().contains(q) ||
            customer.profile.cnicNo.toLowerCase().contains(q) ||
            customer.profile.identifier.toLowerCase().contains(q);
      })
      .toList(growable: false);
}

String _cleanError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}
