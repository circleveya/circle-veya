import '../../features/activities/domain/entities/activity.dart';

/// Clientseitige Sortierung nach Nähe (Distanzfilter läuft serverseitig).
abstract final class ActivityDistanceFilter {
  static List<DiscoverableActivity> apply(
    List<DiscoverableActivity> activities, {
    double? maxDistanceKm,
  }) {
    var result = List<DiscoverableActivity>.from(activities);

    if (maxDistanceKm != null) {
      result = result.where((activity) {
        final distance = activity.distanceKm;
        if (distance == null) return false;
        return distance <= maxDistanceKm;
      }).toList();
    }

    result.sort((a, b) {
      final rankA = _sortRank(a);
      final rankB = _sortRank(b);
      if (rankA != rankB) return rankA.compareTo(rankB);

      final dateA = a.dateTime ?? DateTime.fromMillisecondsSinceEpoch(9999999999999);
      final dateB = b.dateTime ?? DateTime.fromMillisecondsSinceEpoch(9999999999999);
      if (dateA != dateB) return dateA.compareTo(dateB);

      final distA = a.distanceKm ?? double.infinity;
      final distB = b.distanceKm ?? double.infinity;
      return distA.compareTo(distB);
    });

    return result;
  }

  static int _sortRank(DiscoverableActivity activity) {
    if (activity.isFeatured) return 0;
    if (activity.isExternal) return 1;
    return 2;
  }
}
