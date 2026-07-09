import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Prominenter Button zum Nachladen weiterer Events.
class DiscoverLoadMoreFooter extends StatelessWidget {
  const DiscoverLoadMoreFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadedCount,
    required this.onLoadMore,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final int loadedCount;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore && !isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Text(
          loadedCount > 0
              ? 'Alle $loadedCount Events geladen.'
              : 'Keine weiteren Events.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        children: [
          if (loadedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$loadedCount Events geladen',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more, size: 26),
                label: const Text(
                  'Mehr Events laden',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.seed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
