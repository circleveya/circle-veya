import 'package:flutter/material.dart';

import '../../../activities/domain/entities/activity.dart';
import '../../domain/discover_feed_item.dart';
import 'discover_grid_card.dart';

/// Responsives 2-/3-Spalten-Grid für Entdecken (Quiet Luxury).
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

  static const double _spacing = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Immer 2 oder 3 Spalten – saubere Optik bei 12 Events pro Seite.
        final crossAxisCount = constraints.maxWidth >= 900 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
            childAspectRatio: crossAxisCount == 3 ? 0.78 : 0.82,
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
