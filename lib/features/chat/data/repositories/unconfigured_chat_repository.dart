import 'package:image_picker/image_picker.dart';

import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';

class UnconfiguredChatRepository implements ChatRepository {
  const UnconfiguredChatRepository();

  static const _message = 'Supabase ist nicht konfiguriert. Chat nicht verfügbar.';

  Never _throw() => throw UnsupportedError(_message);

  @override
  Future<String?> getActivityGroupChatId(String activityId) async => null;

  @override
  Future<List<ChatSummary>> getChatList() async => [];

  @override
  Future<void> markChatRead(String chatId) async => _throw();

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
    ChatMessageType messageType = ChatMessageType.text,
    String? mediaUrl,
  }) async =>
      _throw();

  @override
  Future<String> uploadChatMedia({
    required String chatId,
    required XFile file,
  }) async =>
      _throw();

  @override
  Future<String?> getMyWallpaper(String chatId) async => null;

  @override
  Future<void> setMyWallpaper({
    required String chatId,
    String? wallpaperUrl,
  }) async =>
      _throw();

  @override
  Future<String> uploadWallpaper({
    required String chatId,
    required XFile file,
  }) async =>
      _throw();

  @override
  Future<String> startDmChat(String interestId) async => _throw();

  @override
  Future<String> startFriendChat(String friendId) async => _throw();

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) => Stream.value([]);

  @override
  Stream<List<ChatSummary>> watchChatList() => Stream.value([]);

  @override
  Future<void> leaveChat(String chatId) async => _throw();
}
