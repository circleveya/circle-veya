import '../../domain/entities/circle_group.dart';
import '../../domain/repositories/groups_repository.dart';

class UnconfiguredGroupsRepository implements GroupsRepository {
  const UnconfiguredGroupsRepository();

  static const _message =
      'Supabase ist nicht konfiguriert. Gruppen sind nicht verfügbar.';

  Never _throw() => throw UnsupportedError(_message);

  @override
  Future<List<CircleGroup>> getMyGroups() async => [];

  @override
  Future<List<CircleGroupMember>> getGroupMembers(String groupId) async => [];

  @override
  Future<String> createGroup({
    required String name,
    String? description,
    List<String> memberIds = const [],
  }) async =>
      _throw();

  @override
  Future<String> createGroupFromActivity({
    required String activityId,
    String? name,
    bool includePendingInterests = false,
  }) async =>
      _throw();

  @override
  Future<List<ActivityParticipant>> getActivityParticipants(
    String activityId,
  ) async =>
      [];
}
