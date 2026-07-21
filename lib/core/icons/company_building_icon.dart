import 'package:flutter/material.dart';

/// Minimalistisches Unternehmens-Icon: zwei Bürogebäude mit Fenstern
/// (Outline-Stil, passend zu Material outlined Icons).
class CompanyBuildingIcon extends StatelessWidget {
  const CompanyBuildingIcon({
    super.key,
    this.size = 28,
    this.color,
    this.strokeWidth = 1.6,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? Theme.of(context).iconTheme.color;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompanyBuildingPainter(
          color: resolved ?? Colors.black,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _CompanyBuildingPainter extends CustomPainter {
  const _CompanyBuildingPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final inset = strokeWidth / 2;

    // Linkes (höheres) Gebäude
    final left = RRect.fromRectAndRadius(
      Rect.fromLTRB(inset, h * 0.12, w * 0.48, h - inset),
      const Radius.circular(1.5),
    );
    // Rechtes (niedrigeres) Gebäude
    final right = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.48, h * 0.32, w - inset, h - inset),
      const Radius.circular(1.5),
    );

    canvas.drawRRect(left, paint);
    canvas.drawRRect(right, paint);

    // Fenster – linkes Gebäude (2 Spalten × 3 Reihen)
    _drawWindows(
      canvas,
      paint,
      left: w * 0.10,
      top: h * 0.22,
      colGap: w * 0.14,
      rowGap: h * 0.14,
      cols: 2,
      rows: 3,
      winW: w * 0.08,
      winH: h * 0.07,
    );

    // Fenster – rechtes Gebäude (2 Spalten × 2 Reihen)
    _drawWindows(
      canvas,
      paint,
      left: w * 0.56,
      top: h * 0.42,
      colGap: w * 0.14,
      rowGap: h * 0.14,
      cols: 2,
      rows: 2,
      winW: w * 0.08,
      winH: h * 0.07,
    );
  }

  void _drawWindows(
    Canvas canvas,
    Paint paint, {
    required double left,
    required double top,
    required double colGap,
    required double rowGap,
    required int cols,
    required int rows,
    required double winW,
    required double winH,
  }) {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left + c * colGap,
            top + r * rowGap,
            winW,
            winH,
          ),
          const Radius.circular(0.8),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompanyBuildingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
