import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/level_milestone.dart';
import '../providers/challenge_provider.dart';
import '../widgets/level_milestones_ui.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final myProfile = ref.watch(myProfileProvider).valueOrNull;
    if (myProfile?.isBusinessProfile == true) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.companies,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: AppColors.surfaceTint,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.businessNoLevelTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.businessNoLevelBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    myProfile!.followerCount == 1
                        ? l10n.oneFollower
                        : l10n.followersCount(myProfile.followerCount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.seed,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

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
              l10n.challenges,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.weeklyChallengesHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ChallengeLevelCard(stats: stats),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (context) => SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.85,
                    child: LevelMilestonesGallery(userLevel: stats.level),
                  ),
                );
              },
              icon: const Icon(Icons.emoji_events_outlined),
              label: Text(
                LevelMilestone.currentFor(stats.level) != null
                    ? l10n.levelBadgesWithName(
                        LevelMilestone.currentFor(stats.level)!.name,
                      )
                    : l10n.levelBadges,
              ),
            ),
            if (weekly.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(
                title: l10n.weekly,
                subtitle: l10n.weeklyChallengesHint,
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
                title: l10n.monthly,
                subtitle: l10n.monthlyReset,
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
              Text(l10n.otherChallenges, style: theme.textTheme.titleMedium),
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
                l10n.noActiveChallenges,
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
    final milestone = LevelMilestone.currentFor(stats.level);
    final l10n = AppLocalizations.of(context);
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
                l10n.levelLabel(stats.level),
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
                  if (milestone != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          LevelBadgeImage(milestone: milestone, size: 40),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              milestone.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.seed,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    l10n.xpRemaining(
                      stats.xpForNextLevel - stats.currentXp,
                      stats.level + 1,
                    ),
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
    final l10n = AppLocalizations.of(context);

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
                      challenge.localizedPeriodBadge(l10n),
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
                challenge.localizedTitle(l10n),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                challenge.localizedResetHint(l10n),
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
