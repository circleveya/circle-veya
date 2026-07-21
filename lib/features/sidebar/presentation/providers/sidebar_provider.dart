import 'dart:async';

import 'package:flutter/widgets.dart';
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

/// Sendet alle 30s einen Online-Heartbeat solange die App sichtbar ist.
/// Beim Verlassen/Hintergrund → sofort offline.
final presenceHeartbeatProvider = Provider<void>((ref) {
  final datasource = ref.watch(sidebarRemoteDatasourceProvider);
  Timer? timer;
  AppLifecycleListener? lifecycle;
  var isActive = true;

  Future<void> pulse() async {
    if (!isActive) return;
    try {
      await datasource.heartbeatPresence();
      ref.read(sidebarRefreshTickProvider.notifier).state++;
    } catch (_) {
      // Heartbeat darf die App nicht blockieren.
    }
  }

  Future<void> goOffline() async {
    isActive = false;
    timer?.cancel();
    timer = null;
    try {
      await datasource.leavePresence();
      ref.read(sidebarRefreshTickProvider.notifier).state++;
    } catch (_) {
      // Offline-Signal ist best-effort.
    }
  }

  void goOnline() {
    if (isActive && timer != null) return;
    isActive = true;
    timer?.cancel();
    pulse();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => pulse());
  }

  goOnline();

  lifecycle = AppLifecycleListener(
    onResume: goOnline,
    onShow: goOnline,
    onHide: () {
      unawaited(goOffline());
    },
    onPause: () {
      unawaited(goOffline());
    },
    onDetach: () {
      unawaited(goOffline());
    },
    onInactive: () {
      // Kurz inaktiv (z.B. Systemdialog) – noch online lassen.
    },
  );

  ref.onDispose(() {
    lifecycle?.dispose();
    timer?.cancel();
    unawaited(datasource.leavePresence());
  });
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
