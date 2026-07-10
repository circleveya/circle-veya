import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// CircleVeya Logo – clean, ohne Slogan.
///
/// Assets:
/// - [logoAsset] horizontale Wortmarke (Icon + Text)
/// - [emblemAsset] nur das C-Emblem für enge Flächen
///
/// Skalierung über [ConstrainedBox] + [AspectRatio] (kein starres 20×20).
class CircleVeyaBrand extends StatelessWidget {
  const CircleVeyaBrand({
    super.key,
    this.onTap,
    this.compact = false,
    this.logoHeight = 40,
    this.emblemOnly = false,
    @Deprecated('Slogan entfernt – Parameter wird ignoriert')
    this.showSlogan = false,
  });

  static const logoAsset = 'assets/branding/circleveya_logo.png';
  static const emblemAsset = 'assets/branding/circleveya_emblem.png';

  /// Ungefähres Seitenverhältnis der Wortmarke (Breite / Höhe).
  static const logoAspectRatio = 883 / 226;

  /// Untere Grenze – verhindert „zu klein“-Wirkung im Live-Build.
  static const minLogoExtent = 28.0;

  static const appName = 'CircleVeya';

  final VoidCallback? onTap;
  final bool compact;
  final double logoHeight;
  final bool emblemOnly;

  @Deprecated('Slogan entfernt')
  final bool showSlogan;

  @override
  Widget build(BuildContext context) {
    // Emblem nur bei explizitem compact/emblemOnly (z.B. Mobile-AppBar).
    final useEmblem = compact || emblemOnly;
    final content = useEmblem ? _buildEmblemOnly() : _buildFullLogo();

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.seed.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: content,
        ),
      ),
    );
  }

  Widget _buildFullLogo() {
    final preferred = logoHeight.clamp(minLogoExtent, 72.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        var maxH = preferred;
        if (constraints.maxHeight.isFinite) {
          maxH = maxH < constraints.maxHeight ? maxH : constraints.maxHeight;
        }
        if (constraints.maxWidth.isFinite) {
          final fromWidth = constraints.maxWidth / logoAspectRatio;
          maxH = maxH < fromWidth ? maxH : fromWidth;
        }
        final minH =
            maxH < minLogoExtent ? maxH : minLogoExtent;
        final height = preferred.clamp(minH, maxH);

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minH,
            maxHeight: height,
            maxWidth: height * logoAspectRatio,
          ),
          child: AspectRatio(
            aspectRatio: logoAspectRatio,
            child: Image.asset(
              logoAsset,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, _, _) => _FallbackWordmark(
                height: height,
                showEmblem: true,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmblemOnly() {
    final preferred = logoHeight.clamp(minLogoExtent, 56.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        var maxS = preferred;
        if (constraints.maxHeight.isFinite) {
          maxS = maxS < constraints.maxHeight ? maxS : constraints.maxHeight;
        }
        if (constraints.maxWidth.isFinite) {
          maxS = maxS < constraints.maxWidth ? maxS : constraints.maxWidth;
        }
        final minS = maxS < minLogoExtent ? maxS : minLogoExtent;
        final size = preferred.clamp(minS, maxS);

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minS,
            minHeight: minS,
            maxWidth: size,
            maxHeight: size,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(
              emblemAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, _, _) => Icon(
                Icons.circle_outlined,
                size: size * 0.85,
                color: AppColors.seed,
              ),
            ),
          ),
        );
      },
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
