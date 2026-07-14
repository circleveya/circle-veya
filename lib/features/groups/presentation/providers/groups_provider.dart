import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../data/datasources/groups_remote_datasource.dart';
import '../../data/repositories/groups_repository_impl.dart';
import '../../data/repositories/unconfigured_groups_repository.dart';
import '../../domain/entities/circle_group.dart';
import '../../domain/repositories/groups_repository.dart';

final groupsRemoteDatasourceProvider = Provider<GroupsRemoteDatasource>((ref) {
  return GroupsRemoteDatasource(ref.watch(supabaseClientProvider));
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  if (!Env.isConfigured) {
    return const UnconfiguredGroupsRepository();
  }
  return GroupsRepositoryImpl(ref.watch(groupsRemoteDatasourceProvider));
});

final myGroupsProvider =
    FutureProvider.autoDispose<List<CircleGroup>>((ref) {
  return ref.watch(groupsRepositoryProvider).getMyGroups();
});

final groupMembersProvider = FutureProvider.autoDispose
    .family<List<CircleGroupMember>, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).getGroupMembers(groupId);
});

final activityParticipantsProvider = FutureProvider.autoDispose
    .family<List<ActivityParticipant>, String>((ref, activityId) {
  return ref.watch(groupsRepositoryProvider).getActivityParticipants(activityId);
});

class GroupsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  GroupsRepository get _repo => ref.read(groupsRepositoryProvider);

  Future<String?> createGroup({
    required String name,
    String? description,
    List<String> memberIds = const [],
  }) async {
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      id = await _repo.createGroup(
        name: name,
        description: description,
        memberIds: memberIds,
      );
    });
    if (!state.hasError) {
      ref.invalidate(myGroupsProvider);
    }
    return id;
  }

  Future<String?> createGroupFromActivity({
    required String activityId,
    String? name,
    bool includePendingInterests = false,
  }) async {
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      id = await _repo.createGroupFromActivity(
        activityId: activityId,
        name: name,
        includePendingInterests: includePendingInterests,
      );
    });
    if (!state.hasError) {
      ref.invalidate(myGroupsProvider);
    }
    return id;
  }
}

final groupsControllerProvider =
    AutoDisposeAsyncNotifierProvider<GroupsController, void>(
  GroupsController.new,
);
