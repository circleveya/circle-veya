import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/location/distance_display.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';

/// Kompakte Aktivitätskarte (Quiet Luxury) mit 120px Cover.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    this.onAction,
    this.onTap,
    this.isLoading = false,
  });

  static const double coverHeight = 120;

  final DiscoverableActivity activity;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final bool isLoading;

  bool get _showActionButton =>
      activity.viewerAction != ViewerAction.none &&
      activity.viewerAction != ViewerAction.host;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFeatured = activity.isFeatured;

    return Material(
      color: isFeatured
          ? Color.alphaBlend(
              Colors.amber.withValues(alpha: 0.06),
              theme.colorScheme.surface,
            )
          : theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isFeatured
              ? Colors.amber.shade600.withValues(alpha: 0.55)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ActivityCoverImage(
                imageUrl: activity.imageUrl,
                height: coverHeight,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(height: 16),
              if (isFeatured) ...[
                const _SponsoredLabel(),
                const SizedBox(height: 8),
              ],
              Text(
                activity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: -0.2,
                  color: AppColors.brandNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _hostLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _MetaRow(activity: activity),
              if (_showActionButton) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: _ActionButton(
                    label: activity.viewerAction.buttonLabel,
                    enabled: activity.viewerAction.canTap && !isLoading,
                    isLoading: isLoading,
                    emphasized:
                        activity.viewerAction == ViewerAction.directJoin,
                    onPressed: onAction,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _hostLine {
    final parts = <String>[
      activity.hostUsername,
      activity.visibleAs.label,
    ];
    if (activity.isNew) parts.add('Neu');
    return parts.join(' · ');
  }
}

/// Cover mit fester Höhe, zentriertem Crop und Brand-Gradient als Fallback.
class ActivityCoverImage extends StatelessWidget {
  const ActivityCoverImage({
    super.key,
    required this.imageUrl,
    this.height = ActivityCard.coverHeight,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  final String? imageUrl;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (_, _) => const _BrandGradientFallback(),
                errorWidget: (_, _, _) => const _BrandGradientFallback(),
              )
            : const _BrandGradientFallback(),
      ),
    );
  }
}

class _BrandGradientFallback extends StatelessWidget {
  const _BrandGradientFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.brandGradient),
      child: SizedBox.expand(),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.activity});

  final DiscoverableActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, dd.MM. · HH:mm');
    final items = <_MetaItem>[
      if (activity.dateTime != null)
        _MetaItem(
          Icons.schedule_outlined,
          dateFormat.format(activity.dateTime!.toLocal()),
        )
      else
        const _MetaItem(Icons.event_available_outlined, 'Flexibel'),
      _MetaItem(Icons.people_outline, activity.participantsLabel),
      if (DistanceDisplay.placeLabel(activity) != null)
        _MetaItem(
          Icons.place_outlined,
          DistanceDisplay.placeLabel(activity)!,
        )
      else if (activity.distanceKm != null)
        _MetaItem(
          Icons.near_me_outlined,
          DistanceDisplay.forActivity(activity),
        ),
      _MetaItem(activity.locationType.icon, activity.locationType.label),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 8),
              Text(
                '·',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              items[i].icon,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              items[i].label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaItem {
  const _MetaItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.isLoading,
    required this.emphasized,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool isLoading;
  final bool emphasized;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.1,
        ),
        side: BorderSide(
          color: emphasized
              ? AppColors.seed.withValues(alpha: 0.55)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        foregroundColor: emphasized
            ? AppColors.seed
            : Theme.of(context).colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child,
    );
  }
}

class _SponsoredLabel extends StatelessWidget {
  const _SponsoredLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Gesponsert',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.amber.shade800,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
    );
  }
}
