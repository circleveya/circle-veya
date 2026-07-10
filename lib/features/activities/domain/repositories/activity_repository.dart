import 'dart:typed_data';

import '../entities/activity.dart';
import '../entities/discover_activities_state.dart';
import '../entities/discover_filters.dart';

abstract class ActivityRepository {
  Future<List<DiscoverableActivity>> discoverActivities({
    required double latitude,
    required double longitude,
    ActivityDiscoverFilters filters = const ActivityDiscoverFilters.empty(),
    int offset = 0,
    int limit = discoverActivitiesPageSize,
  });

  /// Aktivitäten von Freunden/Bekannten (als Host oder Teilnehmer).
  Future<List<DiscoverableActivity>> getSocialFeed({
    required double latitude,
    required double longitude,
    int offset = 0,
    int limit = 50,
  });

  /// Eigene Aktivitäten: erstellt oder zugesagt (keine Interests).
  Future<List<DiscoverableActivity>> getMyActivities({
    int offset = 0,
    int limit = 100,
  });

  Future<List<DiscoverableActivity>> getHostedActivities();

  Future<void> createActivity(
    CreateActivityInput input, {
    Uint8List? coverImageBytes,
    String? coverImageFileName,
  });

  Future<void> updateActivity(UpdateActivityInput input);

  Future<void> joinDirect(String activityId);

  Future<void> expressInterest(String activityId, {String? message});

  Future<void> deleteActivity(String activityId);

  Future<void> acceptInterest(String interestId);

  Future<void> declineInterest(String interestId);

  Future<List<ActivityInterest>> getActivityInterests(String activityId);
}
