import 'package:flutter/material.dart';

/// Farben passend zu den Level-Badge-Grafiken.
class LevelBadgeTheme {
  const LevelBadgeTheme({
    required this.fill,
    required this.accent,
    required this.onFill,
  });

  /// Hintergrund der Badge-Scheibe.
  final Color fill;

  /// Gold-/Akzentfarbe (Rand, Icons, Text auf dunklen Badges).
  final Color accent;

  /// Textfarbe auf [fill] (Level-Chip).
  final Color onFill;

  /// Navy + Gold – Spark … Captain, Collector, Pathfinder.
  static const navy = LevelBadgeTheme(
    fill: Color(0xFF142859),
    accent: Color(0xFFFCB452),
    onFill: Color(0xFFFFF6E8),
  );

  /// Sage + Gold – Explorer / Builder / Seeker.
  static const sage = LevelBadgeTheme(
    fill: Color(0xFFCCDDBF),
    accent: Color(0xFFEDAF3F),
    onFill: Color(0xFF1B2E1A),
  );

  /// Rot + Gold – Connector / Creator / Guide.
  static const crimson = LevelBadgeTheme(
    fill: Color(0xFFD21C24),
    accent: Color(0xFFE6AE41),
    onFill: Color(0xFFFFF6E8),
  );

  /// Teal + Gold – Ambassador / Master / Hero.
  static const teal = LevelBadgeTheme(
    fill: Color(0xFF1B4D4A),
    accent: Color(0xFFE6AE41),
    onFill: Color(0xFFFFF6E8),
  );

  /// Burgundy + Gold – Guardian / Champion / Host Legend.
  static const burgundy = LevelBadgeTheme(
    fill: Color(0xFF8B1538),
    accent: Color(0xFFE6AE41),
    onFill: Color(0xFFFFF6E8),
  );

  /// Gold – Circle Icon / Veya Legend.
  static const gold = LevelBadgeTheme(
    fill: Color(0xFFB8860B),
    accent: Color(0xFFFFF0C2),
    onFill: Color(0xFF3D2A00),
  );

  static LevelBadgeTheme forLevel(int level) {
    if (level >= 95) return gold;
    if (level >= 80) return burgundy;
    if (level >= 65) return teal;
    if (level >= 35 && level < 50) return crimson;
    if (level >= 20 && level < 35) return sage;
    return navy;
  }
}
