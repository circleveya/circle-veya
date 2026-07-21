import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_service.dart';
import 'user_location.dart';

export 'user_location.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationCoordsKeyProvider = Provider<String>((ref) {
  final location = ref.watch(userLocationProvider).valueOrNull;
  if (location == null) return 'pending';
  return '${location.latitude}|${location.longitude}|${location.source.name}';
});

final userLocationProvider =
    AsyncNotifierProvider<UserLocationController, UserLocation>(
  UserLocationController.new,
);

class UserLocationController extends AsyncNotifier<UserLocation> {
  @override
  Future<UserLocation> build() async {
    return ref.read(locationServiceProvider).resolveInitialLocation();
  }

  void selectPreset(LocationPreset preset) {
    state = AsyncData(preset.toLocation());
  }

  void selectPlace({
    required String label,
    required double latitude,
    required double longitude,
  }) {
    state = AsyncData(
      UserLocation(
        latitude: latitude,
        longitude: longitude,
        source: LocationSource.manual,
        label: label,
      ),
    );
  }

  Future<void> requestGps() async {
    final previous = state.valueOrNull;
    try {
      final location = await ref
          .read(locationServiceProvider)
          .requestGps(forceRealGps: true);
      state = AsyncData(location);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }
}
