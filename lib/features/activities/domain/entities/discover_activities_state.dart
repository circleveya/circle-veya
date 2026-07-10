import 'activity.dart';

/// Standard-Seitengröße für den Entdecken-Feed (genau 12 Events pro Seite).
const int discoverActivitiesPageSize = 12;

class DiscoverActivitiesState {
  const DiscoverActivitiesState({
    this.activities = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.page = 1,
    this.totalCount = 0,
    this.error,
  });

  final List<DiscoverableActivity> activities;
  final bool isLoading;
  final bool isLoadingMore;
  final int page;
  final int totalCount;
  final Object? error;

  int get totalPages {
    if (totalCount <= 0) return 1;
    return ((totalCount - 1) ~/ discoverActivitiesPageSize) + 1;
  }

  bool get hasPreviousPage => page > 1;

  bool get hasNextPage => page < totalPages;

  bool get isInitialLoading => isLoading && activities.isEmpty && error == null;

  bool get hasError => error != null && activities.isEmpty;

  DiscoverActivitiesState copyWith({
    List<DiscoverableActivity>? activities,
    bool? isLoading,
    bool? isLoadingMore,
    int? page,
    int? totalCount,
    Object? error,
    bool clearError = false,
  }) {
    return DiscoverActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
