import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/groups_provider.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.groupCreate),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Kreis erstellen'),
        backgroundColor: AppColors.seed,
        foregroundColor: Colors.white,
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(myGroupsProvider),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (groups) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myGroupsProvider);
              await ref.read(myGroupsProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kreise',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dauerhafte Communities – austauschen und neue Treffen planen',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (groups.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Noch keine Kreise.\n'
                          'Erstelle einen oder mach aus einer gehosteten '
                          'Aktivität einen Kreis.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    sliver: SliverList.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return Material(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.pushNamed(
                              RouteNames.groupDetail,
                              pathParameters: {'id': group.id},
                              extra: group.name,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        AppColors.seed.withValues(alpha: 0.15),
                                    backgroundImage: group.imageUrl != null &&
                                            group.imageUrl!.trim().isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            group.imageUrl!,
                                          )
                                        : null,
                                    child: group.imageUrl == null ||
                                            group.imageUrl!.trim().isEmpty
                                        ? Text(
                                            group.name.isNotEmpty
                                                ? group.name[0].toUpperCase()
                                                : 'K',
                                            style: const TextStyle(
                                              color: AppColors.seed,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${group.memberCount} Mitglieder'
                                          '${group.sourceActivityId != null ? ' · aus Aktivität' : ''}'
                                          '${group.isOwner ? ' · Owner' : ''}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
