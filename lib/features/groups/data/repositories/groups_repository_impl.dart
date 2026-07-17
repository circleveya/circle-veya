import '../../domain/entities/circle_group.dart';
import '../../domain/repositories/groups_repository.dart';
import '../datasources/groups_remote_datasource.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  GroupsRepositoryImpl(this._datasource);

  final GroupsRemoteDatasource _datasource;

  @override
  Future<List<CircleGroup>> getMyGroups() => _datasource.getMyGroups();

  @override
  Future<List<CircleGroupMember>> getGroupMembers(String groupId) =>
      _datasource.getGroupMembers(groupId);

  @override
  Future<String> createGroup({
    required String name,
    String? description,
    List<String> memberIds = const [],
  }) =>
      _datasource.createGroup(
        name: name,
        description: description,
        memberIds: memberIds,
      );

  @override
  Future<String> createGroupFromActivity({
    required String activityId,
    String? name,
    bool includePendingInterests = false,
  }) =>
      _datasource.createGroupFromActivity(
        activityId: activityId,
        name: name,
        includePendingInterests: includePendingInterests,
      );

  @override
  Future<List<ActivityParticipant>> getActivityParticipants(
    String activityId,
  ) =>
      _datasource.getActivityParticipants(activityId);

  @override
  Future<CircleGroup> getGroupDetail(String groupId) =>
      _datasource.getGroupDetail(groupId);

  @override
  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
  }) =>
      _datasource.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
      );

  @override
  Future<int> addMembers({
    required String groupId,
    required List<String> memberIds,
  }) =>
      _datasource.addMembers(groupId: groupId, memberIds: memberIds);

  @override
  Future<void> setMemberRole({
    required String groupId,
    required String profileId,
    required String role,
  }) =>
      _datasource.setMemberRole(
        groupId: groupId,
        profileId: profileId,
        role: role,
      );

  @override
  Future<void> removeMember({
    required String groupId,
    required String profileId,
  }) =>
      _datasource.removeMember(groupId: groupId, profileId: profileId);
}
