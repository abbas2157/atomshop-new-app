/// Display helpers shared by every v2 screen (DESIGN.md §1.7–1.8).
abstract final class AtomFormat {
  /// "Rs. 119,999". Whole rupees, thousands separators, no decimals.
  static String rupees(num? value) {
    if (value == null) return 'Rs. —';
    return 'Rs. ${_group(value.round())}';
  }

  /// "119,999" without the prefix, for places that style "Rs." separately.
  static String amount(num value) => _group(value.round());

  static String _group(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return negative ? '-$out' : out.toString();
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// "05 Nov 2026" (d M Y).
  static String date(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
  }

  /// Parses an amount the old API sends formatted ("80,000") or as a number.
  static int? parseAmount(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.round();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return cleaned.isEmpty ? null : double.tryParse(cleaned)?.round();
  }
}
