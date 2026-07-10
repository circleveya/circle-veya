import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../activities/domain/entities/activity_enums.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../activities/presentation/widgets/activity_card.dart';

/// Social Feed – nur Aktivitäten von Freunden & Bekannten.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(socialFeedProvider);
    final actionsState = ref.watch(activityActionsProvider);
    final theme = Theme.of(context);
    final isActionLoading = actionsState.isLoading;

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(socialFeedProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
      data: (activities) {
        final acquaintances = activities
            .where((a) => a.visibleAs == VisibleAs.acquaintance)
            .toList();
        final friends =
            activities.where((a) => a.visibleAs == VisibleAs.friend).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feed',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aktivitäten von Freunden und Bekannten',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (activities.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Noch keine Aktivitäten von Freunden oder Bekannten.\n'
                      'Füge Freunde hinzu oder warte auf neue Events in deinem Kreis.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else ...[
              _FeedSection(
                title: 'Freunde',
                activities: friends,
                isActionLoading: isActionLoading,
                onTap: (a) => _openDetail(context, a),
                onAction: (a) => _handleAction(context, ref, a),
              ),
              _FeedSection(
                title: 'Bekannte',
                activities: acquaintances,
                isActionLoading: isActionLoading,
                onTap: (a) => _openDetail(context, a),
                onAction: (a) => _handleAction(context, ref, a),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }

  void _openDetail(BuildContext context, DiscoverableActivity activity) {
    context.pushNamed(
      RouteNames.activityDetail,
      pathParameters: {'id': activity.id},
      extra: activity,
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    DiscoverableActivity activity,
  ) async {
    if (activity.viewerAction == ViewerAction.externalLink) {
      final url = activity.externalUrl;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine externe Quelle verfügbar')),
        );
        return;
      }
      final ok = await openExternalUrl(url);
      if (!context.mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link konnte nicht geöffnet werden')),
        );
      }
      return;
    }

    final controller = ref.read(activityActionsProvider.notifier);

    if (activity.viewerAction == ViewerAction.directJoin) {
      await controller.joinDirect(activity.id);
    } else if (activity.viewerAction == ViewerAction.interest) {
      await controller.expressInterest(activity.id);
    }

    if (!context.mounted) return;
    final error = ref.read(activityActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erfolgreich!')),
      );
      ref.invalidate(socialFeedProvider);
    }
  }
}

class _FeedSection extends StatelessWidget {
  const _FeedSection({
    required this.title,
    required this.activities,
    required this.isActionLoading,
    required this.onTap,
    required this.onAction,
  });

  final String title;
  final List<DiscoverableActivity> activities;
  final bool isActionLoading;
  final void Function(DiscoverableActivity activity) onTap;
  final void Function(DiscoverableActivity activity) onAction;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActivityCard(
                  activity: activity,
                  isLoading: isActionLoading,
                  onTap: () => onTap(activity),
                  onAction: () => onAction(activity),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
