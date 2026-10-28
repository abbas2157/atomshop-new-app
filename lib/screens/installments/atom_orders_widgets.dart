import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/atom_account.dart';
import '../../design/atom_text.dart';
import '../../design/atom_tokens.dart';
import '../../utils/atom_format.dart';
import '../../widgets/atom_network_image.dart';
import '../../widgets/atom_surfaces.dart';

/// Pieces shared by the orders, order detail, installments and payments
/// screens.

/// Opens the dialler with [phone].
Future<void> atomCall(String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.isEmpty) return;
  await launchUrl(Uri(scheme: 'tel', path: digits));
}

/// How a schedule row is shown.
enum ScheduleTone { paid, overdue, due, upcoming }

/// Paid and overdue as the server says; the first other unpaid month is
/// "Due", the rest "Upcoming".
List<ScheduleTone> scheduleTones(List<Installment> rows) {
  var dueShown = false;
  final tones = <ScheduleTone>[];
  for (final r in rows) {
    switch (r.status) {
      case InstallmentStatus.paid:
        tones.add(ScheduleTone.paid);
      case InstallmentStatus.overdue:
        tones.add(ScheduleTone.overdue);
      case InstallmentStatus.unpaid:
        tones.add(dueShown ? ScheduleTone.upcoming : ScheduleTone.due);
        dueShown = true;
    }
  }
  return tones;
}

/// Rounded tile with the product picture (or a box icon).
class OrderThumb extends StatelessWidget {
  const OrderThumb({super.key, required this.pictureUrl, this.size = 44, this.dark = false});

  final String pictureUrl;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: dark ? AtomColors.white.withValues(alpha: 0.12) : AtomColors.surface, borderRadius: BorderRadius.circular(12)),
      child: pictureUrl.isEmpty
          ? Icon(Icons.inventory_2_outlined, size: size * 0.45, color: dark ? AtomColors.white : AtomColors.muted)
          : AtomNetworkImage(pictureUrl, fit: BoxFit.contain, placeholderIcon: Icons.inventory_2_outlined),
    );
  }
}

/// One month of a payment schedule.
class ScheduleRow extends StatelessWidget {
  const ScheduleRow({super.key, required this.row, required this.tone, this.onTap});

  final Installment row;
  final ScheduleTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (dot, badge) = switch (tone) {
      ScheduleTone.paid => (AtomColors.green, const AtomBadge('Paid', tone: AtomTone.green)),
      ScheduleTone.overdue => (AtomColors.rose, const AtomBadge('Overdue', tone: AtomTone.rose)),
      ScheduleTone.due => (AtomColors.amber, const AtomBadge('Due', tone: AtomTone.amber)),
      ScheduleTone.upcoming => (AtomColors.line2, const AtomBadge('Upcoming')),
    };
    final date = row.status == InstallmentStatus.paid ? (row.paidAt ?? row.dueDate) : row.dueDate;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 12),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: AtomSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.label, style: AtomText.label),
                  Text(date == null ? 'Date set at delivery' : AtomFormat.date(date), style: AtomText.small),
                ],
              ),
            ),
            Text(AtomFormat.rupees(row.amount), style: AtomText.label),
            const SizedBox(width: AtomSpace.xs),
            badge,
            if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 20, color: AtomColors.placeholder),
          ],
        ),
      ),
    );
  }
}

/// White card holding schedule rows separated by hairlines.
class ScheduleList extends StatelessWidget {
  const ScheduleList({super.key, required this.rows, required this.onOpenReceipt, this.onOpenOther});

  final List<Installment> rows;
  final ValueChanged<int> onOpenReceipt;

  /// Unpaid rows (e.g. open the order); null leaves them untappable.
  final VoidCallback? onOpenOther;

  @override
  Widget build(BuildContext context) {
    final tones = scheduleTones(rows);
    return AtomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AtomColors.line),
            ScheduleRow(
              row: rows[i],
              tone: tones[i],
              onTap: rows[i].status == InstallmentStatus.paid && rows[i].id != null ? () => onOpenReceipt(rows[i].id!) : onOpenOther,
            ),
          ],
        ],
      ),
    );
  }
}

/// Navy box with a headline figure and small label/value pairs.
class DarkFigures extends StatelessWidget {
  const DarkFigures({super.key, required this.label, required this.amount, required this.items});

  final String label;
  final int amount;

  /// (label, value, highlight).
  final List<(String, String, bool)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AtomSpace.md),
      decoration: BoxDecoration(color: AtomColors.ink, borderRadius: BorderRadius.circular(AtomRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AtomText.body.copyWith(fontSize: 13, color: AtomColors.onDark)),
          Text(AtomFormat.rupees(amount), style: AtomText.title.copyWith(color: AtomColors.white, fontSize: 28)),
          if (items.isNotEmpty) ...[
            const SizedBox(height: AtomSpace.sm),
            Row(
              children: [
                for (final (l, v, hi) in items)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l, style: AtomText.small.copyWith(color: AtomColors.onDark)),
                        Text(v, style: AtomText.label.copyWith(color: hi ? AtomColors.amber : AtomColors.white)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A centred message with an icon, used inside lists.
class ListMessage extends StatelessWidget {
  const ListMessage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AtomSpace.lg), child: Center(child: child));
}
