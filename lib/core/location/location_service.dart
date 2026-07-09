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
    return requestGps();
  }

  Future<UserLocation> requestGps() async {
    if (Env.useMockLocation) {
      return UserLocation.mockFrauenfeld;
    }

    final geolocatorResult = await _tryGeolocator();
    if (geolocatorResult != null) return geolocatorResult;

    final browserResult = await _tryNativeBrowserGeolocation();
    if (browserResult != null) return browserResult;

    return _fallback('GPS-Abruf fehlgeschlagen oder abgelehnt');
  }

  Future<UserLocation?> _tryGeolocator() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !kIsWeb) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          debugPrint('CircleVeya: Geolocator-Berechtigung verweigert.');
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        source: LocationSource.gps,
        isMock: false,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CircleVeya: Geolocator-Fehler: $error');
      }
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
      debugPrint(
        'CircleVeya: $reason – nutze Fallback Frauenfeld '
        '(${UserLocation.mockFrauenfeld.latitude}, '
        '${UserLocation.mockFrauenfeld.longitude}).',
      );
    }
    return UserLocation.mockFrauenfeld;
  }
}
