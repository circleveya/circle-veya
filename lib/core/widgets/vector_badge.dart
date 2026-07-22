import 'package:flutter/material.dart';

import '../../features/challenges/domain/entities/level_milestone.dart';
import '../../features/challenges/presentation/widgets/level_badge_theme.dart';
import '../../features/profile/domain/entities/special_badge.dart';

/// Scharfe Vektor-Badges – skalieren ohne Verpixelung (Web + Mobile).
class VectorLevelBadge extends StatelessWidget {
  const VectorLevelBadge({
    super.key,
    required this.milestone,
    required this.size,
    this.unlocked = true,
  });

  final LevelMilestone milestone;
  final double size;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = LevelBadgeTheme.forLevel(milestone.level);
    final badge = VectorBadgeDisk(
      size: size,
      fill: theme.fill,
      accent: theme.accent,
      icon: _iconForLevel(milestone.level),
      iconColor: theme.accent,
    );

    if (!unlocked) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.55, 0,
        ]),
        child: badge,
      );
    }

    return badge;
  }

  static IconData _iconForLevel(int level) => switch (level) {
        5 => Icons.bolt_rounded,
        10 => Icons.flag_rounded,
        15 => Icons.group_rounded,
        20 => Icons.explore_rounded,
        25 => Icons.construction_rounded,
        30 => Icons.travel_explore_rounded,
        35 => Icons.hub_rounded,
        40 => Icons.brush_rounded,
        45 => Icons.signpost_rounded,
        50 => Icons.sports_score_rounded,
        55 => Icons.collections_bookmark_rounded,
        60 => Icons.route_rounded,
        65 => Icons.public_rounded,
        70 => Icons.military_tech_rounded,
        75 => Icons.shield_rounded,
        80 => Icons.security_rounded,
        85 => Icons.emoji_events_rounded,
        90 => Icons.celebration_rounded,
        95 => Icons.all_inclusive_rounded,
        _ => Icons.stars_rounded,
      };
}

class VectorSpecialBadge extends StatelessWidget {
  const VectorSpecialBadge({
    super.key,
    required this.badge,
    required this.size,
  });

  final SpecialBadge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (fill, accent, icon) = switch (badge.type) {
      SpecialBadgeType.founder => (
          const Color(0xFF0A1128),
          const Color(0xFFE6AE41),
          Icons.auto_awesome_rounded,
        ),
      SpecialBadgeType.event => (
          const Color(0xFF5E35B1),
          const Color(0xFFFFD180),
          Icons.event_rounded,
        ),
      SpecialBadgeType.team => (
          const Color(0xFF00695C),
          const Color(0xFFE6AE41),
          Icons.groups_rounded,
        ),
      SpecialBadgeType.premium => (
          const Color(0xFFB8860B),
          const Color(0xFFFFF8E1),
          Icons.diamond_rounded,
        ),
    };

    return VectorBadgeDisk(
      size: size,
      fill: fill,
      accent: accent,
      icon: icon,
      iconColor: accent,
      premiumGlow: badge.type == SpecialBadgeType.premium,
    );
  }
}

class VectorBadgeDisk extends StatelessWidget {
  const VectorBadgeDisk({
    super.key,
    required this.size,
    required this.fill,
    required this.accent,
    required this.icon,
    required this.iconColor,
    this.premiumGlow = false,
  });

  final double size;
  final Color fill;
  final Color accent;
  final IconData icon;
  final Color iconColor;
  final bool premiumGlow;

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.045;
    final iconSize = size * 0.42;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: fill.withValues(alpha: 0.35),
              blurRadius: size * 0.08,
              offset: Offset(0, size * 0.04),
            ),
            if (premiumGlow)
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: size * 0.14,
                spreadRadius: size * 0.01,
              ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color.lerp(fill, Colors.white, 0.22)!,
                fill,
                Color.lerp(fill, Colors.black, 0.18)!,
              ],
              stops: const [0.0, 0.55, 1.0],
              center: const Alignment(-0.25, -0.35),
            ),
            border: Border.all(color: accent, width: ring),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: size * 0.12,
                left: size * 0.18,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Icon(
                icon,
                size: iconSize,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
