import 'dart:async';
import 'dart:math';
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
    return getActivitiesByHost(userId);
  }

  /// Gehostete Aktivitäten eines Users (respektiert privates Profil).
  Future<List<DiscoverableActivity>> getActivitiesByHost(String hostId) async {
    final viewerId = _client.auth.currentUser?.id;
    if (viewerId == null) {
      throw const AppAuthException('Nicht angemeldet');
    }

    final response = await _client.rpc(
      'get_profile_host_activities',
      params: {'p_host_id': hostId},
    );
    if (response is! List) return const [];

    final activities = <DiscoverableActivity>[];
    for (final row in response) {
      if (row is! Map<String, dynamic>) continue;
      try {
        final map = row;
        final isOwnHost = hostId == viewerId;
        activities.add(
          DiscoverableActivity(
            id: _requireString(map['id'], fallback: ''),
            hostId: _requireString(map['host_id'], fallback: hostId),
            hostUsername: _optionalString(map['host_username']) ??
                (isOwnHost ? 'Du' : 'User'),
            hostIsCompany: map['host_user_type'] == 'company' ||
                map['host_user_type'] == 'event' ||
                map['host_user_type'] == 'dev',
            hostAvatarUrl: _optionalString(map['host_avatar_url']),
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
            viewerAction:
                isOwnHost ? ViewerAction.host : ViewerAction.none,
            isSponsored: map['is_sponsored'] as bool? ?? false,
            isFeatured: (map['is_sponsored'] as bool? ?? false) &&
                (map['host_user_type'] == 'company' ||
                    map['host_user_type'] == 'event' ||
                    map['host_user_type'] == 'dev'),
            source: ActivitySource.fromDb(map['source'] as String?),
            externalUrl: _optionalString(map['external_url']),
            sourceEventId: _optionalString(map['source_event_id']),
            sourceEventTitle: _optionalString(map['source_event_title']),
            createdAt: _parseOptionalDateTime(map['created_at']),
          ),
        );
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            'CircleVeya: Profil-Aktivität übersprungen: $error\n$stackTrace',
          );
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

    final occurrences = input.resolvedDateTimes;
    final seriesId =
        occurrences.length > 1 ? _generateUuidV4() : null;

    final eventImageUrl = input.imageUrl?.trim();
    final hasImageUrl = eventImageUrl != null && eventImageUrl.isNotEmpty;
    final hasSourceEvent =
        input.sourceEventId?.trim().isNotEmpty == true;
    final sourceEventId = input.sourceEventId?.trim();

    final payloads = <Map<String, dynamic>>[];
    for (final occurrence in occurrences) {
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

      if (seriesId != null) {
        payload['series_id'] = seriesId;
      }

      if (occurrence != null) {
        payload['date_time'] = occurrence.toUtc().toIso8601String();
      }

      if (hasImageUrl) {
        payload['image_url'] = eventImageUrl;
        payload['image_source'] = hasSourceEvent ? 'external' : 'pexels';
      }

      if (sourceEventId != null && sourceEventId.isNotEmpty) {
        payload['source_event_id'] = sourceEventId;
        payload['source_event_title'] = input.sourceEventTitle?.trim();
      }

      payloads.add(payload);
    }

    final response = await _client
        .from('activities')
        .insert(payloads)
        .select('id');

    final rows = response as List;
    final activityIds = rows
        .map((row) => (row as Map<String, dynamic>)['id'] as String)
        .toList();

    if (!hasImageUrl &&
        coverImageBytes != null &&
        coverImageBytes.isNotEmpty &&
        activityIds.isNotEmpty) {
      final extension = _extensionFromFileName(coverImageFileName);
      final firstId = activityIds.first;
      final path = '$userId/$firstId.$extension';

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
      }).inFilter('id', activityIds);
    }
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> updateActivity(UpdateActivityInput input) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Nicht angemeldet');
    }

    final payload = <String, dynamic>{
      'title': input.title,
      'description': input.description,
      'location_name': input.locationName,
    };

    if (input.clearDateTime) {
      payload['date_time'] = null;
    } else if (input.dateTime != null) {
      payload['date_time'] = input.dateTime!.toUtc().toIso8601String();
    }

    await _client
        .from('activities')
        .update(payload)
        .eq('id', input.activityId)
        .eq('host_id', userId);
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

  Future<DiscoverableActivity?> getActivityDetail(String activityId) async {
    final response = await _client.rpc(
      'get_activity_detail',
      params: {'p_activity_id': activityId},
    );
    if (response is! List || response.isEmpty) return null;
    final map = Map<String, dynamic>.from(response.first as Map);
    return _mapDiscoverableActivity(map);
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
