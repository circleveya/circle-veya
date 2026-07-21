import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/chat.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';

const _kEmojis = [
  '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
  '🙂', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋',
  '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
  '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '😮', '😯',
  '😲', '😳', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '😈',
  '👍', '👎', '👏', '🙌', '🤝', '✌️', '🤞', '🤟', '🤘', '👌',
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '💔', '❣️',
  '🔥', '⭐', '✨', '🎉', '🎊', '🎈', '💯', '✅', '❌', '🙏',
];

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.chatId,
    this.chat,
  });

  final String chatId;
  final ChatSummary? chat;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markChatRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() => _showEmojiPicker = false);
    await ref.read(chatActionsProvider.notifier).sendMessage(
          chatId: widget.chatId,
          content: text,
        );

    if (!mounted) return;
    final error = ref.read(chatActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _pickAndSendMedia({required bool asGif}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: asGif ? null : 1600,
      imageQuality: asGif ? null : 85,
    );
    if (image == null || !mounted) return;

    await ref.read(chatActionsProvider.notifier).sendMediaMessage(
          chatId: widget.chatId,
          file: image,
          messageType: asGif ? ChatMessageType.gif : ChatMessageType.image,
        );

    if (!mounted) return;
    final error = ref.read(chatActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _changeWallpaper() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Hintergrund wählen'),
              subtitle: const Text('Nur für dich sichtbar'),
              onTap: () => Navigator.pop(context, 'pick'),
            ),
            ListTile(
              leading: const Icon(Icons.hide_image_outlined),
              title: const Text('Hintergrund entfernen'),
              onTap: () => Navigator.pop(context, 'clear'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'clear') {
      await ref.read(chatActionsProvider.notifier).clearWallpaper(widget.chatId);
    } else {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;
      await ref.read(chatActionsProvider.notifier).setWallpaperFromFile(
            chatId: widget.chatId,
            file: image,
          );
    }

    if (!mounted) return;
    final error = ref.read(chatActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            choice == 'clear'
                ? 'Hintergrund entfernt'
                : 'Hintergrund gespeichert (nur für dich)',
          ),
        ),
      );
    }
  }

  Future<void> _leaveChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat löschen?'),
        content: const Text(
          'Der Chat verschwindet aus deiner Liste. '
          'Bei Gruppenchats bleibt er für andere Teilnehmer erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(chatActionsProvider.notifier).leaveChat(widget.chatId);
    if (!mounted) return;

    final error = ref.read(chatActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final wallpaperAsync = ref.watch(chatWallpaperProvider(widget.chatId));
    final isSending = ref.watch(chatActionsProvider).isLoading;
    final wallpaperUrl = wallpaperAsync.valueOrNull;

    ref.listen(messagesProvider(widget.chatId), (_, next) {
      if (next.hasValue) {
        _scrollToBottom();
        ref.read(chatRepositoryProvider).markChatRead(widget.chatId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chat?.displayTitle ?? 'Chat'),
            if (widget.chat != null)
              Text(
                widget.chat!.type.label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'wallpaper') _changeWallpaper();
              if (value == 'delete') _leaveChat();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'wallpaper',
                child: Text('Hintergrundbild'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Chat löschen'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                image: wallpaperUrl != null && wallpaperUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(wallpaperUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.08),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('Schreib die erste Nachricht …'),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageIndex = messages.length - 1 - index;
                      final message = messages[messageIndex];
                      final showDate = messageIndex == 0 ||
                          !_isSameDay(
                            messages[messageIndex - 1].createdAt,
                            message.createdAt,
                          );

                      return Column(
                        children: [
                          if (showDate) _DateSeparator(date: message.createdAt),
                          MessageBubble(message: message),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 220,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemCount: _kEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _kEmojis[index];
                  return InkWell(
                    onTap: () => _insertEmoji(emoji),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Emoji',
                    onPressed: isSending
                        ? null
                        : () => setState(
                              () => _showEmojiPicker = !_showEmojiPicker,
                            ),
                    icon: Icon(
                      _showEmojiPicker
                          ? Icons.keyboard_outlined
                          : Icons.emoji_emotions_outlined,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Anhang',
                    enabled: !isSending,
                    onSelected: (value) {
                      if (value == 'image') {
                        _pickAndSendMedia(asGif: false);
                      } else if (value == 'gif') {
                        _pickAndSendMedia(asGif: true);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'image',
                        child: Text('Bild senden'),
                      ),
                      PopupMenuItem(
                        value: 'gif',
                        child: Text('GIF / Animation senden'),
                      ),
                    ],
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Nachricht schreiben …',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onTap: () {
                        if (_showEmojiPicker) {
                          setState(() => _showEmojiPicker = false);
                        }
                      },
                      onSubmitted: isSending ? null : (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: isSending ? null : _send,
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime first, DateTime second) {
  final a = first.toLocal();
  final b = second.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay =
        DateTime(localDate.year, localDate.month, localDate.day);
    final difference = today.difference(messageDay).inDays;
    final label = switch (difference) {
      0 => 'Heute',
      1 => 'Gestern',
      _ => DateFormat('dd.MM.yyyy').format(localDate),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}
