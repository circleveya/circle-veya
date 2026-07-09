import '../../domain/entities/connection.dart';
import '../../domain/repositories/friends_repository.dart';

class UnconfiguredFriendsRepository implements FriendsRepository {
  const UnconfiguredFriendsRepository();

  @override
  Future<void> addAcquaintance(String profileId) async =>
      throw UnsupportedError('Supabase ist nicht konfiguriert.');

  @override
  Future<void> addFriend(String profileId) async =>
      throw UnsupportedError('Supabase ist nicht konfiguriert.');

  @override
  Future<List<UserConnection>> getMyConnections() async => [];

  @override
  Future<void> removeConnection(String profileId) async =>
      throw UnsupportedError('Supabase ist nicht konfiguriert.');

  @override
  Future<List<SearchableProfile>> searchProfiles(String query) async => [];
}
