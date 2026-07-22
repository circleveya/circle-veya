import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/special_badge.dart';

void showSpecialBadgeDetails(BuildContext context, SpecialBadge badge) {
  final lang = Localizations.localeOf(context).languageCode;
  final theme = Theme.of(context);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpecialBadgeImage(badge: badge, size: 132),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              badge.descriptionFor(lang),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SpecialBadgeImage extends StatelessWidget {
  const SpecialBadgeImage({
    super.key,
    required this.badge,
    this.size = 44,
  });

  final SpecialBadge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        badge.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Icon(
          Icons.emoji_events,
          size: size * 0.55,
          color: AppColors.seed,
        ),
      ),
    );
  }
}

class SpecialBadgeButton extends StatelessWidget {
  const SpecialBadgeButton({
    super.key,
    required this.badge,
    this.showLabel = true,
    this.size = 44,
    this.labelFontSize = 13,
  });

  final SpecialBadge badge;
  final bool showLabel;
  final double size;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showSpecialBadgeDetails(context, badge),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpecialBadgeImage(badge: badge, size: size),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                badge.name,
                style: TextStyle(
                  color: const Color(0xFFE6AE41),
                  fontWeight: FontWeight.w800,
                  fontSize: labelFontSize,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
