import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// CircleVeya Emblem + Wordmark (+ optional Slogan).
class CircleVeyaBrand extends StatelessWidget {
  const CircleVeyaBrand({
    super.key,
    this.onTap,
    this.showSlogan = false,
    this.compact = false,
    this.logoHeight = 40,
    this.emblemOnly = false,
  });

  static const emblemAsset = 'assets/branding/circleveya_emblem.png';
  /// Legacy-Vollbild-Logo (Wordmark im PNG) – bevorzugt [CircleVeyaBrand] Widget.
  static const logoAsset = emblemAsset;

  static const appName = 'CircleVeya';
  static const slogan = 'Find people. Create memories.';

  final VoidCallback? onTap;
  final bool showSlogan;
  final bool compact;
  final double logoHeight;
  final bool emblemOnly;

  @override
  Widget build(BuildContext context) {
    final useCompact = compact ||
        emblemOnly ||
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
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: content,
        ),
      ),
    );
  }

  Widget _buildFullBrand(BuildContext context) {
    final emblemSize = logoHeight + 6;
    final wordmarkSize = logoHeight * 0.62;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          showSlogan ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        _EmblemImage(size: emblemSize),
        SizedBox(width: logoHeight * 0.28),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Wordmark(fontSize: wordmarkSize),
              if (showSlogan) ...[
                SizedBox(height: logoHeight * 0.12),
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
          ),
        ),
      ],
    );
  }

  Widget _buildEmblemOnly() {
    return _EmblemImage(size: logoHeight + 4);
  }
}

class _EmblemImage extends StatelessWidget {
  const _EmblemImage({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.14),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Image.asset(
        CircleVeyaBrand.emblemAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.05,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Circle',
          style: baseStyle.copyWith(color: AppColors.brandNavy),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.brandOrange,
              AppColors.brandMagenta,
              AppColors.brandPurple,
              AppColors.tertiary,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            'Veya',
            style: baseStyle.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
