import 'package:equatable/equatable.dart';

import 'activity_filters.dart';

class ActivityDiscoverFilters extends Equatable {
  const ActivityDiscoverFilters({
    this.locationType,
    this.weatherCondition,
  });

  final LocationType? locationType;
  final WeatherCondition? weatherCondition;

  bool get hasActiveFilters =>
      locationType != null || weatherCondition != null;

  ActivityDiscoverFilters copyWith({
    LocationType? locationType,
    bool clearLocationType = false,
    WeatherCondition? weatherCondition,
    bool clearWeatherCondition = false,
  }) {
    return ActivityDiscoverFilters(
      locationType: clearLocationType ? null : (locationType ?? this.locationType),
      weatherCondition: clearWeatherCondition
          ? null
          : (weatherCondition ?? this.weatherCondition),
    );
  }

  const ActivityDiscoverFilters.empty() : this();

  @override
  List<Object?> get props => [locationType, weatherCondition];
}
