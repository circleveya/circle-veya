import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/challenge.dart';

class ChallengesRemoteDatasource {
  ChallengesRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<UserLevelStats> getUserLevelStats() async {
    final response = await _client.rpc('get_user_level_stats');
    final rows = response as List;
    if (rows.isEmpty) {
      return kMockLevelStats;
    }

    final first = rows.first as Map<String, dynamic>;
    final level = first['level'] as int? ?? 1;
    final currentXp = first['current_xp'] as int? ?? 0;
    final xpNeeded = first['xp_for_next_level'] as int? ?? 1000;

    final challenges = <UserChallenge>[];
    final interestScores = <String, double>{};

    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      final challengeId = map['challenge_id'] as String?;
      if (challengeId != null) {
        challenges.add(
          UserChallenge(
            id: challengeId,
            title: map['challenge_title'] as String? ?? 'Challenge',
            progress: map['challenge_progress'] as int? ?? 0,
            target: map['challenge_target'] as int? ?? 1,
          ),
        );
      }
    }

    if (challenges.isEmpty) {
      return kMockLevelStats;
    }

    return UserLevelStats(
      level: level,
      currentXp: currentXp,
      xpForNextLevel: xpNeeded,
      challenges: challenges,
      interestScores: interestScores,
    );
  }
}
