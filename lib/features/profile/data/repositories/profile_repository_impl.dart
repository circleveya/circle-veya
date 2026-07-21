import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileFailure extends Failure {
  const ProfileFailure(super.message);
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._datasource);

  final ProfileRemoteDatasource _datasource;

  @override
  Future<UserProfile> getMyProfile() async {
    try {
      return await _datasource.getMyProfile();
    } on PostgrestException catch (error) {
      throw ProfileFailure(error.message);
    } on AuthException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  @override
  Future<UserProfile> getProfile(String profileId) async {
    try {
      return await _datasource.getProfile(profileId);
    } on PostgrestException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  @override
  Future<void> updateProfile(UpdateProfileInput input) async {
    try {
      await _datasource.updateProfile(input);
    } on PostgrestException catch (error) {
      throw ProfileFailure(error.message);
    } on AuthException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return await _datasource.uploadAvatar(bytes: bytes, fileName: fileName);
    } on StorageException catch (error) {
      throw ProfileFailure(error.message);
    } on PostgrestException catch (error) {
      throw ProfileFailure(error.message);
    } on AuthException catch (error) {
      throw ProfileFailure(error.message);
    }
  }

  @override
  Future<String> uploadCover({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return await _datasource.uploadCover(bytes: bytes, fileName: fileName);
    } on StorageException catch (error) {
      throw ProfileFailure(error.message);
    } on PostgrestException catch (error) {
      throw ProfileFailure(error.message);
    } on AuthException catch (error) {
      throw ProfileFailure(error.message);
    }
  }
}
