import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activities/domain/entities/activity.dart';
import '../../features/activities/presentation/screens/activity_detail_screen.dart';
import '../../features/activities/presentation/screens/edit_activity_screen.dart';
import '../../features/chat/domain/entities/chat.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/challenges/domain/entities/challenge.dart';
import '../../features/challenges/presentation/screens/challenge_detail_screen.dart';
import '../../features/gallery/presentation/screens/activity_gallery_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/profile_view_screen.dart';
import 'route_names.dart';

bool _isPublicRoute(String location) {
  if (location == '/login' || location == '/register') return true;
  return RegExp(r'^/activity/[^/]+$').hasMatch(location);
}

String? _redirectAfterLogin(GoRouterState state) {
  final target = state.uri.queryParameters['redirect']?.trim();
  if (target == null || target.isEmpty) return null;
  if (!target.startsWith('/') || target.startsWith('//')) return null;
  return target;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges,
    ),
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isLoading) return null;

      if (!isLoggedIn && !_isPublicRoute(state.matchedLocation)) {
        final returnTo = Uri.encodeComponent(state.uri.toString());
        return '/login?redirect=$returnTo';
      }
      if (isLoggedIn && isAuthRoute) {
        return _redirectAfterLogin(state) ?? '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/activity/:id',
        name: RouteNames.activityDetail,
        builder: (context, state) {
          final activity = state.extra as DiscoverableActivity?;
          return ActivityDetailScreen(
            activityId: state.pathParameters['id']!,
            activity: activity,
          );
        },
      ),
      GoRoute(
        path: '/activity/:id/edit',
        name: RouteNames.activityEdit,
        builder: (context, state) {
          final activity = state.extra as DiscoverableActivity?;
          if (activity == null) {
            return const Scaffold(
              body: Center(child: Text('Aktivität nicht gefunden')),
            );
          }
          return EditActivityScreen(activity: activity);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        name: RouteNames.chatRoom,
        builder: (context, state) {
          final chat = state.extra as ChatSummary?;
          return ChatRoomScreen(
            chatId: state.pathParameters['id']!,
            chat: chat,
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        name: RouteNames.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile/:id',
        name: RouteNames.profileView,
        builder: (context, state) {
          final isOwn = state.uri.queryParameters['own'] == 'true';
          return ProfileViewScreen(
            profileId: state.pathParameters['id']!,
            isOwnProfile: isOwn,
          );
        },
      ),
      GoRoute(
        path: '/gallery',
        name: RouteNames.gallery,
        builder: (context, state) => const PastActivitiesGalleryScreen(),
      ),
      GoRoute(
        path: '/activity/:id/gallery',
        name: RouteNames.activityGallery,
        builder: (context, state) {
          final title = state.extra as String?;
          final ownerId = state.uri.queryParameters['owner'];
          return ActivityGalleryScreen(
            activityId: state.pathParameters['id']!,
            activityTitle: title,
            ownerId: ownerId,
          );
        },
      ),
      GoRoute(
        path: '/groups/create',
        name: RouteNames.groupCreate,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:id',
        name: RouteNames.groupDetail,
        builder: (context, state) {
          final name = state.extra as String?;
          return GroupDetailScreen(
            groupId: state.pathParameters['id']!,
            groupName: name,
          );
        },
      ),
      GoRoute(
        path: '/challenges/:id',
        name: RouteNames.challengeDetail,
        builder: (context, state) {
          final challenge = state.extra as UserChallenge?;
          return ChallengeDetailScreen(
            challengeId: state.pathParameters['id']!,
            challenge: challenge,
          );
        },
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
