import 'package:atompro/features/seller/core/design/design.dart';
import 'package:flutter/material.dart';

/// Formats [date] as the calendar-only `Y-m-d` string the seller API expects
/// for backdated payment fields (`payment_date`, `advance_date`).
String formatYmd(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// Human-readable form of a date for the field face, e.g. `10 Sep 2026`.
String formatDayMonthYear(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Opens the shared "collected on" picker. Any past date is allowed; the
/// picker never offers a date after today because the server rejects them.
Future<DateTime?> showSellerPastDatePicker(
  BuildContext context, {
  required DateTime initial,
}) {
  final c = context.sellerColors;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final safeInitial = initial.isAfter(today) ? today : initial;
  return showDatePicker(
    context: context,
    initialDate: safeInitial,
    firstDate: DateTime(2000),
    lastDate: today,
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: c.accent,
              onPrimary: c.onAccent,
              surface: c.surface,
              onSurface: c.textPrimary,
            ),
      ),
      child: child!,
    ),
  );
}

/// Tappable date field used by every form that records an instalment
/// payment (Record Payment, Setup Instalments, Close Deal). Defaults to
/// today and caps selection at today so a backdated payment can be entered
/// but a future one cannot.
class SellerDateField extends StatelessWidget {
  final String label;
  final String? helperText;
  final DateTime value;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  const SellerDateField({
    super.key,
    required this.label,
    this.helperText,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showSellerPastDatePicker(context, initial: value);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final text = context.sellerText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.label),
        const Gap.v(AppSpace.xs),
        InkWell(
          onTap: enabled ? () => _pick(context) : null,
          borderRadius: AppRadius.brMd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm + 2,
            ),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: c.accent),
                const Gap.h(AppSpace.xs),
                Expanded(
                  child: Text(formatDayMonthYear(value), style: text.bodySm),
                ),
                Icon(Icons.expand_more_rounded, size: 18, color: c.textTertiary),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const Gap.v(AppSpace.xs),
          Text(helperText!, style: text.caption),
        ],
      ],
    );
  }
}
