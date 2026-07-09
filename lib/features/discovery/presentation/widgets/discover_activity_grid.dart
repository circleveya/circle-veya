import 'package:flutter/material.dart';

import '../../../activities/domain/entities/activity.dart';
import '../../domain/discover_feed_item.dart';
import 'discover_grid_card.dart';

/// Responsives Aktivitäten-Grid für Entdecken.
class DiscoverActivityGrid extends StatelessWidget {
  const DiscoverActivityGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.onAction,
    this.isActionLoading = false,
  });

  final List<DiscoverFeedItem> items;
  final void Function(DiscoverFeedItem item) onTap;
  final void Function(DiscoverableActivity activity)? onAction;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 3
            : width >= 560
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 1.35 : 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final activity = item.nextOccurrence;
            return DiscoverGridCard(
              activity: activity,
              occurrenceCount: item.occurrences.length,
              isLoading: isActionLoading,
              onTap: () => onTap(item),
              onAction:
                  onAction != null ? () => onAction!(activity) : null,
            );
          },
        );
      },
    );
  }
}
