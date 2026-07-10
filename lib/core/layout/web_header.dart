import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/data/notifications_remote_datasource.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../router/route_names.dart';
import '../search/global_search_provider.dart';
import '../search/search_models.dart';
import '../theme/app_colors.dart';
import 'web_shell_destination.dart';

/// Globaler Web-Header mit kontextsensitiver Suche, Benachrichtigungen und Profil.
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
          const Expanded(child: _ContextualSearchField()),
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

class _ContextualSearchField extends ConsumerStatefulWidget {
  const _ContextualSearchField();

  @override
  ConsumerState<_ContextualSearchField> createState() =>
      _ContextualSearchFieldState();
}

class _ContextualSearchFieldState
    extends ConsumerState<_ContextualSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      ref.read(globalSearchProvider.notifier).openOverlay();
    } else {
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        if (!_focusNode.hasFocus) {
          ref.read(globalSearchProvider.notifier).closeOverlay();
        }
      });
    }
  }

  void _syncOverlay(bool open) {
    if (open) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlay != null) {
      _overlay!.markNeedsBuild();
      return;
    }
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (context) => _SearchOverlay(
        link: _layerLink,
        onSelect: _onResultSelected,
      ),
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _onResultSelected(GlobalSearchResult result) {
    ref.read(globalSearchProvider.notifier).clear();
    _controller.clear();
    _focusNode.unfocus();
    _removeOverlay();

    switch (result.type) {
      case GlobalSearchResultType.activity:
        context.pushNamed(
          RouteNames.activityDetail,
          pathParameters: {'id': result.id},
        );
      case GlobalSearchResultType.profile:
        context.pushNamed(
          RouteNames.profileView,
          pathParameters: {'id': result.id},
        );
      case GlobalSearchResultType.chat:
        context.pushNamed(
          RouteNames.chatRoom,
          pathParameters: {'id': result.id},
          extra: result.title,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchContext = ref.watch(searchContextProvider);
    final searchState = ref.watch(globalSearchProvider);

    ref.listen(globalSearchProvider, (prev, next) {
      _syncOverlay(next.isOverlayOpen && next.hasQuery);
    });

    if (_controller.text != searchState.query &&
        searchState.query.isEmpty &&
        _controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.clear();
      });
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: (value) {
          ref.read(globalSearchProvider.notifier).setQuery(value);
        },
        onTap: () => ref.read(globalSearchProvider.notifier).openOverlay(),
        decoration: InputDecoration(
          hintText: searchContext.hintText,
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: searchState.query.isNotEmpty
              ? IconButton(
                  tooltip: 'Leeren',
                  onPressed: () {
                    ref.read(globalSearchProvider.notifier).clear();
                    _controller.clear();
                    _removeOverlay();
                  },
                  icon: const Icon(Icons.close, size: 18),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Center(
                    widthFactor: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandNavy.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        searchContext.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.brandNavy.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
          filled: true,
          fillColor: AppColors.surfaceTint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ),
    );
  }
}

class _SearchOverlay extends ConsumerWidget {
  const _SearchOverlay({
    required this.link,
    required this.onSelect,
  });

  final LayerLink link;
  final ValueChanged<GlobalSearchResult> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchContext = ref.watch(searchContextProvider);
    final resultsAsync = ref.watch(globalSearchResultsProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () =>
                ref.read(globalSearchProvider.notifier).closeOverlay(),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
                minWidth: 320,
                maxHeight: 360,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Ergebnisse · ${searchContext.label}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.brandNavy.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Flexible(
                    child: resultsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('$e'),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                            child: Text('Keine Treffer in diesem Bereich.'),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = results[index];
                            return ListTile(
                              dense: true,
                              leading: _ResultLeading(result: item),
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: item.subtitle == null
                                  ? null
                                  : Text(
                                      item.subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              onTap: () => onSelect(item),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultLeading extends StatelessWidget {
  const _ResultLeading({required this.result});

  final GlobalSearchResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = result.imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: CachedNetworkImageProvider(url),
      );
    }

    final icon = switch (result.type) {
      GlobalSearchResultType.activity => Icons.event_outlined,
      GlobalSearchResultType.profile => Icons.person_outline,
      GlobalSearchResultType.chat => Icons.chat_bubble_outline,
    };

    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(icon, size: 16, color: AppColors.brandNavy),
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
