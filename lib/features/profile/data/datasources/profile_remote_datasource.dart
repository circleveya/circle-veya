import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_profile.dart';

class ProfileRemoteDatasource {
  ProfileRemoteDatasource(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<UserProfile> getProfile(String profileId) async {
    final response = await _client.rpc(
      'get_profile',
      params: {'p_profile_id': profileId},
    );

    final rows = response as List;
    if (rows.isEmpty) {
      throw StateError('Profil nicht gefunden');
    }

    return _mapProfile(rows.first as Map<String, dynamic>);
  }

  Future<UserProfile> getMyProfile() async {
    final userId = _userId;
    if (userId == null) {
      throw const AuthException('Nicht angemeldet');
    }
    return getProfile(userId);
  }

  Future<void> updateProfile(UpdateProfileInput input) async {
    final userId = _userId;
    if (userId == null) {
      throw const AuthException('Nicht angemeldet');
    }

    await _client.from('profiles').update({
      'username': input.username,
      'bio': input.bio,
      'age': input.age,
      'interests': input.interests,
    }).eq('id', userId);
  }

  Future<({double avgRating, int reviewCount})> getUserRating(
    String profileId,
  ) async {
    final response = await _client.rpc(
      'get_user_rating',
      params: {'p_profile_id': profileId},
    );

    final rows = response as List;
    if (rows.isEmpty) {
      return (avgRating: 0.0, reviewCount: 0);
    }

    final map = rows.first as Map<String, dynamic>;
    return (
      avgRating: (map['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['review_count'] as int? ?? 0,
    );
  }

  Future<bool> simulatePremium({required bool enabled}) async {
    final response = await _client.rpc(
      'simulate_premium',
      params: {'p_enabled': enabled},
    );
    return response as bool? ?? enabled;
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw const AuthException('Nicht angemeldet');
    }

    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final path = '$userId/avatar.$extension';

    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(extension),
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

    await _client.from('profiles').update({
      'avatar_url': publicUrl,
    }).eq('id', userId);

    return publicUrl;
  }

  String _contentType(String extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

  UserProfile _mapProfile(Map<String, dynamic> map) {
    final interestsRaw = map['interests'];
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String,
      avatarUrl: map['avatar_url'] as String?,
      coverUrl: map['cover_url'] as String?,
      bio: map['bio'] as String?,
      age: map['age'] as int?,
      interests: interestsRaw is List
          ? interestsRaw.map((e) => e.toString()).toList()
          : const [],
      userType: map['user_type'] as String? ?? 'standard',
      isPremium: map['is_premium'] as bool? ?? false,
    );
  }
}
