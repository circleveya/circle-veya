import 'package:equatable/equatable.dart';

enum ChatType {
  activityGroup,
  direct;

  static ChatType fromDb(String value) => switch (value) {
        'activity_group' => activityGroup,
        _ => direct,
      };

  String get label => switch (this) {
        activityGroup => 'Gruppe',
        direct => 'Direkt',
      };
}

class ChatSummary extends Equatable {
  const ChatSummary({
    required this.id,
    required this.type,
    this.activityId,
    required this.title,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.unreadCount,
    this.otherUsername,
  });

  final String id;
  final ChatType type;
  final String? activityId;
  final String title;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final String? otherUsername;

  @override
  List<Object?> get props => [
        id,
        type,
        activityId,
        title,
        lastMessageAt,
        lastMessagePreview,
        unreadCount,
        otherUsername,
      ];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String senderUsername;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderUsername,
        content,
        createdAt,
        isMine,
      ];
}
