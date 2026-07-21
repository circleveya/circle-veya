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

final groupDetailProvider =
    FutureProvider.autoDispose.family<CircleGroup, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).getGroupDetail(groupId);
});

final activityParticipantsProvider = FutureProvider.autoDispose
    .family<List<ActivityParticipant>, String>((ref, activityId) {
  return ref.watch(groupsRepositoryProvider).getActivityParticipants(activityId);
});

class GroupsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  GroupsRepository get _repo => ref.read(groupsRepositoryProvider);

  void _invalidateGroup(String groupId) {
    ref.invalidate(groupDetailProvider(groupId));
    ref.invalidate(groupMembersProvider(groupId));
    ref.invalidate(myGroupsProvider);
  }

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

  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    bool? membersCanPost,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        membersCanPost: membersCanPost,
      );
    });
    if (!state.hasError) {
      _invalidateGroup(groupId);
    }
  }

  Future<String?> openGroupChat(String groupId) async {
    state = const AsyncLoading();
    String? chatId;
    state = await AsyncValue.guard(() async {
      chatId = await _repo.getOrCreateGroupChat(groupId);
    });
    if (state.hasError) return null;
    return chatId;
  }

  Future<int?> addMembers({
    required String groupId,
    required List<String> memberIds,
  }) async {
    state = const AsyncLoading();
    int? added;
    state = await AsyncValue.guard(() async {
      added = await _repo.addMembers(
        groupId: groupId,
        memberIds: memberIds,
      );
    });
    if (!state.hasError) {
      _invalidateGroup(groupId);
    }
    return added;
  }

  Future<void> setMemberRole({
    required String groupId,
    required String profileId,
    required String role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.setMemberRole(
        groupId: groupId,
        profileId: profileId,
        role: role,
      );
    });
    if (!state.hasError) {
      _invalidateGroup(groupId);
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String profileId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.removeMember(
        groupId: groupId,
        profileId: profileId,
      );
    });
    if (!state.hasError) {
      _invalidateGroup(groupId);
    }
  }

  Future<void> uploadGroupImage({
    required String groupId,
    required List<int> bytes,
    required String fileName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.uploadGroupImage(
        groupId: groupId,
        bytes: bytes,
        fileName: fileName,
      );
    });
    if (!state.hasError) {
      _invalidateGroup(groupId);
    }
  }
}

final groupsControllerProvider =
    AutoDisposeAsyncNotifierProvider<GroupsController, void>(
  GroupsController.new,
);
