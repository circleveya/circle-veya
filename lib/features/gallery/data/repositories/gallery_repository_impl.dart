import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/gallery.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../datasources/gallery_remote_datasource.dart';

class GalleryFailure extends Failure {
  const GalleryFailure(super.message);
}

class GalleryRepositoryImpl implements GalleryRepository {
  GalleryRepositoryImpl(this._datasource);

  final GalleryRemoteDatasource _datasource;

  @override
  Future<bool> canUploadPhoto(String activityId) async {
    try {
      return await _datasource.canUploadPhoto(activityId);
    } on PostgrestException catch (error) {
      throw GalleryFailure(error.message);
    }
  }

  @override
  Future<List<ActivityPhoto>> getActivityPhotos(
    String activityId, {
    String? ownerId,
  }) async {
    try {
      return await _datasource.getActivityPhotos(
        activityId,
        ownerId: ownerId,
      );
    } on PostgrestException catch (error) {
      throw GalleryFailure(error.message);
    }
  }

  @override
  Future<List<PastActivityGallery>> getPastActivities() async {
    try {
      return await _datasource.getPastActivities();
    } on PostgrestException catch (error) {
      throw GalleryFailure(error.message);
    }
  }

  @override
  Future<List<PastActivityGallery>> getPublicGalleryForProfile(
    String profileId,
  ) async {
    try {
      return await _datasource.getPublicGalleryForProfile(profileId);
    } on PostgrestException catch (error) {
      throw GalleryFailure(error.message);
    }
  }

  @override
  Future<void> setMemoryPublic({
    required String activityId,
    required bool isPublic,
  }) async {
    try {
      await _datasource.setMemoryPublic(
        activityId: activityId,
        isPublic: isPublic,
      );
    } on PostgrestException catch (error) {
      throw GalleryFailure(error.message);
    }
  }

  @override
  Future<void> uploadActivityPhoto({
    required String activityId,
    required XFile file,
    String? caption,
  }) async {
    try {
      await _datasource.uploadActivityPhoto(
        activityId: activityId,
        file: file,
        caption: caption,
      );
    } on StorageException catch (error) {
      throw GalleryFailure(error.message);
    } on PostgrestException catch (error) {
      throw GalleryFailure(error.message);
    } on AuthException catch (error) {
      throw GalleryFailure(error.message);
    }
  }
}
