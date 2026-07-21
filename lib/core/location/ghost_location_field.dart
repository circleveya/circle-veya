import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'swiss_places.dart';

/// Textfeld mit ausgegrauter Orts-Vervollständigung (Tab / → / Enter).
class GhostLocationField extends StatefulWidget {
  const GhostLocationField({
    super.key,
    required this.controller,
    this.onConfirm,
    this.hintText = 'Ort suchen (Zürich, Basel, Bern…)',
  });

  final TextEditingController controller;

  /// Nach Übernehmen (Enter / Häkchen) – Vervollständigung ist schon eingefügt.
  final VoidCallback? onConfirm;
  final String hintText;

  @override
  State<GhostLocationField> createState() => _GhostLocationFieldState();
}

class _GhostLocationFieldState extends State<GhostLocationField> {
  final _focusNode = FocusNode();
  String? _ghostSuffix;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncGhost);
    _syncGhost();
  }

  @override
  void didUpdateWidget(covariant GhostLocationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncGhost);
      widget.controller.addListener(_syncGhost);
      _syncGhost();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncGhost);
    _focusNode.dispose();
    super.dispose();
  }

  void _syncGhost() {
    final next = ghostCompletionSuffix(widget.controller.text);
    if (next != _ghostSuffix) {
      setState(() => _ghostSuffix = next);
    }
  }

  bool _acceptGhost() {
    final suffix = _ghostSuffix;
    if (suffix == null || suffix.isEmpty) return false;
    final typed = widget.controller.text;
    final completed = '$typed$suffix';
    widget.controller.value = TextEditingValue(
      text: completed,
      selection: TextSelection.collapsed(offset: completed.length),
    );
    setState(() => _ghostSuffix = null);
    return true;
  }

  void _confirm() {
    _acceptGhost();
    widget.onConfirm?.call();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isTab = event.logicalKey == LogicalKeyboardKey.tab;
    final isRight = event.logicalKey == LogicalKeyboardKey.arrowRight;
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;

    if ((isTab || isRight) && _ghostSuffix != null) {
      if (isRight) {
        final sel = widget.controller.selection;
        final atEnd = !sel.isValid ||
            sel.baseOffset >= widget.controller.text.length;
        if (!atEnd) return KeyEventResult.ignored;
      }
      _acceptGhost();
      return KeyEventResult.handled;
    }

    if (isEnter) {
      _confirm();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typed = widget.controller.text;
    final ghost = _ghostSuffix;
    final bodyStyle = theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);

    return Focus(
      onKeyEvent: _onKey,
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: typed.isEmpty ? widget.hintText : null,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Ort übernehmen',
            onPressed: _confirm,
          ),
          isDense: true,
          // Inhalt selbst zeichnen wir
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (ghost != null && typed.isNotEmpty)
              IgnorePointer(
                child: Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: [
                      TextSpan(
                        text: typed,
                        style: const TextStyle(color: Colors.transparent),
                      ),
                      TextSpan(
                        text: ghost,
                        style: bodyStyle.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.42),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              style: bodyStyle,
              cursorColor: theme.colorScheme.primary,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _syncGhost(),
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
    );
  }
}
