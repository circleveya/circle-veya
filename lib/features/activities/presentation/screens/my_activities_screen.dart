import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/activity_provider.dart';
import '../widgets/activity_card.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';

class MyActivitiesScreen extends ConsumerWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAsync = ref.watch(myActivitiesProvider);
    final isDeleting = ref.watch(activityActionsProvider).isLoading;

    return myAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (activities) {
        final created = activities
            .where((a) => a.viewerAction == ViewerAction.host)
            .toList();
        final joined = activities
            .where((a) => a.viewerAction == ViewerAction.joined)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myActivitiesProvider);
            await ref.read(myActivitiesProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _GalleryCard(),
              const SizedBox(height: 16),
              if (created.isEmpty && joined.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Noch keine eigenen Aktivitäten.\n'
                      'Erstelle eine oder sage bei Freunden zu.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                if (created.isNotEmpty) ...[
                  Text(
                    'Erstellt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...created.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ActivityCard(
                            activity: activity,
                            compactImage: true,
                            onTap: () => context.pushNamed(
                              RouteNames.activityDetail,
                              pathParameters: {'id': activity.id},
                              extra: activity,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: isDeleting
                                  ? null
                                  : () =>
                                      _confirmDelete(context, ref, activity),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Löschen'),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (joined.isNotEmpty) ...[
                  if (created.isNotEmpty) const SizedBox(height: 8),
                  Text(
                    'Zugesagt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...joined.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ActivityCard(
                        activity: activity,
                        compactImage: true,
                        onTap: () => context.pushNamed(
                          RouteNames.activityDetail,
                          pathParameters: {'id': activity.id},
                          extra: activity,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DiscoverableActivity activity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktivität löschen?'),
        content: Text(
          '„${activity.title}“ wird unwiderruflich gelöscht '
          '(inkl. Teilnehmer, Interessen und Chats).',
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

    if (confirmed != true || !context.mounted) return;

    await ref
        .read(activityActionsProvider.notifier)
        .deleteActivity(activity.id);

    if (!context.mounted) return;

    final error = ref.read(activityActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivität gelöscht')),
      );
    }
  }
}

class _GalleryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.photo_library_outlined),
        title: const Text('Erinnerungen'),
        subtitle: const Text(
          'Fotos von abgeschlossenen Aktivitäten – nur für dich',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(RouteNames.gallery),
      ),
    );
  }
}
