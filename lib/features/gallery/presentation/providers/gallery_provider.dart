import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../data/datasources/gallery_remote_datasource.dart';
import '../../data/repositories/gallery_repository_impl.dart';
import '../../data/repositories/unconfigured_gallery_repository.dart';
import '../../domain/entities/gallery.dart';
import '../../domain/repositories/gallery_repository.dart';

final galleryRemoteDatasourceProvider = Provider<GalleryRemoteDatasource>((ref) {
  return GalleryRemoteDatasource(ref.watch(supabaseClientProvider));
});

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  if (!Env.isConfigured) {
    return const UnconfiguredGalleryRepository();
  }
  return GalleryRepositoryImpl(ref.watch(galleryRemoteDatasourceProvider));
});

final pastActivitiesGalleryProvider =
    FutureProvider.autoDispose<List<PastActivityGallery>>((ref) {
  return ref.watch(galleryRepositoryProvider).getPastActivities();
});

final publicGalleryForProfileProvider = FutureProvider.autoDispose
    .family<List<PastActivityGallery>, String>((ref, profileId) {
  return ref.watch(galleryRepositoryProvider).getPublicGalleryForProfile(profileId);
});

/// activityId|ownerId – ownerId leer = aktuelle Session
final activityPhotosProvider = FutureProvider.autoDispose
    .family<List<ActivityPhoto>, String>((ref, key) {
  final parts = key.split('|');
  final activityId = parts.first;
  final ownerId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
  return ref.watch(galleryRepositoryProvider).getActivityPhotos(
        activityId,
        ownerId: ownerId,
      );
});

String activityPhotosKey(String activityId, {String? ownerId}) =>
    '$activityId|${ownerId ?? ''}';

final canUploadPhotoProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, activityId) {
  return ref.watch(galleryRepositoryProvider).canUploadPhoto(activityId);
});

class GalleryUploadController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> upload({
    required String activityId,
    required XFile file,
    String? caption,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(galleryRepositoryProvider).uploadActivityPhoto(
            activityId: activityId,
            file: file,
            caption: caption,
          ),
    );
    if (!state.hasError) {
      ref.invalidate(activityPhotosProvider(activityPhotosKey(activityId)));
      ref.invalidate(pastActivitiesGalleryProvider);
      ref.invalidate(canUploadPhotoProvider(activityId));
    }
  }
}

final galleryUploadControllerProvider = AutoDisposeAsyncNotifierProvider<
    GalleryUploadController, void>(GalleryUploadController.new);

class MemoryPrivacyController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setMemoryPublic({
    required String activityId,
    required bool isPublic,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(galleryRepositoryProvider).setMemoryPublic(
            activityId: activityId,
            isPublic: isPublic,
          ),
    );
    if (!state.hasError) {
      ref.invalidate(pastActivitiesGalleryProvider);
    }
  }
}

final memoryPrivacyControllerProvider = AutoDisposeAsyncNotifierProvider<
    MemoryPrivacyController, void>(MemoryPrivacyController.new);
