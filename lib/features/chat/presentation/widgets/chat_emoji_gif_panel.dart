import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gif_catalog.dart';
import '../../data/gif_search_service.dart';

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

  static const _categories = <({IconData icon, String label, List<String> emojis})>[
    (
      icon: Icons.emoji_emotions_outlined,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest;

    return Material(
      color: surface,
      child: SizedBox(
        height: 280,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 0),
              child: Row(
                children: [
                  _TabChip(
                    label: 'Emoji',
                    selected: _tab == ChatPickerTab.emoji,
                    onTap: () => setState(() => _tab = ChatPickerTab.emoji),
                  ),
                  const SizedBox(width: 6),
                  _TabChip(
                    label: 'GIF',
                    selected: _tab == ChatPickerTab.gif,
                    onTap: () {
                      setState(() => _tab = ChatPickerTab.gif);
                      if (_gifs.isEmpty || _gifQuery.text.isEmpty) {
                        _loadGifs(_gifQuery.text);
                      }
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Schließen',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.keyboard_outlined, size: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tab == ChatPickerTab.emoji
                  ? _buildEmojiPane(theme)
                  : _buildGifPane(theme),
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
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 1,
            ),
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              final emoji = emojis[index];
              return InkWell(
                onTap: () => widget.onEmojiSelected(emoji),
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              for (var i = 0; i < _categories.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _emojiCategory = i),
                    child: ColoredBox(
                      color: _emojiCategory == i
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      child: Icon(
                        _categories[i].icon,
                        size: 22,
                        color: _emojiCategory == i
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGifPane(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
          child: TextField(
            controller: _gifQuery,
            onChanged: _onGifQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'GIF suchen …',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: theme.colorScheme.surface,
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
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => widget.onGifSelected(gif),
                            child: Image.network(
                              gif.previewUrl,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.gif_box_outlined),
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

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.16)
          : theme.colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
