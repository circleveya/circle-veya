import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/chat.dart';

class ChatRemoteDatasource {
  ChatRemoteDatasource(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<ChatSummary>> getChatList() async {
    final response = await _client.rpc('get_my_chats');
    return (response as List)
        .map((row) => _mapChatSummary(row as Map<String, dynamic>))
        .toList();
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .asyncMap((rows) async {
          final profiles = await _loadSenderProfiles(rows);
          return rows
              .where((row) => row['deleted_at'] == null)
              .map((row) => _mapMessage(row, userId, profiles))
              .toList();
        });
  }

  Future<Map<String, String>> _loadSenderProfiles(
    List<Map<String, dynamic>> rows,
  ) async {
    final senderIds = rows
        .map((row) => row['sender_id'] as String)
        .toSet()
        .toList();

    if (senderIds.isEmpty) return {};

    final response = await _client
        .from('profiles')
        .select('id, username')
        .inFilter('id', senderIds);

    return {
      for (final row in response as List)
        (row as Map<String, dynamic>)['id'] as String:
            row['username'] as String,
    };
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('Nicht angemeldet');
    }

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': userId,
      'content': content.trim(),
    });
  }

  Future<void> markChatRead(String chatId) async {
    await _client.rpc('mark_chat_read', params: {'p_chat_id': chatId});
  }

  Future<String> startDmChat(String interestId) async {
    final response = await _client.rpc(
      'start_dm_chat',
      params: {'p_interest_id': interestId},
    );
    return response as String;
  }

  Future<String> startFriendChat(String friendId) async {
    final response = await _client.rpc(
      'get_or_create_friend_chat',
      params: {'p_friend_id': friendId},
    );
    return response as String;
  }

  Future<String?> getActivityGroupChatId(String activityId) async {
    final response = await _client.rpc(
      'get_activity_group_chat_id',
      params: {'p_activity_id': activityId},
    );
    return response as String?;
  }

  Future<void> leaveChat(String chatId) async {
    await _client.rpc('leave_chat', params: {'p_chat_id': chatId});
  }

  ChatSummary _mapChatSummary(Map<String, dynamic> map) {
    return ChatSummary(
      id: map['id'] as String,
      type: ChatType.fromDb(map['type'] as String),
      activityId: map['activity_id'] as String?,
      title: map['title'] as String,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      lastMessagePreview: map['last_message_preview'] as String?,
      unreadCount: (map['unread_count'] as num).toInt(),
      otherUsername: map['other_username'] as String?,
    );
  }

  ChatMessage _mapMessage(
    Map<String, dynamic> map,
    String userId,
    Map<String, String> profiles,
  ) {
    final senderId = map['sender_id'] as String;
    return ChatMessage(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      senderId: senderId,
      senderUsername: profiles[senderId] ?? 'User',
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isMine: senderId == userId,
    );
  }
}
