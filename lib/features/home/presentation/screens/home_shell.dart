import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/shell_destination_provider.dart';
import '../../../../core/layout/shell_destination_request.dart';
import '../../../../core/layout/web_layout_scaffold.dart';
import '../../../../core/layout/web_shell_destination.dart';
import '../../../../core/branding/circleveya_brand.dart';
import '../../../../core/l10n/language_switcher_button.dart';
import '../../../../core/router/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../sidebar/presentation/providers/sidebar_provider.dart';
import '../../../discovery/presentation/screens/discover_feed_screen.dart';
import '../../../activities/presentation/screens/create_activity_screen.dart';
import '../../../activities/presentation/screens/my_activities_screen.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../friends/presentation/screens/friends_screen.dart';
import '../../../gallery/presentation/screens/activity_gallery_screen.dart';
import '../../../groups/presentation/screens/groups_screen.dart';
import '../../../profile/presentation/screens/profile_view_screen.dart';
import '../../../challenges/presentation/screens/challenges_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  // Legacy-Index für Mobile-Bottom-Nav
  int _mobileIndexFor(WebShellDestination destination) => switch (destination) {
        WebShellDestination.discover => 0,
        WebShellDestination.create => 1,
        WebShellDestination.myActivities => 2,
        WebShellDestination.friends => 3,
        WebShellDestination.messages => 4,
        _ => 0,
      };

  void _onDestinationChanged(WebShellDestination dest) {
    ref.read(shellDestinationProvider.notifier).set(dest);
  }

  Widget _bodyFor(WebShellDestination dest, {bool embedded = false}) {
    final userId = ref.read(authStateProvider).valueOrNull?.id;

    return switch (dest) {
      WebShellDestination.create => const CreateActivityScreen(),
      WebShellDestination.discover => const DiscoverFeedScreen(),
      WebShellDestination.feed => const FeedScreen(),
      WebShellDestination.myActivities => const MyActivitiesScreen(),
      WebShellDestination.groups => const GroupsScreen(),
      WebShellDestination.messages => const ChatListScreen(),
      WebShellDestination.friends => const FriendsScreen(),
      WebShellDestination.memories => const PastActivitiesGalleryScreen(),
      WebShellDestination.challenges => const ChallengesScreen(),
      WebShellDestination.profile => userId != null
          ? ProfileViewScreen(
              profileId: userId,
              isOwnProfile: true,
              embedded: embedded,
            )
          : const Center(child: Text('Nicht angemeldet')),
      WebShellDestination.settings => const SettingsScreen(),
    };
  }

  bool _showRightPanel(WebShellDestination dest) {
    return dest == WebShellDestination.discover ||
        dest == WebShellDestination.feed ||
        dest == WebShellDestination.profile;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(presenceHeartbeatProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final unreadChatCount = ref.watch(unreadChatCountProvider);
    final useWebLayout = kIsWeb && WebLayoutScaffold.isDesktop(context);
    final destination = ref.watch(shellDestinationProvider);

    ref.listen(shellDestinationRequestProvider, (previous, next) {
      if (next == null) return;
      _onDestinationChanged(next);
      ref.read(shellDestinationRequestProvider.notifier).clear();
    });

    final pendingDestination = ref.watch(shellDestinationRequestProvider);
    if (pendingDestination != null && destination != pendingDestination) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pending = ref.read(shellDestinationRequestProvider);
        if (pending == null) return;
        _onDestinationChanged(pending);
        ref.read(shellDestinationRequestProvider.notifier).clear();
      });
    }

    if (useWebLayout) {
      return WebLayoutScaffold(
        destination: destination,
        onDestinationChanged: _onDestinationChanged,
        showRightPanel: _showRightPanel(destination),
        notificationCount: unreadCount,
        unreadChatCount: unreadChatCount,
        body: _bodyFor(destination, embedded: true),
      );
    }

    return _MobileHomeShell(
      currentIndex: _mobileIndexFor(destination),
      onIndexChanged: (index) {
        final dest = switch (index) {
          0 => WebShellDestination.discover,
          1 => WebShellDestination.create,
          2 => WebShellDestination.myActivities,
          3 => WebShellDestination.friends,
          _ => WebShellDestination.messages,
        };
        _onDestinationChanged(dest);
      },
      body: _bodyFor(destination),
    );
  }
}

class _MobileHomeShell extends ConsumerWidget {
  const _MobileHomeShell({
    required this.currentIndex,
    required this.onIndexChanged,
    required this.body,
  });

  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    final l10n = AppLocalizations.of(context);
    final titles = [
      l10n.discover,
      l10n.create,
      l10n.myActivities,
      l10n.friends,
      l10n.chats,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CircleVeyaBrand.minLogoExtent,
                maxHeight: 36,
                minWidth: CircleVeyaBrand.minLogoExtent,
                maxWidth: 36,
              ),
              child: CircleVeyaBrand(
                compact: true,
                logoHeight: 36,
                onTap: () => ref
                    .read(shellDestinationProvider.notifier)
                    .set(WebShellDestination.discover),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(titles[currentIndex])),
          ],
        ),
        actions: [
          const LanguageSwitcherButton(),
          if (userId != null)
            IconButton(
              onPressed: () => context.pushNamed(
                RouteNames.profileView,
                pathParameters: {'id': userId},
                queryParameters: {'own': 'true'},
              ),
              icon: const Icon(Icons.person_outline),
              tooltip: l10n.myProfile,
            ),
          IconButton(
            onPressed: isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            tooltip: l10n.signOut,
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onIndexChanged,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l10n.discover,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: l10n.create,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event),
            label: l10n.events,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outlined),
            selectedIcon: const Icon(Icons.people),
            label: l10n.friends,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_outlined),
            selectedIcon: const Icon(Icons.chat),
            label: l10n.chats,
          ),
        ],
      ),
    );
  }
}
