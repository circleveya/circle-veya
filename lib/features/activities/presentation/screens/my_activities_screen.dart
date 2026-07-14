import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';
import '../providers/activity_provider.dart';
import '../widgets/activity_card.dart';

class MyActivitiesScreen extends ConsumerWidget {
  const MyActivitiesScreen({super.key});

  static bool _isPast(DiscoverableActivity activity) {
    final date = activity.dateTime;
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAsync = ref.watch(myActivitiesProvider);

    return myAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (activities) {
        final upcoming = activities.where((a) => !_isPast(a)).toList();
        final past = activities.where(_isPast).toList()
          ..sort((a, b) {
            final aDate = a.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

        final created = upcoming
            .where((a) => a.viewerAction == ViewerAction.host)
            .toList();
        final joined = upcoming
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
              const _GalleryCard(),
              const SizedBox(height: 16),
              if (created.isEmpty && joined.isEmpty && past.isEmpty)
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
                if (created.isEmpty && joined.isEmpty && past.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Keine aktuellen Aktivitäten.\n'
                      'Vergangene findest du unten.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                if (created.isNotEmpty) ...[
                  Text(
                    'Erstellt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...created.map(
                    (activity) => _HostedActivityTile(
                      activity: activity,
                      onConfirmDelete: () =>
                          _confirmDelete(context, ref, activity),
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
                        onTap: () => context.pushNamed(
                          RouteNames.activityDetail,
                          pathParameters: {'id': activity.id},
                          extra: activity,
                        ),
                      ),
                    ),
                  ),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _PastActivitiesFolder(activities: past),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(
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

    if (confirmed != true || !context.mounted) return false;

    await ref
        .read(activityActionsProvider.notifier)
        .deleteActivity(activity.id);

    if (!context.mounted) return false;

    final error = ref.read(activityActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aktivität gelöscht')),
    );
    return true;
  }
}

class _HostedActivityTile extends StatelessWidget {
  const _HostedActivityTile({
    required this.activity,
    required this.onConfirmDelete,
  });

  final DiscoverableActivity activity;
  final Future<bool> Function() onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('delete-${activity.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onConfirmDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        child: ActivityCard(
          activity: activity,
          onTap: () => context.pushNamed(
            RouteNames.activityDetail,
            pathParameters: {'id': activity.id},
            extra: activity,
          ),
        ),
      ),
    );
  }
}

/// Zugeklappter Ordner für vergangene Aktivitäten.
class _PastActivitiesFolder extends StatelessWidget {
  const _PastActivitiesFolder({required this.activities});

  final List<DiscoverableActivity> activities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(
            Icons.folder_outlined,
            color: AppColors.brandNavy.withValues(alpha: 0.75),
          ),
          title: Text(
            'Vergangene Aktivitäten',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${activities.length} '
            '${activities.length == 1 ? 'Aktivität' : 'Aktivitäten'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            for (final activity in activities)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ActivityCard(
                  activity: activity,
                  onTap: () => context.pushNamed(
                    RouteNames.activityDetail,
                    pathParameters: {'id': activity.id},
                    extra: activity,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard();

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
