import 'package:atompro/core/local_storage/local_storage_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'seller_colors.dart';
import 'seller_tokens.dart';
import 'seller_typography.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Seller Design System — Theme assembly
///
///  Builds the light & dark [ThemeData] for Seller Mode, wires the
///  [SellerColors] extension, and exposes ergonomic `context.*` accessors.
/// ─────────────────────────────────────────────────────────────────────────
abstract final class SellerTheme {
  static ThemeData get light => _build(SellerColors.light);
  static ThemeData get dark => _build(SellerColors.dark);

  static ThemeData _build(SellerColors c) {
    final brightness = c.isDark ? Brightness.dark : Brightness.light;
    final text = SellerTextTheme(c);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.danger,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.border,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: brightness,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      colorScheme: scheme,
      dividerColor: c.divider,
      splashFactory: InkRipple.splashFactory,
      extensions: [c],

      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMd,
        iconTheme: IconThemeData(color: c.textPrimary),
      ),

      iconTheme: IconThemeData(color: c.textSecondary),

      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        showDragHandle: false,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
        titleTextStyle: text.titleMd,
        contentTextStyle: text.bodySm,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.isDark ? c.surfaceAlt : const Color(0xFF1B2233),
        contentTextStyle: text.bodySm.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionHandleColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.2),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
///  Theme-mode controller (persisted)
/// ─────────────────────────────────────────────────────────────────────────
final sellerThemeModeProvider =
    NotifierProvider<SellerThemeModeNotifier, ThemeMode>(
      SellerThemeModeNotifier.new,
    );

class SellerThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'seller_theme_mode';

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  Future<void> _restore() async {
    final stored = await LocalStorageMethods.instance.readData(_key);
    if (stored == 'dark') {
      state = ThemeMode.dark;
    } else if (stored == 'system') {
      state = ThemeMode.system;
    } else if (stored == 'light') {
      state = ThemeMode.light;
    }
  }

  void _persist(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    LocalStorageMethods.instance.writeData(_key, value);
  }

  void set(ThemeMode mode) {
    state = mode;
    _persist(mode);
  }

  /// Quick light ↔ dark toggle used by the dashboard header.
  void toggle() {
    set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Wraps a subtree (the Seller shell + its tabs) in the resolved seller theme.
///
/// The customer side of the app is untouched; only the seller experience opts
/// into this theme, which is what unlocks full dark mode for Seller Mode.
class SellerThemeScope extends ConsumerWidget {
  final Widget child;
  const SellerThemeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(sellerThemeModeProvider);
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);
    return AnimatedTheme(
      data: isDark ? SellerTheme.dark : SellerTheme.light,
      duration: AppMotion.base,
      child: child,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
///  Ergonomic context accessors
/// ─────────────────────────────────────────────────────────────────────────
extension SellerThemeContext on BuildContext {
  /// Resolved seller colour palette for the current brightness.
  SellerColors get sellerColors =>
      Theme.of(this).extension<SellerColors>() ?? SellerColors.light;

  /// Colour-aware seller type scale.
  SellerTextTheme get sellerText => SellerTextTheme(sellerColors);

  bool get sellerIsDark => sellerColors.isDark;

  /// Push a seller screen as its own route, re-applying [SellerThemeScope] so
  /// the destination resolves the seller theme (incl. dark mode) even though
  /// it sits outside the shell's scope on the root navigator.
  Future<T?> pushSeller<T>(Widget screen) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => SellerThemeScope(child: screen)),
    );
  }
}
