import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_order_details_screen.dart';
import 'package:atompro/features/seller/website_orders/model/seller_website_orders_model.dart';
import 'package:atompro/features/seller/website_orders/viewmodel/seller_website_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerWebsiteOrdersScreen extends ConsumerStatefulWidget {
  const SellerWebsiteOrdersScreen({super.key});

  @override
  ConsumerState<SellerWebsiteOrdersScreen> createState() =>
      _SellerWebsiteOrdersScreenState();
}

class _SellerWebsiteOrdersScreenState
    extends ConsumerState<SellerWebsiteOrdersScreen> {
  final _searchCtrl = TextEditingController();
  SellerWebsiteOrdersQuery _query = const SellerWebsiteOrdersQuery();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch() => setState(() {
        final kw = _searchCtrl.text.trim();
        _query = _query.copyWith(
          page: 1,
          search: kw.isEmpty ? null : kw,
          clearSearch: kw.isEmpty,
        );
      });

  void _goToPage(int page) =>
      setState(() => _query = _query.copyWith(page: page));

  void _openOrder(SellerWebsiteOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SellerCustomOrderDetailsScreen(orderUuid: order.uuid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final state = ref.watch(sellerWebsiteOrdersProvider(_query));

    return Column(
      children: [
        // ── Search bar ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.sm,
            AppSpace.md,
            AppSpace.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: c.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _applySearch(),
                    style: text.body,
                    decoration: InputDecoration(
                      hintText: 'Search by order, customer, product…',
                      hintStyle: text.body.copyWith(color: c.textTertiary),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: c.textSecondary,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: c.textSecondary,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applySearch();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Content ────────────────────────────────────────
        Expanded(
          child: state.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: c.accent),
            ),
            error: (e, _) => e is SellerPlanUpgradeException
                ? SellerPlanGateState(exception: e)
                : SellerErrorState(
                    message: e.toString().replaceFirst('Exception: ', ''),
                    onRetry: () =>
                        ref.invalidate(sellerWebsiteOrdersProvider(_query)),
                  ),
            data: (data) {
              if (data.orders.isEmpty) {
                return SellerEmptyState(
                  icon: Icons.language_rounded,
                  title: 'No website orders',
                  message: _query.search != null
                      ? 'No results for "${_query.search}"'
                      : 'New website orders in your area will appear here.',
                );
              }
              return RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async =>
                    ref.invalidate(sellerWebsiteOrdersProvider(_query)),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.md,
                    AppSpace.xs,
                    AppSpace.md,
                    AppInsets.pageWithNav.bottom,
                  ),
                  itemCount: data.orders.length + 1,
                  separatorBuilder: (_, _) =>
                      const Gap.v(AppSpace.xs),
                  itemBuilder: (context, index) {
                    if (index == data.orders.length) {
                      return _PaginationBar(
                        pagination: data.pagination,
                        onPage: _goToPage,
                      );
                    }
                    return _OrderCard(
                      order: data.orders[index],
                      onTap: () => _openOrder(data.orders[index]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Order card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final SellerWebsiteOrder order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  order.productTitle,
                  style: text.body.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap.h(AppSpace.sm),
              SellerStatusPill(label: order.status),
            ],
          ),
          const Gap.v(AppSpace.xs),

          // ── Sub-heading: brand · category ────────────────
          Text(
            '${order.brandTitle} · ${order.categoryTitle}',
            style: text.bodySm.copyWith(color: c.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap.v(AppSpace.sm),

          // ── Customer ─────────────────────────────────────
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 14, color: c.textTertiary),
              const Gap.h(4),
              Expanded(
                child: Text(
                  '${order.customerName}  ·  ${order.customerPhone}',
                  style: text.bodySm.copyWith(color: c.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.xs),

          // ── Price · tenure · date ─────────────────────────
          Row(
            children: [
              Text(
                order.formattedTotalDealPrice,
                style: text.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
              const Gap.h(AppSpace.sm),
              Text(
                '${order.tenure} months',
                style: text.bodySm.copyWith(color: c.textSecondary),
              ),
              const Spacer(),
              Text(
                order.formattedDate,
                style: text.caption.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pagination bar ──────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final SellerWebsiteOrdersPagination pagination;
  final void Function(int page) onPage;

  const _PaginationBar({required this.pagination, required this.onPage});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    if (pagination.lastPage <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: pagination.hasPrevious,
            onTap: () => onPage(pagination.currentPage - 1),
          ),
          const Gap.h(AppSpace.sm),
          Text(
            '${pagination.currentPage} / ${pagination.lastPage}',
            style: text.bodySm.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.h(AppSpace.sm),
          _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: pagination.hasNext,
            onTap: () => onPage(pagination.currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? c.accent : c.surfaceMuted,
          borderRadius: AppRadius.brSm,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.white : c.textTertiary,
        ),
      ),
    );
  }
}
