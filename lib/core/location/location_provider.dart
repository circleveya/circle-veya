import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_service.dart';
import 'user_location.dart';

export 'user_location.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Aktiver Standort für Feed, Filter und Supabase-RPCs.
final userLocationProvider =
    AsyncNotifierProvider<UserLocationController, UserLocation>(
  UserLocationController.new,
);

class UserLocationController extends AsyncNotifier<UserLocation> {
  @override
  Future<UserLocation> build() async {
    return ref.read(locationServiceProvider).resolveInitialLocation();
  }

  Future<void> selectPreset(LocationPreset preset, {bool asMock = false}) async {
    state = AsyncData(preset.toLocation(isMock: asMock));
  }

  Future<void> requestGps() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(locationServiceProvider).requestGps();
    });
  }
}
