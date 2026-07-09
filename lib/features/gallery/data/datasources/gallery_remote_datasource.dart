import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

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
        isHost: map['is_host'] as bool,
        photoCount: (map['photo_count'] as num).toInt(),
        canUpload: map['can_upload'] as bool,
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
        uploaderUsername: map['uploader_username'] as String,
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
    return response as bool;
  }

  Future<void> uploadActivityPhoto({
    required String activityId,
    required String filePath,
    String? caption,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw const AuthException('Nicht angemeldet');
    }

    final file = File(filePath);
    final extension = filePath.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$activityId/$userId/$timestamp.$extension';

    await _client.storage.from('activity-photos').upload(
          storagePath,
          file,
        );

    final publicUrl =
        _client.storage.from('activity-photos').getPublicUrl(storagePath);

    await _client.rpc('register_activity_photo', params: {
      'p_activity_id': activityId,
      'p_storage_path': storagePath,
      'p_public_url': publicUrl,
      'p_caption': caption,
    });
  }
}
