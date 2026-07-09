import '../../features/activities/domain/entities/activity.dart';
import '../../features/activities/domain/entities/activity_enums.dart';

/// Datenschutz-konforme Entfernungs- und Ortsanzeige.
abstract final class DistanceDisplay {
  /// Gerundete Entfernung – nie exakte Meter.
  static String formatDistanceKm(double? distanceKm) {
    if (distanceKm == null) return 'In deiner Region';
    if (distanceKm < 0.5) return 'In deiner Nähe';
    if (distanceKm < 1) return 'weniger als 1 km entfernt';
    if (distanceKm < 10) {
      return '${distanceKm.round()} km entfernt';
    }
    final rounded = (distanceKm / 5).round() * 5;
    return '$rounded km entfernt';
  }

  static String forActivity(DiscoverableActivity activity) =>
      formatDistanceKm(activity.distanceKm);

  /// Exakte Adresse nur für Freunde / eigene Events.
  static bool showExactPlace(DiscoverableActivity activity) {
    return activity.viewerAction == ViewerAction.host ||
        activity.visibleAs == VisibleAs.friend;
  }

  static String? placeLabel(DiscoverableActivity activity) {
    if (!showExactPlace(activity)) return null;
    final name = activity.locationName?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  static String locationLine(DiscoverableActivity activity) {
    final distance = forActivity(activity);
    final place = placeLabel(activity);
    if (place != null) return '$place · $distance';
    return distance;
  }
}
