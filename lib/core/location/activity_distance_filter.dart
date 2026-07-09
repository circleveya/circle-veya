import '../../features/activities/domain/entities/activity.dart';

/// Clientseitige Entfernungs-Filterung und Sortierung nach Nähe.
abstract final class ActivityDistanceFilter {
  static List<DiscoverableActivity> apply(
    List<DiscoverableActivity> activities, {
    double? maxDistanceKm,
  }) {
    var result = List<DiscoverableActivity>.from(activities);

    if (maxDistanceKm != null) {
      result = result.where((activity) {
        final distance = activity.distanceKm;
        if (distance == null) {
          // Externe Events ohne Koordinate weiter anzeigen.
          return activity.isExternal;
        }
        return distance <= maxDistanceKm;
      }).toList();
    }

    result.sort((a, b) {
      final rankA = _sortRank(a);
      final rankB = _sortRank(b);
      if (rankA != rankB) return rankA.compareTo(rankB);

      final distA = a.distanceKm ?? double.infinity;
      final distB = b.distanceKm ?? double.infinity;
      if (distA != distB) return distA.compareTo(distB);

      final dateA = a.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateA.compareTo(dateB);
    });

    return result;
  }

  static int _sortRank(DiscoverableActivity activity) {
    if (activity.isFeatured) return 0;
    if (activity.isExternal) return 1;
    return 2;
  }
}
