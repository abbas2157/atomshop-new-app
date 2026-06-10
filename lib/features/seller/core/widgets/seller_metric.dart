import 'package:flutter/material.dart';

import '../design/design.dart';
import 'seller_card.dart';
import 'seller_icon_badge.dart';

/// A featured KPI card — the prominent headline numbers on the dashboard.
class SellerKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final SellerTone? tone;
  final String? caption;
  final VoidCallback? onTap;

  const SellerKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final t = tone ?? c.accentTone;

    return SellerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SellerIconBadge(icon: icon, tone: t, size: 38, iconSize: 19),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, size: 18, color: c.textTertiary),
            ],
          ),
          const Gap.v(AppSpace.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: text.metric),
          ),
          const Gap.v(AppSpace.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySm,
          ),
          if (caption != null) ...[
            const Gap.v(AppSpace.xxs),
            Text(caption!, style: text.caption.copyWith(color: t.fg)),
          ],
        ],
      ),
    );
  }
}

/// A compact stat tile for dense grids — label above a value, optional icon.
class SellerStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final SellerTone? tone;

  const SellerStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    final t = tone ?? c.neutralTone;

    return SellerCard(
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SellerIconBadge(icon: icon!, tone: t, size: 32, iconSize: 17, radius: AppRadius.sm),
            const Gap.v(AppSpace.xs),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: text.metricSm),
          ),
          const Gap.v(2),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.caption),
        ],
      ),
    );
  }
}

/// A labelled progress bar (win rate, recovery %, etc.).
class SellerProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;

  const SellerProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final fill = color ?? c.accent;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: Stack(
        children: [
          Container(height: height, color: c.surfaceMuted),
          LayoutBuilder(
            builder: (context, constraints) => AnimatedContainer(
              duration: AppMotion.slow,
              curve: AppMotion.standard,
              height: height,
              width: constraints.maxWidth * clamped,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadius.brPill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An evenly-distributed grid built from equal-width [Expanded] cells, so rows
/// stay aligned and cards within a row share the same height. The canonical
/// way to lay out KPI / stat / action tiles across the seller app.
class SellerGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double spacing;

  const SellerGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.spacing = AppSpace.sm,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var j = 0; j < columns; j++) {
        final index = i + j;
        cells.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
        if (j < columns - 1) cells.add(SizedBox(width: spacing));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// A label/value row for detail sheets and grouped info sections.
class SellerDataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const SellerDataRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.sellerText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: text.bodySm),
          ),
          const Gap.h(AppSpace.sm),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: emphasize
                  ? text.bodyLg.copyWith(fontWeight: FontWeight.w700)
                  : text.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
