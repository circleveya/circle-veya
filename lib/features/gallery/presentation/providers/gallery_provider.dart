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

final activityPhotosProvider = FutureProvider.autoDispose
    .family<List<ActivityPhoto>, String>((ref, activityId) {
  return ref.watch(galleryRepositoryProvider).getActivityPhotos(activityId);
});

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
      ref.invalidate(activityPhotosProvider(activityId));
      ref.invalidate(pastActivitiesGalleryProvider);
      ref.invalidate(canUploadPhotoProvider(activityId));
    }
  }
}

final galleryUploadControllerProvider = AutoDisposeAsyncNotifierProvider<
    GalleryUploadController, void>(GalleryUploadController.new);
