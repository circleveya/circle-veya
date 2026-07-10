import 'package:image_picker/image_picker.dart';

import '../entities/gallery.dart';

abstract class GalleryRepository {
  Future<List<PastActivityGallery>> getPastActivities();

  Future<List<ActivityPhoto>> getActivityPhotos(String activityId);

  Future<bool> canUploadPhoto(String activityId);

  Future<void> uploadActivityPhoto({
    required String activityId,
    required XFile file,
    String? caption,
  });
}
