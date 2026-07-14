import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/groups_provider.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  final String groupId;
  final String? groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName ?? 'Gruppe'),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (members) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupMembersProvider(groupId));
              await ref.read(groupMembersProvider(groupId).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  '${members.length} Mitglieder',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final member in members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: member.avatarUrl != null
                          ? CachedNetworkImageProvider(member.avatarUrl!)
                          : null,
                      child: member.avatarUrl == null
                          ? Text(member.username[0].toUpperCase())
                          : null,
                    ),
                    title: Text(member.username),
                    subtitle: Text(
                      member.role == 'owner'
                          ? 'Owner'
                          : member.role == 'admin'
                              ? 'Admin'
                              : 'Mitglied',
                    ),
                    onTap: () => context.pushNamed(
                      RouteNames.profileView,
                      pathParameters: {'id': member.profileId},
                    ),
                    trailing: member.role == 'owner'
                        ? const Icon(Icons.star, color: AppColors.seed, size: 18)
                        : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
