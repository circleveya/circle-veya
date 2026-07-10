import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/location/distance_display.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';

/// Kompakte horizontale Aktivitätskarte (Quiet Luxury).
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    this.onAction,
    this.onTap,
    this.isLoading = false,
  });

  static const double thumbnailSize = 80;

  final DiscoverableActivity activity;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final bool isLoading;

  bool get _showActionButton =>
      onAction != null &&
      activity.viewerAction != ViewerAction.none &&
      activity.viewerAction != ViewerAction.host;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFeatured = activity.isFeatured;

    return Material(
      color: isFeatured
          ? Color.alphaBlend(
              Colors.amber.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            )
          : theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFeatured
              ? Colors.amber.shade600.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActivityThumbnail(imageUrl: activity.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFeatured || activity.isEventTakeover) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (isFeatured) const _SponsoredLabel(),
                          if (activity.isEventTakeover)
                            _VisitedEventLabel(
                              title: activity.sourceEventTitle
                                          ?.trim()
                                          .isNotEmpty ==
                                      true
                                  ? activity.sourceEventTitle!
                                  : activity.title,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.15,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(activity: activity),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _HostAvatar(
                          username: activity.hostUsername,
                          avatarUrl: activity.hostAvatarUrl,
                          isCompany: activity.hostIsCompany,
                        ),
                        const SizedBox(width: 8),
                        _RelationBadge(label: activity.visibleAs.label),
                        if (activity.isNew) ...[
                          const SizedBox(width: 6),
                          _RelationBadge(
                            label: 'Neu',
                            muted: true,
                          ),
                        ],
                        const Spacer(),
                        if (_showActionButton)
                          _ActionButton(
                            label: activity.viewerAction.buttonLabel,
                            enabled:
                                activity.viewerAction.canTap && !isLoading,
                            isLoading: isLoading,
                            emphasized: activity.viewerAction ==
                                ViewerAction.directJoin,
                            onPressed: onAction,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityThumbnail extends StatelessWidget {
  const _ActivityThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: ActivityCard.thumbnailSize,
        height: ActivityCard.thumbnailSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasUrl)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (_, _) => const _FallbackThumbnail(),
                errorWidget: (_, _, _) => const _FallbackThumbnail(),
              )
            else
              const _FallbackThumbnail(),
          ],
        ),
      ),
    );
  }
}

/// Sehr blasser Brand-Gradient + linker Akzentstreifen als Thumbnail-Fallback.
class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _SoftGradientFill(),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brandOrange,
                    AppColors.brandMagenta,
                    AppColors.brandPurple,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sehr blasser Brand-Gradient als Thumbnail-Fallback.
class _SoftGradientFill extends StatelessWidget {
  const _SoftGradientFill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandOrange.withValues(alpha: 0.12),
            AppColors.brandMagenta.withValues(alpha: 0.10),
            AppColors.brandPurple.withValues(alpha: 0.12),
            AppColors.tertiary.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _HostAvatar extends StatelessWidget {
  const _HostAvatar({
    required this.username,
    required this.avatarUrl,
    required this.isCompany,
  });

  static const double diameter = 24;

  final String username;
  final String? avatarUrl;
  final bool isCompany;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = username.trim().isNotEmpty
        ? username.trim()[0].toUpperCase()
        : '?';
    final url = avatarUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final bg = isCompany
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.primaryContainer;
    final fg = isCompany
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onPrimaryContainer;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: CircleAvatar(
        radius: diameter / 2,
        backgroundColor: bg,
        foregroundColor: fg,
        backgroundImage: hasUrl ? CachedNetworkImageProvider(url) : null,
        onBackgroundImageError: hasUrl ? (_, _) {} : null,
        child: hasUrl
            ? null
            : Text(
                initial,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
      ),
    );
  }
}

class _RelationBadge extends StatelessWidget {
  const _RelationBadge({
    required this.label,
    this.muted = false,
  });

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: muted
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
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
      if (DistanceDisplay.placeLabel(activity) != null)
        _MetaItem(
          Icons.place_outlined,
          DistanceDisplay.placeLabel(activity)!,
        )
      else if (activity.distanceKm != null)
        _MetaItem(
          Icons.near_me_outlined,
          DistanceDisplay.forActivity(activity),
        )
      else if (activity.locationName != null &&
          activity.locationName!.trim().isNotEmpty)
        _MetaItem(Icons.place_outlined, activity.locationName!.trim()),
      _MetaItem(Icons.people_outline, activity.participantsLabel),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 6),
              Text(
                '·',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              items[i].icon,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 3),
            Text(
              items[i].label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
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
    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor:
            emphasized ? AppColors.seed : Theme.of(context).colorScheme.primary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      child: Text(label),
    );
  }
}

class _VisitedEventLabel extends StatelessWidget {
  const _VisitedEventLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Besucht: $title',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
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
            letterSpacing: 0.3,
          ),
    );
  }
}
