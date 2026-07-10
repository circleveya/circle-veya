import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../activities/domain/entities/activity.dart';
import '../../../activities/domain/entities/activity_enums.dart';
import '../../../activities/domain/entities/discover_activities_state.dart';
import '../../../activities/domain/entities/discover_filters.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../activities/presentation/widgets/discover_filter_bar.dart';
import '../../../activities/presentation/widgets/discover_quick_filters_bar.dart';
import '../../../activities/presentation/widgets/location_filter_bar.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/url_utils.dart';
import '../../domain/discover_activity_grouper.dart';
import '../../domain/discover_feed_item.dart';
import '../widgets/discover_activity_grid.dart';
import '../widgets/discover_hero.dart';
import '../widgets/discover_occurrence_picker.dart';
import '../widgets/discover_page_navigation.dart';

class DiscoverFeedScreen extends ConsumerStatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  ConsumerState<DiscoverFeedScreen> createState() =>
      _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends ConsumerState<DiscoverFeedScreen> {
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(discoverActivitiesProvider);
    final actionsState = ref.watch(activityActionsProvider);
    final filters = ref.watch(discoverFiltersProvider);
    final isActionLoading = actionsState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverFilterBar(
          filters: filters,
          onChanged: (next) {
            ref.read(discoverFiltersProvider.notifier).state = next;
          },
        ),
        DiscoverQuickFiltersBar(
          filters: filters,
          onFiltersChanged: (next) {
            ref.read(discoverFiltersProvider.notifier).state = next;
          },
        ),
        Expanded(
          child: _buildBody(
            context,
            feedState: feedState,
            filters: filters,
            isActionLoading: isActionLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required DiscoverActivitiesState feedState,
    required ActivityDiscoverFilters filters,
    required bool isActionLoading,
  }) {
    if (feedState.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feedState.hasError) {
      return _ErrorState(
        message: _friendlyErrorMessage(feedState.error!),
        onRetry: () {
          ref.invalidate(userLocationProvider);
          ref.invalidate(discoverActivitiesProvider);
        },
      );
    }

    final filtered = _searchQuery.isEmpty
        ? feedState.activities
        : feedState.activities
            .where(
              (a) =>
                  a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (a.locationName?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();

    if (filtered.isEmpty) {
      return ListView(
        controller: _scrollController,
        children: [
          LocationFilterBar(
            filters: filters,
            onFiltersChanged: (next) {
              ref.read(discoverFiltersProvider.notifier).state = next;
            },
          ),
          DiscoverHero(onSearch: _onSearch),
          SizedBox(
            height: 200,
            child: _EmptyState(
              hasFilters:
                  filters.hasActiveFilters || _searchQuery.isNotEmpty,
              onRefresh: () =>
                  ref.read(discoverActivitiesProvider.notifier).refresh(),
              onClearFilters: filters.hasActiveFilters
                  ? () {
                      ref.read(discoverFiltersProvider.notifier).state =
                          const ActivityDiscoverFilters.empty();
                      setState(() => _searchQuery = '');
                      ref.invalidate(discoverActivitiesProvider);
                    }
                  : null,
            ),
          ),
        ],
      );
    }

    final grouped = DiscoverActivityGrouper.group(filtered);
    final featured = grouped.where((item) => item.primary.isFeatured).toList();
    final regular = grouped.where((item) => !item.primary.isFeatured).toList();
    final gridItems = [...featured, ...regular];

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(discoverActivitiesProvider.notifier).refresh(),
      child: ListView(
        controller: _scrollController,
        children: [
          LocationFilterBar(
            filters: filters,
            onFiltersChanged: (next) {
              ref.read(discoverFiltersProvider.notifier).state = next;
            },
          ),
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
            items: gridItems,
            isActionLoading: isActionLoading,
            onTap: (item) => _openFeedItem(context, item),
            onAction: (activity) => _handleAction(context, ref, activity),
          ),
          DiscoverPageNavigation(
            state: feedState,
            onPageSelected: (page) {
              ref.read(discoverActivitiesProvider.notifier).goToPage(page);
            },
          ),
        ],
      ),
    );
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query.trim());
  }

  Future<void> _openFeedItem(BuildContext context, DiscoverFeedItem item) async {
    final activity = item.isGrouped
        ? await showDiscoverOccurrencePicker(context, item)
        : item.primary;
    if (activity == null || !context.mounted) return;
    _openDetail(context, activity);
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

String _friendlyErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('non-volatile function')) {
    return 'Datenbank-Fix nötig: scripts/fixes/01_volatile_functions.sql in Supabase ausführen.';
  }
  if (text.contains('Nicht authentifiziert')) {
    return 'Bitte erneut anmelden.';
  }
  if (text.contains('geography') || text.contains('PostGIS')) {
    return 'Standort-Datenbank nicht vollständig eingerichtet (PostGIS).';
  }
  return 'Aktivitäten konnten nicht geladen werden. Standort prüfen und erneut versuchen.';
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
