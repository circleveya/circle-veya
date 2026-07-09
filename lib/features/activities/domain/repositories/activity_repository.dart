import 'dart:typed_data';

import '../entities/activity.dart';
import '../entities/discover_filters.dart';

abstract class ActivityRepository {
  Future<List<DiscoverableActivity>> discoverActivities({
    required double latitude,
    required double longitude,
    ActivityDiscoverFilters filters = const ActivityDiscoverFilters.empty(),
  });

  Future<List<DiscoverableActivity>> getHostedActivities();

  Future<void> createActivity(
    CreateActivityInput input, {
    Uint8List? coverImageBytes,
    String? coverImageFileName,
  });

  Future<void> joinDirect(String activityId);

  Future<void> expressInterest(String activityId, {String? message});

  Future<void> deleteActivity(String activityId);

  Future<void> acceptInterest(String interestId);

  Future<void> declineInterest(String interestId);

  Future<List<ActivityInterest>> getActivityInterests(String activityId);
}
