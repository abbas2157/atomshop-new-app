import 'package:atompro/core/local_storage/local_storage_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Customer-side theme mode (light / dark / system), persisted across launches.
final customerThemeModeProvider =
    NotifierProvider<CustomerThemeModeNotifier, ThemeMode>(
      CustomerThemeModeNotifier.new,
    );

class CustomerThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'customer_theme_mode';

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

  void set(ThemeMode mode) {
    state = mode;
    _persist(mode);
  }

  /// Light ↔ dark quick toggle (used by the drawer switch).
  void toggle() => set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void _persist(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    LocalStorageMethods.instance.writeData(_key, value);
  }
}
