import 'package:flutter/material.dart';

/// Einfaches Outline-Smiley (Kreis, Punkte, Mund) wie in Messenger-UIs.
class WhatsAppSmileyIcon extends StatelessWidget {
  const WhatsAppSmileyIcon({
    super.key,
    this.size = 26,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SimpleSmileyPainter(color: fg),
      ),
    );
  }
}

class _SimpleSmileyPainter extends CustomPainter {
  _SimpleSmileyPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final inset = size.width * 0.08;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawOval(rect, stroke);

    final eyeY = size.height * 0.38;
    final eyeR = size.width * 0.055;
    canvas.drawCircle(Offset(size.width * 0.35, eyeY), eyeR, fill);
    canvas.drawCircle(Offset(size.width * 0.65, eyeY), eyeR, fill);

    final smile = Path()
      ..moveTo(size.width * 0.30, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.72,
        size.width * 0.70,
        size.height * 0.55,
      );
    canvas.drawPath(smile, stroke);
  }

  @override
  bool shouldRepaint(covariant _SimpleSmileyPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// GIF-Badge wie bei WhatsApp: „GIF“ in abgerundetem Rahmen.
class WhatsAppGifIcon extends StatelessWidget {
  const WhatsAppGifIcon({
    super.key,
    this.selected = false,
    this.compact = false,
    this.color,
  });

  final bool selected;
  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ??
        (selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant);
    final padH = compact ? 4.0 : 5.0;
    final padV = compact ? 1.5 : 2.0;
    final fontSize = compact ? 9.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg, width: 1.6),
      ),
      child: Text(
        'GIF',
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
