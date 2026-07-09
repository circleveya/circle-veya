import 'package:equatable/equatable.dart';

import '../../../../core/location/user_location.dart';
import 'activity_filters.dart';
import 'discover_date_filter.dart';

class ActivityDiscoverFilters extends Equatable {
  const ActivityDiscoverFilters({
    this.locationType,
    this.weatherCondition,
    this.maxDistanceKm,
    this.distanceOption = DistanceFilterOption.everywhere,
    this.dateFilter = DiscoverDateFilterOption.all,
    this.customDateFrom,
    this.customDateTo,
  });

  final LocationType? locationType;
  final WeatherCondition? weatherCondition;
  final double? maxDistanceKm;
  final DistanceFilterOption distanceOption;
  final DiscoverDateFilterOption dateFilter;
  final DateTime? customDateFrom;
  final DateTime? customDateTo;

  ({DateTime? start, DateTime? end}) get dateRange => dateFilter.resolveRange(
        customStart: customDateFrom,
        customEnd: customDateTo,
      );

  bool get hasActiveFilters =>
      locationType != null ||
      weatherCondition != null ||
      maxDistanceKm != null ||
      dateFilter != DiscoverDateFilterOption.all;

  ActivityDiscoverFilters copyWith({
    LocationType? locationType,
    bool clearLocationType = false,
    WeatherCondition? weatherCondition,
    bool clearWeatherCondition = false,
    double? maxDistanceKm,
    bool clearMaxDistance = false,
    DistanceFilterOption? distanceOption,
    DiscoverDateFilterOption? dateFilter,
    DateTime? customDateFrom,
    DateTime? customDateTo,
    bool clearCustomDateRange = false,
  }) {
    return ActivityDiscoverFilters(
      locationType: clearLocationType ? null : (locationType ?? this.locationType),
      weatherCondition: clearWeatherCondition
          ? null
          : (weatherCondition ?? this.weatherCondition),
      maxDistanceKm:
          clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      distanceOption: distanceOption ?? this.distanceOption,
      dateFilter: dateFilter ?? this.dateFilter,
      customDateFrom: clearCustomDateRange
          ? null
          : (customDateFrom ?? this.customDateFrom),
      customDateTo:
          clearCustomDateRange ? null : (customDateTo ?? this.customDateTo),
    );
  }

  const ActivityDiscoverFilters.empty() : this();

  @override
  List<Object?> get props => [
        locationType,
        weatherCondition,
        maxDistanceKm,
        distanceOption,
        dateFilter,
        customDateFrom,
        customDateTo,
      ];
}
