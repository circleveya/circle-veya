import 'package:flutter/material.dart';

/// Footer für paginiertes Laden im Entdecken-Feed.
class DiscoverLoadMoreFooter extends StatelessWidget {
  const DiscoverLoadMoreFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (!hasMore) {
      return const SizedBox(height: 24);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: OutlinedButton.icon(
        onPressed: onLoadMore,
        icon: const Icon(Icons.expand_more),
        label: const Text('Mehr Events laden'),
      ),
    );
  }
}
