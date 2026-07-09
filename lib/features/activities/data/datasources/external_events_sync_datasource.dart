import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Triggert die Edge Function sync-external-events mit User-Standort + Radius.
class ExternalEventsSyncDatasource {
  ExternalEventsSyncDatasource(this._client);

  final SupabaseClient _client;

  static String? _lastSyncKey;
  static DateTime? _lastSyncAt;
  static const _minInterval = Duration(minutes: 5);

  Future<void> syncForUserLocation({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String countryCode = 'CH',
  }) async {
    final radius = radiusKm ?? 25;
    final syncKey =
        '${latitude.toStringAsFixed(4)}|${longitude.toStringAsFixed(4)}|$radius';

    final now = DateTime.now();
    if (_lastSyncKey == syncKey &&
        _lastSyncAt != null &&
        now.difference(_lastSyncAt!) < _minInterval) {
      return;
    }

    try {
      await _client.functions.invoke(
        'sync-external-events',
        body: {
          'lat': double.parse(latitude.toStringAsFixed(4)),
          'lng': double.parse(longitude.toStringAsFixed(4)),
          'radius_km': radius.round(),
          'country_code': countryCode,
        },
      );

      _lastSyncKey = syncKey;
      _lastSyncAt = now;

      if (kDebugMode) {
        debugPrint(
          'CircleVeya: Externe Events synchronisiert '
          '(latlong=${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}, '
          'radius=${radius.round()}km, country=$countryCode)',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CircleVeya: Externe Event-Sync übersprungen: $error');
      }
    }
  }
}
