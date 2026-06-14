import 'package:atompro/features/seller/core/design/design.dart';
import 'package:atompro/features/seller/core/widgets/widgets.dart';
import 'package:atompro/features/seller/reports/model/seller_reports_model.dart';
import 'package:atompro/features/seller/reports/viewmodel/seller_reports_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerAgingReportScreen extends ConsumerWidget {
  const SellerAgingReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sellerColors;
    final state = ref.watch(sellerAgingReportProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: [
          SellerGradientHeader(
            leading: const _Glyph(icon: Icons.schedule_outlined),
            title: 'Aging Report',
            subtitle: 'Overdue instalments by time bucket',
            actions: const [SellerNotificationBell(), SellerHeaderProfileButton()],
          ),
          Expanded(
            child: state.when(
              loading: () => const SellerListSkeleton(),
              error: (e, _) => SellerErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(sellerAgingReportProvider),
              ),
              data: (data) => RefreshIndicator(
                color: c.accent,
                backgroundColor: c.surface,
                onRefresh: () async {
                  ref.invalidate(sellerAgingReportProvider);
                  await ref.read(sellerAgingReportProvider.future);
                },
                child: _AgingBody(data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgingBody extends StatelessWidget {
  final AgingResponse data;
  const _AgingBody({required this.data});

  static const _bucketOrder = ['0-30', '31-60', '61-90', '90+'];

  SellerTone _bucketTone(String key, SellerColors c) {
    switch (key) {
      case '0-30':  return c.infoTone;
      case '31-60': return c.warningTone;
      case '61-90': return c.warningTone;
      default:      return c.warningTone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;

    return ListView(
      padding: AppInsets.pageWithNav,
      children: [
        // Grand total
        SellerGrid(
          children: [
            SellerKpiCard(
              label: 'Total Overdue',
              value: _money(data.total),
              icon: Icons.warning_amber_rounded,
              tone: c.warningTone,
              caption: '${data.count} instalments',
            ),
          ],
        ),
        const Gap.v(AppSpace.lg),
        // Buckets
        ..._bucketOrder.map((key) {
          final bucket = data.buckets[key];
          if (bucket == null) return const SizedBox.shrink();
          return _BucketSection(
            bucket: bucket,
            tone: _bucketTone(key, c),
          );
        }),
      ],
    );
  }

  static String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return 'Rs $buf';
  }
}

class _BucketSection extends StatelessWidget {
  final AgingBucket bucket;
  final SellerTone tone;
  const _BucketSection({required this.bucket, required this.tone});

  static String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return 'Rs $buf';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SellerSectionHeader(
          overline: '${bucket.count} items',
          title: bucket.label,
          actionLabel: _money(bucket.total),
        ),
        const Gap.v(AppSpace.sm),
        if (bucket.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.lg),
            child: SellerCard(
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: c.success),
                  const Gap.h(AppSpace.xs),
                  Text('No overdue in this range', style: text.bodySm),
                ],
              ),
            ),
          )
        else ...[
          ...bucket.rows.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _AgingRowCard(row: row, tone: tone),
          )),
          const Gap.v(AppSpace.sm),
        ],
      ],
    );
  }
}

class _AgingRowCard extends StatelessWidget {
  final AgingRow row;
  final SellerTone tone;
  const _AgingRowCard({required this.row, required this.tone});

  static String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return 'Rs $buf';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;

    return SellerCard(
      accentEdge: tone.fg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xs, vertical: AppSpace.xxs),
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: tone.border),
            ),
            child: Text(
              '${row.days}d',
              style: text.caption.copyWith(
                  color: tone.fg, fontWeight: FontWeight.w800),
            ),
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${row.customerName} · ${row.customerPhone}',
                    style: text.titleSm),
                const Gap.v(AppSpace.xxs),
                Text(row.productTitle,
                    style: text.bodySm.copyWith(color: c.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const Gap.v(AppSpace.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${row.orderNo} · Month ${row.month}',
                        style: text.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap.h(AppSpace.xs),
                    Text(row.dueDate, style: text.caption),
                  ],
                ),
              ],
            ),
          ),
          const Gap.h(AppSpace.sm),
          Text(_money(row.amount),
              style: text.titleSm.copyWith(
                  color: tone.fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  final IconData icon;
  const _Glyph({required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    width: 42, height: 42, alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: AppRadius.brMd,
    ),
    child: Icon(icon, color: Colors.white, size: 22),
  );
}
