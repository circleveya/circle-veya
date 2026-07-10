import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/storage/supabase_storage_helper.dart';
import '../../domain/entities/gallery.dart';

class GalleryRemoteDatasource {
  GalleryRemoteDatasource(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<PastActivityGallery>> getPastActivities() async {
    final response = await _client.rpc('get_past_activities_for_gallery');

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return PastActivityGallery(
        id: map['id'] as String,
        title: map['title'] as String,
        dateTime: DateTime.parse(map['date_time'] as String),
        locationName: map['location_name'] as String?,
        isHost: map['is_host'] as bool? ?? false,
        photoCount: (map['photo_count'] as num?)?.toInt() ?? 0,
        canUpload: map['can_upload'] as bool? ?? false,
      );
    }).toList();
  }

  Future<List<ActivityPhoto>> getActivityPhotos(String activityId) async {
    final response = await _client.rpc(
      'get_activity_photos',
      params: {'p_activity_id': activityId},
    );

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return ActivityPhoto(
        id: map['id'] as String,
        uploaderId: map['uploader_id'] as String,
        uploaderUsername: map['uploader_username'] as String? ?? 'Du',
        publicUrl: map['public_url'] as String,
        caption: map['caption'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }

  Future<bool> canUploadPhoto(String activityId) async {
    final response = await _client.rpc(
      'can_upload_activity_photo',
      params: {'p_activity_id': activityId},
    );
    return response as bool? ?? false;
  }

  Future<void> uploadActivityPhoto({
    required String activityId,
    required XFile file,
    String? caption,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw const AuthException('Nicht angemeldet');
    }

    final extension = SupabaseStorageHelper.extensionFrom(file);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$activityId/$userId/$timestamp.$extension';

    final helper = SupabaseStorageHelper(_client);
    final publicUrl = await helper.uploadImage(
      bucket: 'activity-photos',
      path: storagePath,
      file: file,
    );

    await _client.rpc('register_activity_photo', params: {
      'p_activity_id': activityId,
      'p_storage_path': storagePath,
      'p_public_url': publicUrl,
      'p_caption': caption,
    });

    if (kDebugMode) {
      debugPrint('CircleVeya: Erinnerungsfoto hochgeladen ($storagePath)');
    }
  }
}
