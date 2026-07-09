import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../domain/entities/chat.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);

    return chatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error.toString()),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(chatListProvider),
              child: const Text('Erneut laden'),
            ),
          ],
        ),
      ),
      data: (chats) {
        if (chats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Noch keine Chats.\n'
                'Gruppenchats erscheinen, sobald Teilnehmer beitreten.\n'
                'DMs startest du als Host bei Interessenten.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(chatListProvider);
            await ref.read(chatListProvider.future);
          },
          child: ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _ChatListTile(chat: chat);
            },
          ),
        );
      },
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({required this.chat});

  final ChatSummary chat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = chat.lastMessagePreview ?? 'Noch keine Nachrichten';
    final time = chat.lastMessageAt != null
        ? DateFormat('dd.MM. HH:mm').format(chat.lastMessageAt!.toLocal())
        : '';

    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          chat.type == ChatType.activityGroup
              ? Icons.groups_outlined
              : Icons.chat_bubble_outline,
        ),
      ),
      title: Text(chat.title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time.isNotEmpty)
            Text(time, style: theme.textTheme.labelSmall),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 10,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                '${chat.unreadCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.pushNamed(
        RouteNames.chatRoom,
        pathParameters: {'id': chat.id},
        extra: chat,
      ),
    );
  }
}
