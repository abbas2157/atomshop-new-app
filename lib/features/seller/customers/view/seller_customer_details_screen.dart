import 'dart:io';

import 'package:atompro/core/network/api_endpoints.dart';
import 'package:atompro/core/services/snackbar_services.dart';
import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/custom_orders/repository/seller_custom_orders_repository.dart';
import 'package:atompro/features/seller/custom_orders/view/seller_custom_order_details_screen.dart';
import 'package:atompro/features/seller/customers/model/seller_customers_model.dart';
import 'package:atompro/features/seller/customers/view/seller_customer_form_screen.dart';
import 'package:atompro/features/seller/customers/viewmodel/seller_customers_viewmodel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ── Root screen — wrapped in SellerThemeScope so the pushed route inherits the
//    correct theme even when the shell's theme differs from system theme.
class SellerCustomerDetailsScreen extends ConsumerWidget {
  final String customerUuid;
  final SellerCustomer? initialCustomer;

  const SellerCustomerDetailsScreen({
    super.key,
    required this.customerUuid,
    this.initialCustomer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SellerThemeScope(
      child: Builder(
        builder: (context) {
          final c = context.sellerColors;

          final profileState =
              ref.watch(sellerCustomerProfileProvider(customerUuid));
          final instalmentsState =
              ref.watch(sellerCustomerInstalmentsProvider(customerUuid));
          final ordersState =
              ref.watch(sellerCustomerCustomOrdersProvider(customerUuid));

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: c.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: c.canvas,
              appBar: AppBar(
                backgroundColor: c.canvas,
                surfaceTintColor: Colors.transparent,
                title: Text('Customer Details', style: c.isDark
                    ? context.sellerText.titleMd.copyWith(color: c.textPrimary)
                    : context.sellerText.titleMd),
                titleSpacing: 0,
                iconTheme: IconThemeData(color: c.textPrimary),
                actions: [
                  IconButton(
                    tooltip: 'Edit customer',
                    icon: Icon(Icons.edit_outlined, color: c.textPrimary),
                    onPressed: profileState.asData == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SellerCustomerFormScreen(
                                  existing: profileState.asData!.value.user,
                                ),
                              ),
                            ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: Icon(Icons.refresh_rounded, color: c.textPrimary),
                    onPressed: () {
                      ref.invalidate(
                          sellerCustomerProfileProvider(customerUuid));
                      ref.invalidate(
                          sellerCustomerInstalmentsProvider(customerUuid));
                      ref.invalidate(
                          sellerCustomerCustomOrdersProvider(customerUuid));
                    },
                  ),
                ],
              ),
              body: profileState.when(
                loading: () =>
                    _LoadingView(initialCustomer: initialCustomer),
                error: (error, _) => SellerErrorState(
                  message: _cleanError(error),
                  onRetry: () => ref.invalidate(
                      sellerCustomerProfileProvider(customerUuid)),
                ),
                data: (details) => RefreshIndicator(
                  color: c.accent,
                  backgroundColor: c.surface,
                  onRefresh: () async {
                    ref.invalidate(
                        sellerCustomerProfileProvider(customerUuid));
                    ref.invalidate(
                        sellerCustomerInstalmentsProvider(customerUuid));
                    ref.invalidate(
                        sellerCustomerCustomOrdersProvider(customerUuid));
                    await Future.wait([
                      ref.read(
                          sellerCustomerProfileProvider(customerUuid).future),
                      ref.read(sellerCustomerInstalmentsProvider(customerUuid)
                          .future),
                      ref.read(sellerCustomerCustomOrdersProvider(customerUuid)
                          .future),
                    ]);
                  },
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: AppInsets.pageWithNav,
                    children: [
                      // ── Hero ──────────────────────────────────────────
                      _HeroCard(details: details),
                      const Gap.v(AppSpace.md),

                      // ── Customer Information ──────────────────────────
                      _SectionCard(
                        title: 'Customer Information',
                        icon: Icons.person_outline_rounded,
                        child: Column(
                          children: [
                            _GRow(
                              'Identifier',
                              details.user.profile.identifier,
                              'Name',
                              details.user.name,
                            ),
                            _GRow(
                              'Phone',
                              details.user.phone,
                              'Email',
                              details.user.email,
                            ),
                            _GRow(
                              'Father Name',
                              details.user.profile.fatherName,
                              'CNIC',
                              details.user.profile.cnicNo,
                            ),
                            _GRow(
                              'Address',
                              details.user.profile.address,
                              'Res. Phone',
                              details.user.profile.residencePhone,
                            ),
                            _GRow(
                              'Office Address',
                              details.user.profile.officeAddress,
                              'Office Phone',
                              details.user.profile.officePhone,
                            ),
                            _GRow(
                              'Joined Date',
                              details.user.formattedCreatedAt,
                              'Joined Through',
                              details.user.joinedThrough,
                            ),
                            _GRow(
                              'Portal',
                              details.user.profile.portal,
                              'Status',
                              details.user.status,
                            ),
                          ],
                        ),
                      ),

                      // ── Customer Verification ─────────────────────────
                      if (details.verification.exists) ...[
                        const Gap.v(AppSpace.md),
                        _SectionCard(
                          title: 'Customer Verification',
                          icon: Icons.verified_user_outlined,
                          child: Column(
                            children: [
                              _GRow(
                                'Physical Meet',
                                details.verification.physicalMeet
                                    ? 'Yes'
                                    : 'No',
                                'Address Found',
                                details.verification.addressFound
                                    ? 'Yes'
                                    : 'No',
                              ),
                              _GRow(
                                'House',
                                details.verification.house,
                                'Work',
                                details.verification.work,
                              ),
                              const Gap.v(AppSpace.sm),
                              _DocumentImages(
                                front: details.verification.idCardFront,
                                back: details.verification.idCardBack,
                                selfie: details.verification.selfie,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Custom Orders ─────────────────────────────────
                      const Gap.v(AppSpace.md),
                      _SectionCard(
                        title: 'Custom Orders',
                        icon: Icons.receipt_long_outlined,
                        child: ordersState.when(
                          loading: () => const _InlineLoading(
                              label: 'Loading orders…'),
                          error: (e, _) =>
                              _InlineError(message: _cleanError(e)),
                          data: (data) => data.orders.isEmpty
                              ? const _EmptyInline(
                                  label: 'No custom orders yet.')
                              : Column(
                                  children: data.orders
                                      .map(
                                        (o) => _OrderTile(
                                          order: o,
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SellerCustomOrderDetailsScreen(
                                                orderUuid: o.uuid,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                        ),
                      ),

                      // ── Instalments ───────────────────────────────────
                      const Gap.v(AppSpace.md),
                      _SectionCard(
                        title: 'Instalments',
                        icon: Icons.payments_outlined,
                        child: instalmentsState.when(
                          loading: () => const _InlineLoading(
                              label: 'Loading instalments…'),
                          error: (e, _) =>
                              _InlineError(message: _cleanError(e)),
                          data: (data) {
                            if (data.instalments.isEmpty) {
                              return const _EmptyInline(
                                  label: 'No instalments yet.');
                            }
                            // Per order, the pay-instalment endpoint always
                            // settles the first Unpaid Instalment/Outstanding
                            // row — surface a "Pay" action only on that row so
                            // the seller can't be misled into paying a
                            // different one than the one tapped.
                            final payableIds =
                                _payableInstalmentIds(data.instalments);
                            return Column(
                              children: data.instalments
                                  .take(10)
                                  .map(
                                    (item) => _InstalmentTile(
                                      item: item,
                                      onPay: payableIds.contains(item.id)
                                          ? () => _showPayInstalmentSheet(
                                                context: context,
                                                ref: ref,
                                                customerUuid: customerUuid,
                                                instalment: item,
                                              )
                                          : null,
                                    ),
                                  )
                                  .toList(growable: false),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final SellerCustomerDetails details;
  const _HeroCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final customer = details.user;
    final verified = customer.verified;

    return Container(
      decoration: BoxDecoration(
        gradient: c.headerGradient,
        borderRadius: AppRadius.brXl,
        boxShadow: c.floatingShadow,
      ),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar row ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CustomerAvatar(
                name: customer.name,
                picture: customer.profile.picture,
                size: 52,
              ),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap.v(AppSpace.xxs),
                    Text(
                      customer.phone,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Verified pill on gradient (white-tinted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs + 2,
                ),
                decoration: BoxDecoration(
                  color: verified
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: AppRadius.brPill,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      verified
                          ? Icons.verified_outlined
                          : Icons.schedule_outlined,
                      color: Colors.white,
                      size: 13,
                    ),
                    const Gap.h(AppSpace.xxs),
                    Text(
                      verified ? 'Verified' : 'Pending',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.md),
          // ── KPI strip ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Total Sales',
                  value: details.formattedTotalCustomSales,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _HeroMetric(
                  label: 'Recovery',
                  value: details.formattedTotalCustomRecovery,
                ),
              ),
              const Gap.h(AppSpace.xs),
              Expanded(
                child: _HeroMetric(
                  label: 'Rate',
                  value: details.formattedRecoveryPercentage,
                ),
              ),
            ],
          ),
          // ── Recovery bar ────────────────────────────────────────────
          const Gap.v(AppSpace.sm),
          Text(
            'Recovery rate',
            style: text.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const Gap.v(AppSpace.xxs),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: _clampPct(details.formattedRecoveryPercentage),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Hero metric tile (lives on the gradient, so uses white text)
class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs + 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap.v(AppSpace.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
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

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header stripe
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              AppSpace.sm,
            ),
            decoration: BoxDecoration(
              color: c.accentSurface,
              border: Border(bottom: BorderSide(color: c.border)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: c.accent),
                const Gap.h(AppSpace.xs - 2),
                Text(
                  title.toUpperCase(),
                  style: text.overline.copyWith(color: c.accent),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── 2-column grid row ─────────────────────────────────────────────────────────
// ── Customer photo (falls back to monogram) ────────────────────────────────
class _CustomerAvatar extends StatelessWidget {
  final String name;
  final String picture;
  final double size;
  const _CustomerAvatar({
    required this.name,
    required this.picture,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiEndpoints.publicAsset(picture);
    final fallback = SellerMonogram(name: name, size: size);
    if (url.isEmpty) return fallback;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => fallback,
          errorWidget: (_, _, _) => fallback,
        ),
      ),
    );
  }
}

// ── Verification document thumbnails (tap → full-screen viewer) ─────────────
class _DocumentImages extends StatelessWidget {
  final String front;
  final String back;
  final String selfie;
  const _DocumentImages({
    required this.front,
    required this.back,
    required this.selfie,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    final items = <(String, String)>[
      ('CNIC Front', ApiEndpoints.publicAsset(front)),
      ('CNIC Back', ApiEndpoints.publicAsset(back)),
      ('Selfie', ApiEndpoints.publicAsset(selfie)),
    ].where((e) => e.$2.isNotEmpty).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DOCUMENTS', style: text.overline),
        const Gap.v(AppSpace.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Gap.h(AppSpace.sm),
              Expanded(
                child: _DocThumb(label: items[i].$1, url: items[i].$2),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DocThumb extends StatelessWidget {
  final String label;
  final String url;
  const _DocThumb({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return GestureDetector(
      onTap: () => _openImageViewer(context, url, label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.brSm,
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: c.surfaceMuted),
                errorWidget: (_, _, _) => Container(
                  color: c.surfaceMuted,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: c.textTertiary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const Gap.v(AppSpace.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.caption,
          ),
        ],
      ),
    );
  }
}

void _openImageViewer(BuildContext context, String url, String label) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (_) => Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpace.xs,
          right: AppSpace.sm,
          child: Material(
            color: Colors.white24,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + AppSpace.md,
          left: 0,
          right: 0,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GRow extends StatelessWidget {
  final String l1, v1, l2, v2;
  const _GRow(this.l1, this.v1, this.l2, this.v2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _GCell(label: l1, value: v1)),
          if (l2.isNotEmpty) ...[
            const Gap.h(AppSpace.sm),
            Expanded(child: _GCell(label: l2, value: v2)),
          ],
        ],
      ),
    );
  }
}

class _GCell extends StatelessWidget {
  final String label;
  final String value;
  const _GCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.caption),
        const Gap.v(AppSpace.xxs),
        Text(
          value.isEmpty || value == 'Not available' ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodySm.copyWith(
            color: context.sellerColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Order tile ────────────────────────────────────────────────────────────────
class _OrderTile extends StatelessWidget {
  final SellerCustomerOrderSummary order;
  final VoidCallback onTap;
  const _OrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: SellerCard(
        onTap: onTap,
        color: c.surfaceAlt,
        elevated: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: text.titleSm,
                  ),
                  const Gap.v(AppSpace.xxs),
                  Text(
                    '${order.formattedTotalDealPrice} · ${order.formattedCreatedAt}',
                    style: text.caption,
                  ),
                ],
              ),
            ),
            SellerStatusPill(label: order.status, dense: true),
            const Gap.h(AppSpace.xxs),
            Icon(
              Icons.chevron_right_rounded,
              color: c.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instalment tile ───────────────────────────────────────────────────────────
class _InstalmentTile extends StatelessWidget {
  final SellerCustomerInstalment item;
  /// Set when this is the instalment the pay endpoint will actually settle
  /// next for its order — see [_payableInstalmentIds]. Null hides the action.
  final VoidCallback? onPay;
  const _InstalmentTile({required this.item, this.onPay});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final tone = SellerStatus.toneFor(item.status, c);
    final isPaid = item.status.toLowerCase() == 'paid';
    final isPayable = onPay != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: SellerCard(
        color: isPaid ? c.successSurface : c.surfaceAlt,
        borderColor: isPayable
            ? c.accent
            : isPaid
                ? c.success.withValues(alpha: 0.25)
                : c.border,
        elevated: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.month, style: text.titleSm),
                      const Gap.v(AppSpace.xxs),
                      Text(
                        '${item.formattedPrice} · ${item.installmentDate}',
                        style: text.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tone.bg,
                    borderRadius: AppRadius.brPill,
                    border: Border.all(color: tone.border),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tone.fg,
                    ),
                  ),
                ),
              ],
            ),
            if (isPayable) ...[
              const Gap.v(AppSpace.xs),
              SellerButton(
                label: 'Pay This Instalment',
                icon: Icons.payments_outlined,
                size: SellerButtonSize.small,
                onPressed: onPay,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Inline helpers ────────────────────────────────────────────────────────────
class _InlineLoading extends StatelessWidget {
  final String label;
  const _InlineLoading({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Row(
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
        Text(label, style: text.bodySm),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    return Text(
      message,
      style: context.sellerText.bodySm.copyWith(color: c.danger),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String label;
  const _EmptyInline({required this.label});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: context.sellerText.bodySm);
}

// ── Full-screen loading (with optional initial-customer preview) ──────────────
class _LoadingView extends StatelessWidget {
  final SellerCustomer? initialCustomer;
  const _LoadingView({this.initialCustomer});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    if (initialCustomer == null) {
      return Center(
        child: CircularProgressIndicator(color: c.accent),
      );
    }

    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        SellerCard(
          child: Row(
            children: [
              SellerMonogram(name: initialCustomer!.name, size: 44),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Text(initialCustomer!.name, style: text.titleSm),
              ),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
        const Gap.v(AppSpace.md),
        const SellerListSkeleton(count: 3, itemHeight: 100),
      ],
    );
  }
}

// ── Pure-logic helpers ────────────────────────────────────────────────────────
String _cleanError(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
}

double _clampPct(String pct) {
  final v = double.tryParse(pct.replaceAll('%', '').trim()) ?? 0;
  return (v / 100).clamp(0.0, 1.0);
}

/// IDs of the instalments the pay endpoint will actually settle next, one per
/// order — the server always marks the first `Unpaid` row of type `Instalment`
/// or `Outstanding` (in schedule order) as `Paid`, regardless of which row in
/// this customer's flat, multi-order list the seller taps.
Set<int> _payableInstalmentIds(List<SellerCustomerInstalment> items) {
  final byOrder = <int, List<SellerCustomerInstalment>>{};
  for (final item in items) {
    byOrder.putIfAbsent(item.orderId, () => []).add(item);
  }

  final payable = <int>{};
  for (final group in byOrder.values) {
    for (final item in group) {
      if (item.status.toLowerCase() != 'paid' &&
          (item.type == 'Instalment' || item.type == 'Outstanding')) {
        payable.add(item.id);
        break;
      }
    }
  }
  return payable;
}

// ── Pay Instalment ────────────────────────────────────────────────────────────
Future<void> _showPayInstalmentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String customerUuid,
  required SellerCustomerInstalment instalment,
}) async {
  final dark = context.sellerIsDark;
  final paid = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: dark ? SellerTheme.dark : SellerTheme.light,
      child: _PayInstalmentSheet(instalment: instalment),
    ),
  );

  if (paid == true) {
    ref.invalidate(sellerCustomerInstalmentsProvider(customerUuid));
    ref.invalidate(sellerCustomerCustomOrdersProvider(customerUuid));
  }
}

/// The server always settles the first `Unpaid` instalment of type
/// `Instalment`/`Outstanding` for the order — [instalment] (selected by
/// [_payableInstalmentIds]) is shown purely as context; its amount seeds the
/// editable field.
class _PayInstalmentSheet extends ConsumerStatefulWidget {
  final SellerCustomerInstalment instalment;

  const _PayInstalmentSheet({required this.instalment});

  @override
  ConsumerState<_PayInstalmentSheet> createState() =>
      _PayInstalmentSheetState();
}

class _PayInstalmentSheetState extends ConsumerState<_PayInstalmentSheet> {
  static const _methods = ['By Hand', 'JazzCash', 'Easypaisa', 'Bank'];

  late final TextEditingController _amountCtrl;
  String? _method;
  File? _receipt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.instalment.installmentPrice.toString(),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null) return;
    setState(() => _receipt = File(picked.path));
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      SnackbarService().showErrorSnackBar('Enter a valid instalment amount.');
      return;
    }
    if (_method == null) {
      SnackbarService().showErrorSnackBar('Please select a payment method.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(sellerCustomOrdersRepositoryProvider).payInstalment(
            orderId: widget.instalment.orderId,
            instalmentPrice: amount.toString(),
            paymentMethod: _method!,
            receipt: _receipt,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      SnackbarService().showSuccessSnackBar('Instalment paid successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService().showErrorSnackBar(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final instalment = widget.instalment;

    return _PaySheetShell(
      title: 'Pay Instalment',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Context — which instalment this payment will settle.
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: AppRadius.brSm,
              border: Border.all(color: c.border),
            ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${instalment.month} • ${instalment.type}',
                        style:
                            text.bodyLg.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Gap.v(2),
                      Text(
                        'Due ${instalment.formattedPrice} on ${instalment.installmentDate}',
                        style: text.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.md),
          Text('Amount collected', style: text.label),
          const Gap.v(AppSpace.xs),
          _PayDecimalField(
            controller: _amountCtrl,
            label: 'Instalment amount',
            enabled: !_saving,
          ),
          const Gap.v(AppSpace.md),
          Text('Payment method', style: text.label),
          const Gap.v(AppSpace.xs),
          _PayMethodChips(
            methods: _methods,
            selected: _method,
            enabled: !_saving,
            onChanged: (m) => setState(() => _method = m),
          ),
          const Gap.v(AppSpace.md),
          Text('Receipt (optional)', style: text.label),
          const Gap.v(AppSpace.xs),
          _PayReceiptPicker(
            receipt: _receipt,
            onPick: _saving ? () {} : _pickReceipt,
            onClear: () => setState(() => _receipt = null),
          ),
          const Gap.v(AppSpace.md),
          SellerButton(
            label: 'Confirm Payment',
            icon: Icons.payments_rounded,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _PaySheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _PaySheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpace.sm,
        right: AppSpace.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.sm,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.lg,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brXl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: text.titleMd)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  ),
                ],
              ),
              const Gap.v(AppSpace.xs),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PayMethodChips extends StatelessWidget {
  final List<String> methods;
  final String? selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _PayMethodChips({
    required this.methods,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: methods.map((m) {
        final isSelected = m == selected;
        return GestureDetector(
          onTap: enabled ? () => onChanged(m) : null,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected ? c.accent : c.surface,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: isSelected ? c.accent : c.border),
            ),
            child: Text(
              m,
              style: text.labelSm.copyWith(
                color: isSelected ? c.onAccent : c.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

/// A whole-number amount field (instalment amounts are never fractional).
class _PayDecimalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;

  const _PayDecimalField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: text.body,
      cursorColor: c.accent,
      decoration: _payInputDecoration(context, label),
    );
  }
}

class _PayReceiptPicker extends StatelessWidget {
  final File? receipt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _PayReceiptPicker({
    required this.receipt,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    if (receipt != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.brSm,
            child: Image.file(
              receipt!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Text(
              receipt!.path.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySm,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
            onPressed: onClear,
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: c.accent, size: 22),
            const Gap.v(AppSpace.xs - 2),
            Text(
              'Upload image',
              style: text.bodySm.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _payInputDecoration(BuildContext context, String label) {
  final c = context.sellerColors;
  final text = context.sellerText;
  return InputDecoration(
    labelText: label,
    labelStyle: text.bodySm,
    floatingLabelStyle: text.labelSm.copyWith(color: c.accent),
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
  );
}
