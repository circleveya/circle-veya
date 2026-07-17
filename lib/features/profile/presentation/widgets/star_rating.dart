import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Interaktive oder nur-Anzeige Sterne mit Pop-Animation beim Tippen.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.max = 5,
    this.size = 28,
    this.interactive = false,
    this.onChanged,
    this.color = AppColors.seed,
    this.emptyColor,
  });

  /// Aktueller Wert (0–[max]). Bei Anzeige darf auch z. B. 4.3 sein.
  final double value;
  final int max;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onChanged;
  final Color color;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    final muted = emptyColor ??
        AppColors.brandNavy.withValues(alpha: 0.35);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= max; i++)
          _StarButton(
            index: i,
            value: value,
            size: size,
            color: color,
            emptyColor: muted,
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

  IconData get _icon {
    if (widget.value >= widget.index) return Icons.star_rounded;
    if (widget.value >= widget.index - 0.5) return Icons.star_half_rounded;
    return Icons.star_border_rounded;
  }

  Color get _iconColor {
    if (widget.value >= widget.index - 0.5) return widget.color;
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
      child: Icon(
        _icon,
        size: widget.size,
        color: _iconColor,
      ),
    );

    if (!widget.interactive || widget.onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: star,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          customBorder: const CircleBorder(),
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
