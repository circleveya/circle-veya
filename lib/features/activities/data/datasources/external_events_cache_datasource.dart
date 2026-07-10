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

/// Liest den Eventfrog-Cache (`public.external_events`) – schnell, paginiert.
class ExternalEventsCacheDatasource {
  ExternalEventsCacheDatasource(this._client);

  final SupabaseClient _client;

  static const _selectColumns =
      'id, title, start_date, end_date, city, location_name, '
      'image_url, external_url, latitude, longitude, provider, external_id';

  Future<ExternalEventsPageResult> fetchPage({
    required int page,
    int pageSize = discoverActivitiesPageSize,
    ActivityDiscoverFilters filters = const ActivityDiscoverFilters.empty(),
    String? cityHint,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final from = (safePage - 1) * pageSize;
    final to = from + pageSize - 1;
    final dateRange = filters.dateRange;
    final city = cityHint?.trim();

    try {
      final countBuilder = _applyFilters(
        _client.from('external_events').select('id'),
        dateRange: dateRange,
        city: city,
      );
      final countResponse = await countBuilder.count(CountOption.exact);

      final dataBuilder = _applyFilters(
        _client.from('external_events').select(_selectColumns),
        dateRange: dateRange,
        city: city,
      );
      final rows = await dataBuilder
          .order('start_date', ascending: true, nullsFirst: false)
          .range(from, to)
          .timeout(const Duration(seconds: 15));

      final events = <DiscoverableActivity>[];
      for (final row in rows as List) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        try {
          events.add(_mapRow(map));
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'CircleVeya: external_event übersprungen (${map['id']}): $error\n$stackTrace',
            );
          }
        }
      }

      return ExternalEventsPageResult(
        events: events,
        totalCount: countResponse.count,
      );
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint('CircleVeya: external_events Query-Fehler: ${error.message}');
      }
      rethrow;
    }
  }

  PostgrestFilterBuilder _applyFilters(
    PostgrestFilterBuilder query, {
    required ({DateTime? start, DateTime? end}) dateRange,
    required String? city,
  }) {
    var q = query.eq('is_cancelled', false);

    if (dateRange.start != null) {
      q = q.gte('start_date', dateRange.start!.toUtc().toIso8601String());
    }
    if (dateRange.end != null) {
      q = q.lte('start_date', dateRange.end!.toUtc().toIso8601String());
    }
    if (city != null && city.isNotEmpty && city.toLowerCase() != 'gps') {
      q = q.ilike('city', '%$city%');
    }
    if (dateRange.start == null && dateRange.end == null) {
      q = q.or(
        'start_date.is.null,start_date.gte.${DateTime.now().toUtc().toIso8601String()}',
      );
    }
    return q;
  }

  DiscoverableActivity _mapRow(Map<String, dynamic> map) {
    final id = (map['id'] as String?) ?? '';
    final title = (map['title'] as String?)?.trim();

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
      distanceKm: null,
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
