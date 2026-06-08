import 'package:flutter/material.dart';
import 'package:atompro/core/style/color_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final double? placeHolderheight;
  final double? placeHolderwidth;
  final double borderRadius;
  final BoxFit fit;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.placeHolderheight,
    this.placeHolderwidth,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit,

        /// 🔄 Loading Placeholder
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: ColorPalette.surfaceGray,
          highlightColor: ColorPalette.surface,
          child: Container(
            height: placeHolderheight,
            width: placeHolderwidth,
            color: ColorPalette.surface,
          ),
        ),

        /// ❌ Error Widget
        errorWidget: (context, url, error) => Container(
          height: height,
          width: width,
          color: ColorPalette.surfaceGray,
          child: Icon(
            Icons.broken_image_outlined,
            color: ColorPalette.textSecondary,
            size: 40,
          ),
        ),
      ),
    );
  }
}
