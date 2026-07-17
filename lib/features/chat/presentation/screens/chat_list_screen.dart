import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../friends/domain/entities/connection.dart';
import '../../../friends/presentation/providers/friends_provider.dart';
import '../../domain/entities/chat.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewChatSheet(context, ref),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Neuer Chat'),
        backgroundColor: AppColors.seed,
        foregroundColor: Colors.white,
      ),
      body: chatsAsync.when(
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Chats',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Starte einen neuen Chat mit einem Freund\n'
                      'oder warte auf Gruppenchats aus Aktivitäten.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: chats.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return Dismissible(
                  key: ValueKey('chat-${chat.id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    final ok = await _confirmLeave(context);
                    if (ok != true || !context.mounted) return false;
                    await ref
                        .read(chatActionsProvider.notifier)
                        .leaveChat(chat.id);
                    if (!context.mounted) return false;
                    final error = ref.read(chatActionsProvider).error;
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler: $error')),
                      );
                      return false;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat gelöscht')),
                    );
                    return true;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  child: _ChatListTile(
                    chat: chat,
                    onDelete: () async {
                      final ok = await _confirmLeave(context);
                      if (ok == true && context.mounted) {
                        await _leaveChat(context, ref, chat);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNewChatSheet(BuildContext context, WidgetRef ref) async {
    final listContext = context;
    try {
      await ref.read(myConnectionsProvider.future);
    } catch (_) {
      // Fehler wird im Sheet angezeigt.
    }
    if (!listContext.mounted) return;

    await showModalBottomSheet<void>(
      context: listContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final connectionsAsync = sheetRef.watch(myConnectionsProvider);
            final isStarting = sheetRef.watch(chatActionsProvider).isLoading;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Neuer Chat',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wähle einen Freund aus, um eine Unterhaltung zu starten.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: connectionsAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$e', textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => sheetRef
                                      .invalidate(myConnectionsProvider),
                                  child: const Text('Erneut laden'),
                                ),
                              ],
                            ),
                          ),
                          data: (connections) {
                            final friends = connections
                                .where((c) => c.type == ConnectionType.friend)
                                .toList();
                            if (friends.isEmpty) {
                              return Center(
                                child: Text(
                                  'Noch keine Freunde.\n'
                                  'Füge zuerst Freunde hinzu, um Chats zu starten.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              );
                            }
                            return ListView.separated(
                              controller: scrollController,
                              itemCount: friends.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final friend = friends[index];
                                final avatar = friend.avatarUrl?.trim();
                                final hasAvatar =
                                    avatar != null && avatar.isNotEmpty;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppColors.seed.withValues(alpha: 0.15),
                                    backgroundImage: hasAvatar
                                        ? CachedNetworkImageProvider(avatar)
                                        : null,
                                    child: hasAvatar
                                        ? null
                                        : Text(
                                            friend.username.isNotEmpty
                                                ? friend.username[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.seed,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    friend.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: friend.bio != null &&
                                          friend.bio!.trim().isNotEmpty
                                      ? Text(
                                          friend.bio!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: isStarting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.chevron_right,
                                          color: AppColors.brandNavy,
                                        ),
                                  onTap: isStarting
                                      ? null
                                      : () => _startFriendChat(
                                            sheetContext: sheetContext,
                                            listContext: listContext,
                                            ref: sheetRef,
                                            friendId: friend.profileId,
                                          ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _startFriendChat({
    required BuildContext sheetContext,
    required BuildContext listContext,
    required WidgetRef ref,
    required String friendId,
  }) async {
    try {
      final chatId = await ref
          .read(chatActionsProvider.notifier)
          .startFriendChat(friendId);
      if (sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
      if (!listContext.mounted) return;
      await listContext.pushNamed(
        RouteNames.chatRoom,
        pathParameters: {'id': chatId},
      );
    } catch (error) {
      if (!sheetContext.mounted) return;
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<bool?> _confirmLeave(BuildContext context) {
    return showDialog<bool>(
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
  }

  Future<void> _leaveChat(
    BuildContext context,
    WidgetRef ref,
    ChatSummary chat,
  ) async {
    await ref.read(chatActionsProvider.notifier).leaveChat(chat.id);
    if (!context.mounted) return;
    final error = ref.read(chatActionsProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? 'Chat gelöscht' : 'Fehler: $error',
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.chat,
    required this.onDelete,
  });

  final ChatSummary chat;
  final VoidCallback onDelete;

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
      title: Text(chat.displayTitle),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'delete',
                child: Text('Chat löschen'),
              ),
            ],
          ),
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
