import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activities/presentation/providers/activity_provider.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/friends/presentation/providers/friends_provider.dart';
import '../layout/shell_destination_provider.dart';
import '../layout/web_shell_destination.dart';
import 'search_models.dart';

final searchContextProvider = Provider<SearchContext>((ref) {
  final destination = ref.watch(shellDestinationProvider);
  return SearchContextX.fromDestination(destination);
});

class GlobalSearchController extends Notifier<GlobalSearchState> {
  Timer? _debounce;

  @override
  GlobalSearchState build() {
    ref.onDispose(() => _debounce?.cancel());

    // Tab-Wechsel: Overlay schließen, Query behalten oder leeren.
    ref.listen<WebShellDestination>(shellDestinationProvider, (prev, next) {
      if (prev == next) return;
      state = state.copyWith(isOverlayOpen: false);
    });

    return const GlobalSearchState();
  }

  void setQuery(String value) {
    final trimmed = value.trimLeft();
    state = state.copyWith(
      query: trimmed,
      isOverlayOpen: trimmed.trim().length >= 2,
    );

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      // Provider invalidiert sich über query-Abhängigkeit selbst.
      state = state.copyWith(query: trimmed.trim());
    });
  }

  void openOverlay() {
    if (state.hasQuery) {
      state = state.copyWith(isOverlayOpen: true);
    }
  }

  void closeOverlay() {
    state = state.copyWith(isOverlayOpen: false);
  }

  void clear() {
    _debounce?.cancel();
    state = const GlobalSearchState();
  }
}

final globalSearchProvider =
    NotifierProvider<GlobalSearchController, GlobalSearchState>(
  GlobalSearchController.new,
);

/// Kontextsensitive Suchergebnisse für den Header.
final globalSearchResultsProvider =
    FutureProvider.autoDispose<List<GlobalSearchResult>>((ref) async {
  final search = ref.watch(globalSearchProvider);
  final context = ref.watch(searchContextProvider);
  final query = search.query.trim();

  if (query.length < 2) return [];

  return switch (context) {
    SearchContext.activities => _searchMyActivities(ref, query),
    SearchContext.friends => _searchFriends(ref, query),
    SearchContext.messages => _searchChats(ref, query),
    SearchContext.feed => _searchFeed(ref, query),
    SearchContext.discover => _searchDiscover(ref, query),
    SearchContext.general => _searchGeneral(ref, query),
  };
});

Future<List<GlobalSearchResult>> _searchMyActivities(
  Ref ref,
  String query,
) async {
  final activities = await ref.watch(myActivitiesProvider.future);
  final q = query.toLowerCase();

  return activities
      .where((a) {
        final hay = '${a.title} ${a.locationName ?? ''}'.toLowerCase();
        return hay.contains(q);
      })
      .take(12)
      .map(
        (a) => GlobalSearchResult(
          id: a.id,
          title: a.title,
          type: GlobalSearchResultType.activity,
          subtitle: a.locationName,
          imageUrl: a.imageUrl,
        ),
      )
      .toList();
}

Future<List<GlobalSearchResult>> _searchFriends(Ref ref, String query) async {
  final connections = await ref.watch(myConnectionsProvider.future);
  final q = query.toLowerCase();
  final fromConnections = connections
      .where((c) => c.username.toLowerCase().contains(q))
      .map(
        (c) => GlobalSearchResult(
          id: c.profileId,
          title: c.username,
          type: GlobalSearchResultType.profile,
          subtitle: c.type.label,
          imageUrl: c.avatarUrl,
        ),
      );

  final fromRpc = await ref.watch(profileSearchProvider(query).future);
  final rpcResults = fromRpc.map(
    (p) => GlobalSearchResult(
      id: p.id,
      title: p.username,
      type: GlobalSearchResultType.profile,
      subtitle: p.bio,
      imageUrl: p.avatarUrl,
    ),
  );

  final seen = <String>{};
  final merged = <GlobalSearchResult>[];
  for (final item in [...fromConnections, ...rpcResults]) {
    if (seen.add(item.id)) merged.add(item);
  }
  return merged.take(12).toList();
}

Future<List<GlobalSearchResult>> _searchChats(Ref ref, String query) async {
  final chats = await ref.watch(chatListProvider.future);
  final q = query.toLowerCase();

  return chats
      .where((c) {
        final hay =
            '${c.title} ${c.otherUsername ?? ''} ${c.lastMessagePreview ?? ''}'
                .toLowerCase();
        return hay.contains(q);
      })
      .take(12)
      .map(
        (c) => GlobalSearchResult(
          id: c.id,
          title: c.title,
          type: GlobalSearchResultType.chat,
          subtitle: c.lastMessagePreview ?? c.otherUsername,
        ),
      )
      .toList();
}

Future<List<GlobalSearchResult>> _searchFeed(Ref ref, String query) async {
  final activities = await ref.watch(socialFeedProvider.future);
  final q = query.toLowerCase();

  return activities
      .where((a) {
        final hay =
            '${a.title} ${a.hostUsername} ${a.locationName ?? ''}'.toLowerCase();
        return hay.contains(q);
      })
      .take(12)
      .map(
        (a) => GlobalSearchResult(
          id: a.id,
          title: a.title,
          type: GlobalSearchResultType.activity,
          subtitle: a.hostUsername,
          imageUrl: a.imageUrl,
        ),
      )
      .toList();
}

Future<List<GlobalSearchResult>> _searchDiscover(Ref ref, String query) async {
  final state = ref.watch(discoverActivitiesProvider);
  final q = query.toLowerCase();

  return state.activities
      .where((a) {
        final hay = '${a.title} ${a.locationName ?? ''}'.toLowerCase();
        return hay.contains(q);
      })
      .take(12)
      .map(
        (a) => GlobalSearchResult(
          id: a.id,
          title: a.title,
          type: GlobalSearchResultType.activity,
          subtitle: a.locationName,
          imageUrl: a.imageUrl,
        ),
      )
      .toList();
}

Future<List<GlobalSearchResult>> _searchGeneral(Ref ref, String query) async {
  final friends = await _searchFriends(ref, query);
  final activities = await _searchMyActivities(ref, query);
  return [...friends.take(6), ...activities.take(6)];
}
