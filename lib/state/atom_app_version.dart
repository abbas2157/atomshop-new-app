import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'atom_catalogue_providers.dart';

/// This build's version ("2.0.0"), for the Account footer and update checks.
final appVersionProvider = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);

enum AppUpdate { none, available, required }

/// Android: what Google Play says about this install, or null when Play
/// can't answer (debug or sideloaded builds, no Play services, offline).
final playUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  if (!Platform.isAndroid) return null;
  try {
    return await InAppUpdate.checkForUpdate();
  } catch (_) {
    return null;
  }
});

/// Any newer build on Google Play is a required update, as is a version
/// below `version.min` from GET api/app/config (APP_MIN_VERSION on the
/// server; the only gate on iOS). Below `version.latest` is a one-time
/// prompt, unless Play already answered (Play knows what this phone can get).
/// Unknown or unreadable versions never block the app.
final appUpdateProvider = FutureProvider<AppUpdate>((ref) async {
  final play = await ref.watch(playUpdateProvider.future);
  if (play != null && play.updateAvailability != UpdateAvailability.updateNotAvailable && play.updateAvailability != UpdateAvailability.unknown) {
    return AppUpdate.required;
  }
  final config = await ref.watch(appConfigProvider.future);
  final current = await ref.watch(appVersionProvider.future);
  if (compareVersions(current, config.minVersion) < 0) return AppUpdate.required;
  if (play == null && compareVersions(current, config.latestVersion) < 0) return AppUpdate.available;
  return AppUpdate.none;
});

/// Semantic compare of "1.2.3" style versions: negative when [a] is older.
/// An empty or unparsable side counts as equal, so it never forces an update.
@visibleForTesting
int compareVersions(String a, String b) {
  List<int>? parts(String v) {
    final core = v.trim().split('+').first;
    if (core.isEmpty) return null;
    final out = <int>[];
    for (final p in core.split('.')) {
      final n = int.tryParse(p);
      if (n == null) return null;
      out.add(n);
    }
    return out;
  }

  final x = parts(a), y = parts(b);
  if (x == null || y == null) return 0;
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}
