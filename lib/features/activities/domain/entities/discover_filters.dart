import 'package:equatable/equatable.dart';

import '../../../../core/location/user_location.dart';
import 'activity_filters.dart';

class ActivityDiscoverFilters extends Equatable {
  const ActivityDiscoverFilters({
    this.locationType,
    this.weatherCondition,
    this.maxDistanceKm,
    this.distanceOption = DistanceFilterOption.everywhere,
  });

  final LocationType? locationType;
  final WeatherCondition? weatherCondition;
  final double? maxDistanceKm;
  final DistanceFilterOption distanceOption;

  bool get hasActiveFilters =>
      locationType != null ||
      weatherCondition != null ||
      maxDistanceKm != null;

  ActivityDiscoverFilters copyWith({
    LocationType? locationType,
    bool clearLocationType = false,
    WeatherCondition? weatherCondition,
    bool clearWeatherCondition = false,
    double? maxDistanceKm,
    bool clearMaxDistance = false,
    DistanceFilterOption? distanceOption,
  }) {
    return ActivityDiscoverFilters(
      locationType: clearLocationType ? null : (locationType ?? this.locationType),
      weatherCondition: clearWeatherCondition
          ? null
          : (weatherCondition ?? this.weatherCondition),
      maxDistanceKm:
          clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      distanceOption: distanceOption ?? this.distanceOption,
    );
  }

  const ActivityDiscoverFilters.empty() : this();

  @override
  List<Object?> get props => [
        locationType,
        weatherCondition,
        maxDistanceKm,
        distanceOption,
      ];
}
