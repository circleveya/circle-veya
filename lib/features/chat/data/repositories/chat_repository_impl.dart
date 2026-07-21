import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatFailure extends Failure {
  const ChatFailure(super.message);
}

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._datasource);

  final ChatRemoteDatasource _datasource;

  @override
  Stream<List<ChatSummary>> watchChatList() async* {
    yield await getChatList();
    await for (final _ in Stream.periodic(const Duration(seconds: 8))) {
      yield await getChatList();
    }
  }

  @override
  Future<List<ChatSummary>> getChatList() async {
    try {
      return await _datasource.getChatList();
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _datasource.watchMessages(chatId);
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
    ChatMessageType messageType = ChatMessageType.text,
    String? mediaUrl,
  }) async {
    try {
      await _datasource.sendMessage(
        chatId: chatId,
        content: content,
        messageType: messageType,
        mediaUrl: mediaUrl,
      );
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<String> uploadChatMedia({
    required String chatId,
    required XFile file,
  }) async {
    try {
      return await _datasource.uploadChatMedia(chatId: chatId, file: file);
    } on StorageException catch (error) {
      throw ChatFailure(error.message);
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<String?> getMyWallpaper(String chatId) async {
    try {
      return await _datasource.getMyWallpaper(chatId);
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<void> setMyWallpaper({
    required String chatId,
    String? wallpaperUrl,
  }) async {
    try {
      await _datasource.setMyWallpaper(
        chatId: chatId,
        wallpaperUrl: wallpaperUrl,
      );
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<String> uploadWallpaper({
    required String chatId,
    required XFile file,
  }) async {
    try {
      return await _datasource.uploadWallpaper(chatId: chatId, file: file);
    } on StorageException catch (error) {
      throw ChatFailure(error.message);
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<void> markChatRead(String chatId) async {
    try {
      await _datasource.markChatRead(chatId);
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<String> startDmChat(String interestId) async {
    try {
      return await _datasource.startDmChat(interestId);
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<String> startFriendChat(String friendId) async {
    try {
      return await _datasource.startFriendChat(friendId);
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<String?> getActivityGroupChatId(String activityId) async {
    try {
      return await _datasource.getActivityGroupChatId(activityId);
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }

  @override
  Future<void> leaveChat(String chatId) async {
    try {
      await _datasource.leaveChat(chatId);
    } on PostgrestException catch (error) {
      throw ChatFailure(error.message);
    }
  }
}
