import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// CircleVeya Logo + Wordmark (+ optional Slogan).
class CircleVeyaBrand extends StatelessWidget {
  const CircleVeyaBrand({
    super.key,
    this.onTap,
    this.showSlogan = false,
    this.compact = false,
    this.logoHeight = 40,
  });

  static const logoAsset = 'assets/branding/circleveya_logo.png';
  static const appName = 'CircleVeya';
  static const slogan = 'Find people. Create memories.';

  final VoidCallback? onTap;
  final bool showSlogan;
  final bool compact;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final useCompact = compact ||
        (showSlogan == false &&
            MediaQuery.sizeOf(context).width < AppColors.webBreakpoint);

    final content = useCompact ? _buildEmblemOnly() : _buildFullBrand(context);

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.seed.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
        ),
        if (showSlogan) ...[
          const SizedBox(height: 6),
          Text(
            slogan,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.brandNavy.withValues(alpha: 0.65),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.1,
                ),
          ),
        ],
      ],
    );
  }

  /// Nur das Emblem (linker Teil des Logos) – für enge Viewports.
  Widget _buildEmblemOnly() {
    final size = logoHeight + 4;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 0.34,
          child: Image.asset(
            logoAsset,
            height: size,
            fit: BoxFit.fitHeight,
          ),
        ),
      ),
    );
  }
}
