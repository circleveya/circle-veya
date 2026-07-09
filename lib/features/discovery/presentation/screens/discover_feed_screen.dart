import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../activities/domain/entities/activity.dart';
import '../../../activities/domain/entities/activity_enums.dart';
import '../../../activities/domain/entities/discover_filters.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../activities/presentation/widgets/discover_filter_bar.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/url_utils.dart';
import '../widgets/discover_activity_grid.dart';
import '../widgets/discover_hero.dart';

class DiscoverFeedScreen extends ConsumerStatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  ConsumerState<DiscoverFeedScreen> createState() =>
      _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends ConsumerState<DiscoverFeedScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(discoverActivitiesProvider);
    final actionsState = ref.watch(activityActionsProvider);
    final filters = ref.watch(discoverFiltersProvider);
    final isActionLoading = actionsState.isLoading;

    return Column(
      children: [
        DiscoverFilterBar(
          filters: filters,
          onChanged: (next) {
            ref.read(discoverFiltersProvider.notifier).state = next;
            ref.invalidate(discoverActivitiesProvider);
          },
        ),
        ref.watch(userLocationProvider).maybeWhen(
              data: (location) => location.isMock == true
                  ? const _MockLocationBanner()
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
        Expanded(
          child: activitiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(discoverActivitiesProvider),
            ),
            data: (activities) {
              final filtered = _searchQuery.isEmpty
                  ? activities
                  : activities
                      .where(
                        (a) =>
                            a.title
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            (a.locationName?.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ??
                                false),
                      )
                      .toList();

              if (filtered.isEmpty) {
                return ListView(
                  children: [
                    DiscoverHero(onSearch: _onSearch),
                    SizedBox(
                      height: 200,
                      child: _EmptyState(
                        hasFilters: filters.hasActiveFilters ||
                            _searchQuery.isNotEmpty,
                        onRefresh: () =>
                            ref.invalidate(discoverActivitiesProvider),
                        onClearFilters: filters.hasActiveFilters
                            ? () {
                                ref
                                    .read(discoverFiltersProvider.notifier)
                                    .state = const ActivityDiscoverFilters
                                        .empty();
                                setState(() => _searchQuery = '');
                                ref.invalidate(discoverActivitiesProvider);
                              }
                            : null,
                      ),
                    ),
                  ],
                );
              }

              final featured =
                  filtered.where((a) => a.isFeatured).toList();
              final regular =
                  filtered.where((a) => !a.isFeatured).toList();
              final gridItems = [...featured, ...regular];

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(discoverActivitiesProvider);
                  await ref.read(discoverActivitiesProvider.future);
                },
                child: ListView(
                  children: [
                    DiscoverHero(onSearch: _onSearch),
                    if (featured.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Text(
                          'Featured Partner',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                    DiscoverActivityGrid(
                      activities: gridItems,
                      isActionLoading: isActionLoading,
                      onTap: (a) => _openDetail(context, a),
                      onAction: (a) => _handleAction(context, ref, a),
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

  void _onSearch(String query) {
    setState(() => _searchQuery = query.trim());
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

class _MockLocationBanner extends StatelessWidget {
  const _MockLocationBanner();

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: const Text(
        'Test-Standort Frauenfeld, CH – GPS ist deaktiviert oder nicht verfügbar.',
      ),
      leading: const Icon(Icons.my_location),
      actions: [
        TextButton(
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onRefresh,
    this.hasFilters = false,
    this.onClearFilters,
  });

  final VoidCallback onRefresh;
  final bool hasFilters;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_alt_off_outlined : Icons.explore_outlined,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Keine Aktivitäten für diese Suche'
                  : 'Keine Aktivitäten in deiner Nähe',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onClearFilters != null)
              FilledButton(
                onPressed: onClearFilters,
                child: const Text('Filter zurücksetzen'),
              ),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Aktualisieren'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
