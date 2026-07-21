import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/shell_destination_request.dart';
import '../../../../core/layout/web_shell_destination.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_provider.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
    this.challenge,
  });

  final String challengeId;
  final UserChallenge? challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userLevelStatsProvider);
    final isCompleting = ref.watch(challengeActionsProvider).isLoading;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final resolved = challenge ??
        statsAsync.valueOrNull?.challenges
            .where((c) => c.id == challengeId)
            .firstOrNull;

    if (resolved == null && statsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (resolved == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.challenge)),
        body: Center(child: Text(l10n.challengeNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(resolved.localizedTitle(l10n))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            resolved.localizedTitle(l10n),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resolved.localizedResetHint(l10n),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.seed,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resolved.localizedDescription(l10n),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.progress,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: resolved.progressRatio,
                    minHeight: 12,
                    backgroundColor: AppColors.surfaceTint,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${resolved.progress} / ${resolved.target}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.seed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.rewardXp(resolved.xpReward),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.howToComplete,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resolved.localizedHowTo(l10n),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          if (resolved.isComplete)
            FilledButton(
              onPressed: isCompleting
                  ? null
                  : () async {
                      await ref
                          .read(challengeActionsProvider.notifier)
                          .complete(resolved.id);
                      if (!context.mounted) return;
                      final error = ref.read(challengeActionsProvider).error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error == null
                                ? l10n.rewardClaimed(resolved.xpReward)
                                : '$error',
                          ),
                        ),
                      );
                      if (error == null) context.pop();
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.brandNavy,
              ),
              child: isCompleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.claimReward),
            )
          else
            FilledButton(
              onPressed: () {
                final dest = switch (resolved.challengeType) {
                  'social' => WebShellDestination.friends,
                  'weekly' => WebShellDestination.create,
                  'sport' => WebShellDestination.discover,
                  _ => WebShellDestination.discover,
                };
                ref.read(shellDestinationRequestProvider.notifier).goTo(dest);
                context.goNamed(RouteNames.home);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.seed,
              ),
              child: Text(
                switch (resolved.challengeType) {
                  'social' => l10n.goToFriends,
                  'weekly' => l10n.createActivity,
                  'sport' => l10n.discoverActivities,
                  _ => l10n.getStarted,
                },
              ),
            ),
        ],
      ),
    );
  }
}
