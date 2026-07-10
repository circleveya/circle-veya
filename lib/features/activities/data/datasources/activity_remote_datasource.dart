import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';
import '../../domain/entities/activity_filters.dart';
import '../../domain/entities/discover_activities_state.dart';
import '../../domain/entities/discover_filters.dart';

class ActivityRemoteDatasource {
  ActivityRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<List<DiscoverableActivity>> discoverActivities({
    required double latitude,
    required double longitude,
    ActivityDiscoverFilters filters = const ActivityDiscoverFilters.empty(),
    int offset = 0,
    int limit = discoverActivitiesPageSize,
  }) async {
    // PostgREST-Äquivalent: .range(from, to) mit pageSize = limit
    final from = offset;
    final to = offset + limit - 1;
    assert(to >= from);

    final params = <String, dynamic>{
      'p_lat': latitude,
      'p_lng': longitude,
      'p_limit': limit,
      'p_offset': from,
    };

    if (filters.locationType != null) {
      params['p_location_type'] = filters.locationType!.dbValue;
    }
    if (filters.weatherCondition != null) {
      params['p_weather_condition'] = filters.weatherCondition!.dbValue;
    }

    final dateRange = filters.dateRange;
    if (dateRange.start != null) {
      params['p_date_from'] = dateRange.start!.toUtc().toIso8601String();
    }
    if (dateRange.end != null) {
      params['p_date_to'] = dateRange.end!.toUtc().toIso8601String();
    }

    try {
      final response = await _client
          .rpc('discover_activities', params: params)
          .timeout(const Duration(seconds: 20));
      if (response is! List) return const [];

      final activities = <DiscoverableActivity>[];
      for (final row in response) {
        if (row is! Map<String, dynamic>) continue;
        try {
          activities.add(_mapDiscoverableActivity(row));
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'CircleVeya: Aktivität übersprungen (id=${row['id']}): $error\n$stackTrace',
            );
          }
        }
      }
      return activities;
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('CircleVeya: discover_activities Timeout – leere Liste');
      }
      return const [];
    }
  }

  Future<List<DiscoverableActivity>> getSocialFeed({
    required double latitude,
    required double longitude,
    int offset = 0,
    int limit = 50,
  }) async {
    final from = offset < 0 ? 0 : offset;
    final safeLimit = limit < 1 ? 50 : limit;

    try {
      final response = await _client
          .rpc(
            'social_feed_activities',
            params: {
              'p_lat': latitude,
              'p_lng': longitude,
              'p_limit': safeLimit,
              'p_offset': from,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response is! List) return const [];

      final activities = <DiscoverableActivity>[];
      for (final row in response) {
        if (row is! Map<String, dynamic>) continue;
        try {
          activities.add(_mapDiscoverableActivity(row));
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'CircleVeya: Social-Feed-Aktivität übersprungen '
              '(id=${row['id']}): $error\n$stackTrace',
            );
          }
        }
      }
      return activities;
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('CircleVeya: social_feed_activities Timeout – leere Liste');
      }
      return const [];
    }
  }

  Future<List<DiscoverableActivity>> getMyActivities({
    int offset = 0,
    int limit = 100,
  }) async {
    final from = offset < 0 ? 0 : offset;
    final safeLimit = limit < 1 ? 100 : limit;

    try {
      final response = await _client
          .rpc(
            'my_activities',
            params: {
              'p_limit': safeLimit,
              'p_offset': from,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response is! List) return const [];

      final activities = <DiscoverableActivity>[];
      for (final row in response) {
        if (row is! Map<String, dynamic>) continue;
        try {
          activities.add(_mapDiscoverableActivity(row));
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'CircleVeya: Meine-Aktivität übersprungen '
              '(id=${row['id']}): $error\n$stackTrace',
            );
          }
        }
      }
      return activities;
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('CircleVeya: my_activities Timeout – leere Liste');
      }
      return const [];
    }
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
          'is_sponsored, status, source, external_url, source_event_id, '
          'source_event_title, created_at, '
          'profiles!activities_host_id_fkey(username, user_type, avatar_url)',
        )
        .eq('host_id', userId)
        .order('date_time', ascending: true, nullsFirst: false);

    final activities = <DiscoverableActivity>[];
    for (final row in response as List) {
      if (row is! Map<String, dynamic>) continue;
      try {
        final map = row;
        final profile = map['profiles'] as Map<String, dynamic>?;
        activities.add(
          DiscoverableActivity(
            id: _requireString(map['id'], fallback: ''),
            hostId: _requireString(map['host_id'], fallback: userId),
            hostUsername:
                _optionalString(profile?['username']) ?? 'Du',
            hostIsCompany: profile?['user_type'] == 'company',
            hostAvatarUrl: _optionalString(profile?['avatar_url']),
            title: _requireString(map['title'], fallback: 'Aktivität'),
            description: _optionalString(map['description']),
            maxParticipants: _optionalInt(map['max_participants']),
            currentParticipants: _optionalInt(map['current_participants']) ?? 0,
            dateTime: _parseOptionalDateTime(map['date_time']),
            imageUrl: _optionalString(map['image_url']),
            locationType: _parseLocationType(map['location_type']),
            weatherCondition: _parseWeatherCondition(map['weather_condition']),
            locationName: _optionalString(map['location_name']),
            distanceKm: null,
            visibleAs: VisibleAs.friend,
            viewerAction: ViewerAction.host,
            isSponsored: map['is_sponsored'] as bool? ?? false,
            isFeatured: (map['is_sponsored'] as bool? ?? false) &&
                profile?['user_type'] == 'company',
            source: ActivitySource.fromDb(map['source'] as String?),
            externalUrl: _optionalString(map['external_url']),
            sourceEventId: _optionalString(map['source_event_id']),
            sourceEventTitle: _optionalString(map['source_event_title']),
            createdAt: _parseOptionalDateTime(map['created_at']),
          ),
        );
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('CircleVeya: Gehostete Aktivität übersprungen: $error\n$stackTrace');
        }
      }
    }
    return activities;
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

    final eventImageUrl = input.imageUrl?.trim();
    final hasImageUrl = eventImageUrl != null && eventImageUrl.isNotEmpty;
    final hasSourceEvent =
        input.sourceEventId?.trim().isNotEmpty == true;

    // Cover-URL setzen (Eventfrog oder Pexels).
    if (hasImageUrl) {
      payload['image_url'] = eventImageUrl;
      payload['image_source'] = hasSourceEvent ? 'external' : 'pexels';
    }

    final sourceEventId = input.sourceEventId?.trim();
    if (sourceEventId != null && sourceEventId.isNotEmpty) {
      payload['source_event_id'] = sourceEventId;
      payload['source_event_title'] = input.sourceEventTitle?.trim();
    }

    final response = await _client
        .from('activities')
        .insert(payload)
        .select('id')
        .single();

    final activityId = response['id'] as String;

    if (!hasImageUrl &&
        coverImageBytes != null &&
        coverImageBytes.isNotEmpty) {
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

      await _client.from('activities').update({
        'image_url': publicUrl,
        'image_source': 'user',
      }).eq('id', activityId);
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
    final id = _requireString(map['id']);
    if (id.isEmpty) {
      throw const FormatException('Aktivität ohne id');
    }

    return DiscoverableActivity(
      id: id,
      hostId: _requireString(map['host_id'], fallback: id),
      hostUsername:
          _optionalString(map['host_username']) ?? 'CircleVeya',
      hostIsCompany: map['host_is_company'] as bool? ?? false,
      hostAvatarUrl: _optionalString(map['host_avatar_url']),
      title: _requireString(map['title'], fallback: 'Event'),
      description: _optionalString(map['description']),
      maxParticipants: _optionalInt(map['max_participants']),
      currentParticipants: _optionalInt(map['current_participants']) ?? 0,
      dateTime: _parseOptionalDateTime(map['date_time']),
      imageUrl: _optionalString(map['image_url']),
      locationType: _parseLocationType(map['location_type']),
      weatherCondition: _parseWeatherCondition(map['weather_condition']),
      locationName: _optionalString(map['location_name']),
      distanceKm: _optionalDouble(map['distance_km']),
      visibleAs: VisibleAs.fromDb(
        _optionalString(map['visible_as']) ?? 'stranger',
      ),
      viewerAction: ViewerAction.fromDb(
        _optionalString(map['viewer_action']) ?? 'none',
      ),
      isSponsored: map['is_sponsored'] as bool? ?? false,
      isFeatured: map['is_featured'] as bool? ?? false,
      source: ActivitySource.fromDb(map['source'] as String?),
      externalUrl: _optionalString(map['external_url']),
      sourceEventId: _optionalString(map['source_event_id']),
      sourceEventTitle: _optionalString(map['source_event_title']),
      createdAt: _parseOptionalDateTime(map['created_at']),
      participantAvatarUrls: _parseAvatarUrls(map['participant_avatar_urls']),
    );
  }

  String _requireString(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _optionalInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  double? _optionalDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }

  LocationType _parseLocationType(dynamic value) {
    final raw = _optionalString(value);
    if (raw == null) return LocationType.indoor;
    for (final type in LocationType.values) {
      if (type.name == raw) return type;
    }
    return LocationType.indoor;
  }

  WeatherCondition _parseWeatherCondition(dynamic value) {
    final raw = _optionalString(value);
    if (raw == null) return WeatherCondition.sun;
    for (final condition in WeatherCondition.values) {
      if (condition.name == raw) return condition;
    }
    return WeatherCondition.sun;
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
    if (value is DateTime) return value;
    if (value is! String || value.trim().isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
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
