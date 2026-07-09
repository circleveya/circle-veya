import '../entities/connection.dart';

abstract class FriendsRepository {
  Future<List<UserConnection>> getMyConnections();

  Future<List<SearchableProfile>> searchProfiles(String query);

  Future<void> addFriend(String profileId);

  Future<void> addAcquaintance(String profileId);

  Future<void> removeConnection(String profileId);
}
