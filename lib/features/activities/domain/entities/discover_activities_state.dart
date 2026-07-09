import 'activity.dart';

/// Standard-Seitengröße für den Entdecken-Feed (entspricht `.range(from, to)`).
const int discoverActivitiesPageSize = 10;

class DiscoverActivitiesState {
  const DiscoverActivitiesState({
    this.activities = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<DiscoverableActivity> activities;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get isInitialLoading => isLoading && activities.isEmpty && error == null;

  bool get hasError => error != null && activities.isEmpty;

  DiscoverActivitiesState copyWith({
    List<DiscoverableActivity>? activities,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return DiscoverActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
