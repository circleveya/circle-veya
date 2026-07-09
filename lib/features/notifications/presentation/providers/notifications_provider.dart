import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/notifications_remote_datasource.dart';

final notificationsRemoteDatasourceProvider =
    Provider<NotificationsRemoteDatasource>((ref) {
  return NotificationsRemoteDatasource(ref.watch(supabaseClientProvider));
});

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationsRemoteDatasourceProvider).watchNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).valueOrNull;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.isRead).length;
});
