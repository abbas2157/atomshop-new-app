import 'package:flutter/material.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';
import 'atom_focus_ring.dart';

/// Bordered card: 20 px radius, 1 px line, no shadow. Tappable when [onTap]
/// is set.
class AtomCard extends StatelessWidget {
  const AtomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AtomSpace.md),
    this.color = AtomColors.white,
    this.borderColor = AtomColors.line,
    this.radius = AtomRadius.card,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return AtomFocusRing(
      shape: shape,
      builder: (context, onFocusChange) => Material(
        color: color,
        shape: shape.copyWith(side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, onFocusChange: onFocusChange, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Section title with an optional "View all" link (which carries an icon).
class AtomSectionHeader extends StatelessWidget {
  const AtomSectionHeader({super.key, required this.title, this.subtitle, this.actionLabel, this.onAction, this.leading});

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: AtomSpace.xs)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AtomText.heading),
              if (subtitle != null) Text(subtitle!, style: AtomText.body.copyWith(fontSize: 13)),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            label: Text(actionLabel!, style: AtomText.label.copyWith(color: AtomColors.primary)),
            style: TextButton.styleFrom(foregroundColor: AtomColors.primary, minimumSize: const Size(44, 44)),
          ),
      ],
    );
  }
}

enum AtomTone { neutral, blue, amber, green, rose, violet, teal, dark }

/// Status pill. Never wraps. One tone per status everywhere (style guide).
class AtomBadge extends StatelessWidget {
  const AtomBadge(this.label, {super.key, this.tone = AtomTone.neutral, this.icon});

  final String label;
  final AtomTone tone;
  final IconData? icon;

  /// Order status → tone, using the API's values ("Varification" included).
  factory AtomBadge.orderStatus(String status, {Key? key}) {
    final s = status.toLowerCase();
    final (label, tone) = switch (s) {
      'pending' => ('Pending', AtomTone.neutral),
      'varification' || 'verification' => ('Verification', AtomTone.blue),
      'processing' => ('Processing', AtomTone.violet),
      'delivered' => ('Delivered', AtomTone.teal),
      'instalments' || 'installments' => ('Installments', AtomTone.amber),
      'completed' => ('Completed', AtomTone.green),
      'cancelled' => ('Cancelled', AtomTone.rose),
      _ => (status, AtomTone.neutral),
    };
    return AtomBadge(label, key: key, tone: tone);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AtomTone.neutral => (AtomColors.surface, AtomColors.body),
      AtomTone.blue => (AtomColors.primarySoft, AtomColors.primary),
      AtomTone.amber => (AtomColors.amberSoft, AtomColors.amberInk),
      AtomTone.green => (AtomColors.greenSoft, AtomColors.green),
      AtomTone.rose => (AtomColors.roseSoft, AtomColors.rose),
      AtomTone.violet => (AtomColors.violetSoft, AtomColors.violet),
      AtomTone.teal => (AtomColors.tealSoft, AtomColors.teal),
      AtomTone.dark => (AtomColors.ink, AtomColors.amber),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AtomRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(label, maxLines: 1, softWrap: false, style: AtomText.small.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

/// Selectable chip (months, advance %, brand filters, tabs). Text only by
/// design; selection is shown by colour and a semantics flag.
class AtomChoiceChip extends StatelessWidget {
  const AtomChoiceChip({super.key, required this.label, required this.selected, required this.onTap, this.dark = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Dark filled style for filter rows; otherwise the soft blue style.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = selected
        ? (dark ? (AtomColors.ink, AtomColors.white, AtomColors.ink) : (AtomColors.primarySoft, AtomColors.primary, AtomColors.primary))
        : (AtomColors.white, AtomColors.ink, AtomColors.line2);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(dark ? AtomRadius.pill : AtomRadius.chip));
    return Semantics(
      selected: selected,
      button: true,
      child: AtomFocusRing(
        shape: shape,
        builder: (context, onFocusChange) => Material(
          color: bg,
          shape: shape.copyWith(side: BorderSide(color: border, width: selected && !dark ? 1.5 : 1)),
          child: InkWell(
            onTap: onTap,
            onFocusChange: onFocusChange,
            customBorder: shape,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AtomSize.iconButton, minWidth: AtomSize.iconButton),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  child: Text(label, style: AtomText.label.copyWith(color: fg, fontWeight: selected ? FontWeight.w800 : FontWeight.w700)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented tabs in a soft pill track (Installment / AtomPay / Cash, etc.).
class AtomSegmented<T> extends StatelessWidget {
  const AtomSegmented({super.key, required this.items, required this.value, required this.onChanged});

  final Map<T, String> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AtomColors.surface, borderRadius: BorderRadius.circular(AtomRadius.pill), border: Border.all(color: AtomColors.line)),
      child: Row(
        children: [
          for (final entry in items.entries)
            Expanded(
              child: Semantics(
                selected: entry.key == value,
                button: true,
                child: AtomFocusRing(
                  shape: const StadiumBorder(),
                  builder: (context, onFocusChange) => Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => onChanged(entry.key),
                      onFocusChange: onFocusChange,
                      customBorder: const StadiumBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: AtomSize.iconButton,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: entry.key == value ? AtomColors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(AtomRadius.pill),
                          boxShadow: entry.key == value ? const [BoxShadow(color: Color(0x1A14213D), blurRadius: 8, offset: Offset(0, 2))] : null,
                        ),
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtomText.label.copyWith(fontSize: 13, color: entry.key == value ? AtomColors.ink : AtomColors.body),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Row card that leads somewhere else: icon tile, title, one line, chevron.
/// Used for "Can't find your model?" and similar links under lists.
class AtomLinkCard extends StatelessWidget {
  const AtomLinkCard({super.key, required this.icon, required this.title, required this.message, required this.onTap});

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: AtomCard(
        onTap: onTap,
        borderColor: AtomColors.line2,
        padding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AtomColors.primarySoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: AtomColors.primary),
            ),
            const SizedBox(width: AtomSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AtomText.label.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(message, style: AtomText.small.copyWith(color: AtomColors.body)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AtomColors.placeholder),
          ],
        ),
      ),
    );
  }
}
