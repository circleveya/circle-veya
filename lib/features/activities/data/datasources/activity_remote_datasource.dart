import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';
import '../../domain/entities/activity_filters.dart';
import '../../domain/entities/discover_filters.dart';

class ActivityRemoteDatasource {
  ActivityRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<List<DiscoverableActivity>> discoverActivities({
    required double latitude,
    required double longitude,
    ActivityDiscoverFilters filters = const ActivityDiscoverFilters.empty(),
  }) async {
    final params = <String, dynamic>{
      'p_lat': latitude,
      'p_lng': longitude,
    };

    if (filters.locationType != null) {
      params['p_location_type'] = filters.locationType!.dbValue;
    }
    if (filters.weatherCondition != null) {
      params['p_weather_condition'] = filters.weatherCondition!.dbValue;
    }

    final response = await _client.rpc('discover_activities', params: params);

    return (response as List)
        .map((row) => _mapDiscoverableActivity(row as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    return await _client
        .from('profiles')
        .select('id, username, user_type')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<List<DiscoverableActivity>> getHostedActivities() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Nicht angemeldet');
    }

    final response = await _client
        .from('activities')
        .select(
          'id, host_id, title, description, max_participants, current_participants, '
          'date_time, image_url, location_type, weather_condition, location_name, '
          'is_sponsored, status, source, external_url, created_at, '
          'profiles!activities_host_id_fkey(username, user_type)',
        )
        .eq('host_id', userId)
        .order('date_time', ascending: true, nullsFirst: false);

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      final profile = map['profiles'] as Map<String, dynamic>?;
      return DiscoverableActivity(
        id: map['id'] as String,
        hostId: map['host_id'] as String,
        hostUsername: profile?['username'] as String? ?? 'Du',
        hostIsCompany: profile?['user_type'] == 'company',
        title: map['title'] as String,
        description: map['description'] as String?,
        maxParticipants: map['max_participants'] as int?,
        currentParticipants: map['current_participants'] as int,
        dateTime: _parseOptionalDateTime(map['date_time']),
        imageUrl: map['image_url'] as String?,
        locationType: LocationType.values.byName(
          map['location_type'] as String,
        ),
        weatherCondition: WeatherCondition.values.byName(
          map['weather_condition'] as String,
        ),
        locationName: map['location_name'] as String?,
        distanceKm: null,
        visibleAs: VisibleAs.friend,
        viewerAction: ViewerAction.host,
        isSponsored: map['is_sponsored'] as bool? ?? false,
        isFeatured: (map['is_sponsored'] as bool? ?? false) &&
            profile?['user_type'] == 'company',
      );
    }).toList();
  }

  Future<void> createActivity(
    CreateActivityInput input, {
    Uint8List? coverImageBytes,
    String? coverImageFileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Nicht angemeldet');
    }

    final payload = <String, dynamic>{
      'host_id': userId,
      'title': input.title,
      'description': input.description,
      'max_participants': input.maxParticipants,
      'location_geo': 'POINT(${input.longitude} ${input.latitude})',
      'location_name': input.locationName,
      'location_type': input.locationType.dbValue,
      'weather_condition': input.weatherCondition.dbValue,
      'visible_to_friends': input.visibleToFriends,
      'visible_to_acquaintances': input.visibleToAcquaintances,
      'visible_to_strangers': input.visibleToStrangers,
      'discovery_radius_km': input.discoveryRadiusKm,
      'is_sponsored': input.isSponsored,
    };

    if (input.dateTime != null) {
      payload['date_time'] = input.dateTime!.toUtc().toIso8601String();
    }

    final response = await _client
        .from('activities')
        .insert(payload)
        .select('id')
        .single();

    final activityId = response['id'] as String;

    if (coverImageBytes != null && coverImageBytes.isNotEmpty) {
      final extension = _extensionFromFileName(coverImageFileName);
      final path = '$userId/$activityId.$extension';

      await _client.storage.from('activity-images').uploadBinary(
            path,
            coverImageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentType(extension),
            ),
          );

      final publicUrl =
          _client.storage.from('activity-images').getPublicUrl(path);

      await _client
          .from('activities')
          .update({'image_url': publicUrl})
          .eq('id', activityId);
    }
  }

  Future<void> joinDirect(String activityId) async {
    await _client.rpc('join_activity_direct', params: {
      'p_activity_id': activityId,
    });
  }

  Future<void> expressInterest(String activityId, {String? message}) async {
    await _client.rpc('express_activity_interest', params: {
      'p_activity_id': activityId,
      'p_message': message,
    });
  }

  Future<void> deleteActivity(String activityId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Nicht angemeldet');
    }

    await _client.from('activities').delete().eq('id', activityId);
  }

  Future<void> acceptInterest(String interestId) async {
    await _client.rpc('accept_activity_interest', params: {
      'p_interest_id': interestId,
    });
  }

  Future<void> declineInterest(String interestId) async {
    await _client.rpc('decline_activity_interest', params: {
      'p_interest_id': interestId,
    });
  }

  Future<List<ActivityInterest>> getActivityInterests(String activityId) async {
    final response = await _client.rpc(
      'get_activity_interests',
      params: {'p_activity_id': activityId},
    );

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return ActivityInterest(
        id: map['id'] as String,
        profileId: map['profile_id'] as String,
        username: map['username'] as String,
        avatarUrl: map['avatar_url'] as String?,
        message: map['message'] as String?,
        status: map['status'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }

  DiscoverableActivity _mapDiscoverableActivity(Map<String, dynamic> map) {
    return DiscoverableActivity(
      id: map['id'] as String,
      hostId: map['host_id'] as String,
      hostUsername: map['host_username'] as String,
      hostIsCompany: map['host_is_company'] as bool? ?? false,
      title: map['title'] as String,
      description: map['description'] as String?,
      maxParticipants: map['max_participants'] as int?,
      currentParticipants: map['current_participants'] as int,
      dateTime: _parseOptionalDateTime(map['date_time']),
      imageUrl: map['image_url'] as String?,
      locationType: LocationType.values.byName(
        map['location_type'] as String,
      ),
      weatherCondition: WeatherCondition.values.byName(
        map['weather_condition'] as String,
      ),
      locationName: map['location_name'] as String?,
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      visibleAs: VisibleAs.fromDb(map['visible_as'] as String),
      viewerAction: ViewerAction.fromDb(map['viewer_action'] as String),
      isSponsored: map['is_sponsored'] as bool? ?? false,
      isFeatured: map['is_featured'] as bool? ?? false,
      source: ActivitySource.fromDb(map['source'] as String?),
      externalUrl: map['external_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      participantAvatarUrls: _parseAvatarUrls(map['participant_avatar_urls']),
    );
  }

  List<String> _parseAvatarUrls(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  String _extensionFromFileName(String? fileName) {
    if (fileName != null && fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return 'jpg';
  }

  String _contentType(String extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
}

/// Hilfsmethode für die UI-Schicht (image_picker).
extension ActivityCoverImageX on XFile {
  Future<({Uint8List bytes, String fileName})> toCoverPayload() async {
    return (bytes: await readAsBytes(), fileName: name);
  }
}
