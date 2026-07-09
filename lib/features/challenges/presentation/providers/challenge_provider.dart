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
