import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../friends/domain/entities/connection.dart';
import '../../../friends/presentation/providers/friends_provider.dart';
import '../../domain/entities/circle_group.dart';
import '../providers/groups_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  final String groupId;
  final String? groupName;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  String get _groupId => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(groupDetailProvider(_groupId));
    final membersAsync = ref.watch(groupMembersProvider(_groupId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;
    final isBusy = ref.watch(groupsControllerProvider).isLoading;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detailAsync.valueOrNull?.name ?? widget.groupName ?? 'Kreis',
        ),
        actions: [
          if (detailAsync case AsyncData(:final value) when value.isAdmin)
            IconButton(
              tooltip: 'Kreis bearbeiten',
              onPressed: isBusy ? null : () => _showEditDialog(value),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      floatingActionButton: detailAsync.maybeWhen(
        data: (group) {
          if (!group.isAdmin) return null;
          return FloatingActionButton.extended(
            onPressed: isBusy
                ? null
                : () => _showInviteSheet(
                      existingMemberIds: membersAsync.valueOrNull
                              ?.map((m) => m.profileId)
                              .toSet() ??
                          {},
                    ),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Einladen'),
            backgroundColor: AppColors.seed,
            foregroundColor: Colors.white,
          );
        },
        orElse: () => null,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(groupDetailProvider(_groupId)),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (group) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupDetailProvider(_groupId));
              ref.invalidate(groupMembersProvider(_groupId));
              await Future.wait([
                ref.read(groupDetailProvider(_groupId).future),
                ref.read(groupMembersProvider(_groupId).future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                Center(
                  child: _GroupAvatarEditor(
                    group: group,
                    isBusy: isBusy,
                    onPick: group.isAdmin ? () => _pickGroupImage() : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  group.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (group.description != null &&
                    group.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    group.description!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${group.memberCount} Mitglieder · Erstellt am ${dateFormat.format(group.createdAt.toLocal())}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mitglieder',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                membersAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('$e'),
                  data: (members) {
                    if (members.isEmpty) {
                      return Text(
                        'Noch keine Mitglieder.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final member in members)
                          _MemberTile(
                            member: member,
                            group: group,
                            currentUserId: currentUserId,
                            isBusy: isBusy,
                            onAction: (action) =>
                                _handleMemberAction(member, action),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    final bytes = await image.readAsBytes();
    await ref.read(groupsControllerProvider.notifier).uploadGroupImage(
          groupId: _groupId,
          bytes: bytes,
          fileName: image.name,
        );

    if (!mounted) return;
    _showControllerErrorOrSnack('Profilbild aktualisiert');
  }

  Future<void> _showEditDialog(CircleGroup group) async {
    final nameController = TextEditingController(text: group.name);
    final descriptionController = TextEditingController(
      text: group.description ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kreis bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name des Kreises',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 280,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    nameController.dispose();
    descriptionController.dispose();

    if (saved != true || !mounted) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte einen Namen für den Kreis eingeben'),
        ),
      );
      return;
    }

    await ref.read(groupsControllerProvider.notifier).updateGroup(
          groupId: _groupId,
          name: name,
          description: description.isEmpty ? null : description,
        );

    if (!mounted) return;
    _showControllerErrorOrSnack('Kreis aktualisiert');
  }

  Future<void> _showInviteSheet({
    required Set<String> existingMemberIds,
  }) async {
    final selectedIds = <String>{};

    // Verbindungen vorab laden, damit das Sheet nicht ewig auf Loading hängt.
    try {
      await ref.read(myConnectionsProvider.future);
    } catch (_) {
      // Fehler wird im Sheet angezeigt.
    }
    if (!mounted) return;

    final invited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final connectionsAsync = sheetRef.watch(myConnectionsProvider);
                final theme = Theme.of(context);

                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Freunde einladen',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        connectionsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Text('$e', textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => sheetRef
                                      .invalidate(myConnectionsProvider),
                                  child: const Text('Erneut laden'),
                                ),
                              ],
                            ),
                          ),
                          data: (connections) {
                            final friends = connections
                                .where(
                                  (c) =>
                                      c.type == ConnectionType.friend &&
                                      !existingMemberIds.contains(c.profileId),
                                )
                                .toList();
                            if (friends.isEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'Keine Freunde zum Einladen.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.sizeOf(context).height * 0.5,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: friends.length,
                                itemBuilder: (context, index) {
                                  final friend = friends[index];
                                  return CheckboxListTile(
                                    value:
                                        selectedIds.contains(friend.profileId),
                                    onChanged: (checked) {
                                      setModalState(() {
                                        if (checked == true) {
                                          selectedIds.add(friend.profileId);
                                        } else {
                                          selectedIds.remove(friend.profileId);
                                        }
                                      });
                                    },
                                    secondary: CircleAvatar(
                                      backgroundImage: friend.avatarUrl != null
                                          ? CachedNetworkImageProvider(
                                              friend.avatarUrl!,
                                            )
                                          : null,
                                      child: friend.avatarUrl == null
                                          ? Text(
                                              friend.username[0].toUpperCase(),
                                            )
                                          : null,
                                    ),
                                    title: Text(friend.username),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: selectedIds.isEmpty
                              ? null
                              : () => Navigator.pop(sheetContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandNavy,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            selectedIds.isEmpty
                                ? 'Einladen'
                                : '${selectedIds.length} einladen',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (invited != true || selectedIds.isEmpty || !mounted) return;

    final added = await ref.read(groupsControllerProvider.notifier).addMembers(
          groupId: _groupId,
          memberIds: selectedIds.toList(),
        );

    if (!mounted) return;
    final error = ref.read(groupsControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $error')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added != null && added > 0
              ? '$added Freund${added == 1 ? '' : 'e'} eingeladen'
              : 'Keine neuen Mitglieder hinzugefügt',
        ),
      ),
    );
  }

  Future<void> _handleMemberAction(
    CircleGroupMember member,
    _MemberAction action,
  ) async {
    switch (action) {
      case _MemberAction.makeAdmin:
        await ref.read(groupsControllerProvider.notifier).setMemberRole(
              groupId: _groupId,
              profileId: member.profileId,
              role: 'admin',
            );
        if (!mounted) return;
        _showControllerErrorOrSnack('${member.username} ist jetzt Admin');
      case _MemberAction.removeAdmin:
        await ref.read(groupsControllerProvider.notifier).setMemberRole(
              groupId: _groupId,
              profileId: member.profileId,
              role: 'member',
            );
        if (!mounted) return;
        _showControllerErrorOrSnack(
          'Admin-Rechte von ${member.username} entfernt',
        );
      case _MemberAction.transferOwnership:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eigentümerschaft übertragen?'),
            content: Text(
              'Möchtest du die Eigentümerschaft an ${member.username} '
              'übertragen? Du wirst danach Admin dieses Kreises.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Übertragen'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        await ref.read(groupsControllerProvider.notifier).setMemberRole(
              groupId: _groupId,
              profileId: member.profileId,
              role: 'owner',
            );
        if (!mounted) return;
        _showControllerErrorOrSnack(
          'Eigentümerschaft an ${member.username} übertragen',
        );
      case _MemberAction.remove:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mitglied entfernen?'),
            content: Text(
              '${member.username} wird aus diesem Kreis entfernt.',
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
                child: const Text('Entfernen'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        await ref.read(groupsControllerProvider.notifier).removeMember(
              groupId: _groupId,
              profileId: member.profileId,
            );
        if (!mounted) return;
        _showControllerErrorOrSnack('${member.username} entfernt');
    }
  }

  void _showControllerErrorOrSnack(String successMessage) {
    final error = ref.read(groupsControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error != null ? 'Fehler: $error' : successMessage),
      ),
    );
  }
}

enum _MemberAction { makeAdmin, removeAdmin, transferOwnership, remove }

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.group,
    required this.currentUserId,
    required this.isBusy,
    required this.onAction,
  });

  final CircleGroupMember member;
  final CircleGroup group;
  final String? currentUserId;
  final bool isBusy;
  final ValueChanged<_MemberAction> onAction;

  String get _roleLabel {
    switch (member.role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      default:
        return 'Mitglied';
    }
  }

  List<PopupMenuEntry<_MemberAction>> _menuItems() {
    final isSelf = member.profileId == currentUserId;
    if (isSelf || isBusy) return const [];

    if (group.isOwner) {
      if (member.role == 'owner') return const [];
      return [
        if (member.role == 'member')
          const PopupMenuItem(
            value: _MemberAction.makeAdmin,
            child: Text('Zum Admin machen'),
          ),
        if (member.role == 'admin')
          const PopupMenuItem(
            value: _MemberAction.removeAdmin,
            child: Text('Admin entfernen'),
          ),
        const PopupMenuItem(
          value: _MemberAction.transferOwnership,
          child: Text('Eigentümerschaft übertragen'),
        ),
        const PopupMenuItem(
          value: _MemberAction.remove,
          child: Text('Entfernen'),
        ),
      ];
    }

    if (group.isAdmin && member.role == 'member') {
      return const [
        PopupMenuItem(
          value: _MemberAction.remove,
          child: Text('Entfernen'),
        ),
      ];
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuItems = _menuItems();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: member.avatarUrl != null
            ? CachedNetworkImageProvider(member.avatarUrl!)
            : null,
        child: member.avatarUrl == null
            ? Text(member.username[0].toUpperCase())
            : null,
      ),
      title: Text(member.username),
      subtitle: Text(_roleLabel),
      onTap: () => context.pushNamed(
        RouteNames.profileView,
        pathParameters: {'id': member.profileId},
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.role == 'owner')
            const Icon(Icons.star, color: AppColors.seed, size: 18),
          if (menuItems.isNotEmpty)
            PopupMenuButton<_MemberAction>(
              onSelected: onAction,
              itemBuilder: (_) => menuItems,
            ),
        ],
      ),
    );
  }
}

class _GroupAvatarEditor extends StatelessWidget {
  const _GroupAvatarEditor({
    required this.group,
    required this.isBusy,
    this.onPick,
  });

  final CircleGroup group;
  final bool isBusy;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final imageUrl = group.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: AppColors.seed.withValues(alpha: 0.15),
          backgroundImage:
              hasImage ? CachedNetworkImageProvider(imageUrl) : null,
          child: hasImage
              ? null
              : Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.seed,
                  ),
                ),
        ),
        if (onPick != null)
          Material(
            color: AppColors.brandNavy,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isBusy ? null : onPick,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }
}
