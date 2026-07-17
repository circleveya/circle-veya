import 'package:image_picker/image_picker.dart';

import '../entities/gallery.dart';

abstract class GalleryRepository {
  Future<List<PastActivityGallery>> getPastActivities();

  Future<List<PastActivityGallery>> getPublicGalleryForProfile(String profileId);

  Future<List<ActivityPhoto>> getActivityPhotos(
    String activityId, {
    String? ownerId,
  });

  Future<bool> canUploadPhoto(String activityId);

  Future<void> setMemoryPublic({
    required String activityId,
    required bool isPublic,
  });

  Future<void> uploadActivityPhoto({
    required String activityId,
    required XFile file,
    String? caption,
  });
}
