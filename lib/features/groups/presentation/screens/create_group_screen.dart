import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../friends/domain/entities/connection.dart';
import '../../../friends/presentation/providers/friends_provider.dart';
import '../providers/groups_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _selectedIds = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final isLoading = ref.watch(groupsControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Kreis erstellen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name des Kreises',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 80,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Beschreibung (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 280,
          ),
          const SizedBox(height: 20),
          Text(
            'Freunde einladen',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          connectionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e'),
            data: (connections) {
              final friends = connections
                  .where((c) => c.type == ConnectionType.friend)
                  .toList();
              if (friends.isEmpty) {
                return Text(
                  'Noch keine Freunde zum Einladen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                children: [
                  for (final friend in friends)
                    CheckboxListTile(
                      value: _selectedIds.contains(friend.profileId),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.add(friend.profileId);
                          } else {
                            _selectedIds.remove(friend.profileId);
                          }
                        });
                      },
                      secondary: CircleAvatar(
                        backgroundImage: friend.avatarUrl != null
                            ? CachedNetworkImageProvider(friend.avatarUrl!)
                            : null,
                        child: friend.avatarUrl == null
                            ? Text(friend.username[0].toUpperCase())
                            : null,
                      ),
                      title: Text(friend.username),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandNavy,
              minimumSize: const Size.fromHeight(52),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kreis erstellen'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen für den Kreis eingeben')),
      );
      return;
    }

    final id = await ref.read(groupsControllerProvider.notifier).createGroup(
          name: name,
          description: _descriptionController.text.trim(),
          memberIds: _selectedIds.toList(),
        );

    if (!mounted) return;
    final error = ref.read(groupsControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $error')),
      );
      return;
    }

    if (id != null) {
      context.pushReplacementNamed(
        RouteNames.groupDetail,
        pathParameters: {'id': id},
        extra: name,
      );
    }
  }
}
