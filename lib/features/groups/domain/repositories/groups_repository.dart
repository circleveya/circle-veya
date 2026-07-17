import '../entities/circle_group.dart';

abstract class GroupsRepository {
  Future<List<CircleGroup>> getMyGroups();

  Future<List<CircleGroupMember>> getGroupMembers(String groupId);

  Future<String> createGroup({
    required String name,
    String? description,
    List<String> memberIds,
  });

  Future<String> createGroupFromActivity({
    required String activityId,
    String? name,
    bool includePendingInterests = false,
  });

  Future<List<ActivityParticipant>> getActivityParticipants(String activityId);

  Future<CircleGroup> getGroupDetail(String groupId);

  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
  });

  Future<int> addMembers({
    required String groupId,
    required List<String> memberIds,
  });

  Future<void> setMemberRole({
    required String groupId,
    required String profileId,
    required String role,
  });

  Future<void> removeMember({
    required String groupId,
    required String profileId,
  });

  Future<String> uploadGroupImage({
    required String groupId,
    required List<int> bytes,
    required String fileName,
  });
}
