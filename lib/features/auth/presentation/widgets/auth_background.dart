import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Programmatischer Auth-Hintergrund – keine PNG-Grafik, kein Ghosting.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  static const _base = Color(0xFFF9F7F3);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _AuthBlob(
            top: -90,
            left: -70,
            size: 320,
            colors: [
              Color(0xFFFFB86A),
              Color(0xFFFFD4A8),
            ],
            opacity: 0.55,
          ),
          _AuthBlob(
            bottom: -110,
            left: -80,
            size: 340,
            colors: [
              Color(0xFFB39DDB),
              Color(0xFFCE93D8),
            ],
            opacity: 0.5,
          ),
          _AuthBlob(
            top: -60,
            right: -90,
            size: 280,
            colors: [
              Color(0xFF4DD0C8),
              Color(0xFF80DEEA),
            ],
            opacity: 0.45,
          ),
          _AuthBlob(
            bottom: -80,
            right: -70,
            size: 300,
            colors: [
              Color(0xFFFFCC80),
              Color(0xFFFFAB91),
            ],
            opacity: 0.48,
          ),
          // Dezente Mitte – Formular bleibt lesbar.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.05),
                radius: 0.72,
                colors: [
                  Color(0xFFFDFCFA),
                  Color(0x00FDFCFA),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBlob extends StatelessWidget {
  const _AuthBlob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.colors,
    required this.opacity,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final List<Color> colors;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colors.first.withValues(alpha: opacity),
                colors.last.withValues(alpha: opacity * 0.35),
                colors.last.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Leichte Karte hinter dem Formular für Kontrast.
class AuthFormSurface extends StatelessWidget {
  const AuthFormSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNavy.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: child,
      ),
    );
  }
}
