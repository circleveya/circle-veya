import '../../activities/domain/entities/activity.dart';
import 'discover_feed_item.dart';

/// Fasst identische Events (Titel + Ort) zu einer Feed-Zeile zusammen.
abstract final class DiscoverActivityGrouper {
  static List<DiscoverFeedItem> group(List<DiscoverableActivity> activities) {
    final buckets = <String, List<DiscoverableActivity>>{};

    for (final activity in activities) {
      final key = _groupKey(activity);
      buckets.putIfAbsent(key, () => []).add(activity);
    }

    final items = buckets.values.map((occurrences) {
      final sorted = List<DiscoverableActivity>.from(occurrences)
        ..sort(_compareByDate);
      return DiscoverFeedItem(primary: sorted.first, occurrences: sorted);
    }).toList();

    items.sort((a, b) => _compareByDate(a.primary, b.primary));
    return items;
  }

  static String _groupKey(DiscoverableActivity activity) {
    return '${_normalize(activity.title)}|${_normalize(activity.locationName ?? '')}';
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static int _compareByDate(DiscoverableActivity a, DiscoverableActivity b) {
    final featuredA = a.isFeatured ? 0 : 1;
    final featuredB = b.isFeatured ? 0 : 1;
    if (featuredA != featuredB) return featuredA.compareTo(featuredB);

    final dateA = a.dateTime ?? DateTime.fromMillisecondsSinceEpoch(9999999999999);
    final dateB = b.dateTime ?? DateTime.fromMillisecondsSinceEpoch(9999999999999);
    return dateA.compareTo(dateB);
  }
}
