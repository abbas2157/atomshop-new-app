import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/network/api_endpoints.dart';
import '../design/atom_tokens.dart';

/// The only way app v2 shows a remote picture.
///
/// Memory: the image is decoded at the size it is drawn (`memCacheWidth` =
/// layout width × device pixel ratio), not at the file's full resolution, so a
/// 2000 px product photo in a 170 px card costs ~0.5 MB instead of ~16 MB.
/// Files are kept on disk by cached_network_image, so scrolling back is free.
class AtomNetworkImage extends StatelessWidget {
  const AtomNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholderIcon = Icons.image_outlined,
    this.semanticLabel,
  });

  /// Absolute URL or a stored path (resolved with [ApiEndpoints.publicAsset]).
  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final IconData placeholderIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiEndpoints.publicAsset(url);
    if (resolved.isEmpty) return _Placeholder(icon: placeholderIcon);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.hasBoundedWidth ? (constraints.maxWidth * dpr).round() : null;
        final height = width == null && constraints.hasBoundedHeight ? (constraints.maxHeight * dpr).round() : null;

        return CachedNetworkImage(
          imageUrl: resolved,
          fit: fit,
          alignment: alignment,
          memCacheWidth: width,
          memCacheHeight: height,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, _) => const ColoredBox(color: AtomColors.surface),
          errorWidget: (_, _, _) => _Placeholder(icon: placeholderIcon),
          imageBuilder: semanticLabel == null
              ? null
              : (context, provider) => Semantics(
                    label: semanticLabel,
                    image: true,
                    child: Image(image: provider, fit: fit, alignment: alignment),
                  ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AtomColors.surface,
      child: Center(child: Icon(icon, size: 36, color: AtomColors.placeholder)),
    );
  }
}
