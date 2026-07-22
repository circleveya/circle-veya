import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'swiss_places.dart';

/// Textfeld mit blauer Inline-Vervollständigung (Tab / → / Enter).
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
  PlaceSuggestion? _suggestion;

  static const _contentPadding = EdgeInsets.symmetric(vertical: 14);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncGhost);
    _focusNode.addListener(_onFocusChange);
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
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  void _syncGhost() {
    final typed = widget.controller.text;
    final suggestion = findPlaceSuggestion(typed);
    final suffix = ghostCompletionSuffix(typed);
    if (suffix == _ghostSuffix && suggestion?.name == _suggestion?.name) {
      return;
    }
    setState(() {
      _ghostSuffix = suffix;
      _suggestion = suffix != null ? suggestion : null;
    });
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
    setState(() {
      _ghostSuffix = null;
      _suggestion = null;
    });
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
    final suggestion = _suggestion;
    final bodyStyle = (theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16))
        .copyWith(height: 1.25, letterSpacing: 0);

    return Focus(
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: _focusNode.hasFocus
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      if (ghost != null && typed.isNotEmpty)
                        Padding(
                          padding: _contentPadding,
                          child: IgnorePointer(
                            child: Text.rich(
                              TextSpan(
                                style: bodyStyle,
                                children: [
                                  TextSpan(
                                    text: typed,
                                    style: const TextStyle(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ghost,
                                    style: bodyStyle.copyWith(
                                      color: Colors.white,
                                      backgroundColor: AppColors.brandBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ),
                      TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        style: bodyStyle.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        cursorColor: theme.colorScheme.primary,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: typed.isEmpty ? widget.hintText : null,
                          border: InputBorder.none,
                          contentPadding: _contentPadding,
                        ),
                        onChanged: (_) => _syncGhost(),
                        onSubmitted: (_) => _confirm(),
                        onTapOutside: (_) => _focusNode.unfocus(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Ort übernehmen',
                  onPressed: _confirm,
                ),
              ],
            ),
          ),
          if (suggestion != null && ghost != null && typed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Tab für ${suggestion.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
