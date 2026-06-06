import 'package:flutter/material.dart';

import '../design/design.dart';

enum SellerButtonVariant { primary, secondary, ghost, danger }

enum SellerButtonSize { regular, small }

/// The single button used across Seller Mode. Consistent height, radius,
/// weight and loading behaviour for every call-to-action.
class SellerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SellerButtonVariant variant;
  final SellerButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool expand;

  const SellerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SellerButtonVariant.primary,
    this.size = SellerButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = true,
  });

  const SellerButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SellerButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = true,
  }) : variant = SellerButtonVariant.secondary;

  const SellerButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SellerButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
  }) : variant = SellerButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final disabled = onPressed == null || loading;
    final isSmall = size == SellerButtonSize.small;
    final height = isSmall ? 40.0 : 52.0;

    late final Color bg;
    late final Color fg;
    late final Color? borderColor;

    switch (variant) {
      case SellerButtonVariant.primary:
        bg = c.accent;
        fg = c.onAccent;
        borderColor = null;
      case SellerButtonVariant.secondary:
        bg = c.isDark ? c.surfaceAlt : c.surface;
        fg = c.textPrimary;
        borderColor = c.borderStrong;
      case SellerButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.accent;
        borderColor = null;
      case SellerButtonVariant.danger:
        bg = c.danger;
        fg = Colors.white;
        borderColor = null;
    }

    final br = AppRadius.brMd;

    final child = AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: disabled && !loading ? 0.55 : 1,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(fg),
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: isSmall ? 16 : 18, color: fg),
              const Gap.h(AppSpace.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: fg,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const Gap.h(AppSpace.xs),
              Icon(trailingIcon, size: isSmall ? 16 : 18, color: fg),
            ],
          ],
        ],
      ),
    );

    return Material(
      color: bg,
      borderRadius: br,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: br,
        splashColor: fg.withValues(alpha: 0.12),
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? AppSpace.md : AppSpace.lg),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: br,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.4)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
