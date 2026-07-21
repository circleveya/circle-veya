import 'package:flutter/material.dart';

/// Outline-Smiley wie bei WhatsApp (Eingabe & Picker).
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
    return Icon(
      Icons.sentiment_satisfied_alt_outlined,
      size: size,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
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
