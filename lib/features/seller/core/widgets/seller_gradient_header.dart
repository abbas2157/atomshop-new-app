import 'package:flutter/material.dart';

import '../design/design.dart';

/// The premium indigo hero header used at the top of primary seller screens.
///
/// Provides a [leading] slot (avatar / icon), a title + subtitle, trailing
/// [actions], and an optional [bottom] widget (e.g. inline KPIs) that sits
/// within the gradient.
class SellerGradientHeader extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;
  final EdgeInsetsGeometry padding;

  /// When true (default), a back button is shown automatically if the current
  /// route can be popped — so pushed screens are never dead-ends, while shell
  /// tabs (which can't pop) keep their [leading] glyph.
  final bool automaticallyImplyLeading;

  const SellerGradientHeader({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.md,
      AppSpace.md,
      AppSpace.lg,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sellerColors;
    final topInset = MediaQuery.of(context).padding.top;
    final showBack =
        automaticallyImplyLeading && Navigator.of(context).canPop();

    return Container(
      decoration: BoxDecoration(
        gradient: c.headerGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: c.gradientEnd.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset) + (padding as EdgeInsets),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showBack) ...[
                  SellerHeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Gap.h(AppSpace.sm),
                ] else if (leading != null) ...[
                  leading!,
                  const Gap.h(AppSpace.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const Gap.v(2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                for (final action in actions) ...[
                  const Gap.h(AppSpace.xs),
                  action,
                ],
              ],
            ),
            if (bottom != null) ...[
              const Gap.v(AppSpace.lg),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A frosted circular icon button for use inside [SellerGradientHeader].
class SellerHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const SellerHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// A frosted pill button (icon + label) for the header (e.g. mode switch).
class SellerHeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SellerHeaderPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: AppRadius.brPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs + 1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const Gap.h(AppSpace.xs - 2),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular monogram avatar (first letter of a name) on the header gradient.
class SellerMonogram extends StatelessWidget {
  final String name;
  final double size;

  const SellerMonogram({super.key, required this.name, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
