import 'dart:typed_data';

import '../../domain/entities/activity.dart';
import '../../domain/entities/discover_activities_state.dart';
import '../../domain/entities/discover_filters.dart';
import '../../domain/repositories/activity_repository.dart';

class UnconfiguredActivityRepository implements ActivityRepository {
  const UnconfiguredActivityRepository();

  static const _message =
      'Supabase ist nicht konfiguriert. Aktivitäten sind nicht verfügbar.';

  Never _throw() => throw UnsupportedError(_message);

  @override
  Future<void> acceptInterest(String interestId) async => _throw();

  @override
  Future<void> createActivity(
    CreateActivityInput input, {
    Uint8List? coverImageBytes,
    String? coverImageFileName,
  }) async =>
      _throw();

  @override
  Future<void> declineInterest(String interestId) async => _throw();

  @override
  Future<void> deleteActivity(String activityId) async => _throw();

  @override
  Future<List<DiscoverableActivity>> discoverActivities({
    required double latitude,
    required double longitude,
    ActivityDiscoverFilters filters = const ActivityDiscoverFilters.empty(),
    int offset = 0,
    int limit = discoverActivitiesPageSize,
  }) async =>
      [];

  @override
  Future<void> expressInterest(String activityId, {String? message}) async =>
      _throw();

  @override
  Future<List<ActivityInterest>> getActivityInterests(String activityId) async =>
      [];

  @override
  Future<List<DiscoverableActivity>> getHostedActivities() async => [];

  @override
  Future<void> joinDirect(String activityId) async => _throw();
}
