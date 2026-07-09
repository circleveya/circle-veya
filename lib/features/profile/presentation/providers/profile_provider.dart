import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/unconfigured_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRemoteDatasourceProvider = Provider<ProfileRemoteDatasource>((ref) {
  return ProfileRemoteDatasource(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (!Env.isConfigured) {
    return const UnconfiguredProfileRepository();
  }
  return ProfileRepositoryImpl(ref.watch(profileRemoteDatasourceProvider));
});

final myProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).getMyProfile();
});

final profileProvider = FutureProvider.autoDispose
    .family<UserProfile, String>((ref, profileId) {
  return ref.watch(profileRepositoryProvider).getProfile(profileId);
});

final profileRatingProvider = FutureProvider.autoDispose
    .family<({double avgRating, int reviewCount}), String>((ref, profileId) {
  return ref.watch(profileRemoteDatasourceProvider).getUserRating(profileId);
});

class PremiumSimulationController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setPremium(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRemoteDatasourceProvider).simulatePremium(
            enabled: enabled,
          );
    });
    if (!state.hasError) {
      ref.invalidate(myProfileProvider);
    }
  }
}

final premiumSimulationControllerProvider = AutoDisposeAsyncNotifierProvider<
    PremiumSimulationController, void>(PremiumSimulationController.new);

class ProfileEditController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(UpdateProfileInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateProfile(input),
    );
    if (!state.hasError) {
      ref.invalidate(myProfileProvider);
    }
  }

  Future<String?> uploadAvatar(XFile image) async {
    state = const AsyncLoading();
    String? url;
    state = await AsyncValue.guard(() async {
      final bytes = await image.readAsBytes();
      url = await ref.read(profileRepositoryProvider).uploadAvatar(
            bytes: bytes,
            fileName: image.name,
          );
    });
    if (!state.hasError) {
      ref.invalidate(myProfileProvider);
    }
    return url;
  }
}

final profileEditControllerProvider = AutoDisposeAsyncNotifierProvider<
    ProfileEditController, void>(ProfileEditController.new);
