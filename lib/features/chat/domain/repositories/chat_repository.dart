import 'package:image_picker/image_picker.dart';

import '../entities/chat.dart';

abstract class ChatRepository {
  Stream<List<ChatSummary>> watchChatList();

  Future<List<ChatSummary>> getChatList();

  Stream<List<ChatMessage>> watchMessages(String chatId);

  Future<void> sendMessage({
    required String chatId,
    required String content,
    ChatMessageType messageType = ChatMessageType.text,
    String? mediaUrl,
  });

  Future<String> uploadChatMedia({
    required String chatId,
    required XFile file,
  });

  Future<String?> getMyWallpaper(String chatId);

  Future<void> setMyWallpaper({
    required String chatId,
    String? wallpaperUrl,
  });

  Future<String> uploadWallpaper({
    required String chatId,
    required XFile file,
  });

  Future<void> markChatRead(String chatId);

  Future<String> startDmChat(String interestId);

  Future<String> startFriendChat(String friendId);

  Future<String?> getActivityGroupChatId(String activityId);

  Future<void> leaveChat(String chatId);
}
