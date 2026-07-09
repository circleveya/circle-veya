import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../activities/domain/entities/activity_enums.dart';
import '../../../activities/presentation/widgets/activity_status_badges.dart';
import '../../../activities/presentation/widgets/participant_avatar_stack.dart';

/// Kompakte Karte für das Entdecken-Grid.
class DiscoverGridCard extends StatelessWidget {
  const DiscoverGridCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onAction,
    this.isLoading = false,
  });

  final DiscoverableActivity activity;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final bool isLoading;

  bool get _showAction =>
      activity.viewerAction != ViewerAction.none &&
      activity.viewerAction != ViewerAction.host;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM. · HH:mm');

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: activity.isFeatured
              ? Colors.amber.shade600
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: activity.isFeatured ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (activity.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: activity.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.seed.withValues(alpha: 0.7),
                            AppColors.gradientEnd.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ActivityStatusBadges(activity: activity),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.hostUsername,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (activity.dateTime != null)
                          Expanded(
                            child: Text(
                              dateFormat.format(activity.dateTime!.toLocal()),
                              style: theme.textTheme.labelSmall,
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              'Flexibel',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.tertiary,
                              ),
                            ),
                          ),
                        if (activity.distanceKm != null)
                          Text(
                            '${activity.distanceKm!.toStringAsFixed(1)} km',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.seed,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ParticipantAvatarStack(
                          count: activity.currentParticipants,
                          hostInitial: activity.hostUsername,
                          avatarUrls: activity.participantAvatarUrls,
                        ),
                        const Spacer(),
                        Text(
                          activity.participantsLabel,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    if (_showAction) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: activity.viewerAction.canTap &&
                                  !isLoading
                              ? onAction
                              : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor:
                                activity.viewerAction == ViewerAction.interest
                                    ? AppColors.secondary
                                    : null,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(activity.viewerAction.buttonLabel),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
