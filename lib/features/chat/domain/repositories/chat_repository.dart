import '../entities/chat.dart';

abstract class ChatRepository {
  Stream<List<ChatSummary>> watchChatList();

  Future<List<ChatSummary>> getChatList();

  Stream<List<ChatMessage>> watchMessages(String chatId);

  Future<void> sendMessage({
    required String chatId,
    required String content,
  });

  Future<void> markChatRead(String chatId);

  Future<String> startDmChat(String interestId);

  Future<String> startFriendChat(String friendId);

  Future<String?> getActivityGroupChatId(String activityId);

  Future<void> leaveChat(String chatId);
}
