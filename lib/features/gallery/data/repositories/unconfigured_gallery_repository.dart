import 'package:image_picker/image_picker.dart';

import '../../domain/entities/gallery.dart';
import '../../domain/repositories/gallery_repository.dart';

class UnconfiguredGalleryRepository implements GalleryRepository {
  const UnconfiguredGalleryRepository();

  @override
  Future<bool> canUploadPhoto(String activityId) async => false;

  @override
  Future<List<ActivityPhoto>> getActivityPhotos(String activityId) async => [];

  @override
  Future<List<PastActivityGallery>> getPastActivities() async => [];

  @override
  Future<List<PastActivityGallery>> getPublicGalleryForProfile(
    String profileId,
  ) async =>
      [];

  @override
  Future<void> uploadActivityPhoto({
    required String activityId,
    required XFile file,
    String? caption,
  }) async {
    throw UnsupportedError('Supabase ist nicht konfiguriert.');
  }
}
