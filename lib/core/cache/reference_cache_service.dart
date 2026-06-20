import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'reference_cache_models.dart';

final referenceCacheServiceProvider = Provider<ReferenceCacheService>(
  (_) => ReferenceCacheService(),
);

/// Persists [ReferenceData] as a single JSON file under the app's support
/// directory. All I/O errors are silently swallowed — a storage failure must
/// never crash the app or block the UI.
class ReferenceCacheService {
  static const _fileName = 'reference_data.json';

  Future<File> _file() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/ref_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  /// Returns the persisted [ReferenceData], or `null` if no cache exists yet.
  Future<ReferenceData?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return ReferenceData.tryFromJsonString(await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  /// Writes [data] to disk. Fire-and-forget safe.
  Future<void> save(ReferenceData data) async {
    try {
      await (await _file()).writeAsString(data.toJsonString());
    } catch (_) {}
  }
}
