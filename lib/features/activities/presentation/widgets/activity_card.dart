import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/location/distance_display.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';
import 'activity_status_badges.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    this.onAction,
    this.onTap,
    this.isLoading = false,
    this.compactImage = false,
  });

  final DiscoverableActivity activity;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final bool isLoading;

  /// Kompaktes Cover für den Social-Feed (deutlich kleiner).
  final bool compactImage;

  bool get _showActionButton =>
      activity.viewerAction != ViewerAction.none &&
      activity.viewerAction != ViewerAction.host;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, dd.MM.yyyy · HH:mm');
    final isFeatured = activity.isFeatured;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isFeatured ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFeatured
            ? BorderSide(color: Colors.amber.shade600, width: 2)
            : BorderSide.none,
      ),
      color: isFeatured
          ? Color.alphaBlend(
              Colors.amber.withValues(alpha: 0.08),
              theme.cardColor,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: compactImage ? 72 : 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: activity.effectiveImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: ActivityStatusBadges(activity: activity),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFeatured) ...[
                    _SponsoredBadge(hostIsCompany: activity.hostIsCompany),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: activity.hostIsCompany
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.primaryContainer,
                        foregroundColor: activity.hostIsCompany
                            ? theme.colorScheme.onTertiaryContainer
                            : theme.colorScheme.onPrimaryContainer,
                        child: Text(activity.hostUsername[0].toUpperCase()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    activity.hostUsername,
                                    style: theme.textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (activity.hostIsCompany) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              activity.visibleAs.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (activity.distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DistanceDisplay.forActivity(activity),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activity.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: isFeatured ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  if (activity.description != null &&
                      activity.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      activity.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (activity.dateTime != null)
                        _Chip(
                          icon: Icons.calendar_today,
                          label: dateFormat.format(activity.dateTime!.toLocal()),
                          color: theme.colorScheme.primaryContainer,
                        )
                      else
                        _Chip(
                          icon: Icons.event_available,
                          label: 'Flexibel / ohne Termin',
                          color: theme.colorScheme.tertiaryContainer,
                        ),
                      _Chip(
                        icon: Icons.people_outline,
                        label: activity.participantsLabel,
                        color: theme.colorScheme.secondaryContainer,
                      ),
                      _Chip(
                        icon: activity.locationType.icon,
                        label: activity.locationType.label,
                      ),
                      _Chip(
                        icon: activity.weatherCondition.icon,
                        label: activity.weatherCondition.label,
                      ),
                      if (DistanceDisplay.placeLabel(activity) != null)
                        _Chip(
                          icon: Icons.place_outlined,
                          label: DistanceDisplay.placeLabel(activity)!,
                        )
                      else if (activity.distanceKm != null)
                        _Chip(
                          icon: Icons.near_me_outlined,
                          label: DistanceDisplay.forActivity(activity),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showActionButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: activity.viewerAction.canTap && !isLoading
                    ? onAction
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: activity.viewerAction == ViewerAction.interest
                      ? theme.colorScheme.secondary
                      : null,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(activity.viewerAction.buttonLabel),
              ),
            ),
        ],
      ),
    );
  }
}

class _SponsoredBadge extends StatelessWidget {
  const _SponsoredBadge({required this.hostIsCompany});

  final bool hostIsCompany;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.featuredGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            hostIsCompany ? 'Gesponsert · Partner' : 'Gesponsert',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color ?? theme.colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }
}
