import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/location/activity_distance_filter.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/datasources/activity_remote_datasource.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../data/repositories/unconfigured_activity_repository.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/discover_filters.dart';
import '../../domain/repositories/activity_repository.dart';
final activityRemoteDatasourceProvider = Provider<ActivityRemoteDatasource>((ref) {
  return ActivityRemoteDatasource(ref.watch(supabaseClientProvider));
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

final discoverActivitiesProvider =
    FutureProvider.autoDispose<List<DiscoverableActivity>>((ref) async {
  ref.watch(locationCoordsKeyProvider);

  final locationState = ref.watch(userLocationProvider);
  final UserLocation location = locationState.hasValue
      ? locationState.requireValue
      : await ref.read(userLocationProvider.future);

  final filters = ref.watch(discoverFiltersProvider);
  final activities =
      await ref.watch(activityRepositoryProvider).discoverActivities(
            latitude: location.latitude,
            longitude: location.longitude,
            filters: filters,
          );

  return ActivityDistanceFilter.apply(
    activities,
    maxDistanceKm: filters.maxDistanceKm,
  );
});

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
