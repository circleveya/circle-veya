import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gif_catalog.dart';
import '../../data/gif_search_service.dart';
import 'whatsapp_chat_icons.dart';

enum ChatPickerTab { emoji, gif }

class ChatEmojiGifPanel extends ConsumerStatefulWidget {
  const ChatEmojiGifPanel({
    super.key,
    required this.initialTab,
    required this.onEmojiSelected,
    required this.onGifSelected,
    required this.onClose,
  });

  final ChatPickerTab initialTab;
  final ValueChanged<String> onEmojiSelected;
  final ValueChanged<CatalogGif> onGifSelected;
  final VoidCallback onClose;

  @override
  ConsumerState<ChatEmojiGifPanel> createState() => _ChatEmojiGifPanelState();
}

class _ChatEmojiGifPanelState extends ConsumerState<ChatEmojiGifPanel> {
  late ChatPickerTab _tab;
  int _emojiCategory = 0;
  final _gifQuery = TextEditingController();
  Timer? _debounce;
  List<CatalogGif> _gifs = List<CatalogGif>.from(kCatalogGifs);
  bool _gifLoading = false;

  static const _categories =
      <({IconData icon, String label, List<String> emojis})>[
    (
      icon: Icons.sentiment_satisfied_alt_outlined,
      label: 'Smileys',
      emojis: [
        '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
        '🙂', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋',
        '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
        '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '😮', '😯',
        '😲', '😳', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '😈',
      ],
    ),
    (
      icon: Icons.back_hand_outlined,
      label: 'Gesten',
      emojis: [
        '👍', '👎', '👏', '🙌', '🤝', '✌️', '🤞', '🤟', '🤘', '👌',
        '🤌', '👈', '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐️', '🖖',
        '👋', '🤙', '💪', '🦾', '🖕', '✍️', '🙏', '💅', '🤳', '💃',
      ],
    ),
    (
      icon: Icons.favorite_border,
      label: 'Herzen',
      emojis: [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💕',
        '💞', '💓', '💗', '💖', '💘', '💝', '💟', '❣️', '💔', '❤️‍🔥',
        '💋', '💯', '✨', '⭐', '🌟', '💫', '🔥', '🎉', '🎊', '🎈',
      ],
    ),
    (
      icon: Icons.sports_soccer_outlined,
      label: 'Aktiv',
      emojis: [
        '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🥏', '🎱', '🏓',
        '🏸', '🥅', '⛳', '⛸️', '🎿', '🏂', '🪂', '🏋️', '🤸', '🧘',
        '🏃', '🚶', '🚴', '🏊', '🏄', '🧗', '🏕️', '⛰️', '🏖️', '🎯',
      ],
    ),
    (
      icon: Icons.fastfood_outlined,
      label: 'Essen',
      emojis: [
        '🍎', '🍕', '🍔', '🍟', '🌮', '🌯', '🍣', '🍜', '🍝', '🥗',
        '🍦', '🍩', '🍪', '🎂', '🍰', '🧁', '☕', '🍵', '🍺', '🍻',
        '🥂', '🍷', '🥤', '🧃', '🍫', '🍿', '🥑', '🍇', '🍓', '🍉',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    if (_tab == ChatPickerTab.gif) {
      _loadGifs('');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _gifQuery.dispose();
    super.dispose();
  }

  Future<void> _loadGifs(String query) async {
    setState(() => _gifLoading = true);
    final results = await ref.read(gifSearchServiceProvider).search(query);
    if (!mounted) return;
    setState(() {
      _gifs = results;
      _gifLoading = false;
    });
  }

  void _onGifQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadGifs(value);
    });
  }

  void _selectTab(ChatPickerTab tab) {
    setState(() => _tab = tab);
    if (tab == ChatPickerTab.gif) {
      _loadGifs(_gifQuery.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 2,
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: _tab == ChatPickerTab.emoji
                  ? _buildEmojiPane(theme)
                  : _buildGifPane(theme),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _WhatsAppModeSwitch(
                      tab: _tab,
                      onChanged: _selectTab,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Schließen',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.keyboard_outlined,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPane(ThemeData theme) {
    final emojis = _categories[_emojiCategory].emojis;
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: Row(
            children: [
              for (var i = 0; i < _categories.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _emojiCategory = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _categories[i].icon,
                          size: 20,
                          color: _emojiCategory == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 2,
                          width: 22,
                          decoration: BoxDecoration(
                            color: _emojiCategory == i
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 1.05,
            ),
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              final emoji = emojis[index];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onEmojiSelected(emoji),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGifPane(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: TextField(
            controller: _gifQuery,
            onChanged: _onGifQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'GIF suchen …',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _gifLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _gifs.isEmpty
                  ? Center(
                      child: Text(
                        'Keine GIFs gefunden',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: _gifs.length,
                      itemBuilder: (context, index) {
                        final gif = _gifs[index];
                        return Material(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.antiAlias,
                          child: GestureDetector(
                            onTap: () => widget.onGifSelected(gif),
                            child: Image.network(
                              gif.previewUrl,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => const Center(
                                child: WhatsAppGifIcon(compact: true),
                              ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _WhatsAppModeSwitch extends StatelessWidget {
  const _WhatsAppModeSwitch({
    required this.tab,
    required this.onChanged,
  });

  final ChatPickerTab tab;
  final ValueChanged<ChatPickerTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSegment(
              selected: tab == ChatPickerTab.emoji,
              onTap: () => onChanged(ChatPickerTab.emoji),
              child: WhatsAppSmileyIcon(
                size: 22,
                color: tab == ChatPickerTab.emoji
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _ModeSegment(
              selected: tab == ChatPickerTab.gif,
              onTap: () => onChanged(ChatPickerTab.gif),
              child: WhatsAppGifIcon(
                selected: tab == ChatPickerTab.gif,
                color: tab == ChatPickerTab.gif
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: selected ? theme.colorScheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        elevation: selected ? 0.5 : 0,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
