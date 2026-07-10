import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/sidebar_remote_datasource.dart';

final sidebarRemoteDatasourceProvider = Provider<SidebarRemoteDatasource>((ref) {
  return SidebarRemoteDatasource(ref.watch(supabaseClientProvider));
});

final trendingActivitiesProvider =
    FutureProvider.autoDispose<List<TrendingActivityItem>>((ref) async {
  ref.watch(sidebarRefreshTickProvider);
  return ref.watch(sidebarRemoteDatasourceProvider).getTrending();
});

final recommendedActivitiesProvider =
    FutureProvider.autoDispose<List<RecommendedActivityItem>>((ref) async {
  ref.watch(sidebarRefreshTickProvider);
  return ref.watch(sidebarRemoteDatasourceProvider).getRecommended();
});

final onlineFriendsProvider =
    FutureProvider.autoDispose<List<OnlineFriendItem>>((ref) async {
  ref.watch(sidebarRefreshTickProvider);
  return ref.watch(sidebarRemoteDatasourceProvider).getOnlineFriends();
});

/// Tick für periodisches Neuladen der Sidebar-Daten.
final sidebarRefreshTickProvider = StateProvider<int>((ref) => 0);

/// Sendet alle 45s einen Online-Heartbeat und aktualisiert die Sidebar.
final presenceHeartbeatProvider = Provider<void>((ref) {
  final datasource = ref.watch(sidebarRemoteDatasourceProvider);
  Timer? timer;

  Future<void> pulse() async {
    try {
      await datasource.heartbeatPresence();
      ref.read(sidebarRefreshTickProvider.notifier).state++;
    } catch (_) {
      // Heartbeat darf die App nicht blockieren.
    }
  }

  pulse();
  timer = Timer.periodic(const Duration(seconds: 45), (_) => pulse());

  ref.onDispose(() => timer?.cancel());
});

String sidebarErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('PGRST202') || text.contains('Could not find the function')) {
    return 'Sidebar-Funktion fehlt in der Datenbank. Migration 00014 ausführen.';
  }
  if (text.contains('non-volatile function')) {
    return 'Datenbank-Fix nötig: scripts/fixes/01_volatile_functions.sql ausführen.';
  }
  if (text.contains('Nicht authentifiziert')) {
    return 'Bitte erneut anmelden.';
  }
  return 'Daten konnten nicht geladen werden.';
}
