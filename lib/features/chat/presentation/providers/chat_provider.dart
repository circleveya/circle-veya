import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/unconfigured_chat_repository.dart';
import '../../domain/entities/activity_share_payload.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRemoteDatasourceProvider = Provider<ChatRemoteDatasource>((ref) {
  return ChatRemoteDatasource(ref.watch(supabaseClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (!Env.isConfigured) {
    return const UnconfiguredChatRepository();
  }
  return ChatRepositoryImpl(ref.watch(chatRemoteDatasourceProvider));
});

final chatListProvider = StreamProvider.autoDispose<List<ChatSummary>>((ref) {
  return ref.watch(chatRepositoryProvider).watchChatList();
});

final unreadChatCountProvider = Provider<int>((ref) {
  final chats = ref.watch(chatListProvider).valueOrNull;
  if (chats == null) return 0;
  return chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);
});

final messagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});

final activityGroupChatProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, activityId) async {
  return ref.watch(chatRepositoryProvider).getActivityGroupChatId(activityId);
});

final chatWallpaperProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, chatId) async {
  return ref.watch(chatRepositoryProvider).getMyWallpaper(chatId);
});

class ChatActionsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  Future<String> startDmChat(String interestId) async {
    state = const AsyncLoading();
    String? chatId;
    state = await AsyncValue.guard(() async {
      chatId = await _repo.startDmChat(interestId);
    });
    if (state.hasError) throw state.error!;
    ref.invalidate(chatListProvider);
    return chatId!;
  }

  Future<String> startFriendChat(String friendId) async {
    state = const AsyncLoading();
    String? chatId;
    state = await AsyncValue.guard(() async {
      chatId = await _repo.startFriendChat(friendId);
    });
    if (state.hasError) throw state.error!;
    ref.invalidate(chatListProvider);
    return chatId!;
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    ChatMessageType messageType = ChatMessageType.text,
    String? mediaUrl,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.sendMessage(
        chatId: chatId,
        content: content,
        messageType: messageType,
        mediaUrl: mediaUrl,
      ),
    );
  }

  Future<void> sendActivityShare({
    required String chatId,
    required ActivitySharePayload payload,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.sendMessage(
        chatId: chatId,
        content: jsonEncode(payload.toJson()),
        messageType: ChatMessageType.activityShare,
        mediaUrl: payload.imageUrl,
      ),
    );
  }

  Future<void> sendMediaMessage({
    required String chatId,
    required XFile file,
    ChatMessageType messageType = ChatMessageType.image,
    String? caption,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final url = await _repo.uploadChatMedia(chatId: chatId, file: file);
      await _repo.sendMessage(
        chatId: chatId,
        content: caption?.trim().isNotEmpty == true
            ? caption!.trim()
            : (messageType == ChatMessageType.gif ? 'GIF' : 'Bild'),
        messageType: messageType,
        mediaUrl: url,
      );
    });
  }

  Future<void> setWallpaperFromFile({
    required String chatId,
    required XFile file,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.uploadWallpaper(chatId: chatId, file: file),
    );
    if (!state.hasError) {
      ref.invalidate(chatWallpaperProvider(chatId));
    }
  }

  Future<void> clearWallpaper(String chatId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.setMyWallpaper(chatId: chatId, wallpaperUrl: null),
    );
    if (!state.hasError) {
      ref.invalidate(chatWallpaperProvider(chatId));
    }
  }

  Future<void> leaveChat(String chatId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.leaveChat(chatId));
    if (!state.hasError) {
      ref.invalidate(chatListProvider);
    }
  }
}

final chatActionsProvider = AutoDisposeAsyncNotifierProvider<
    ChatActionsController, void>(ChatActionsController.new);
