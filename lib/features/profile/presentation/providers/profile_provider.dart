import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../gallery/presentation/providers/gallery_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/unconfigured_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_review.dart';
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

final profileReviewsProvider = FutureProvider.autoDispose
    .family<List<UserReview>, String>((ref, profileId) {
  return ref.watch(profileRemoteDatasourceProvider).getReviewsForProfile(
        profileId,
      );
});

final myReviewForProfileProvider = FutureProvider.autoDispose
    .family<UserReview?, String>((ref, targetUserId) {
  return ref
      .watch(profileRemoteDatasourceProvider)
      .getMyReviewForProfile(targetUserId);
});

class ReviewController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String targetUserId,
    required int rating,
    String? comment,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRemoteDatasourceProvider).upsertReview(
            targetUserId: targetUserId,
            rating: rating,
            comment: comment,
          );
    });
    if (!state.hasError) {
      ref.invalidate(profileRatingProvider(targetUserId));
      ref.invalidate(profileReviewsProvider(targetUserId));
      ref.invalidate(myReviewForProfileProvider(targetUserId));
    }
  }
}

final reviewControllerProvider =
    AutoDisposeAsyncNotifierProvider<ReviewController, void>(
  ReviewController.new,
);

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

class GalleryPrivacyController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setGalleryPublic(bool isPublic) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRemoteDatasourceProvider).updateGalleryPublic(
            isPublic: isPublic,
          );
    });
    if (!state.hasError) {
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      ref.invalidate(myProfileProvider);
      ref.invalidate(pastActivitiesGalleryProvider);
      if (userId != null) {
        ref.invalidate(profileProvider(userId));
        ref.invalidate(publicGalleryForProfileProvider(userId));
      }
    }
  }
}

final galleryPrivacyControllerProvider = AutoDisposeAsyncNotifierProvider<
    GalleryPrivacyController, void>(GalleryPrivacyController.new);

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
      _invalidateProfiles();
    }
    return url;
  }

  Future<String?> uploadCover(XFile image) async {
    state = const AsyncLoading();
    String? url;
    state = await AsyncValue.guard(() async {
      final bytes = await image.readAsBytes();
      url = await ref.read(profileRepositoryProvider).uploadCover(
            bytes: bytes,
            fileName: image.name,
          );
    });
    if (!state.hasError) {
      _invalidateProfiles();
    }
    return url;
  }

  void _invalidateProfiles() {
    ref.invalidate(myProfileProvider);
    final userId =
        ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId != null) {
      ref.invalidate(profileProvider(userId));
    }
  }
}

final profileEditControllerProvider = AutoDisposeAsyncNotifierProvider<
    ProfileEditController, void>(ProfileEditController.new);
