import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/supabase_client.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/unconfigured_chat_repository.dart';
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
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.sendMessage(chatId: chatId, content: content),
    );
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
