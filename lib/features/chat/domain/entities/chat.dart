import 'package:equatable/equatable.dart';

import '../../../../l10n/app_localizations.dart';
import 'activity_share_payload.dart';

enum ChatType {
  activityGroup,
  circleGroup,
  direct;

  static ChatType fromDb(String value) => switch (value) {
        'activity_group' => activityGroup,
        'circle_group' => circleGroup,
        _ => direct,
      };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        activityGroup => l10n.activity,
        circleGroup => l10n.circle,
        direct => l10n.direct,
      };

  String get label => switch (this) {
        activityGroup => 'Aktivität',
        circleGroup => 'Kreis',
        direct => 'Direkt',
      };
}

enum ChatMessageType {
  text,
  image,
  gif,
  activityShare;

  static ChatMessageType fromDb(String? value) => switch (value) {
        'image' => image,
        'gif' => gif,
        'activity_share' => activityShare,
        _ => text,
      };

  String get dbValue => switch (this) {
        text => 'text',
        image => 'image',
        gif => 'gif',
        activityShare => 'activity_share',
      };
}

class ChatSummary extends Equatable {
  const ChatSummary({
    required this.id,
    required this.type,
    this.activityId,
    this.circleGroupId,
    required this.title,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.unreadCount,
    this.otherUsername,
    this.avatarUrl,
    this.otherProfileId,
  });

  final String id;
  final ChatType type;
  final String? activityId;
  final String? circleGroupId;
  final String title;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final String? otherUsername;
  final String? avatarUrl;
  final String? otherProfileId;

  String get displayTitle {
    final other = otherUsername?.trim();
    if (type == ChatType.direct && other != null && other.isNotEmpty) {
      return other;
    }
    return title;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        activityId,
        circleGroupId,
        title,
        lastMessageAt,
        lastMessagePreview,
        unreadCount,
        otherUsername,
        avatarUrl,
        otherProfileId,
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
    this.messageType = ChatMessageType.text,
    this.mediaUrl,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String senderUsername;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  final ChatMessageType messageType;
  final String? mediaUrl;

  bool get hasMedia =>
      mediaUrl != null &&
      mediaUrl!.isNotEmpty &&
      (messageType == ChatMessageType.image ||
          messageType == ChatMessageType.gif);

  ActivitySharePayload? get activityShare {
    if (messageType != ChatMessageType.activityShare) return null;
    final parsed = ActivitySharePayload.fromMessageContent(content);
    if (parsed == null) return null;

    final thumb = parsed.imageUrl?.trim();
    final media = mediaUrl?.trim();
    if ((thumb == null || thumb.isEmpty) && media != null && media.isNotEmpty) {
      return ActivitySharePayload(
        activityId: parsed.activityId,
        title: parsed.title,
        url: parsed.url,
        caption: parsed.caption,
        imageUrl: media,
      );
    }
    return parsed;
  }

  bool get isActivityShare => activityShare != null;

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderUsername,
        content,
        createdAt,
        isMine,
        messageType,
        mediaUrl,
      ];
}
