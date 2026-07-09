import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/connection.dart';
import '../../domain/repositories/friends_repository.dart';
import '../datasources/friends_remote_datasource.dart';

class FriendsFailure extends Failure {
  const FriendsFailure(super.message);
}

class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl(this._datasource);

  final FriendsRemoteDatasource _datasource;

  @override
  Future<List<UserConnection>> getMyConnections() async {
    try {
      return await _datasource.getMyConnections();
    } on PostgrestException catch (error) {
      throw FriendsFailure(error.message);
    }
  }

  @override
  Future<List<SearchableProfile>> searchProfiles(String query) async {
    try {
      return await _datasource.searchProfiles(query);
    } on PostgrestException catch (error) {
      throw FriendsFailure(error.message);
    }
  }

  @override
  Future<void> addFriend(String profileId) async {
    try {
      await _datasource.addFriend(profileId);
    } on PostgrestException catch (error) {
      throw FriendsFailure(error.message);
    }
  }

  @override
  Future<void> addAcquaintance(String profileId) async {
    try {
      await _datasource.addAcquaintance(profileId);
    } on PostgrestException catch (error) {
      throw FriendsFailure(error.message);
    }
  }

  @override
  Future<void> removeConnection(String profileId) async {
    try {
      await _datasource.removeConnection(profileId);
    } on PostgrestException catch (error) {
      throw FriendsFailure(error.message);
    }
  }
}
