import '../../activities/domain/entities/activity.dart';

/// Eine Feed-Zeile – einzelnes Event oder gruppierte Terminreihe.
class DiscoverFeedItem {
  const DiscoverFeedItem({
    required this.primary,
    required this.occurrences,
  });

  final DiscoverableActivity primary;
  final List<DiscoverableActivity> occurrences;

  bool get isGrouped => occurrences.length > 1;

  int get additionalOccurrenceCount => occurrences.length - 1;

  DiscoverableActivity get nextOccurrence {
    final sorted = List<DiscoverableActivity>.from(occurrences)
      ..sort((a, b) {
        final dateA = a.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });
    return sorted.first;
  }
}
