import 'package:flutter/material.dart';

import '../../../activities/domain/entities/activity.dart';
import 'discover_grid_card.dart';

/// Responsives Aktivitäten-Grid für Entdecken.
class DiscoverActivityGrid extends StatelessWidget {
  const DiscoverActivityGrid({
    super.key,
    required this.activities,
    required this.onTap,
    this.onAction,
    this.isActionLoading = false,
  });

  final List<DiscoverableActivity> activities;
  final void Function(DiscoverableActivity activity) onTap;
  final void Function(DiscoverableActivity activity)? onAction;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 3
            : width >= 700
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
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return DiscoverGridCard(
              activity: activity,
              isLoading: isActionLoading,
              onTap: () => onTap(activity),
              onAction: onAction != null ? () => onAction!(activity) : null,
            );
          },
        );
      },
    );
  }
}
