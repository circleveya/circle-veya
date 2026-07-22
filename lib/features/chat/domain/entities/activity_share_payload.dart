import 'dart:convert';

import '../../../../core/utils/share_links.dart';

/// Event-Link in Chat-Nachrichten (WhatsApp-Style Vorschau).
class ActivitySharePayload {
  const ActivitySharePayload({
    required this.activityId,
    required this.title,
    required this.url,
    this.caption,
    this.imageUrl,
  });

  final String activityId;
  final String title;
  final String url;
  final String? caption;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
        'activity_id': activityId,
        'title': title,
        'url': url,
        if (caption != null && caption!.trim().isNotEmpty)
          'caption': caption!.trim(),
        if (imageUrl != null && imageUrl!.trim().isNotEmpty)
          'image_url': imageUrl!.trim(),
      };

  static ActivitySharePayload? fromJson(Map<String, dynamic> json) {
    final activityId = json['activity_id']?.toString().trim();
    final title = json['title']?.toString().trim();
    if (activityId == null ||
        activityId.isEmpty ||
        title == null ||
        title.isEmpty) {
      return null;
    }

    final url = json['url']?.toString().trim();
    return ActivitySharePayload(
      activityId: activityId,
      title: title,
      url: url?.isNotEmpty == true
          ? url!
          : CircleShareLinks.activity(activityId),
      caption: json['caption']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  static ActivitySharePayload? fromMessageContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
