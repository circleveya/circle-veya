import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../domain/entities/connection.dart';
import '../providers/friends_provider.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim());
    if (value.trim().length >= 2) {
      ref.invalidate(profileSearchProvider(value.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final searchAsync = _searchQuery.length >= 2
        ? ref.watch(profileSearchProvider(_searchQuery))
        : const AsyncValue<List<SearchableProfile>>.data([]);
    final isLoading = ref.watch(friendsActionsProvider).isLoading;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Username suchen (z.B. lea_go)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
          ),
        ),
        if (_searchQuery.length >= 2)
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (results) {
                if (results.isEmpty) {
                  return const Center(
                    child: Text('Keine Profile gefunden.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final profile = results[index];
                    return _SearchResultTile(
                      profile: profile,
                      isLoading: isLoading,
                      onAddFriend: () => ref
                          .read(friendsActionsProvider.notifier)
                          .addFriend(profile.id),
                      onAddAcquaintance: () => ref
                          .read(friendsActionsProvider.notifier)
                          .addAcquaintance(profile.id),
                      onRemove: () => ref
                          .read(friendsActionsProvider.notifier)
                          .removeConnection(profile.id),
                      onTapProfile: () => context.pushNamed(
                        RouteNames.profileView,
                        pathParameters: {'id': profile.id},
                      ),
                    );
                  },
                );
              },
            ),
          )
        else
          Expanded(
            child: connectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (connections) {
                final friends = connections
                    .where((c) => c.type == ConnectionType.friend)
                    .toList();
                final acquaintances = connections
                    .where((c) => c.type == ConnectionType.acquaintance)
                    .toList();

                if (connections.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Verbindungen',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Suche oben nach Demo-Usern wie lea_go, '
                            'max_kick oder sara_boards.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myConnectionsProvider);
                    await ref.read(myConnectionsProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ConnectionSection(
                        title: 'Freunde',
                        icon: Icons.favorite_outline,
                        connections: friends,
                        isLoading: isLoading,
                        showMessageButton: true,
                        onRemove: (id) => ref
                            .read(friendsActionsProvider.notifier)
                            .removeConnection(id),
                        onTapProfile: (id) => context.pushNamed(
                          RouteNames.profileView,
                          pathParameters: {'id': id},
                        ),
                        onMessage: (id) => _openFriendChat(context, ref, id),
                      ),
                      const SizedBox(height: 24),
                      _ConnectionSection(
                        title: 'Bekannte',
                        icon: Icons.people_outline,
                        connections: acquaintances,
                        isLoading: isLoading,
                        onRemove: (id) => ref
                            .read(friendsActionsProvider.notifier)
                            .removeConnection(id),
                        onTapProfile: (id) => context.pushNamed(
                          RouteNames.profileView,
                          pathParameters: {'id': id},
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _openFriendChat(
    BuildContext context,
    WidgetRef ref,
    String friendId,
  ) async {
    try {
      final chatId = await ref
          .read(chatActionsProvider.notifier)
          .startFriendChat(friendId);
      if (!context.mounted) return;
      await context.pushNamed(
        RouteNames.chatRoom,
        pathParameters: {'id': chatId},
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }
}

class _ConnectionSection extends StatelessWidget {
  const _ConnectionSection({
    required this.title,
    required this.icon,
    required this.connections,
    required this.isLoading,
    required this.onRemove,
    required this.onTapProfile,
    this.showMessageButton = false,
    this.onMessage,
  });

  final String title;
  final IconData icon;
  final List<UserConnection> connections;
  final bool isLoading;
  final void Function(String id) onRemove;
  final void Function(String id) onTapProfile;
  final bool showMessageButton;
  final void Function(String id)? onMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text('(${connections.length})'),
          ],
        ),
        const SizedBox(height: 8),
        if (connections.isEmpty)
          Text(
            'Noch keine $title',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ...connections.map(
            (connection) => _ConnectionTile(
              connection: connection,
              isLoading: isLoading,
              onRemove: () => onRemove(connection.profileId),
              onTap: () => onTapProfile(connection.profileId),
              onMessage: showMessageButton && onMessage != null
                  ? () => onMessage!(connection.profileId)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.connection,
    required this.isLoading,
    required this.onRemove,
    required this.onTap,
    this.onMessage,
  });

  final UserConnection connection;
  final bool isLoading;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: connection.avatarUrl != null
              ? CachedNetworkImageProvider(connection.avatarUrl!)
              : null,
          child: connection.avatarUrl == null
              ? Text(connection.username[0].toUpperCase())
              : null,
        ),
        title: Text(connection.username),
        subtitle: connection.bio != null ? Text(connection.bio!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onMessage != null)
              IconButton(
                onPressed: isLoading ? null : onMessage,
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Nachricht senden',
                color: Theme.of(context).colorScheme.primary,
              ),
            IconButton(
              onPressed: isLoading ? null : onRemove,
              icon: const Icon(Icons.person_remove_outlined),
              tooltip: 'Entfernen',
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.profile,
    required this.isLoading,
    required this.onAddFriend,
    required this.onAddAcquaintance,
    required this.onRemove,
    required this.onTapProfile,
  });

  final SearchableProfile profile;
  final bool isLoading;
  final VoidCallback onAddFriend;
  final VoidCallback onAddAcquaintance;
  final VoidCallback onRemove;
  final VoidCallback onTapProfile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTapProfile,
      leading: CircleAvatar(
        backgroundImage: profile.avatarUrl != null
            ? CachedNetworkImageProvider(profile.avatarUrl!)
            : null,
        child: profile.avatarUrl == null
            ? Text(profile.username[0].toUpperCase())
            : null,
      ),
      title: Text(profile.username),
      subtitle: Text(
        profile.connectionStatus?.label ?? profile.bio ?? 'Noch nicht verbunden',
      ),
      trailing: profile.isConnected
          ? IconButton(
              onPressed: isLoading ? null : onRemove,
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Verbunden – tippen zum Entfernen',
              color: Theme.of(context).colorScheme.primary,
            )
          : PopupMenuButton<String>(
              enabled: !isLoading,
              onSelected: (value) {
                if (value == 'friend') onAddFriend();
                if (value == 'acquaintance') onAddAcquaintance();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'friend',
                  child: Text('Als Freund hinzufügen'),
                ),
                PopupMenuItem(
                  value: 'acquaintance',
                  child: Text('Als Bekannten hinzufügen'),
                ),
              ],
              icon: const Icon(Icons.person_add_outlined),
            ),
    );
  }
}
