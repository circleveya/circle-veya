import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../activities/domain/entities/activity_enums.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../activities/presentation/widgets/activity_card.dart';

/// Social Feed – gruppiert nach sozialen Kreisen (Phase 1: Discover-Daten).
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(discoverActivitiesProvider);
    final actionsState = ref.watch(activityActionsProvider);
    final theme = Theme.of(context);
    final isActionLoading = actionsState.isLoading;

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (activities) {
        final strangers =
            activities.where((a) => a.visibleAs == VisibleAs.stranger).toList();
        final acquaintances = activities
            .where((a) => a.visibleAs == VisibleAs.acquaintance)
            .toList();
        final friends =
            activities.where((a) => a.visibleAs == VisibleAs.friend).toList();
        final sponsored = activities.where((a) => a.isFeatured).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  'Feed',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _CategoryTabs()),
            if (activities.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('Noch keine Aktivitäten im Feed.')),
              )
            else ...[
              _FeedSection(
                title: 'Neue Leute',
                activities: strangers,
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
              _FeedSection(
                title: 'Freunde',
                activities: friends,
                isActionLoading: isActionLoading,
                onTap: (a) => _openDetail(context, a),
                onAction: (a) => _handleAction(context, ref, a),
              ),
              _FeedSection(
                title: 'Gesponsert',
                activities: sponsored,
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
      ref.invalidate(discoverActivitiesProvider);
    }
  }
}

class _CategoryTabs extends StatefulWidget {
  @override
  State<_CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<_CategoryTabs> {
  int _selected = 0;
  static const _tabs = [
    'Alle',
    'Outdoor',
    'Sport',
    'Kultur',
    'Social',
    'Gaming',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selected;
          return FilterChip(
            label: Text(_tabs[index]),
            selected: selected,
            onSelected: (_) => setState(() => _selected = index),
            showCheckmark: false,
          );
        },
      ),
    );
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
    if (activities.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

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
