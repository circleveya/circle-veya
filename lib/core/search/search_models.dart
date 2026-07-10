import 'package:equatable/equatable.dart';

import '../layout/web_shell_destination.dart';

/// Such-Kontext abgeleitet vom aktiven Shell-Tab.
enum SearchContext {
  activities,
  friends,
  messages,
  feed,
  discover,
  general,
}

extension SearchContextX on SearchContext {
  String get label => switch (this) {
        SearchContext.activities => 'Aktivitäten',
        SearchContext.friends => 'Freunde',
        SearchContext.messages => 'Nachrichten',
        SearchContext.feed => 'Feed',
        SearchContext.discover => 'Entdecken',
        SearchContext.general => 'Alles',
      };

  String get hintText => switch (this) {
        SearchContext.activities => 'Eigene Aktivitäten suchen …',
        SearchContext.friends => 'Freunde oder Profile suchen …',
        SearchContext.messages => 'Chats suchen …',
        SearchContext.feed => 'Im Feed suchen …',
        SearchContext.discover => 'Events suchen …',
        SearchContext.general => 'Suchen …',
      };

  static SearchContext fromDestination(WebShellDestination destination) {
    return switch (destination) {
      WebShellDestination.myActivities => SearchContext.activities,
      WebShellDestination.friends ||
      WebShellDestination.profile =>
        SearchContext.friends,
      WebShellDestination.messages => SearchContext.messages,
      WebShellDestination.feed => SearchContext.feed,
      WebShellDestination.discover => SearchContext.discover,
      _ => SearchContext.general,
    };
  }
}

enum GlobalSearchResultType { activity, profile, chat }

class GlobalSearchResult extends Equatable {
  const GlobalSearchResult({
    required this.id,
    required this.title,
    required this.type,
    this.subtitle,
    this.imageUrl,
  });

  final String id;
  final String title;
  final GlobalSearchResultType type;
  final String? subtitle;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, title, type, subtitle, imageUrl];
}

class GlobalSearchState extends Equatable {
  const GlobalSearchState({
    this.query = '',
    this.isOverlayOpen = false,
  });

  final String query;
  final bool isOverlayOpen;

  bool get hasQuery => query.trim().length >= 2;

  GlobalSearchState copyWith({
    String? query,
    bool? isOverlayOpen,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      isOverlayOpen: isOverlayOpen ?? this.isOverlayOpen,
    );
  }

  @override
  List<Object?> get props => [query, isOverlayOpen];
}
