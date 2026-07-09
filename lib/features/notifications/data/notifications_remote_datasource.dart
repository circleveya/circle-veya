import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
}

class NotificationsRemoteDatasource {
  NotificationsRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> getNotifications({int limit = 20}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('notifications')
        .select('id, title, message, type, is_read, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return AppNotification(
        id: map['id'] as String,
        title: map['title'] as String,
        message: map['message'] as String,
        type: map['type'] as String,
        isRead: map['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Stream<List<AppNotification>> watchNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20)
        .map(
          (rows) => rows
              .map(
                (map) => AppNotification(
                  id: map['id'] as String,
                  title: map['title'] as String,
                  message: map['message'] as String,
                  type: map['type'] as String,
                  isRead: map['is_read'] as bool? ?? false,
                  createdAt: DateTime.parse(map['created_at'] as String),
                ),
              )
              .toList(),
        );
  }
}
