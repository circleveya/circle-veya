import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/shell_destination_request.dart';
import '../../../../core/layout/web_shell_destination.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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

    final resolved = challenge ??
        statsAsync.valueOrNull?.challenges
            .where((c) => c.id == challengeId)
            .firstOrNull;

    if (resolved == null && statsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (resolved == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenge')),
        body: const Center(child: Text('Challenge nicht gefunden.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(resolved.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            resolved.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resolved.resolvedDescription,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text(
            'Fortschritt',
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
            'Belohnung: ${resolved.xpReward} XP',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'So schließt du sie ab',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(resolved.resolvedHowTo, style: theme.textTheme.bodyMedium),
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
                                ? 'Belohnung abgeholt (+${resolved.xpReward} XP)'
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
                  : const Text('Belohnung abholen'),
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
                  'social' => 'Zu Freunden',
                  'weekly' => 'Aktivität erstellen',
                  'sport' => 'Aktivitäten entdecken',
                  _ => 'Loslegen',
                },
              ),
            ),
        ],
      ),
    );
  }
}
