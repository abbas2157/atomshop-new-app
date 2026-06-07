import 'seller_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Seller Design System — Status → Tone mapping
///
///  Replaces the 6+ near-identical `_statusColors()` helpers that were
///  duplicated across leads / orders / instalments / customers / dashboard.
///  One source of truth so a "Pending" badge looks the same everywhere.
/// ─────────────────────────────────────────────────────────────────────────
abstract final class SellerStatus {
  /// Resolve any free-text status string into a semantic [SellerTone].
  static SellerTone toneFor(String? status, SellerColors c) {
    final s = (status ?? '').toLowerCase().trim();
    if (s.isEmpty) return c.neutralTone;

    // ── Positive / completed / paid / won ─────────────────────────────────
    if (_has(s, const [
      'complete',
      'delivered',
      'deliver',
      'paid',
      'won',
      'active',
      'approved',
      'success',
      'closed won',
      'settled',
      'verified',
      'confirmed',
    ])) {
      return c.successTone;
    }

    // ── Negative / failed / cancelled / lost ─────────────────────────────
    if (_has(s, const [
      'cancel',
      'lost',
      'rejected',
      'declined',
      'failed',
      'overdue',
      'expired',
      'no response',
      'unpaid',
      'blocked',
      'inactive',
      'default',
    ])) {
      return c.dangerTone;
    }

    // ── In-progress / pending / awaiting ─────────────────────────────────
    if (_has(s, const [
      'pending',
      'process',
      'instalment',
      'installment',
      'partial',
      'await',
      'review',
      'hold',
      'follow',
      'in progress',
      'shipped',
      'dispatch',
      'due',
    ])) {
      return c.warningTone;
    }

    // ── Neutral informational (new / contacted / draft) ──────────────────
    if (_has(s, const ['new', 'contact', 'open', 'draft', 'lead', 'created', 'trial'])) {
      return c.infoTone;
    }

    return c.neutralTone;
  }

  static bool _has(String s, List<String> needles) {
    for (final n in needles) {
      if (s.contains(n)) return true;
    }
    return false;
  }
}
