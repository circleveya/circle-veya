import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../config/env.dart';

class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.isMock = false,
  });

  final double latitude;
  final double longitude;
  final bool isMock;

  /// Fallback für Tests ohne GPS (Frauenfeld, CH).
  static const mock = UserLocation(
    latitude: 47.5569,
    longitude: 8.8982,
    isMock: true,
  );
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final userLocationProvider = FutureProvider<UserLocation>((ref) async {
  return ref.watch(locationServiceProvider).getCurrentLocation();
});

class LocationService {
  Future<UserLocation> getCurrentLocation() async {
    if (Env.useMockLocation) {
      return UserLocation.mock;
    }

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return _fallback('Standortdienste deaktiviert');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback('Standortberechtigung verweigert');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (error) {
      return _fallback(error.toString());
    }
  }

  UserLocation _fallback(String reason) {
    if (kDebugMode) {
      debugPrint(
        'Circle: GPS nicht verfügbar ($reason) – nutze Fallback Frauenfeld, CH '
        '(${UserLocation.mock.latitude}, ${UserLocation.mock.longitude}). '
        'Optional: --dart-define=USE_MOCK_LOCATION=true',
      );
    }
    return UserLocation.mock;
  }
}
