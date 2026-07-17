import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_provider.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userLevelStatsProvider);
    final theme = Theme.of(context);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (stats) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Challenges',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          ChallengeLevelCard(stats: stats),
          const SizedBox(height: 24),
          Text('Aktive Challenges', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...stats.challenges.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChallengeProgressCard(challenge: c),
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeLevelCard extends StatelessWidget {
  const ChallengeLevelCard({super.key, required this.stats});

  final UserLevelStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Level ${stats.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.currentXp} XP',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stats.levelProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                      color: AppColors.seed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Noch ${stats.xpForNextLevel - stats.currentXp} XP bis Level ${stats.level + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChallengeProgressCard extends StatelessWidget {
  const ChallengeProgressCard({super.key, required this.challenge});

  final UserChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.challengeDetail,
          pathParameters: {'id': challenge.id},
          extra: challenge,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${challenge.progress} / ${challenge.target}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.seed,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: challenge.progressRatio,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceTint,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
