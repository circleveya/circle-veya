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

class NotificationsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  NotificationsRemoteDatasource get _ds =>
      ref.read(notificationsRemoteDatasourceProvider);

  Future<void> markAsRead(String notificationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _ds.markAsRead(notificationId));
    if (!state.hasError) {
      ref.invalidate(notificationsStreamProvider);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_ds.markAllAsRead);
    if (!state.hasError) {
      ref.invalidate(notificationsStreamProvider);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _ds.deleteNotification(notificationId));
    if (!state.hasError) {
      ref.invalidate(notificationsStreamProvider);
    }
  }

  Future<void> deleteAll() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_ds.deleteAllNotifications);
    if (!state.hasError) {
      ref.invalidate(notificationsStreamProvider);
    }
  }
}

final notificationsControllerProvider =
    AutoDisposeAsyncNotifierProvider<NotificationsController, void>(
  NotificationsController.new,
);
