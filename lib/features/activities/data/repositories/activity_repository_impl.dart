import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/discover_activities_state.dart';
import '../../domain/entities/discover_filters.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_remote_datasource.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(this._datasource);

  final ActivityRemoteDatasource _datasource;

  @override
  Future<List<DiscoverableActivity>> discoverActivities({
    required double latitude,
    required double longitude,
    ActivityDiscoverFilters filters = const ActivityDiscoverFilters.empty(),
    int offset = 0,
    int limit = discoverActivitiesPageSize,
  }) async {
    try {
      return await _datasource.discoverActivities(
        latitude: latitude,
        longitude: longitude,
        filters: filters,
        offset: offset,
        limit: limit,
      );
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    } on AppAuthException catch (error) {
      throw ActivityFailure(error.message);
    } on FormatException catch (error) {
      throw ActivityFailure(error.message);
    } catch (error) {
      throw ActivityFailure(
        'Aktivitäten konnten nicht geladen werden: $error',
      );
    }
  }

  @override
  Future<List<DiscoverableActivity>> getSocialFeed({
    required double latitude,
    required double longitude,
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      return await _datasource.getSocialFeed(
        latitude: latitude,
        longitude: longitude,
        offset: offset,
        limit: limit,
      );
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    } on AppAuthException catch (error) {
      throw ActivityFailure(error.message);
    } on FormatException catch (error) {
      throw ActivityFailure(error.message);
    } catch (error) {
      throw ActivityFailure(
        'Social Feed konnte nicht geladen werden: $error',
      );
    }
  }

  @override
  Future<List<DiscoverableActivity>> getMyActivities({
    int offset = 0,
    int limit = 100,
  }) async {
    try {
      return await _datasource.getMyActivities(
        offset: offset,
        limit: limit,
      );
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    } on AppAuthException catch (error) {
      throw ActivityFailure(error.message);
    } on FormatException catch (error) {
      throw ActivityFailure(error.message);
    } catch (error) {
      throw ActivityFailure(
        'Meine Aktivitäten konnten nicht geladen werden: $error',
      );
    }
  }

  @override
  Future<List<DiscoverableActivity>> getHostedActivities() async {
    try {
      return await _datasource.getHostedActivities();
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    } on AppAuthException catch (error) {
      throw ActivityFailure(error.message);
    }
  }

  @override
  Future<void> createActivity(
    CreateActivityInput input, {
    Uint8List? coverImageBytes,
    String? coverImageFileName,
  }) async {
    try {
      await _datasource.createActivity(
        input,
        coverImageBytes: coverImageBytes,
        coverImageFileName: coverImageFileName,
      );
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    } on AppAuthException catch (error) {
      throw ActivityFailure(error.message);
    } on StorageException catch (error) {
      throw ActivityFailure(error.message);
    }
  }

  @override
  Future<void> joinDirect(String activityId) async {
    try {
      await _datasource.joinDirect(activityId);
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    }
  }

  @override
  Future<void> expressInterest(String activityId, {String? message}) async {
    try {
      await _datasource.expressInterest(activityId, message: message);
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    }
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    try {
      await _datasource.deleteActivity(activityId);
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    } on AppAuthException catch (error) {
      throw ActivityFailure(error.message);
    }
  }

  @override
  Future<void> acceptInterest(String interestId) async {
    try {
      await _datasource.acceptInterest(interestId);
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    }
  }

  @override
  Future<void> declineInterest(String interestId) async {
    try {
      await _datasource.declineInterest(interestId);
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    }
  }

  @override
  Future<List<ActivityInterest>> getActivityInterests(String activityId) async {
    try {
      return await _datasource.getActivityInterests(activityId);
    } on PostgrestException catch (error) {
      throw ActivityFailure(error.message);
    }
  }
}

class ActivityFailure extends Failure {
  const ActivityFailure(super.message);
}
