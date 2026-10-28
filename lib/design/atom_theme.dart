import 'package:flutter/material.dart';

import 'atom_text.dart';
import 'atom_tokens.dart';

/// Material theme for app v2. Widgets in `lib/v2/widgets` style themselves
/// from tokens; this theme covers the framework pieces (scaffold, inputs,
/// dialogs, snackbars) so they match.
abstract final class AtomTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AtomColors.primary,
      primary: AtomColors.primary,
      onPrimary: AtomColors.white,
      surface: AtomColors.white,
      onSurface: AtomColors.ink,
      error: AtomColors.rose,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AtomRadius.input),
      borderSide: const BorderSide(color: AtomColors.line2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AtomText.family,
      scaffoldBackgroundColor: AtomColors.white,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: AtomColors.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: AtomColors.white,
        foregroundColor: AtomColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AtomText.heading,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtomColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: AtomSpace.md, vertical: 15),
        hintStyle: AtomText.body.copyWith(color: AtomColors.placeholder),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AtomColors.primary, width: 1.5)),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: AtomColors.rose, width: 1.5)),
        focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: AtomColors.rose, width: 1.5)),
        errorStyle: AtomText.small.copyWith(color: AtomColors.rose),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AtomColors.ink,
        contentTextStyle: AtomText.body.copyWith(color: AtomColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AtomRadius.input)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AtomColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AtomRadius.hero))),
      ),
    );
  }
}
