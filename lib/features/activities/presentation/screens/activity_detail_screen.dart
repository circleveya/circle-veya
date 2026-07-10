import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../../core/utils/url_utils.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';
import '../providers/activity_provider.dart';
import '../widgets/activity_card.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    this.activity,
  });

  final String activityId;
  final DiscoverableActivity? activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interestsAsync = ref.watch(activityInterestsProvider(activityId));
    final actionsState = ref.watch(activityActionsProvider);
    final isHost = activity?.viewerAction == ViewerAction.host;
    final isParticipant = activity?.viewerAction == ViewerAction.joined;
    final isPastEvent = activity != null &&
        activity!.dateTime != null &&
        activity!.dateTime!.isBefore(DateTime.now());
    final groupChatAsync = (isHost || isParticipant)
        ? ref.watch(activityGroupChatProvider(activityId))
        : const AsyncValue<String?>.data(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(activity?.title ?? 'Aktivität'),
        actions: [
          if (isHost)
            IconButton(
              onPressed: actionsState.isLoading
                  ? null
                  : () => _confirmDelete(context, ref, activity!),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Aktivität löschen',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activity != null)
            ActivityCard(
              activity: activity!,
              isLoading: actionsState.isLoading,
              onAction: () => _handleAction(context, ref, activity!),
            ),
          if (isHost || isParticipant)
            groupChatAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (chatId) {
                if (chatId == null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Gruppenchat wird freigeschaltet, sobald weitere '
                      'Teilnehmer beitreten.',
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton.icon(
                    onPressed: () => context.pushNamed(
                      RouteNames.chatRoom,
                      pathParameters: {'id': chatId},
                    ),
                    icon: const Icon(Icons.groups),
                    label: const Text('Zum Gruppenchat'),
                  ),
                );
              },
            ),
          if ((isHost || isParticipant) && isPastEvent) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.pushNamed(
                RouteNames.activityGallery,
                pathParameters: {'id': activityId},
                extra: activity?.title,
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Erinnerungen'),
            ),
          ],
          if (isHost) ...[
            const SizedBox(height: 24),
            Text(
              'Interessierte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            interestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString()),
              data: (interests) {
                final pending =
                    interests.where((i) => i.isPending).toList();
                final others =
                    interests.where((i) => !i.isPending).toList();

                if (interests.isEmpty) {
                  return const Text('Noch keine Interessenten.');
                }

                return Column(
                  children: [
                    ...pending.map(
                      (interest) => _InterestTile(
                        interest: interest,
                        isLoading: actionsState.isLoading,
                        onTap: () => context.pushNamed(
                          RouteNames.profileView,
                          pathParameters: {'id': interest.profileId},
                        ),
                        onMessage: () => _startDm(context, ref, interest.id),
                        onAccept: () => ref
                            .read(activityActionsProvider.notifier)
                            .acceptInterest(interest.id, activityId),
                        onDecline: () => ref
                            .read(activityActionsProvider.notifier)
                            .declineInterest(interest.id, activityId),
                      ),
                    ),
                    ...others.map(
                      (interest) => _InterestTile(
                        interest: interest,
                        showActions: false,
                        onTap: () => context.pushNamed(
                          RouteNames.profileView,
                          pathParameters: {'id': interest.profileId},
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    DiscoverableActivity activity,
  ) async {
    if (activity.viewerAction == ViewerAction.externalLink) {
      final url = activity.externalUrl;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine externe Quelle verfügbar')),
        );
        return;
      }
      final ok = await openExternalUrl(url);
      if (!context.mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link konnte nicht geöffnet werden')),
        );
      }
      return;
    }

    final controller = ref.read(activityActionsProvider.notifier);

    if (activity.viewerAction == ViewerAction.directJoin) {
      await controller.joinDirect(activity.id);
    } else if (activity.viewerAction == ViewerAction.interest) {
      await controller.expressInterest(activity.id);
    }

    if (!context.mounted) return;
    final error = ref.read(activityActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erfolgreich!')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DiscoverableActivity activity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktivität löschen?'),
        content: Text(
          '„${activity.title}“ wird unwiderruflich gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref
        .read(activityActionsProvider.notifier)
        .deleteActivity(activity.id);

    if (!context.mounted) return;

    final error = ref.read(activityActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivität gelöscht')),
      );
      context.pop();
    }
  }

  Future<void> _startDm(
    BuildContext context,
    WidgetRef ref,
    String interestId,
  ) async {
    try {
      final chatId =
          await ref.read(chatActionsProvider.notifier).startDmChat(interestId);
      if (!context.mounted) return;
      context.pushNamed(
        RouteNames.chatRoom,
        pathParameters: {'id': chatId},
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.interest,
    this.onAccept,
    this.onDecline,
    this.onMessage,
    this.onTap,
    this.isLoading = false,
    this.showActions = true,
  });

  final ActivityInterest interest;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onMessage;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(interest.username[0].toUpperCase()),
        ),
        title: Text(interest.username),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (interest.message != null) Text(interest.message!),
            Text(
              '${interest.status} · ${dateFormat.format(interest.createdAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: showActions && interest.isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: isLoading ? null : onMessage,
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'DM starten',
                  ),
                  IconButton(
                    onPressed: isLoading ? null : onDecline,
                    icon: const Icon(Icons.close),
                    tooltip: 'Ablehnen',
                  ),
                  IconButton(
                    onPressed: isLoading ? null : onAccept,
                    icon: const Icon(Icons.check),
                    tooltip: 'Annehmen',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
