import 'package:flutter/painting.dart';

/// Memory budget for decoded images, applied once at start-up.
///
/// Flutter's default (100 MB / 1000 images) is generous for a catalogue app
/// that scrolls long product grids on low-end Android phones. Product photos
/// are decoded at their on-screen size by [AtomNetworkImage], so 60 MB holds
/// several screens of cards. Flutter already empties this cache when the OS
/// reports memory pressure (PaintingBinding.handleMemoryPressure).
abstract final class AtomImageMemory {
  static const int maxBytes = 60 << 20;
  static const int maxImages = 250;

  static void configure() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = maxBytes;
    cache.maximumSize = maxImages;
  }

  /// Frees decoded images, e.g. after leaving a long product list.
  static void trim() => PaintingBinding.instance.imageCache.clear();
}
