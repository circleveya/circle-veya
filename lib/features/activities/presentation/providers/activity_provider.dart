import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/location/activity_distance_filter.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/datasources/activity_remote_datasource.dart';
import '../../data/datasources/external_events_cache_datasource.dart';
import '../../data/datasources/external_events_sync_datasource.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../data/repositories/unconfigured_activity_repository.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/discover_activities_state.dart';
import '../../domain/entities/discover_filters.dart';
import '../../domain/repositories/activity_repository.dart';

final activityRemoteDatasourceProvider = Provider<ActivityRemoteDatasource>((ref) {
  return ActivityRemoteDatasource(ref.watch(supabaseClientProvider));
});

final externalEventsCacheDatasourceProvider =
    Provider<ExternalEventsCacheDatasource>((ref) {
  return ExternalEventsCacheDatasource(ref.watch(supabaseClientProvider));
});

final externalEventsSyncDatasourceProvider =
    Provider<ExternalEventsSyncDatasource>((ref) {
  return ExternalEventsSyncDatasource(ref.watch(supabaseClientProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  if (!Env.isConfigured) {
    return const UnconfiguredActivityRepository();
  }
  return ActivityRepositoryImpl(ref.watch(activityRemoteDatasourceProvider));
});

final discoverFiltersProvider = StateProvider<ActivityDiscoverFilters>(
  (ref) => const ActivityDiscoverFilters.empty(),
);

final isCompanyPartnerProvider = Provider<bool>((ref) {
  final profile = ref.watch(myProfileProvider).valueOrNull;
  return profile?.isCompany ?? false;
});

final discoverActivitiesProvider = NotifierProvider.autoDispose<
    DiscoverActivitiesController, DiscoverActivitiesState>(
  DiscoverActivitiesController.new,
);

class DiscoverActivitiesController
    extends AutoDisposeNotifier<DiscoverActivitiesState> {
  bool _fetchInFlight = false;
  bool _backgroundSyncStarted = false;

  @override
  DiscoverActivitiesState build() {
    ref.listen(locationCoordsKeyProvider, (_, __) {
      unawaited(goToPage(1));
    });
    ref.listen(discoverFiltersProvider, (_, __) {
      unawaited(goToPage(1));
    });
    Future.microtask(() => goToPage(1));
    return const DiscoverActivitiesState(isLoading: true);
  }

  Future<void> refresh() => goToPage(1);

  /// Lädt die nächste Seite und hängt sie an (Infinite Scroll).
  Future<void> loadMore() async {
    if (_fetchInFlight || state.isLoading || state.isLoadingMore) return;
    if (!state.hasNextPage) return;
    await goToPage(state.page + 1, append: true);
  }

  Future<void> goToPage(int page, {bool append = false}) async {
    if (_fetchInFlight) return;
    if (page < 1) page = 1;
    if (append && !state.hasNextPage) return;
    _fetchInFlight = true;

    state = state.copyWith(
      isLoading: !append,
      isLoadingMore: append,
      page: append ? state.page : page,
      clearError: true,
    );

    try {
      final location = _resolveLocation();
      final filters = ref.read(discoverFiltersProvider);
      final cache = ref.read(externalEventsCacheDatasourceProvider);

      final result = await cache.fetchPage(
        page: page,
        pageSize: discoverActivitiesPageSize,
        filters: filters,
        cityHint: _cityHint(location),
      );

      final filtered = ActivityDistanceFilter.apply(
        result.events,
        maxDistanceKm: filters.maxDistanceKm,
      );

      final totalPages = result.totalCount <= 0
          ? 1
          : ((result.totalCount - 1) ~/ discoverActivitiesPageSize) + 1;
      final safePage = page > totalPages ? totalPages : page;

      final activities = append
          ? _mergeUnique(state.activities, filtered)
          : filtered;

      state = DiscoverActivitiesState(
        activities: activities,
        isLoading: false,
        isLoadingMore: false,
        page: safePage,
        totalCount: result.totalCount,
      );

      if (!_backgroundSyncStarted) {
        _backgroundSyncStarted = true;
        unawaited(_triggerBackgroundSync());
      }
    } catch (error) {
      if (append) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: error,
        );
      } else {
        state = DiscoverActivitiesState(
          activities: const [],
          isLoading: false,
          isLoadingMore: false,
          page: page,
          totalCount: 0,
          error: error,
        );
      }
    } finally {
      _fetchInFlight = false;
    }
  }

  List<DiscoverableActivity> _mergeUnique(
    List<DiscoverableActivity> existing,
    List<DiscoverableActivity> incoming,
  ) {
    if (incoming.isEmpty) return existing;
    final seen = existing.map((a) => a.id).toSet();
    final merged = List<DiscoverableActivity>.of(existing);
    for (final activity in incoming) {
      if (seen.add(activity.id)) {
        merged.add(activity);
      }
    }
    return merged;
  }

  UserLocation _resolveLocation() {
    final locationState = ref.read(userLocationProvider);
    if (locationState.hasValue) {
      return locationState.requireValue;
    }
    return UserLocation.mockFrauenfeld;
  }

  String? _cityHint(UserLocation location) {
    if (location.source == LocationSource.gps) return null;
    final raw = location.label ?? location.displayLabel;
    return raw.replaceAll(RegExp(r'\s*\(.*\)\s*'), '').trim();
  }

  Future<void> _triggerBackgroundSync() async {
    final location = _resolveLocation();
    final filters = ref.read(discoverFiltersProvider);
    final syncDatasource = ref.read(externalEventsSyncDatasourceProvider);

    await syncDatasource
        .syncForUserLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          radiusKm: filters.maxDistanceKm ?? 25,
          countryCode: 'CH',
          expandRadius: true,
        )
        .timeout(const Duration(seconds: 20), onTimeout: () {})
        .catchError((_) {});
  }
}

final hostedActivitiesProvider =
    FutureProvider.autoDispose<List<DiscoverableActivity>>((ref) async {
  return ref.watch(activityRepositoryProvider).getHostedActivities();
});

/// Erstellt oder zugesagt – keine Interests, keine Discover-Events.
final myActivitiesProvider =
    FutureProvider.autoDispose<List<DiscoverableActivity>>((ref) async {
  return ref.watch(activityRepositoryProvider).getMyActivities();
});

/// Social Feed: nur User-Aktivitäten von Freunden & Bekannten (keine Eventfrog-Events).
final socialFeedProvider =
    FutureProvider.autoDispose<List<DiscoverableActivity>>((ref) async {
  ref.watch(locationCoordsKeyProvider);

  final locationState = ref.watch(userLocationProvider);
  final location = locationState.valueOrNull ?? UserLocation.mockFrauenfeld;
  final repository = ref.watch(activityRepositoryProvider);

  return repository.getSocialFeed(
    latitude: location.latitude,
    longitude: location.longitude,
    limit: 50,
  );
});

final activityInterestsProvider = FutureProvider.autoDispose
    .family<List<ActivityInterest>, String>((ref, activityId) async {
  return ref.watch(activityRepositoryProvider).getActivityInterests(activityId);
});

class ActivityActionsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ActivityRepository get _repo => ref.read(activityRepositoryProvider);

  Future<void> joinDirect(String activityId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.joinDirect(activityId));
    if (!state.hasError) {
      ref.invalidate(discoverActivitiesProvider);
      ref.invalidate(socialFeedProvider);
      ref.invalidate(hostedActivitiesProvider);
      ref.invalidate(myActivitiesProvider);
    }
  }

  Future<void> expressInterest(String activityId, {String? message}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.expressInterest(activityId, message: message),
    );
    if (!state.hasError) {
      ref.invalidate(discoverActivitiesProvider);
      ref.invalidate(socialFeedProvider);
    }
  }

  Future<void> acceptInterest(String interestId, String activityId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.acceptInterest(interestId));
    if (!state.hasError) {
      ref.invalidate(activityInterestsProvider(activityId));
      ref.invalidate(hostedActivitiesProvider);
      ref.invalidate(myActivitiesProvider);
      ref.invalidate(discoverActivitiesProvider);
      ref.invalidate(socialFeedProvider);
    }
  }

  Future<void> declineInterest(String interestId, String activityId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.declineInterest(interestId));
    if (!state.hasError) {
      ref.invalidate(activityInterestsProvider(activityId));
    }
  }

  Future<void> deleteActivity(String activityId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.deleteActivity(activityId));
    if (!state.hasError) {
      ref.invalidate(hostedActivitiesProvider);
      ref.invalidate(myActivitiesProvider);
      ref.invalidate(discoverActivitiesProvider);
      ref.invalidate(socialFeedProvider);
    }
  }
}

final activityActionsProvider = AutoDisposeAsyncNotifierProvider<
    ActivityActionsController, void>(ActivityActionsController.new);

class CreateActivityController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(
    CreateActivityInput input, {
    XFile? coverImage,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      Uint8List? bytes;
      String? fileName;
      if (coverImage != null) {
        final payload = await coverImage.toCoverPayload();
        bytes = payload.bytes;
        fileName = payload.fileName;
      }
      await ref.read(activityRepositoryProvider).createActivity(
            input,
            coverImageBytes: bytes,
            coverImageFileName: fileName,
          );
    });
    if (!state.hasError) {
      ref.invalidate(hostedActivitiesProvider);
      ref.invalidate(myActivitiesProvider);
      ref.invalidate(discoverActivitiesProvider);
      ref.invalidate(socialFeedProvider);
    }
  }
}

final createActivityProvider = AutoDisposeAsyncNotifierProvider<
    CreateActivityController, void>(CreateActivityController.new);
