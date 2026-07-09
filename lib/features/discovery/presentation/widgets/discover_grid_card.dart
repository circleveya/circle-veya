import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/location/distance_display.dart';
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
    this.occurrenceCount = 1,
    this.onTap,
    this.onAction,
    this.isLoading = false,
  });

  final DiscoverableActivity activity;
  final int occurrenceCount;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final bool isLoading;

  bool get _showAction =>
      activity.viewerAction != ViewerAction.none &&
      activity.viewerAction != ViewerAction.host;

  bool get _isGrouped => occurrenceCount > 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = _formatDateLabel(activity.dateTime);

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
                  CachedNetworkImage(
                    imageUrl: activity.effectiveImageUrl,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ActivityStatusBadges(activity: activity),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _DateBadge(label: dateLabel),
                  ),
                  if (_isGrouped)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _SeriesBadge(count: occurrenceCount),
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
                    if (_isGrouped) ...[
                      const SizedBox(height: 6),
                      Text(
                        '+ ${occurrenceCount - 1} weitere Termine',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.seed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                    if (activity.locationName != null &&
                        activity.locationName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activity.locationName!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.seed,
                            ),
                          ),
                        ),
                        if (activity.distanceKm != null)
                          Text(
                            DistanceDisplay.forActivity(activity),
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
                          onPressed:
                              activity.viewerAction.canTap && !isLoading
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

  static String _formatDateLabel(DateTime? dateTime) {
    if (dateTime == null) return 'Flexibel';
    final local = dateTime.toLocal();
    final day = DateFormat('dd.MM.yyyy').format(local);
    final time = DateFormat('HH:mm').format(local);
    return '$day · $time';
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _SeriesBadge extends StatelessWidget {
  const _SeriesBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.seed.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$count Termine',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
