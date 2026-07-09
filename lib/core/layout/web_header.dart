import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/data/notifications_remote_datasource.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import 'web_shell_destination.dart';

/// Globaler Web-Header mit Suche, Benachrichtigungen und Profil-Dropdown.
class WebHeader extends ConsumerWidget {
  const WebHeader({
    super.key,
    this.onNavigate,
    this.notificationCount = 0,
    this.unreadChatCount = 0,
  });

  final ValueChanged<WebShellDestination>? onNavigate;
  final int notificationCount;
  final int unreadChatCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(myProfileProvider);
    final isSigningOut = ref.watch(authControllerProvider).isLoading;
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final effectiveNotificationCount =
        notificationCount > 0 ? notificationCount : unreadCount;

    final displayName = profileAsync.maybeWhen(
      data: (p) => p.username,
      orElse: () => '…',
    );
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;

    void showNotifications() {
      final notifications =
          ref.read(notificationsStreamProvider).valueOrNull ?? [];
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _NotificationsSheet(notifications: notifications),
      );
    }

    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SearchField(
              onSubmitted: (query) {
                if (query.trim().isEmpty) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Suche nach „$query“ (bald verfügbar)')),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            badgeCount: effectiveNotificationCount,
            tooltip: 'Benachrichtigungen',
            onPressed: showNotifications,
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.chat_bubble_outline,
            badgeCount: unreadChatCount,
            tooltip: 'Nachrichten',
            onPressed: () => onNavigate?.call(WebShellDestination.messages),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            tooltip: 'Profil-Menü',
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  if (userId != null) {
                    context.pushNamed(
                      RouteNames.profileView,
                      pathParameters: {'id': userId},
                      queryParameters: {'own': 'true'},
                    );
                  }
                case 'edit':
                  context.pushNamed(RouteNames.profileEdit);
                case 'logout':
                  if (!isSigningOut) {
                    await ref.read(authControllerProvider.notifier).signOut();
                  }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Mein Profil'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Profil bearbeiten'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                enabled: !isSigningOut,
                child: const ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Abmelden'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benachrichtigungen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Keine Benachrichtigungen')),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return ListTile(
                      title: Text(n.title),
                      subtitle: Text(n.message),
                      trailing: n.isRead
                          ? null
                          : const Icon(Icons.circle, size: 8, color: AppColors.seed),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Aktivitäten, Freunde oder Orte suchen …',
        prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceTint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.seed, width: 1.5),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceTint,
            foregroundColor: theme.colorScheme.onSurface,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
