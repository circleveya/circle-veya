import 'package:flutter/material.dart';

/// Markenfarben für Circle.
abstract final class AppColors {
  static const seed = Color(0xFF6C63FF);
  static const secondary = Color(0xFFFF6584);
  static const tertiary = Color(0xFF43D9C6);
  static const surfaceTint = Color(0xFFF4F3FF);

  static const gradientStart = Color(0xFF6C63FF);
  static const gradientEnd = Color(0xFF9B8CFF);

  static const filterExpanded = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B7CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const featuredGradient = LinearGradient(
    colors: [Color(0xFFFFB347), Color(0xFFFF6584)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Web-Layout
  static const sidebarWidth = 272.0;
  static const rightPanelWidth = 320.0;
  static const webBreakpoint = 900.0;
  static const sidebarBackground = Color(0xFFFAFAFE);
  static const sidebarBorder = Color(0xFFE8E6F5);
  static const sidebarSelected = Color(0xFFEEECFF);
  static const premiumGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9B8CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
