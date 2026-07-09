import 'dart:typed_data';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class UnconfiguredProfileRepository implements ProfileRepository {
  const UnconfiguredProfileRepository();

  static const _message = 'Supabase ist nicht konfiguriert.';

  Never _throw() => throw UnsupportedError(_message);

  @override
  Future<UserProfile> getMyProfile() async => _throw();

  @override
  Future<UserProfile> getProfile(String profileId) async => _throw();

  @override
  Future<void> updateProfile(UpdateProfileInput input) async => _throw();

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async =>
      _throw();
}
