import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_review.dart';

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

  Future<List<UserReview>> getReviewsForProfile(String profileId) async {
    final response = await _client
        .from('reviews')
        .select(
          'id, target_user_id, reviewer_id, rating, comment, created_at, '
          'profiles!reviews_reviewer_id_fkey(username, avatar_url)',
        )
        .eq('target_user_id', profileId)
        .order('created_at', ascending: false);

    final reviews = <UserReview>[];
    for (final row in response as List) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final profile = map['profiles'];
      final profileMap = profile is Map
          ? Map<String, dynamic>.from(profile)
          : null;
      reviews.add(
        UserReview(
          id: map['id'] as String,
          targetUserId: map['target_user_id'] as String,
          reviewerId: map['reviewer_id'] as String,
          reviewerUsername: profileMap?['username'] as String? ?? 'User',
          reviewerAvatarUrl: profileMap?['avatar_url'] as String?,
          rating: (map['rating'] as num?)?.toInt() ?? 0,
          comment: map['comment'] as String?,
          createdAt: DateTime.parse(map['created_at'] as String),
        ),
      );
    }
    return reviews;
  }

  Future<UserReview?> getMyReviewForProfile(String targetUserId) async {
    final userId = _userId;
    if (userId == null) return null;

    final row = await _client
        .from('reviews')
        .select(
          'id, target_user_id, reviewer_id, rating, comment, created_at, '
          'profiles!reviews_reviewer_id_fkey(username, avatar_url)',
        )
        .eq('target_user_id', targetUserId)
        .eq('reviewer_id', userId)
        .maybeSingle();

    if (row == null) return null;
    final map = Map<String, dynamic>.from(row);
    final profile = map['profiles'];
    final profileMap =
        profile is Map ? Map<String, dynamic>.from(profile) : null;
    return UserReview(
      id: map['id'] as String,
      targetUserId: map['target_user_id'] as String,
      reviewerId: map['reviewer_id'] as String,
      reviewerUsername: profileMap?['username'] as String? ?? 'Du',
      reviewerAvatarUrl: profileMap?['avatar_url'] as String?,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Future<void> upsertReview({
    required String targetUserId,
    required int rating,
    String? comment,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw const AuthException('Nicht angemeldet');
    }
    if (targetUserId == userId) {
      throw StateError('Du kannst dich nicht selbst bewerten');
    }
    if (rating < 1 || rating > 5) {
      throw StateError('Bewertung muss zwischen 1 und 5 liegen');
    }

    await _client.from('reviews').upsert(
      {
        'target_user_id': targetUserId,
        'reviewer_id': userId,
        'rating': rating,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      },
      onConflict: 'target_user_id,reviewer_id',
    );
  }

  Future<bool> simulatePremium({required bool enabled}) async {
    final response = await _client.rpc(
      'simulate_premium',
      params: {'p_enabled': enabled},
    );
    return response as bool? ?? enabled;
  }

  Future<void> updateGalleryPublic({required bool isPublic}) async {
    await _client.rpc(
      'update_my_gallery_public',
      params: {'p_public': isPublic},
    );
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
    final withCacheBust = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await _client.from('profiles').update({
      'avatar_url': withCacheBust,
    }).eq('id', userId);

    return withCacheBust;
  }

  Future<String> uploadCover({
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
    final path = '$userId/cover.$extension';

    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(extension),
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    final withCacheBust = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await _client.from('profiles').update({
      'cover_url': withCacheBust,
    }).eq('id', userId);

    return withCacheBust;
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
      galleryPublic: map['gallery_public'] as bool? ?? false,
      level: map['level'] == null ? null : (map['level'] as num).toInt(),
      followedByMe: map['followed_by_me'] as bool? ?? false,
      followerCount: (map['follower_count'] as num?)?.toInt() ?? 0,
    );
  }
}
