import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/connection.dart';

class FriendsRemoteDatasource {
  FriendsRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<List<UserConnection>> getMyConnections() async {
    final response = await _client.rpc('get_my_connections');

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return UserConnection(
        profileId: map['profile_id'] as String,
        username: map['username'] as String,
        avatarUrl: map['avatar_url'] as String?,
        bio: map['bio'] as String?,
        type: ConnectionType.fromDb(map['status'] as String?) ??
            ConnectionType.friend,
        connectedAt: DateTime.parse(map['connected_at'] as String),
      );
    }).toList();
  }

  Future<List<SearchableProfile>> searchProfiles(String query) async {
    final response = await _client.rpc(
      'search_profiles',
      params: {'p_query': query},
    );

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return SearchableProfile(
        id: map['id'] as String,
        username: map['username'] as String,
        avatarUrl: map['avatar_url'] as String?,
        bio: map['bio'] as String?,
        connectionStatus:
            ConnectionType.fromDb(map['connection_status'] as String?),
      );
    }).toList();
  }

  Future<void> addFriend(String profileId) async {
    await _client.rpc('add_friend', params: {'p_profile_id': profileId});
  }

  Future<void> addAcquaintance(String profileId) async {
    await _client.rpc('add_acquaintance', params: {'p_profile_id': profileId});
  }

  Future<void> removeConnection(String profileId) async {
    await _client.rpc('remove_connection', params: {'p_profile_id': profileId});
  }
}
