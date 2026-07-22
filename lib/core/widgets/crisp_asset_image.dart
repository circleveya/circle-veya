import 'package:flutter/material.dart';

/// Scharfe Darstellung von PNG-Assets auf Web und HiDPI-Displays.
class CrispAssetImage extends StatelessWidget {
  const CrispAssetImage({
    super.key,
    required this.assetPath,
    required this.size,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String assetPath;
  final double size;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final cache = (size * ratio).round().clamp(64, 2048);

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
      cacheWidth: cache,
      cacheHeight: cache,
      isAntiAlias: true,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }
}
