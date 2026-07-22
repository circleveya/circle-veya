import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// Login/Registrierung mit dekorativen Hintergrund-Blobs wie im Mockup.
class AuthScreenScaffold extends StatelessWidget {
  const AuthScreenScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
  });

  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _AuthBackgroundPainter()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: child,
                ),
              ),
            ),
          ),
          if (showBackButton)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.brandNavy.withValues(alpha: 0.7),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.goNamed('login'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4EB), Color(0xFFFFD9B8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.seed.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFD96A12),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.fullText,
    required this.onPressed,
  });

  final String fullText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = fullText.indexOf('?');
    final prefix = q >= 0 ? '${fullText.substring(0, q + 1)} ' : '';
    final link = q >= 0 ? fullText.substring(q + 2) : fullText;

    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: prefix),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onPressed,
              child: Text(
                link,
                style: const TextStyle(
                  color: AppColors.seed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  const _AuthBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _topLeftPeach(canvas, size);
    _bottomLeftPurple(canvas, size);
    _topRightTeal(canvas, size);
    _bottomRightOrange(canvas, size);
    _waveLines(canvas, size);
    _dotPattern(canvas, size);
  }

  void _topLeftPeach(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-size.width * 0.08, -size.height * 0.04)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.02,
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.48,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.08,
        size.height * 0.16,
        -size.width * 0.06,
        size.height * 0.08,
      )
      ..close();

    _fillBlob(
      canvas,
      path,
      const [Color(0xFFFFE8D4), Color(0xFFFFD4B5), Color(0x00FFD4B5)],
      Rect.fromLTWH(-size.width * 0.1, -size.height * 0.08, size.width * 0.65, size.height * 0.48),
    );
  }

  void _bottomLeftPurple(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-size.width * 0.06, size.height * 0.72)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.82,
        size.width * 0.28,
        size.height * 0.98,
        size.width * 0.42,
        size.height * 1.04,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.88,
        size.width * 0.02,
        size.height * 0.78,
        -size.width * 0.08,
        size.height * 0.68,
      )
      ..close();

    _fillBlob(
      canvas,
      path,
      const [Color(0xFFD8CCF0), Color(0xFFB8A8E8), Color(0x009B8FD4)],
      Rect.fromLTWH(-size.width * 0.12, size.height * 0.58, size.width * 0.62, size.height * 0.5),
    );

    final bluePath = Path()
      ..moveTo(size.width * 0.02, size.height * 0.78)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.86,
        size.width * 0.24,
        size.height * 0.96,
        size.width * 0.34,
        size.height * 1.02,
      )
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.9,
        size.width * 0.08,
        size.height * 0.82,
        -size.width * 0.02,
        size.height * 0.74,
      )
      ..close();

    _fillBlob(
      canvas,
      bluePath,
      const [Color(0xFFB8D8F0), Color(0xFF90C4E8), Color(0x0090C4E8)],
      Rect.fromLTWH(0, size.height * 0.68, size.width * 0.42, size.height * 0.38),
    );
  }

  void _topRightTeal(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.58, -size.height * 0.06)
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.02,
        size.width * 1.02,
        size.height * 0.08,
        size.width * 1.06,
        size.height * 0.22,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.14,
        size.width * 0.72,
        size.height * 0.06,
        size.width * 0.6,
        -size.height * 0.02,
      )
      ..close();

    _fillBlob(
      canvas,
      path,
      const [Color(0xFFB8EEE8), Color(0xFF8EDFD6), Color(0x008EDFD6)],
      Rect.fromLTWH(size.width * 0.52, -size.height * 0.1, size.width * 0.58, size.height * 0.42),
    );
  }

  void _bottomRightOrange(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.62, size.height * 0.74)
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.82,
        size.width * 1.02,
        size.height * 0.92,
        size.width * 1.08,
        size.height * 1.06,
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.96,
        size.width * 0.72,
        size.height * 0.84,
        size.width * 0.58,
        size.height * 0.76,
      )
      ..close();

    _fillBlob(
      canvas,
      path,
      const [Color(0xFFFFE08A), Color(0xFFFFC96B), Color(0x00FFC96B)],
      Rect.fromLTWH(size.width * 0.48, size.height * 0.62, size.width * 0.62, size.height * 0.48),
    );
  }

  void _fillBlob(
    Canvas canvas,
    Path path,
    List<Color> colors,
    Rect bounds,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bounds);
    canvas.drawPath(path, paint);
  }

  void _waveLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.55);

    final topRight = Path()
      ..moveTo(size.width * 0.72, size.height * 0.06)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.12,
        size.width * 0.9,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        size.width * 0.96,
        size.height * 0.28,
        size.width * 1.02,
        size.height * 0.36,
      );
    canvas.drawPath(topRight, paint);

    final topRight2 = Path()
      ..moveTo(size.width * 0.78, size.height * 0.04)
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.1,
        size.width * 0.96,
        size.height * 0.18,
      );
    canvas.drawPath(topRight2, paint..strokeWidth = 0.9);

    final bottomLeft = Path()
      ..moveTo(size.width * 0.02, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.92,
        size.width * 0.22,
        size.height * 0.98,
      );
    canvas.drawPath(bottomLeft, paint..strokeWidth = 1.0);
  }

  void _dotPattern(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    const spacing = 14.0;
    const radius = 1.6;

    for (var y = size.height * 0.68; y < size.height * 1.02; y += spacing) {
      for (var x = size.width * 0.58; x < size.width * 1.02; x += spacing) {
        final dx = (x - size.width * 0.78) / (size.width * 0.28);
        final dy = (y - size.height * 0.78) / (size.height * 0.22);
        if (dx * dx + dy * dy > 1.2) continue;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }

    final peachPaint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    for (var y = 0.0; y < size.height * 0.28; y += spacing * 1.2) {
      for (var x = 0.0; x < size.width * 0.38; x += spacing * 1.2) {
        final dx = (x - size.width * 0.18) / (size.width * 0.22);
        final dy = (y - size.height * 0.12) / (size.height * 0.18);
        if (dx * dx + dy * dy > 1.0) continue;
        canvas.drawCircle(
          Offset(x + math.sin(y * 0.08) * 3, y),
          radius * 0.9,
          peachPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
