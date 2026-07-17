import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/shell_destination_request.dart';
import '../../../../core/layout/web_shell_destination.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_enums.dart';
import '../providers/activity_provider.dart';
import '../providers/event_selection_provider.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    this.activity,
  });

  final String activityId;
  final DiscoverableActivity? activity;

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final passed = widget.activity;
    final fetchedAsync = passed == null
        ? ref.watch(activityDetailProvider(widget.activityId))
        : null;
    final activity = passed ?? fetchedAsync?.valueOrNull;

    if (passed == null && fetchedAsync != null) {
      if (fetchedAsync.isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (fetchedAsync.hasError) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('${fetchedAsync.error}')),
        );
      }
      if (activity == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Aktivität nicht gefunden.')),
        );
      }
    }

    final interestsAsync = ref.watch(activityInterestsProvider(widget.activityId));
    final actionsState = ref.watch(activityActionsProvider);
    final isHost = activity?.viewerAction == ViewerAction.host;
    final isParticipant = activity?.viewerAction == ViewerAction.joined;
    final isPastEvent = activity != null &&
        activity.dateTime != null &&
        activity.dateTime!.isBefore(DateTime.now());
    final groupChatAsync = (isHost || isParticipant)
        ? ref.watch(activityGroupChatProvider(widget.activityId))
        : const AsyncValue<String?>.data(null);

    final imageUrl = activity?.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, dd.MM.yyyy · HH:mm');

    final screen = MediaQuery.sizeOf(context);
    // Rechteckiges Hero (4:3), zentriert – nicht über die volle Breite gezogen.
    const heroAspect = 4 / 3;
    final heroMaxWidth = (screen.width - 48).clamp(280.0, 520.0);
    final heroHeight = heroMaxWidth / heroAspect;
    final expandedHeight = heroHeight + 24;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            stretch: false,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: AppColors.brandNavy,
            actions: [
              if (isHost && activity != null) ...[
                IconButton(
                  tooltip: 'Bearbeiten',
                  onPressed: actionsState.isLoading
                      ? null
                      : () => _openEdit(context, activity),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Löschen',
                  onPressed: actionsState.isLoading
                      ? null
                      : () => _confirmDelete(context, activity),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: ColoredBox(
                color: theme.colorScheme.surface,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: heroMaxWidth),
                      child: AspectRatio(
                        aspectRatio: heroAspect,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'activity-image-${widget.activityId}',
                                child: hasImage
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                        placeholder: (_, _) =>
                                            const _HeroFallback(),
                                        errorWidget: (_, _, _) =>
                                            const _HeroFallback(),
                                      )
                                    : const _HeroFallback(),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black12,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
              child: activity == null
                  ? Text(
                      'Details nicht geladen.',
                      style: theme.textTheme.bodyLarge,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandNavy,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (activity.dateTime != null) ...[
                          _MetaRow(
                            icon: Icons.schedule_outlined,
                            label: dateFormat.format(activity.dateTime!.toLocal()),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (activity.locationName != null &&
                            activity.locationName!.trim().isNotEmpty) ...[
                          _MetaRow(
                            icon: Icons.place_outlined,
                            label: activity.locationName!,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _MetaRow(
                          icon: Icons.people_outline,
                          label: '${activity.participantsLabel} Teilnehmer',
                        ),
                        _MetaRow(
                          icon: Icons.person_outline,
                          label: 'Host: ${activity.hostUsername}',
                        ),
                        if (activity.description != null &&
                            activity.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            'Beschreibung',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandNavy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            activity.description!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        if (!activity.isExternal &&
                            activity.viewerAction != ViewerAction.host &&
                            activity.viewerAction != ViewerAction.none &&
                            activity.viewerAction != ViewerAction.joined)
                          FilledButton(
                            onPressed: actionsState.isLoading
                                ? null
                                : () => _handleAction(context, activity),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandNavy,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              activity.viewerAction == ViewerAction.directJoin
                                  ? 'Zusagen'
                                  : 'Interesse bekunden',
                            ),
                          ),
                        if (activity.isExternal) ...[
                          FilledButton.icon(
                            onPressed: () =>
                                _planWithFriends(context, activity),
                            icon: const Icon(Icons.group_add_outlined),
                            label: const Text('Mit Freunden zum Event'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandNavy,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _handleAction(context, activity),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Zur Event-Quelle'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                        if (isHost || isParticipant)
                          groupChatAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (chatId) {
                              if (chatId == null) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Text(
                                    'Gruppenchat wird freigeschaltet, sobald '
                                    'weitere Teilnehmer beitreten.',
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: OutlinedButton.icon(
                                  onPressed: () => context.pushNamed(
                                    RouteNames.chatRoom,
                                    pathParameters: {'id': chatId},
                                  ),
                                  icon: const Icon(Icons.groups_outlined),
                                  label: const Text('Zum Gruppenchat'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        if ((isHost || isParticipant) && isPastEvent) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.pushNamed(
                              RouteNames.activityGallery,
                              pathParameters: {'id': widget.activityId},
                              extra: activity.title,
                            ),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Erinnerungen'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                        if (isHost) ...[
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () => _createGroupFromActivity(
                              context,
                              ref,
                              activity,
                            ),
                            icon: const Icon(Icons.group_add_outlined),
                            label: const Text(
                              'Kreis mit Teilnehmern erstellen',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brandNavy,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Interessierte',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandNavy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          interestsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => Text(e.toString()),
                            data: (interests) {
                              if (interests.isEmpty) {
                                return Text(
                                  'Noch keine Interessenten.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              }
                              final pending =
                                  interests.where((i) => i.isPending).toList();
                              final others =
                                  interests.where((i) => !i.isPending).toList();
                              return Column(
                                children: [
                                  ...pending.map(
                                    (interest) => _InterestTile(
                                      interest: interest,
                                      isLoading: actionsState.isLoading,
                                      onTap: () => context.pushNamed(
                                        RouteNames.profileView,
                                        pathParameters: {
                                          'id': interest.profileId,
                                        },
                                      ),
                                      onMessage: () =>
                                          _startDm(context, interest.id),
                                      onAccept: () => ref
                                          .read(
                                            activityActionsProvider.notifier,
                                          )
                                          .acceptInterest(
                                            interest.id,
                                            widget.activityId,
                                          ),
                                      onDecline: () => ref
                                          .read(
                                            activityActionsProvider.notifier,
                                          )
                                          .declineInterest(
                                            interest.id,
                                            widget.activityId,
                                          ),
                                    ),
                                  ),
                                  ...others.map(
                                    (interest) => _InterestTile(
                                      interest: interest,
                                      showActions: false,
                                      onTap: () => context.pushNamed(
                                        RouteNames.profileView,
                                        pathParameters: {
                                          'id': interest.profileId,
                                        },
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
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    DiscoverableActivity activity,
  ) async {
    final updated = await context.pushNamed<DiscoverableActivity>(
      RouteNames.activityEdit,
      pathParameters: {'id': activity.id},
      extra: activity,
    );
    if (updated != null && mounted) {
      ref.invalidate(activityDetailProvider(widget.activityId));
      // Wenn per extra navigiert wurde, Screen neu aufbauen mit aktualisierten Daten.
      if (context.mounted) {
        context.pushReplacementNamed(
          RouteNames.activityDetail,
          pathParameters: {'id': updated.id},
          extra: updated,
        );
      }
    }
  }

  Future<void> _planWithFriends(
    BuildContext context,
    DiscoverableActivity activity,
  ) {
    ref.read(eventSelectionProvider.notifier).selectFromActivity(activity);
    ref
        .read(shellDestinationRequestProvider.notifier)
        .goTo(WebShellDestination.create);
    context.goNamed(RouteNames.home);
    return Future.value();
  }

  Future<void> _handleAction(
    BuildContext context,
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
    DiscoverableActivity activity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktivität löschen?'),
        content: Text('„${activity.title}“ wird unwiderruflich gelöscht.'),
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

  Future<void> _createGroupFromActivity(
    BuildContext context,
    WidgetRef ref,
    DiscoverableActivity activity,
  ) async {
    final includePending = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kreis erstellen'),
        content: const Text(
          'Es wird ein Kreis mit dir als Owner und allen '
          'Teilnehmern sowie akzeptierten Interessenten erstellt.\n\n'
          'Auch noch ausstehende Interessenten einladen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nur Teilnehmer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mit ausstehenden'),
          ),
        ],
      ),
    );

    if (includePending == null || !context.mounted) return;

    final groupId =
        await ref.read(groupsControllerProvider.notifier).createGroupFromActivity(
              activityId: activity.id,
              name: 'Kreis: ${activity.title}',
              includePendingInterests: includePending,
            );

    if (!context.mounted) return;

    final error = ref.read(groupsControllerProvider).error;
    if (error != null || groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Kreis konnte nicht erstellt werden')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kreis erstellt')),
    );
    context.pushNamed(
      RouteNames.groupDetail,
      pathParameters: {'id': groupId},
      extra: 'Kreis: ${activity.title}',
    );
  }

  Future<void> _startDm(BuildContext context, String interestId) async {
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

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.premiumGradient),
      child: Center(
        child: Icon(Icons.explore_outlined, size: 64, color: Colors.white70),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.brandNavy.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.brandNavy.withValues(alpha: 0.08),
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
