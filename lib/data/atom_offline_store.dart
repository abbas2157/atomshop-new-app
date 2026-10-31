import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// What the app keeps on the phone to work offline: the last city and area
/// lists, the app settings, the customer's profile and the outbox. Small
/// JSON files in the app's private folder (no other app can read them),
/// read once and then kept in memory.
abstract final class AtomOfflineStore {
  static Future<Directory>? _root;
  static final Map<String, Object?> _memory = {};

  static Future<Directory> _dir() => _root ??= () async {
        final dir = Directory('${(await getApplicationSupportDirectory()).path}/offline');
        await dir.create(recursive: true);
        return dir;
      }();

  static String _safe(String key) => key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  /// The saved value for [key], or null.
  static Future<Object?> read(String key) async {
    if (_memory.containsKey(key)) return _memory[key];
    Object? value;
    try {
      final file = File('${(await _dir()).path}/${_safe(key)}.json');
      if (await file.exists()) value = jsonDecode(await file.readAsString());
    } catch (_) {
      // A damaged file is treated as nothing saved.
    }
    return _memory[key] = value;
  }

  /// Saves [value] (JSON types only). Written to a temporary file first, so
  /// a crash mid-write never leaves half a file.
  static Future<void> write(String key, Object? value) async {
    _memory[key] = value;
    try {
      final dir = await _dir();
      final tmp = File('${dir.path}/${_safe(key)}.tmp');
      await tmp.writeAsString(jsonEncode(value), flush: true);
      await tmp.rename('${dir.path}/${_safe(key)}.json');
    } catch (_) {
      // Memory still has it for this session.
    }
  }

  static Future<void> delete(String key) async {
    _memory.remove(key);
    try {
      final file = File('${(await _dir()).path}/${_safe(key)}.json');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Copies a picked photo into the app's folder: the picker's own copy is
  /// temporary and Android may delete it before the outbox sends it.
  static Future<String> keepFile(String path) async {
    final dir = Directory('${(await _dir()).path}/files');
    await dir.create(recursive: true);
    final dot = path.lastIndexOf('.');
    final ext = dot > path.lastIndexOf('/') ? path.substring(dot) : '';
    final r = Random.secure();
    final name = '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(1 << 32)}$ext';
    return (await File(path).copy('${dir.path}/$name')).path;
  }

  /// Deletes a file [keepFile] made (others are left alone).
  static Future<void> dropFile(String path) async {
    try {
      if (!path.replaceAll(r'\', '/').contains('/offline/files/')) return;
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
