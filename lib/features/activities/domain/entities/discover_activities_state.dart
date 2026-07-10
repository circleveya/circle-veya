import 'activity.dart';

/// Events pro Seite im Entdecken-Feed.
const int discoverActivitiesPageSize = 12;

/// Alias laut Spec: itemsPerPage = 12.
const int itemsPerPage = discoverActivitiesPageSize;

class DiscoverActivitiesState {
  const DiscoverActivitiesState({
    this.activities = const [],
    this.isLoading = false,
    this.currentPage = 0,
    this.totalCount = 0,
    this.error,
  });

  final List<DiscoverableActivity> activities;
  final bool isLoading;

  /// 0-basierter Seitenindex.
  final int currentPage;
  final int totalCount;
  final Object? error;

  /// Anzeige „Seite X“ (1-basiert).
  int get displayPage => currentPage + 1;

  bool get hasPreviousPage => currentPage > 0;

  /// Weiter nur, wenn eine volle Seite geladen wurde.
  bool get hasNextPage => activities.length >= itemsPerPage;

  bool get isInitialLoading => isLoading && activities.isEmpty && error == null;

  bool get hasError => error != null && activities.isEmpty;

  DiscoverActivitiesState copyWith({
    List<DiscoverableActivity>? activities,
    bool? isLoading,
    int? currentPage,
    int? totalCount,
    Object? error,
    bool clearError = false,
  }) {
    return DiscoverActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
