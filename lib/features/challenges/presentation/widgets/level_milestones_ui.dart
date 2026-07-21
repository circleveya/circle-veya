import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/level_milestone.dart';

/// Zeigt Erklärung eines Level-Badges (Level, Name, Beschreibung).
void showLevelMilestoneDetails(
  BuildContext context,
  LevelMilestone milestone, {
  required bool unlocked,
}) {
  final l10n = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LevelBadgeImage(
                milestone: milestone,
                size: 132,
                unlocked: unlocked,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.levelLabel(milestone.level),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.seed,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                milestone.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!unlocked) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.badgeStillLocked(milestone.level),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                milestone.descriptionFor(lang),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Badge-Bild (mit Fallback-Icon, wenn kein Asset vorhanden).
class LevelBadgeImage extends StatelessWidget {
  const LevelBadgeImage({
    super.key,
    required this.milestone,
    this.size = 72,
    this.unlocked = true,
  });

  final LevelMilestone milestone;
  final double size;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

    Widget image;
    if (milestone.hasBadgeImage) {
      image = Image.asset(
        milestone.assetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Icon(
          Icons.emoji_events,
          size: size * 0.55,
          color: unlocked ? AppColors.seed : muted,
        ),
      );
    } else {
      image = Icon(
        unlocked ? Icons.emoji_events : Icons.lock_outline,
        size: size * 0.55,
        color: unlocked ? AppColors.seed : muted,
      );
    }

    if (!unlocked && milestone.hasBadgeImage) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.55, 0,
        ]),
        child: Opacity(opacity: 0.75, child: image),
      );
    }

    return image;
  }
}

/// Kompaktes Badge neben Level im Profil-Header.
class LevelMilestoneChip extends StatelessWidget {
  const LevelMilestoneChip({
    super.key,
    required this.milestone,
    this.onTap,
    this.light = false,
  });

  final LevelMilestone milestone;
  final VoidCallback? onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : AppColors.brandNavy;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LevelBadgeImage(milestone: milestone, size: 26),
            const SizedBox(width: 6),
            Text(
              milestone.name,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raster: freigeschaltet + noch offen.
class LevelMilestonesGallery extends StatelessWidget {
  const LevelMilestonesGallery({
    super.key,
    required this.userLevel,
    this.padding = const EdgeInsets.all(24),
  });

  final int userLevel;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final unlocked = LevelMilestone.unlocked(userLevel);
    final locked = LevelMilestone.locked(userLevel);
    final current = LevelMilestone.currentFor(userLevel);

    return ListView(
      padding: padding,
      children: [
        Text(
          l10n.levelLabel(userLevel),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (current != null) ...[
          const SizedBox(height: 12),
          Center(
            child: InkWell(
              onTap: () => showLevelMilestoneDetails(
                context,
                current,
                unlocked: true,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    LevelBadgeImage(milestone: current, size: 120),
                    const SizedBox(height: 10),
                    Text(
                      current.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.seed,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current.descriptionFor(
                        Localizations.localeOf(context).languageCode,
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Text(
            l10n.noBadgeYetHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 28),
        Text(
          l10n.unlockedBadges(unlocked.length),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.unlockedBadgesHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (unlocked.isEmpty)
          Text(
            l10n.noBadgesYet,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final m in unlocked)
                _MilestoneTile(
                  milestone: m,
                  unlocked: true,
                  highlighted: current?.level == m.level,
                  onTap: () => showLevelMilestoneDetails(
                    context,
                    m,
                    unlocked: true,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 28),
        Text(
          l10n.lockedBadges(locked.length),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.lockedBadgesHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in locked)
              _MilestoneTile(
                milestone: m,
                unlocked: false,
                onTap: () => showLevelMilestoneDetails(
                  context,
                  m,
                  unlocked: false,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.unlocked,
    required this.onTap,
    this.highlighted = false,
  });

  final LevelMilestone milestone;
  final bool unlocked;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = unlocked
        ? AppColors.brandNavy
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 148,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? AppColors.seed
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  LevelBadgeImage(
                    milestone: milestone,
                    size: 84,
                    unlocked: unlocked,
                  ),
                  if (!unlocked)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.lock,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                milestone.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10nLevel(context, milestone.level),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String l10nLevel(BuildContext context, int level) =>
      AppLocalizations.of(context).levelLabel(level);
}
