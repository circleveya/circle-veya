import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/circle_group.dart';

class GroupsRemoteDatasource {
  GroupsRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<List<CircleGroup>> getMyGroups() async {
    final response = await _client.rpc('get_my_circle_groups');
    if (response is! List) return const [];

    return response
        .whereType<Map>()
        .map((row) => _mapGroup(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<CircleGroupMember>> getGroupMembers(String groupId) async {
    final response = await _client.rpc(
      'get_circle_group_members',
      params: {'p_group_id': groupId},
    );
    if (response is! List) return const [];

    return response.whereType<Map>().map((row) {
      final map = Map<String, dynamic>.from(row);
      return CircleGroupMember(
        profileId: map['profile_id'] as String,
        username: map['username'] as String? ?? 'User',
        avatarUrl: map['avatar_url'] as String?,
        role: map['role'] as String? ?? 'member',
        joinedAt: DateTime.parse(map['joined_at'] as String),
      );
    }).toList();
  }

  Future<String> createGroup({
    required String name,
    String? description,
    List<String> memberIds = const [],
  }) async {
    final response = await _client.rpc(
      'create_circle_group',
      params: {
        'p_name': name,
        'p_description': description,
        'p_member_ids': memberIds,
      },
    );
    return response as String;
  }

  Future<String> createGroupFromActivity({
    required String activityId,
    String? name,
    bool includePendingInterests = false,
  }) async {
    final response = await _client.rpc(
      'create_circle_group_from_activity',
      params: {
        'p_activity_id': activityId,
        'p_name': name,
        'p_include_pending_interests': includePendingInterests,
      },
    );
    return response as String;
  }

  Future<List<ActivityParticipant>> getActivityParticipants(
    String activityId,
  ) async {
    final response = await _client.rpc(
      'get_activity_participants',
      params: {'p_activity_id': activityId},
    );
    if (response is! List) return const [];

    return response.whereType<Map>().map((row) {
      final map = Map<String, dynamic>.from(row);
      return ActivityParticipant(
        profileId: map['profile_id'] as String,
        username: map['username'] as String? ?? 'User',
        avatarUrl: map['avatar_url'] as String?,
        joinedVia: map['joined_via'] as String? ?? 'direct',
        joinedAt: DateTime.parse(map['joined_at'] as String),
      );
    }).toList();
  }

  Future<CircleGroup> getGroupDetail(String groupId) async {
    final response = await _client.rpc(
      'get_circle_group_detail',
      params: {'p_group_id': groupId},
    );
    if (response is! List || response.isEmpty) {
      throw StateError('Kreis nicht gefunden');
    }
    final row = response.first;
    if (row is! Map) {
      throw StateError('Kreis nicht gefunden');
    }
    return _mapGroup(Map<String, dynamic>.from(row));
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
  }) async {
    await _client.rpc(
      'update_circle_group',
      params: {
        'p_group_id': groupId,
        'p_name': name,
        'p_description': description,
      },
    );
  }

  Future<int> addMembers({
    required String groupId,
    required List<String> memberIds,
  }) async {
    final response = await _client.rpc(
      'add_circle_group_members',
      params: {
        'p_group_id': groupId,
        'p_member_ids': memberIds,
      },
    );
    return (response as num?)?.toInt() ?? 0;
  }

  Future<void> setMemberRole({
    required String groupId,
    required String profileId,
    required String role,
  }) async {
    await _client.rpc(
      'set_circle_group_member_role',
      params: {
        'p_group_id': groupId,
        'p_profile_id': profileId,
        'p_role': role,
      },
    );
  }

  Future<void> removeMember({
    required String groupId,
    required String profileId,
  }) async {
    await _client.rpc(
      'remove_circle_group_member',
      params: {
        'p_group_id': groupId,
        'p_profile_id': profileId,
      },
    );
  }

  CircleGroup _mapGroup(Map<String, dynamic> map) {
    return CircleGroup(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Kreis',
      description: map['description'] as String?,
      createdBy: map['created_by'] as String,
      sourceActivityId: map['source_activity_id'] as String?,
      memberCount: (map['member_count'] as num?)?.toInt() ?? 0,
      myRole: map['my_role'] as String? ?? 'member',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
