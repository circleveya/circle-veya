import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../config/env.dart';
import 'geolocation_platform.dart';
import 'user_location.dart';

class LocationService {
  Future<UserLocation> resolveInitialLocation() async {
    if (Env.useMockLocation) {
      return UserLocation.mockFrauenfeld;
    }
    return requestGps(forceRealGps: true);
  }

  /// [forceRealGps]: USE_MOCK_LOCATION ignorieren (Nutzer tippt „GPS“).
  Future<UserLocation> requestGps({bool forceRealGps = false}) async {
    if (!forceRealGps && Env.useMockLocation) {
      return UserLocation.mockFrauenfeld;
    }

    if (kIsWeb) {
      final browserResult = await _tryNativeBrowserGeolocation();
      if (browserResult != null) return browserResult;
    }

    final geolocatorResult = await _tryGeolocator();
    if (geolocatorResult != null) return geolocatorResult;

    if (!kIsWeb) {
      final browserResult = await _tryNativeBrowserGeolocation();
      if (browserResult != null) return browserResult;
    }

    if (forceRealGps) {
      throw LocationPermissionException(
        'Standort konnte nicht ermittelt werden. '
        'Bitte im Browser „Standort erlauben“ wählen.',
      );
    }

    return _fallback('GPS-Abruf fehlgeschlagen oder abgelehnt');
  }

  Future<UserLocation?> _tryGeolocator() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !kIsWeb) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        source: LocationSource.gps,
        isMock: false,
        label: 'Aktueller Standort',
      );
    } catch (error) {
      if (kDebugMode) debugPrint('CircleVeya: Geolocator-Fehler: $error');
      return null;
    }
  }

  Future<UserLocation?> _tryNativeBrowserGeolocation() async {
    if (!kIsWeb) return null;

    try {
      final coords = await getNativeBrowserPosition();
      if (coords == null) return null;

      return UserLocation(
        latitude: coords.lat,
        longitude: coords.lng,
        source: LocationSource.gps,
        isMock: false,
        label: 'Aktueller Standort',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CircleVeya: HTML5-Geolocation-Fehler: $error');
      }
      return null;
    }
  }

  UserLocation _fallback(String reason) {
    if (kDebugMode) {
      debugPrint('CircleVeya: $reason – Fallback Frauenfeld.');
    }
    return UserLocation.mockFrauenfeld;
  }
}

class LocationPermissionException implements Exception {
  LocationPermissionException(this.message);
  final String message;

  @override
  String toString() => message;
}
