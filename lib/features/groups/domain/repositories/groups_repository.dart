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
}
