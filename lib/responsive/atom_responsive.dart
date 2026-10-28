import 'package:flutter/widgets.dart';

import '../design/atom_tokens.dart';

/// Screen classes used across app v2. Decided by the shortest usable width
/// so a phone in landscape still lays out as a phone.
enum AtomScreen { compact, medium, expanded }

/// Breakpoints in logical pixels.
abstract final class AtomBreakpoints {
  /// Phones: up to 599.
  static const double medium = 600;

  /// Large tablets and foldables open flat: 1024 and up.
  static const double expanded = 1024;

  /// Content never grows wider than this; extra space becomes side margin.
  static const double maxContentWidth = 960;
}

extension AtomResponsiveContext on BuildContext {
  /// Width only: cheaper than `MediaQuery.of`, so a keyboard opening or a
  /// padding change does not rebuild every responsive widget.
  double get atomWidth => MediaQuery.sizeOf(this).width;

  AtomScreen get atomScreen {
    final w = atomWidth;
    if (w >= AtomBreakpoints.expanded) return AtomScreen.expanded;
    if (w >= AtomBreakpoints.medium) return AtomScreen.medium;
    return AtomScreen.compact;
  }

  bool get isCompact => atomScreen == AtomScreen.compact;

  /// Side gutter for the screen class.
  double get atomGutter => switch (atomScreen) {
        AtomScreen.compact => AtomSpace.gutter,
        AtomScreen.medium => AtomSpace.lg,
        AtomScreen.expanded => AtomSpace.xl,
      };

  /// Value picked by screen class.
  T atomPick<T>({required T compact, T? medium, T? expanded}) => switch (atomScreen) {
        AtomScreen.compact => compact,
        AtomScreen.medium => medium ?? compact,
        AtomScreen.expanded => expanded ?? medium ?? compact,
      };
}

/// Number of columns for a grid of cards with a minimum card width, so cards
/// never shrink below [minTileWidth] and never stretch too wide.
int atomGridColumns(double availableWidth, {double minTileWidth = 160, int max = 6}) {
  final cols = (availableWidth / minTileWidth).floor();
  return cols.clamp(2, max);
}

/// Centres page content and caps its width on tablets, keeping the phone
/// layout readable instead of stretching it edge to edge.
class AtomPageWidth extends StatelessWidget {
  const AtomPageWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AtomBreakpoints.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// Keeps the user's text size preference but within a range the layouts are
/// designed for (0.9x to 1.3x). Wrap the app's `builder` with it.
class AtomTextScaleClamp extends StatelessWidget {
  const AtomTextScaleClamp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3);
    return MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: scaler), child: child);
  }
}
