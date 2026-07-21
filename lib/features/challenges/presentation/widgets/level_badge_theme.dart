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

  /// Navy + Gold – Spark / Starter / Gatherer / Captain (und 55+).
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

  static LevelBadgeTheme forLevel(int level) {
    if (level >= 35 && level < 50) return crimson;
    if (level >= 20 && level < 35) return sage;
    return navy;
  }
}
