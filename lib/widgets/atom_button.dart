import 'package:flutter/material.dart';

import '../design/atom_text.dart';
import '../design/atom_tokens.dart';

enum AtomButtonVariant { primary, secondary, dark, light, text }

enum AtomButtonSize { large, medium, small }

/// Pill button used for every action in app v2. The icon is required: every
/// button in the design carries one (owner decision 2026-10-28).
class AtomButton extends StatelessWidget {
  const AtomButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = AtomButtonVariant.primary,
    this.size = AtomButtonSize.large,
    this.expand = false,
    this.loading = false,
    this.iconAfter = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final AtomButtonVariant variant;
  final AtomButtonSize size;
  final bool expand;
  final bool loading;

  /// Put the icon after the label (e.g. "Proceed" with an arrow).
  final bool iconAfter;

  double get _height => switch (size) {
        AtomButtonSize.large => AtomSize.buttonLg,
        AtomButtonSize.medium => AtomSize.button,
        AtomButtonSize.small => AtomSize.buttonSm,
      };

  double get _fontSize => switch (size) {
        AtomButtonSize.large => 16,
        AtomButtonSize.medium => 14,
        AtomButtonSize.small => 13,
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      AtomButtonVariant.primary => (AtomColors.primary, AtomColors.white, null),
      AtomButtonVariant.secondary => (AtomColors.white, AtomColors.ink, AtomColors.line2),
      AtomButtonVariant.dark => (AtomColors.ink, AtomColors.white, null),
      AtomButtonVariant.light => (AtomColors.white, AtomColors.ink, null),
      AtomButtonVariant.text => (Colors.transparent, AtomColors.primary, null),
    };
    final disabled = onPressed == null || loading;
    final iconSize = _fontSize + 3;

    final iconWidget = loading
        ? SizedBox.square(dimension: iconSize - 2, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        : Icon(icon, size: iconSize, color: fg);
    final text = Flexible(
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AtomText.button.copyWith(fontSize: _fontSize, color: fg)),
    );

    final button = Material(
      color: disabled && variant != AtomButtonVariant.text ? bg.withValues(alpha: 0.55) : bg,
      shape: StadiumBorder(side: border == null ? BorderSide.none : BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _height),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size == AtomButtonSize.small ? 14 : 20),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: iconAfter
                  ? [text, const SizedBox(width: 8), iconWidget]
                  : [iconWidget, const SizedBox(width: 8), text],
            ),
          ),
        ),
      ),
    );

    return Semantics(button: true, enabled: !disabled, child: button);
  }
}

/// Round icon-only button (back, notifications, share). Always labelled for
/// screen readers through [tooltip].
class AtomIconButton extends StatelessWidget {
  const AtomIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.dark = false,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool dark;

  /// Small amber dot (unread notifications).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: dark ? Colors.transparent : AtomColors.white,
        shape: CircleBorder(side: BorderSide(color: dark ? AtomColors.white.withValues(alpha: 0.22) : AtomColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: AtomSize.iconButton,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: dark ? AtomColors.white : AtomColors.ink),
                if (badge)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: AtomColors.amber, shape: BoxShape.circle, border: Border.all(color: AtomColors.white, width: 2)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
