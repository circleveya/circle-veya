import 'package:flutter/material.dart';

/// Markenfarben für CircleVeya (abgestimmt auf Logo-Gradient).
abstract final class AppColors {
  // Kernpalette aus dem Logo
  static const seed = Color(0xFFF58220);
  static const secondary = Color(0xFFE94E77);
  static const tertiary = Color(0xFF2BC0B5);
  static const brandNavy = Color(0xFF0A1128);
  static const brandPurple = Color(0xFF7C4DFF);
  static const brandBlue = Color(0xFF3D5AFE);
  static const brandOrange = Color(0xFFFF8D00);
  static const brandMagenta = Color(0xFFE91E63);

  static const surfaceTint = Color(0xFFFFFAF6);

  static const gradientStart = brandOrange;
  static const gradientEnd = brandPurple;

  /// Logo-Gradient (Orange → Magenta → Violett → Teal)
  static const brandGradient = LinearGradient(
    colors: [
      brandOrange,
      brandMagenta,
      brandPurple,
      tertiary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const filterExpanded = brandGradient;

  static const featuredGradient = LinearGradient(
    colors: [Color(0xFFFFB347), brandOrange, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Web-Layout
  static const sidebarWidth = 272.0;
  static const rightPanelWidth = 320.0;
  static const webBreakpoint = 900.0;
  static const sidebarBackground = Color(0xFFFFFFFF);
  static const sidebarBorder = Color(0xFFE8ECF4);
  static const sidebarSelected = Color(0xFFFFF3E8);

  /// Premium / Hero / CTA – identisch mit Marken-Gradient
  static const premiumGradient = brandGradient;
}
