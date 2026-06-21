import 'package:atompro/core/seller_plan_upgrade_exception.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_order_details_screen.dart';
import 'package:atompro/features/seller/website_orders/model/seller_website_orders_model.dart';
import 'package:atompro/features/seller/website_orders/viewmodel/seller_website_orders_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

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
            loading: () => const SellerListSkeleton(),
            error: (e, _) => e is SellerPlanUpgradeException
                ? SellerPlanGateState(exception: e)
                : SellerErrorState(
                    message: e.toString().replaceFirst('Exception: ', ''),
                    onRetry: () =>
                        ref.invalidate(sellerWebsiteOrdersProvider(_query)),
                  ),
            data: (data) {
              // Plan gate is carried as data (see viewmodel) to avoid an
              // AsyncError refetch loop.
              if (data.gate != null) {
                return SellerPlanGateState(exception: data.gate!);
              }
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
                  separatorBuilder: (_, _) => const Gap.v(AppSpace.xs),
                  itemBuilder: (context, index) {
                    if (index == data.orders.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                        child: SellerPaginationBar(
                          currentPage: data.pagination.currentPage,
                          lastPage: data.pagination.lastPage,
                          onPage: _goToPage,
                        ),
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
    final tone = SellerStatus.toneFor(order.status, c);

    return SellerCard(
      padding: EdgeInsets.zero,
      accentEdge: tone.fg,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──────────────────────
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
                        order.productTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSm,
                      ),
                      const Gap.v(2),
                      Text(
                        order.brandTitle.isNotEmpty
                            ? '${order.productPrNumber} · ${order.brandTitle}'
                            : order.productPrNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.caption,
                      ),
                      if (order.cityTitle.isNotEmpty || order.areaTitle.isNotEmpty) ...[
                        const Gap.v(2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 11, color: c.textTertiary),
                            const Gap.h(2),
                            Flexible(
                              child: Text(
                                [
                                  if (order.cityTitle.isNotEmpty) order.cityTitle,
                                  if (order.areaTitle.isNotEmpty) order.areaTitle,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.caption.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap.h(AppSpace.xs),
                SellerStatusPill(label: order.status),
              ],
            ),

            const Gap.v(AppSpace.sm),
            Divider(height: 1, color: c.divider),
            const Gap.v(AppSpace.sm),

            // ── Stats row ──────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    icon: Icons.price_check_rounded,
                    label: 'Deal Price',
                    value: order.formattedTotalDealPrice,
                    tone: c.accentTone,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    icon: Icons.payments_outlined,
                    label: 'Advance',
                    value: order.formattedAdvancePrice,
                    tone: c.successTone,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    icon: Icons.calendar_month_outlined,
                    label: 'Tenure',
                    value: '${order.tenure} mo.',
                    tone: c.violetTone,
                  ),
                ),
              ],
            ),

            const Gap.v(AppSpace.sm),

            // ── Customer box ────────────────────
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
                          order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap.v(2),
                        Text(order.customerPhone, style: text.caption),
                      ],
                    ),
                  ),
                  if (order.customerPhone.isNotEmpty) ...[
                    const Gap.h(AppSpace.xs),
                    _ContactBtn(
                      icon: Icon(Icons.call_outlined, size: 15, color: c.accent),
                      color: c.accent,
                      onTap: () => _launchCall(order.customerPhone),
                    ),
                    const Gap.h(6),
                    _ContactBtn(
                      icon: SvgPicture.string(
                        _kWhatsAppSvg,
                        width: 15,
                        height: 15,
                        colorFilter: const ColorFilter.mode(Color(0xFF25D366), BlendMode.srcIn),
                      ),
                      color: const Color(0xFF25D366),
                      onTap: () => _launchWhatsApp(order.customerPhone),
                    ),
                  ],
                ],
              ),
            ),

            const Gap.v(AppSpace.xs),

            // ── Meta row ───────────────────────
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(order.formattedDate, style: text.caption),
                const Gap.h(AppSpace.xs),
                Icon(Icons.language_outlined, size: 13, color: c.textTertiary),
                const Gap.h(AppSpace.xxs),
                Text(order.portal, style: text.caption),
                if (order.categoryTitle.isNotEmpty) ...[
                  const Gap.h(AppSpace.xs),
                  Icon(Icons.category_outlined, size: 13, color: c.textTertiary),
                  const Gap.h(AppSpace.xxs),
                  Expanded(
                    child: Text(
                      order.categoryTitle,
                      style: text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final SellerTone tone;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: tone.fg),
            const Gap.h(AppSpace.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.caption,
              ),
            ),
          ],
        ),
        const Gap.v(AppSpace.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: text.bodyLg.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONTACT HELPERS
// ─────────────────────────────────────────────────────────────────────────────

const _kWhatsAppSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512">'
    '<path d="M380.9 97.1C339 55.1 283.2 32 223.9 32c-122.4 0-222 99.6-222 222 '
    '0 39.1 10.2 77.3 29.6 111L0 480l117.7-30.9c32.4 17.7 68.9 27 106.1 27h.1'
    'c122.3 0 224.1-99.6 224.1-222 0-59.3-25.2-115-67.1-157zm-157 341.6c-33.2 '
    '0-65.7-8.9-94-25.7l-6.7-4-69.8 18.3L72 359.2l-4.4-7c-18.5-29.4-28.2-63.3'
    '-28.2-98.2 0-101.7 82.8-184.5 184.6-184.5 49.3 0 95.6 19.2 130.4 54.1 '
    '34.8 34.9 56.2 81.2 56.1 130.5 0 101.8-84.9 184.6-186.6 184.6zm101.2-138'
    '.2c-5.5-2.8-32.8-16.2-37.9-18-5.1-1.9-8.8-2.8-12.5 2.8-3.7 5.6-14.3 18'
    '-17.6 21.8-3.2 3.7-6.5 4.2-12 1.4-32.6-16.3-54-29.1-75.5-66-5.7-9.8 '
    '5.7-9.1 16.3-30.3 1.8-3.7.9-6.9-.5-9.7-1.4-2.8-12.5-30.1-17.1-41.2-4.5'
    '-10.8-9.1-9.3-12.5-9.5-3.2-.2-6.9-.2-10.6-.2-3.7 0-9.7 1.4-14.8 6.9-5.1'
    ' 5.6-19.4 19-19.4 46.3 0 27.3 19.9 53.7 22.6 57.4 2.8 3.7 39.1 59.7 94.8'
    ' 83.8 35.2 15.2 49 16.5 66.6 13.9 10.7-1.6 32.8-13.4 37.4-26.4 4.6-13 '
    '4.6-24.1 3.2-26.4-1.3-2.5-5-3.9-10.5-6.6z"/></svg>';

Future<void> _launchCall(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) launchUrl(uri);
}

Future<void> _launchWhatsApp(String phone) async {
  final normalized = phone.startsWith('0') ? '92${phone.substring(1)}' : phone;
  final uri = Uri.parse('https://wa.me/$normalized');
  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _ContactBtn extends StatelessWidget {
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  const _ContactBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

