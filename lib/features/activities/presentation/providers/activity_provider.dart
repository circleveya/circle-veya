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
  int _loadedCount = 0;
  bool _fetchInFlight = false;

  @override
  DiscoverActivitiesState build() {
    ref.listen(locationCoordsKeyProvider, (_, __) {
      unawaited(refresh());
    });
    ref.listen(discoverFiltersProvider, (_, __) {
      unawaited(refresh());
    });
    Future.microtask(refresh);
    return const DiscoverActivitiesState(isLoading: true);
  }

  Future<void> refresh() async {
    _loadedCount = 0;
    state = const DiscoverActivitiesState(isLoading: true);
    await _fetchPage(append: false);
    unawaited(_triggerBackgroundSync());
  }

  Future<void> loadMore() async {
    if (_fetchInFlight || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _fetchPage(append: true);
  }

  Future<void> _fetchPage({required bool append}) async {
    if (_fetchInFlight) return;
    _fetchInFlight = true;

    try {
      final location = await _resolveLocation();
      final filters = ref.read(discoverFiltersProvider);
      final repository = ref.read(activityRepositoryProvider);

      final page = await repository.discoverActivities(
        latitude: location.latitude,
        longitude: location.longitude,
        filters: filters,
        offset: _loadedCount,
        limit: discoverActivitiesPageSize,
      );

      final filtered = ActivityDistanceFilter.apply(
        page,
        maxDistanceKm: filters.maxDistanceKm,
      );

      final merged = append
          ? _mergeActivities(state.activities, filtered)
          : filtered;

      _loadedCount = append ? _loadedCount + page.length : page.length;

      state = DiscoverActivitiesState(
        activities: merged,
        isLoading: false,
        isLoadingMore: false,
        hasMore: page.length >= discoverActivitiesPageSize,
      );
    } catch (error) {
      if (append && state.activities.isNotEmpty) {
        state = state.copyWith(
          isLoadingMore: false,
          error: error,
        );
      } else {
        state = DiscoverActivitiesState(
          activities: const [],
          isLoading: false,
          isLoadingMore: false,
          hasMore: false,
          error: error,
        );
      }
    } finally {
      _fetchInFlight = false;
    }
  }

  List<DiscoverableActivity> _mergeActivities(
    List<DiscoverableActivity> existing,
    List<DiscoverableActivity> incoming,
  ) {
    final seen = existing.map((a) => a.id).toSet();
    final merged = List<DiscoverableActivity>.from(existing);
    for (final activity in incoming) {
      if (seen.add(activity.id)) {
        merged.add(activity);
      }
    }
    return merged;
  }

  Future<UserLocation> _resolveLocation() async {
    final locationState = ref.read(userLocationProvider);
    if (locationState.hasValue) {
      return locationState.requireValue;
    }
    if (locationState.hasError) {
      return UserLocation.mockFrauenfeld;
    }
    return ref
        .read(userLocationProvider.future)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => UserLocation.mockFrauenfeld,
        )
        .catchError((_) => UserLocation.mockFrauenfeld);
  }

  Future<void> _triggerBackgroundSync() async {
    final location = await _resolveLocation();
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
      ref.invalidate(hostedActivitiesProvider);
    }
  }

  Future<void> expressInterest(String activityId, {String? message}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.expressInterest(activityId, message: message),
    );
    if (!state.hasError) {
      ref.invalidate(discoverActivitiesProvider);
    }
  }

  Future<void> acceptInterest(String interestId, String activityId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.acceptInterest(interestId));
    if (!state.hasError) {
      ref.invalidate(activityInterestsProvider(activityId));
      ref.invalidate(hostedActivitiesProvider);
      ref.invalidate(discoverActivitiesProvider);
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
      ref.invalidate(discoverActivitiesProvider);
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
      ref.invalidate(discoverActivitiesProvider);
    }
  }
}

final createActivityProvider = AutoDisposeAsyncNotifierProvider<
    CreateActivityController, void>(CreateActivityController.new);
