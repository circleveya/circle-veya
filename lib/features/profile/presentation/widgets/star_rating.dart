import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Interaktive oder nur-Anzeige Sterne mit Pop-Animation beim Tippen.
///
/// Nutzt selbst gezeichnete Sterne (kein Material-Icon), damit sie auf
/// Flutter Web trotz Icon-Tree-Shaking immer sichtbar sind.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.max = 5,
    this.size = 28,
    this.interactive = false,
    this.onChanged,
    this.color = const Color(0xFFFFC107), // Gold
    this.emptyColor = const Color(0xFFB0B8C4), // Grau
  });

  /// Aktueller Wert (0–[max]). Bei Anzeige darf auch z. B. 4.3 sein.
  final double value;
  final int max;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onChanged;
  final Color color;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= max; i++)
          _StarButton(
            index: i,
            value: value,
            size: size,
            color: color,
            emptyColor: emptyColor,
            interactive: interactive,
            onTap: interactive && onChanged != null
                ? () => onChanged!(i)
                : null,
          ),
      ],
    );
  }
}

class _StarButton extends StatefulWidget {
  const _StarButton({
    required this.index,
    required this.value,
    required this.size,
    required this.color,
    required this.emptyColor,
    required this.interactive,
    this.onTap,
  });

  final int index;
  final double value;
  final double size;
  final Color color;
  final Color emptyColor;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  State<_StarButton> createState() => _StarButtonState();
}

class _StarButtonState extends State<_StarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.92), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isFilled => widget.value >= widget.index - 0.001;
  bool get _isHalf => !_isFilled && widget.value >= widget.index - 0.5;

  Color get _fillColor {
    if (_isFilled || _isHalf) return widget.color;
    return widget.emptyColor;
  }

  Future<void> _handleTap() async {
    await _controller.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final star = ScaleTransition(
      scale: _scale,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _StarPainter(
          color: _fillColor,
          filled: _isFilled || _isHalf,
          half: _isHalf,
          outlineColor: const Color(0xFF8A93A3),
        ),
      ),
    );

    if (!widget.interactive || widget.onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: star,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: widget.size + 16,
            height: widget.size + 16,
            child: Center(child: star),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.color,
    required this.filled,
    required this.half,
    required this.outlineColor,
  });

  final Color color;
  final bool filled;
  final bool half;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _starPath(size);

    if (filled && !half) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    } else if (half) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
      canvas.drawPath(
        path,
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.08,
      );
    } else {
      // Leerer Stern: grau gefüllt + dunklerer Rand → klar sichtbar
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.06,
      );
    }
  }

  Path _starPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width * 0.48;
    final inner = outer * 0.42;
    final path = Path();

    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = (-math.pi / 2) + (i * math.pi / 5);
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.filled != filled ||
        oldDelegate.half != half ||
        oldDelegate.outlineColor != outlineColor;
  }
}
