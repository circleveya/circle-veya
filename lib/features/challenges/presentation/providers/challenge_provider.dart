import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/challenges_remote_datasource.dart';
import '../../domain/entities/challenge.dart';

final challengesRemoteDatasourceProvider =
    Provider<ChallengesRemoteDatasource>((ref) {
  return ChallengesRemoteDatasource(ref.watch(supabaseClientProvider));
});

final userLevelStatsProvider =
    FutureProvider.autoDispose<UserLevelStats>((ref) async {
  try {
    return await ref.watch(challengesRemoteDatasourceProvider).getUserLevelStats();
  } catch (_) {
    return kMockLevelStats;
  }
});

class ChallengeActionsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> complete(String challengeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(challengesRemoteDatasourceProvider)
          .completeChallenge(challengeId),
    );
    if (!state.hasError) {
      ref.invalidate(userLevelStatsProvider);
    }
  }
}

final challengeActionsProvider = AutoDisposeAsyncNotifierProvider<
    ChallengeActionsController, void>(ChallengeActionsController.new);
