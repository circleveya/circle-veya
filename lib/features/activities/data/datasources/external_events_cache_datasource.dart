import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';
import '../../domain/entities/activity_filters.dart';
import '../../domain/entities/discover_activities_state.dart';
import '../../domain/entities/discover_filters.dart';

class ExternalEventsPageResult {
  const ExternalEventsPageResult({
    required this.events,
    required this.totalCount,
  });

  final List<DiscoverableActivity> events;
  final int totalCount;
}

/// Entdecken: Eventfrog-Cache via PostGIS-RPC `get_activities_by_distance`.
class ExternalEventsCacheDatasource {
  ExternalEventsCacheDatasource(this._client);

  final SupabaseClient _client;

  Future<ExternalEventsPageResult> fetchPage({
    /// 0-basierter Seitenindex (`currentPage`).
    required int currentPage,
    required double userLat,
    required double userLong,
    int itemsPerPage = discoverActivitiesPageSize,
    double? maxDistanceKm,
    ActivityDiscoverFilters filters = const ActivityDiscoverFilters.empty(),
    String? cityHint,
  }) async {
    final safePage = currentPage < 0 ? 0 : currentPage;
    final offset = safePage * itemsPerPage;
    final dateRange = filters.dateRange;
    final city = cityHint?.trim();
    final maxDistMeters =
        maxDistanceKm == null ? null : maxDistanceKm * 1000.0;

    try {
      final rows = await _client
          .rpc(
            'get_activities_by_distance',
            params: {
              'user_lat': userLat,
              'user_long': userLong,
              'max_dist_meters': maxDistMeters,
              'p_limit': itemsPerPage,
              'p_offset': offset,
              'p_date_from': dateRange.start?.toUtc().toIso8601String(),
              'p_date_to': dateRange.end?.toUtc().toIso8601String(),
              'p_city': (city != null &&
                      city.isNotEmpty &&
                      city.toLowerCase() != 'gps')
                  ? city
                  : null,
            },
          )
          .timeout(const Duration(seconds: 15));

      final events = <DiscoverableActivity>[];
      var totalCount = 0;

      for (final row in rows as List) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        try {
          final activity = _mapRow(map);
          events.add(activity);

          // Debug: Distanzberechnung sichtbar machen.
          // ignore: avoid_print
          print(
            'CircleVeya distance: "${activity.title}" → '
            '${activity.distanceKm?.toStringAsFixed(2) ?? "null"} km '
            '(${_asDouble(map['distance_meters'])?.toStringAsFixed(0) ?? "null"} m)',
          );

          final count = map['total_count'];
          if (count is int) {
            totalCount = count;
          } else if (count is num) {
            totalCount = count.toInt();
          }
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'CircleVeya: external_event übersprungen (${map['id']}): $error\n$stackTrace',
            );
          }
        }
      }

      if (kDebugMode) {
        debugPrint(
          'CircleVeya: get_activities_by_distance '
          'page=$safePage limit=$itemsPerPage '
          'maxDistKm=$maxDistanceKm → ${events.length} rows '
          '(total=$totalCount)',
        );
      }

      return ExternalEventsPageResult(
        events: events,
        totalCount: totalCount,
      );
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'CircleVeya: get_activities_by_distance Fehler: ${error.message}',
        );
      }
      rethrow;
    }
  }

  DiscoverableActivity _mapRow(Map<String, dynamic> map) {
    final id = (map['id'] as String?) ?? '';
    final title = (map['title'] as String?)?.trim();
    final distanceKm = _asDouble(map['distance_km']);

    return DiscoverableActivity(
      id: id,
      hostId: id,
      hostUsername: 'CircleVeya',
      hostIsCompany: false,
      title: (title != null && title.isNotEmpty) ? title : 'Event',
      description: null,
      maxParticipants: null,
      currentParticipants: 0,
      dateTime: _parseDate(map['start_date']),
      imageUrl: _optionalString(map['image_url']),
      locationType: LocationType.indoor,
      weatherCondition: WeatherCondition.sun,
      locationName: _optionalString(map['location_name']) ??
          _optionalString(map['city']),
      distanceKm: distanceKm,
      visibleAs: VisibleAs.stranger,
      viewerAction: ViewerAction.externalLink,
      isSponsored: false,
      isFeatured: false,
      source: ActivitySource.external,
      externalUrl: _optionalString(map['external_url']),
      createdAt: null,
      participantAvatarUrls: const [],
    );
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is! String || value.trim().isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}
