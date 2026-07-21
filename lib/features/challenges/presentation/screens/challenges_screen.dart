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
      data: (stats) {
        final weekly = stats.weeklyChallenges;
        final monthly = stats.monthlyChallenges;
        final other = stats.otherChallenges;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Challenges',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wöchentliche Challenges starten montags neu, '
              'monatliche am 1. des Monats.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ChallengeLevelCard(stats: stats),
            if (weekly.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Wöchentlich',
                subtitle: 'Reset jeden Montag',
                icon: Icons.date_range_outlined,
              ),
              const SizedBox(height: 12),
              ...weekly.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChallengeProgressCard(challenge: c),
                ),
              ),
            ],
            if (monthly.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionHeader(
                title: 'Monatlich',
                subtitle: 'Reset am 1. des Monats',
                icon: Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 12),
              ...monthly.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChallengeProgressCard(challenge: c),
                ),
              ),
            ],
            if (other.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Weitere Challenges', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ...other.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChallengeProgressCard(challenge: c),
                ),
              ),
            ],
            if (stats.challenges.isEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Noch keine aktiven Challenges.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.seed),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final theme = Theme.of(context);

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.seed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      challenge.periodBadgeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.seed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${challenge.progress} / ${challenge.target}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.seed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                challenge.title,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                challenge.resetHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
