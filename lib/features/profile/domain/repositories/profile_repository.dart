import 'dart:typed_data';

import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String profileId);

  Future<UserProfile> getMyProfile();

  Future<void> updateProfile(UpdateProfileInput input);

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });

  Future<String> uploadCover({
    required Uint8List bytes,
    required String fileName,
  });
}
