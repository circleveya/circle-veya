import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/challenges/domain/entities/challenge.dart';
import '../../features/challenges/presentation/providers/challenge_provider.dart';
import '../../features/sidebar/presentation/providers/sidebar_provider.dart';
import '../location/distance_display.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import 'shell_destination_request.dart';
import 'web_shell_destination.dart';

/// Rechte Spalte – kontextabhängige Widget-Karten (live aus Supabase).
class WebRightPanel extends ConsumerWidget {
  const WebRightPanel({
    super.key,
    required this.destination,
  });

  final WebShellDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userLevelStatsProvider);

    return Container(
      width: AppColors.rightPanelWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: switch (destination) {
          WebShellDestination.profile =>
            _profileWidgets(context, ref, statsAsync),
          _ => _feedWidgets(context, ref, statsAsync),
        },
      ),
    );
  }

  List<Widget> _feedWidgets(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserLevelStats> statsAsync,
  ) {
    final trendingAsync = ref.watch(trendingActivitiesProvider);
    final recommendedAsync = ref.watch(recommendedActivitiesProvider);
    final onlineFriendsAsync = ref.watch(onlineFriendsProvider);

    return [
      _PanelCard(
        title: 'Im Trend',
        icon: Icons.trending_up,
        child: trendingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(sidebarErrorMessage(e)),
          data: (items) => items.isEmpty
              ? const Text('Noch keine Trend-Aktivitäten.')
              : Column(
                  children: items
                      .map(
                        (item) => _TrendItem(
                          title: item.title,
                          subtitle: item.subtitle,
                          onTap: () => context.pushNamed(
                            RouteNames.activityDetail,
                            pathParameters: {'id': item.activityId},
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
      const SizedBox(height: 16),
      _PanelCard(
        title: 'Für dich empfohlen',
        icon: Icons.auto_awesome,
        child: recommendedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(sidebarErrorMessage(e)),
          data: (items) => items.isEmpty
              ? const Text('Keine Empfehlungen – Interessen im Profil ergänzen.')
              : Column(
                  children: items
                      .map(
                        (item) => _TrendItem(
                          title: item.title,
                          subtitle: item.distanceKm != null
                              ? '${item.matchScore} Treffer · ${DistanceDisplay.formatDistanceKm(item.distanceKm)}'
                              : '${item.matchScore} Treffer',
                          onTap: () => context.pushNamed(
                            RouteNames.activityDetail,
                            pathParameters: {'id': item.activityId},
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
      const SizedBox(height: 16),
      _PanelCard(
        title: 'Deine Challenges',
        icon: Icons.emoji_events_outlined,
        onTap: () => ref
            .read(shellDestinationRequestProvider.notifier)
            .goTo(WebShellDestination.challenges),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
          data: (stats) => Column(
            children: stats.challenges
                .take(2)
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChallengeProgress(
                      title: c.title,
                      progress: c.progressRatio,
                      label: '${c.progress} / ${c.target}',
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _PanelCard(
        title: 'Freunde online',
        icon: Icons.circle,
        iconColor: Colors.green,
        onTap: () => ref
            .read(shellDestinationRequestProvider.notifier)
            .goTo(WebShellDestination.friends),
        child: onlineFriendsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(sidebarErrorMessage(e)),
          data: (friends) => friends.isEmpty
              ? const Text('Keine Freunde gerade online.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: friends
                      .map(
                        (f) => Tooltip(
                          message: f.username,
                          child: InkWell(
                            onTap: () => context.pushNamed(
                              RouteNames.profileView,
                              pathParameters: {'id': f.profileId},
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  AppColors.seed.withValues(alpha: 0.15),
                              backgroundImage: f.avatarUrl != null
                                  ? CachedNetworkImageProvider(f.avatarUrl!)
                                  : null,
                              child: f.avatarUrl == null
                                  ? Text(
                                      f.username[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.seed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    ];
  }

  List<Widget> _profileWidgets(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserLevelStats> statsAsync,
  ) {
    return statsAsync.when(
      loading: () => [
        const Center(child: CircularProgressIndicator()),
      ],
      error: (e, _) => [Text('$e')],
      data: (stats) => [
        _PanelCard(
          title: 'Challenge Level',
          icon: Icons.military_tech_outlined,
          onTap: () => ref
              .read(shellDestinationRequestProvider.notifier)
              .goTo(WebShellDestination.challenges),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level ${stats.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.currentXp} XP',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: stats.levelProgress,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: AppColors.surfaceTint,
                      color: AppColors.seed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PanelCard(
          title: 'Aktive Challenges',
          icon: Icons.flag_outlined,
          onTap: () => ref
              .read(shellDestinationRequestProvider.notifier)
              .goTo(WebShellDestination.challenges),
          child: Column(
            children: stats.challenges
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChallengeProgress(
                      title: c.title,
                      progress: c.progressRatio,
                      label: '${c.progress} / ${c.target}',
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: AppColors.surfaceTint,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: iconColor ?? AppColors.seed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendItem extends StatelessWidget {
  const _TrendItem({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeProgress extends StatelessWidget {
  const _ChallengeProgress({
    required this.title,
    required this.progress,
    required this.label,
  });

  final String title;
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodySmall),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.seed,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white,
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }
}

