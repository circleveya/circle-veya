import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// CircleVeya Logo (+ optional Slogan).
///
/// Nutzt getrennte Assets:
/// - [logoAsset] horizontale Wortmarke (Icon + Text)
/// - [emblemAsset] nur das C-Emblem für enge Flächen
class CircleVeyaBrand extends StatelessWidget {
  const CircleVeyaBrand({
    super.key,
    this.onTap,
    this.showSlogan = false,
    this.compact = false,
    this.logoHeight = 40,
    this.emblemOnly = false,
  });

  static const logoAsset = 'assets/branding/circleveya_logo.png';
  static const emblemAsset = 'assets/branding/circleveya_emblem.png';

  static const appName = 'CircleVeya';
  static const slogan = 'Find people. Create memories.';

  final VoidCallback? onTap;
  final bool showSlogan;
  final bool compact;
  final double logoHeight;
  final bool emblemOnly;

  @override
  Widget build(BuildContext context) {
    final useEmblem = compact ||
        emblemOnly ||
        (showSlogan == false &&
            MediaQuery.sizeOf(context).width < AppColors.webBreakpoint);

    final content =
        useEmblem ? _buildEmblemOnly() : _buildFullBrand(context);

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.seed.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: content,
        ),
      ),
    );
  }

  Widget _buildFullBrand(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          logoAsset,
          height: logoHeight,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _FallbackWordmark(
            height: logoHeight,
            showEmblem: true,
          ),
        ),
        if (showSlogan) ...[
          SizedBox(height: logoHeight * 0.18),
          Text(
            slogan,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.brandNavy.withValues(alpha: 0.62),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.15,
                  height: 1.2,
                ),
          ),
        ],
      ],
    );
  }

  /// Eigenes Emblem-Asset – keine Clipping-Hacks mehr.
  Widget _buildEmblemOnly() {
    final size = logoHeight;
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        emblemAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
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
          Image.asset(
            CircleVeyaBrand.emblemAsset,
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => Icon(
              Icons.circle_outlined,
              size: height * 0.9,
              color: AppColors.seed,
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
