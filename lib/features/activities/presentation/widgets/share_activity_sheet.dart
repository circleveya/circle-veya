import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/share_links.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../chat/domain/entities/activity_share_payload.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../chat/presentation/widgets/activity_share_preview.dart';
import '../../../friends/domain/entities/connection.dart';
import '../../../friends/presentation/providers/friends_provider.dart';

Future<void> shareActivityLink(
  BuildContext context, {
  required String activityId,
  required String title,
  String? imageUrl,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ShareActivitySheet(
      activityId: activityId,
      title: title,
      imageUrl: imageUrl,
      parentContext: context,
    ),
  );
}

class _ShareActivitySheet extends ConsumerStatefulWidget {
  const _ShareActivitySheet({
    required this.activityId,
    required this.title,
    required this.imageUrl,
    required this.parentContext,
  });

  final String activityId;
  final String title;
  final String? imageUrl;
  final BuildContext parentContext;

  @override
  ConsumerState<_ShareActivitySheet> createState() =>
      _ShareActivitySheetState();
}

class _ShareActivitySheetState extends ConsumerState<_ShareActivitySheet> {
  String? _sendingToFriendId;
  String? _linkActivityId;

  @override
  void initState() {
    super.initState();
    _resolveLinkId();
  }

  Future<void> _resolveLinkId() async {
    try {
      final resolved = await ref
          .read(activityRemoteDatasourceProvider)
          .resolveActivityLinkId(widget.activityId);
      if (mounted) setState(() => _linkActivityId = resolved);
    } catch (_) {
      if (mounted) setState(() => _linkActivityId = widget.activityId);
    }
  }

  String get _effectiveActivityId => _linkActivityId ?? widget.activityId;

  String get _url => CircleShareLinks.activity(_effectiveActivityId);

  ActivitySharePayload get _previewPayload => ActivitySharePayload(
        activityId: _effectiveActivityId,
        title: widget.title,
        url: _url,
        imageUrl: widget.imageUrl,
      );

  Future<void> _sendToFriend(UserConnection friend) async {
    if (_sendingToFriendId != null) return;

    final caption = await _promptShareMessage(friend);
    if (!mounted || caption == null) return;

    setState(() => _sendingToFriendId = friend.profileId);

    try {
      final actions = ref.read(chatActionsProvider.notifier);
      final chatId = await actions.startFriendChat(friend.profileId);
      await actions.sendActivityShare(
        chatId: chatId,
        payload: ActivitySharePayload(
          activityId: _effectiveActivityId,
          title: widget.title,
          url: _url,
          imageUrl: widget.imageUrl,
          caption: caption.trim().isEmpty ? null : caption.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);

      final l10n = AppLocalizations.of(widget.parentContext);
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(l10n.activitySentToFriend(friend.username))),
        );
        widget.parentContext.pushNamed(
          RouteNames.chatRoom,
          pathParameters: {'id': chatId},
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingToFriendId = null);
      }
    }
  }

  Future<String?> _promptShareMessage(UserConnection friend) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.shareActivityToFriend(friend.username),
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              ActivitySharePreview(
                payload: _previewPayload,
                compact: true,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: l10n.shareActivityMessageHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) =>
                    Navigator.pop(sheetContext, controller.text),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(sheetContext, controller.text),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l10n.shareActivitySend),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final isBusy = ref.watch(chatActionsProvider).isLoading;

    Future<void> openShare(Uri uri) async {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }

    final shareText = '${widget.title}\n$_url';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.shareActivity,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.shareToFriends,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.shareToFriendsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            connectionsAsync.when(
              loading: () => const SizedBox(
                height: 96,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('$error'),
              data: (connections) {
                final friends = connections
                    .where((c) => c.type == ConnectionType.friend)
                    .toList();
                if (friends.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.noFriendsToShare,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSending =
                          _sendingToFriendId == friend.profileId && isBusy;
                      return _FriendShareTarget(
                        friend: friend,
                        isSending: isSending,
                        onTap: isBusy ? null : () => _sendToFriend(friend),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.share,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _ShareTarget(
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    icon: Icons.chat,
                    onTap: () => openShare(
                      Uri.parse(
                        'https://wa.me/?text=${Uri.encodeComponent(shareText)}',
                      ),
                    ),
                  ),
                  _ShareTarget(
                    label: 'Telegram',
                    color: const Color(0xFF229ED9),
                    icon: Icons.send_rounded,
                    onTap: () => openShare(
                      Uri.parse(
                        'https://t.me/share/url'
                        '?url=${Uri.encodeComponent(_url)}'
                        '&text=${Uri.encodeComponent(widget.title)}',
                      ),
                    ),
                  ),
                  _ShareTarget(
                    label: 'X',
                    color: const Color(0xFF0F1419),
                    icon: Icons.close_rounded,
                    glyph: '𝕏',
                    onTap: () => openShare(
                      Uri.parse(
                        'https://twitter.com/intent/tweet'
                        '?text=${Uri.encodeComponent(widget.title)}'
                        '&url=${Uri.encodeComponent(_url)}',
                      ),
                    ),
                  ),
                  _ShareTarget(
                    label: 'Reddit',
                    color: const Color(0xFFFF4500),
                    icon: Icons.reddit,
                    onTap: () => openShare(
                      Uri.parse(
                        'https://www.reddit.com/submit'
                        '?url=${Uri.encodeComponent(_url)}'
                        '&title=${Uri.encodeComponent(widget.title)}',
                      ),
                    ),
                  ),
                  _ShareTarget(
                    label: 'LinkedIn',
                    color: const Color(0xFF0A66C2),
                    icon: Icons.business_center,
                    onTap: () => openShare(
                      Uri.parse(
                        'https://www.linkedin.com/sharing/share-offsite/'
                        '?url=${Uri.encodeComponent(_url)}',
                      ),
                    ),
                  ),
                  _ShareTarget(
                    label: 'E-Mail',
                    color: const Color(0xFF5F6368),
                    icon: Icons.email_outlined,
                    onTap: () => openShare(
                      Uri.parse(
                        'mailto:?subject=${Uri.encodeComponent(widget.title)}'
                        '&body=${Uri.encodeComponent(shareText)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _url));
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (widget.parentContext.mounted) {
                        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                          SnackBar(content: Text(l10n.linkCopied)),
                        );
                      }
                    },
                    child: Text(l10n.copyLink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.seed.withValues(alpha: 0.15),
                child: const Icon(Icons.link, color: AppColors.seed),
              ),
              title: Text(l10n.copyLink),
              subtitle: Text(l10n.copyLinkSubtitle),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: _url));
                if (!context.mounted) return;
                Navigator.pop(context);
                if (widget.parentContext.mounted) {
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                    SnackBar(content: Text(l10n.linkCopied)),
                  );
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.seed.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.seed,
                ),
              ),
              title: Text(l10n.copyAsText),
              subtitle: Text(l10n.copyAsTextSubtitle),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareText));
                if (!context.mounted) return;
                Navigator.pop(context);
                if (widget.parentContext.mounted) {
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                    SnackBar(content: Text(l10n.textCopied)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendShareTarget extends StatelessWidget {
  const _FriendShareTarget({
    required this.friend,
    required this.onTap,
    this.isSending = false,
  });

  final UserConnection friend;
  final VoidCallback? onTap;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final avatar = friend.avatarUrl?.trim();
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    final initial = friend.username.isNotEmpty
        ? friend.username[0].toUpperCase()
        : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.seed.withValues(alpha: 0.15),
                  backgroundImage:
                      hasAvatar ? CachedNetworkImageProvider(avatar) : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.seed,
                          ),
                        ),
                ),
                if (isSending)
                  const Positioned.fill(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              friend.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.glyph,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String? glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: glyph != null
                    ? Text(
                        glyph!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
