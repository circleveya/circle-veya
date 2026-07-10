import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// CircleVeya Logo – clean, ohne Slogan.
///
/// Assets:
/// - [logoAsset] horizontale Wortmarke (Icon + Text)
/// - [emblemAsset] nur das C-Emblem für enge Flächen
class CircleVeyaBrand extends StatelessWidget {
  const CircleVeyaBrand({
    super.key,
    this.onTap,
    this.compact = false,
    this.logoHeight = 56,
    this.fillWidth = false,
    this.emblemOnly = false,
    @Deprecated('Slogan entfernt – Parameter wird ignoriert')
    this.showSlogan = false,
  });

  static const logoAsset = 'assets/branding/circleveya_logo.png';
  static const emblemAsset = 'assets/branding/circleveya_emblem.png';

  /// Ungefähres Seitenverhältnis der Wortmarke (Breite / Höhe).
  static const logoAspectRatio = 883 / 226;

  static const minLogoExtent = 32.0;

  static const appName = 'CircleVeya';

  final VoidCallback? onTap;
  final bool compact;

  /// Bevorzugte Höhe, wenn [fillWidth] false ist.
  final double logoHeight;

  /// Füllt die verfügbare Breite (Sidebar) – gleiche Optik lokal & live.
  final bool fillWidth;

  final bool emblemOnly;

  @Deprecated('Slogan entfernt')
  final bool showSlogan;

  @override
  Widget build(BuildContext context) {
    final useEmblem = compact || emblemOnly;
    final content = useEmblem ? _buildEmblemOnly() : _buildFullLogo();

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.seed.withValues(alpha: 0.05),
        child: content,
      ),
    );
  }

  Widget _buildFullLogo() {
    if (fillWidth) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : logoHeight * logoAspectRatio;
          final height = (maxW / logoAspectRatio).clamp(48.0, 72.0);
          final width = height * logoAspectRatio;
          return _logoImage(width: width, height: height);
        },
      );
    }

    final height = logoHeight < minLogoExtent ? minLogoExtent : logoHeight;
    return _logoImage(
      width: height * logoAspectRatio,
      height: height,
    );
  }

  Widget _logoImage({required double width, required double height}) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        logoAsset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _FallbackWordmark(
          height: height,
          showEmblem: true,
        ),
      ),
    );
  }

  Widget _buildEmblemOnly() {
    final size = logoHeight < minLogoExtent ? minLogoExtent : logoHeight;

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        emblemAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (_, _, _) => Icon(
          Icons.circle_outlined,
          size: size * 0.85,
          color: AppColors.seed,
        ),
      ),
    );
  }
}

class _FallbackWordmark extends StatelessWidget {
  const _FallbackWordmark({
    required this.height,
    required this.showEmblem,
  });

  final double height;
  final bool showEmblem;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showEmblem) ...[
          SizedBox(
            width: height,
            height: height,
            child: Image.asset(
              CircleVeyaBrand.emblemAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, _, _) => Icon(
                Icons.circle_outlined,
                size: height * 0.9,
                color: AppColors.seed,
              ),
            ),
          ),
          SizedBox(width: height * 0.22),
        ],
        Text(
          CircleVeyaBrand.appName,
          style: TextStyle(
            fontSize: height * 0.55,
            fontWeight: FontWeight.w700,
            color: AppColors.brandNavy,
            height: 1,
          ),
        ),
      ],
    );
  }
}
