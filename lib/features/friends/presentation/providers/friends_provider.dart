import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/datasources/friends_remote_datasource.dart';
import '../../data/repositories/friends_repository_impl.dart';
import '../../data/repositories/unconfigured_friends_repository.dart';
import '../../domain/entities/connection.dart';
import '../../domain/repositories/friends_repository.dart';

final friendsRemoteDatasourceProvider = Provider<FriendsRemoteDatasource>((ref) {
  return FriendsRemoteDatasource(ref.watch(supabaseClientProvider));
});

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  if (!Env.isConfigured) {
    return const UnconfiguredFriendsRepository();
  }
  return FriendsRepositoryImpl(ref.watch(friendsRemoteDatasourceProvider));
});

final myConnectionsProvider =
    FutureProvider.autoDispose<List<UserConnection>>((ref) {
  return ref.watch(friendsRepositoryProvider).getMyConnections();
});

final myFollowedCompaniesProvider =
    FutureProvider.autoDispose<List<FollowedCompany>>((ref) {
  return ref.watch(friendsRepositoryProvider).getMyFollowedCompanies();
});

final profileSearchProvider = FutureProvider.autoDispose
    .family<List<SearchableProfile>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  return ref.watch(friendsRepositoryProvider).searchProfiles(query.trim());
});

class FriendsActionsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  FriendsRepository get _repo => ref.read(friendsRepositoryProvider);

  Future<void> addFriend(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.addFriend(profileId));
    if (!state.hasError) {
      ref.invalidate(myConnectionsProvider);
      ref.invalidate(profileSearchProvider);
    }
  }

  Future<void> addAcquaintance(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.addAcquaintance(profileId));
    if (!state.hasError) {
      ref.invalidate(myConnectionsProvider);
      ref.invalidate(profileSearchProvider);
    }
  }

  Future<void> removeConnection(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.removeConnection(profileId));
    if (!state.hasError) {
      ref.invalidate(myConnectionsProvider);
      ref.invalidate(profileSearchProvider);
    }
  }

  Future<void> followCompany(String companyId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.followCompany(companyId));
    if (!state.hasError) {
      ref.invalidate(myFollowedCompaniesProvider);
      ref.invalidate(profileSearchProvider);
      ref.invalidate(profileProvider(companyId));
    }
  }

  Future<void> unfollowCompany(String companyId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.unfollowCompany(companyId));
    if (!state.hasError) {
      ref.invalidate(myFollowedCompaniesProvider);
      ref.invalidate(profileSearchProvider);
      ref.invalidate(profileProvider(companyId));
    }
  }
}

final friendsActionsProvider = AutoDisposeAsyncNotifierProvider<
    FriendsActionsController, void>(FriendsActionsController.new);
