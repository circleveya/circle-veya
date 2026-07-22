import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity_share_payload.dart';

/// WhatsApp-Style Event-Vorschau in Chat-Bubbles.
class ActivitySharePreview extends StatelessWidget {
  const ActivitySharePreview({
    super.key,
    required this.payload,
    this.compact = false,
  });

  final ActivitySharePayload payload;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = payload.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final caption = payload.caption?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.activityDetail,
          pathParameters: {'id': payload.activityId},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const _ShareImageFallback(),
                        errorWidget: (_, _, _) => const _ShareImageFallback(),
                      )
                    : const _ShareImageFallback(),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payload.title,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandNavy,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CircleVeya · Event',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (caption != null && caption.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  caption,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.brandNavy,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareImageFallback extends StatelessWidget {
  const _ShareImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandOrange.withValues(alpha: 0.25),
            AppColors.brandPurple.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.event_outlined,
          size: 40,
          color: AppColors.brandNavy,
        ),
      ),
    );
  }
}
