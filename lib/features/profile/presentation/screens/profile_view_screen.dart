import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/shell_destination_request.dart';
import '../../../../core/layout/web_shell_destination.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../activities/domain/entities/activity_enums.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../activities/presentation/widgets/activity_card.dart';
import '../../../challenges/domain/entities/level_milestone.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../challenges/presentation/widgets/level_badge_theme.dart';
import '../../../challenges/presentation/widgets/level_milestones_ui.dart';
import '../../../friends/domain/entities/connection.dart';
import '../../../friends/presentation/providers/friends_provider.dart';
import '../../../gallery/presentation/providers/gallery_provider.dart';
import '../../../gallery/presentation/screens/activity_gallery_screen.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../domain/entities/special_badge.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_review.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_image_crop_editor.dart';
import '../widgets/special_badge_ui.dart';
import '../widgets/star_rating.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({
    super.key,
    required this.profileId,
    this.isOwnProfile = false,
    this.embedded = false,
  });

  final String profileId;
  final bool isOwnProfile;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(profileId));
    final sessionUserId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final isOwn = isOwnProfile ||
        (sessionUserId != null && sessionUserId == profileId);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (profile) => _ProfileBody(
        key: ValueKey('${profile.id}-${profile.hasLevelSystem}'),
        profile: profile,
        isOwnProfile: isOwn,
        embedded: embedded,
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    required this.embedded,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final bool embedded;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: widget.profile.hasLevelSystem ? 5 : 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isOwnProfile = widget.isOwnProfile;
    final embedded = widget.embedded;
    final theme = Theme.of(context);
    final statsAsync = ref.watch(userLevelStatsProvider);
    final ratingAsync = ref.watch(profileRatingProvider(profile.id));
    final connections = ref.watch(myConnectionsProvider).valueOrNull ?? [];
    final friendCount =
        connections.where((c) => c.type == ConnectionType.friend).length;
    final activityArgs = (profileId: profile.id, isOwn: isOwnProfile);
    final activitiesAsync = ref.watch(profileActivitiesProvider(activityArgs));
    final activityCount = activitiesAsync.valueOrNull?.length ?? 0;
    final groupCount = isOwnProfile
        ? ref.watch(myGroupsProvider).valueOrNull?.length ?? 0
        : 0;

    final level = !profile.hasLevelSystem
        ? null
        : (isOwnProfile
            ? (statsAsync.valueOrNull?.level ?? profile.level ?? 1)
            : (profile.level ?? 1));
    final rating = ratingAsync.valueOrNull?.avgRating ?? 0.0;
    final reviewCount = ratingAsync.valueOrNull?.reviewCount ?? 0;
    final followBusy = ref.watch(friendsActionsProvider).isLoading;
    final showLevelTab = profile.hasLevelSystem && profile.canViewFullProfile;
    final canViewDetails = isOwnProfile || profile.canViewFullProfile;
    final l10n = AppLocalizations.of(context);

    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileCoverHeader(
            profile: profile,
            isOwnProfile: isOwnProfile,
            level: level,
            onLevelTap: showLevelTab ? () => tabController.animateTo(2) : null,
            showBackButton: !embedded,
          ),
        ),
        if (!isOwnProfile && profile.isBusinessProfile)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: FilledButton.icon(
                onPressed: followBusy
                    ? null
                    : () async {
                        final actions =
                            ref.read(friendsActionsProvider.notifier);
                        if (profile.followedByMe) {
                          await actions.unfollowCompany(profile.id);
                        } else {
                          await actions.followCompany(profile.id);
                        }
                      },
                icon: Icon(
                  profile.followedByMe ? Icons.check : Icons.person_add_alt_1,
                ),
                label: Text(
                  profile.followedByMe ? l10n.following : l10n.follow,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: profile.followedByMe
                      ? theme.colorScheme.surfaceContainerHighest
                      : AppColors.seed,
                  foregroundColor: profile.followedByMe
                      ? theme.colorScheme.onSurface
                      : Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: _ProfileStatsRow(
            activities: canViewDetails ? activityCount : 0,
            friends: canViewDetails
                ? (profile.isBusinessProfile
                    ? profile.followerCount
                    : friendCount)
                : 0,
            groups: canViewDetails && !profile.isBusinessProfile ? groupCount : 0,
            rating: canViewDetails ? rating : 0,
            reviewCount: canViewDetails ? reviewCount : 0,
            friendsLabel:
                profile.isBusinessProfile ? l10n.followers : l10n.friends,
            hideGroups: profile.isBusinessProfile,
            onActivitiesTap:
                canViewDetails ? () => tabController.animateTo(1) : null,
            onFriendsTap: canViewDetails &&
                    !profile.isBusinessProfile &&
                    isOwnProfile
                ? () {
                    ref
                        .read(shellDestinationRequestProvider.notifier)
                        .goTo(WebShellDestination.friends);
                    if (!embedded) {
                      context.goNamed(RouteNames.home);
                    }
                  }
                : null,
            onGroupsTap: canViewDetails &&
                    !profile.isBusinessProfile &&
                    isOwnProfile
                ? () {
                    ref
                        .read(shellDestinationRequestProvider.notifier)
                        .goTo(WebShellDestination.groups);
                    if (!embedded) {
                      context.goNamed(RouteNames.home);
                    }
                  }
                : null,
            onRatingTap: canViewDetails
                ? () => tabController.animateTo(showLevelTab ? 4 : 3)
                : null,
          ),
        ),
        if (!canViewDetails)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _PrivateProfilePlaceholder(
              username: profile.username,
            ),
          )
        else ...[
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: l10n.aboutMe),
                Tab(text: l10n.activities),
                if (showLevelTab) Tab(text: l10n.levelTab),
                Tab(text: l10n.gallery),
                Tab(text: l10n.reviews),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          child: TabBarView(
            controller: tabController,
            children: [
              _AboutTab(profile: profile),
              _ProfileActivitiesTab(
                profileId: profile.id,
                isOwnProfile: isOwnProfile,
              ),
              if (showLevelTab)
                LevelMilestonesGallery(userLevel: level ?? 1),
              _ProfileGalleryTab(
                profileId: profile.id,
                isOwnProfile: isOwnProfile,
                galleryPublic: profile.galleryPublic,
              ),
              _ProfileReviewsTab(
                profileId: profile.id,
                isOwnProfile: isOwnProfile,
                username: profile.username,
                canReview: profile.canReview,
              ),
            ],
          ),
        ),
        ],
      ],
    );

    if (embedded) {
      return ColoredBox(
        color: theme.colorScheme.surface,
        child: content,
      );
    }

    return Scaffold(
      body: content,
      floatingActionButton: isOwnProfile
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(RouteNames.profileEdit),
              icon: const Icon(Icons.edit),
              label: Text(AppLocalizations.of(context).edit),
            )
          : null,
    );
  }
}

class _PrivateProfilePlaceholder extends StatelessWidget {
  const _PrivateProfilePlaceholder({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 56,
              color: AppColors.brandNavy.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privateProfileTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.brandNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.privateProfileBody(username),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCoverHeader extends ConsumerWidget {
  const _ProfileCoverHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.level,
    this.onLevelTap,
    this.showBackButton = false,
  });

  static const _avatarRadius = 68.0;
  static const _headerHeight = 312.0;
  static const _badgeSize = 56.0;
  static const _badgeLabelSize = 15.0;

  final UserProfile profile;
  final bool isOwnProfile;
  final int? level;
  final VoidCallback? onLevelTap;
  final bool showBackButton;

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final cropped = await pickAndCropProfileImage(
      context,
      kind: ProfileCropKind.avatar,
    );
    if (cropped == null || !context.mounted) return;

    await ref
        .read(profileEditControllerProvider.notifier)
        .uploadAvatar(cropped.toXFile());
    if (!context.mounted) return;

    final error = ref.read(profileEditControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? 'Profilbild aktualisiert' : 'Fehler: $error',
        ),
      ),
    );
  }

  Future<void> _pickCover(BuildContext context, WidgetRef ref) async {
    final cropped = await pickAndCropProfileImage(
      context,
      kind: ProfileCropKind.cover,
    );
    if (cropped == null || !context.mounted) return;

    await ref
        .read(profileEditControllerProvider.notifier)
        .uploadCover(cropped.toXFile());
    if (!context.mounted) return;

    final error = ref.read(profileEditControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? 'Banner aktualisiert' : 'Fehler: $error',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final isUploading = ref.watch(profileEditControllerProvider).isLoading;
    final specialBadges = SpecialBadge.forProfile(profile);

    return SizedBox(
      height: _headerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                image: profile.coverUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(profile.coverUrl!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.35),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (showBackButton)
            Positioned(
              top: topInset + 8,
              left: 12,
              child: const _QuietBackButton(),
            ),
          if (isOwnProfile)
            Positioned(
              top: topInset + 8,
              right: 12,
              child: _EditPhotoButton(
                tooltip: 'Banner ändern',
                busy: isUploading,
                onTap: () => _pickCover(context, ref),
              ),
            ),
          Positioned(
            left: 24,
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: _avatarRadius,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: profile.avatarUrl != null
                            ? CachedNetworkImageProvider(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.username[0].toUpperCase(),
                                style: theme.textTheme.displaySmall,
                              )
                            : null,
                      ),
                    ),
                    if (isOwnProfile)
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: _EditPhotoButton(
                          tooltip: 'Profilbild ändern',
                          busy: isUploading,
                          compact: true,
                          onTap: () => _pickAvatar(context, ref),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 18),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          Text(
                            profile.username,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                            ),
                          ),
                          for (final badge in specialBadges)
                            SpecialBadgeButton(
                              badge: badge,
                              size: _badgeSize,
                              labelFontSize: _badgeLabelSize,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.ageLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (level != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            LevelLabelChip(
                              level: level!,
                              onTap: onLevelTap,
                              fontSize: _badgeLabelSize,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                            ),
                            if (LevelMilestone.currentFor(level!) != null)
                              _ProfileBadgeButton(
                                milestone: LevelMilestone.currentFor(level!)!,
                                badgeSize: _badgeSize,
                                labelFontSize: _badgeLabelSize,
                              ),
                          ],
                        ),
                      ],
                      if (profile.isBusinessProfile) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            profile.followerCount == 1
                                ? AppLocalizations.of(context).oneFollower
                                : AppLocalizations.of(context)
                                    .followersCount(profile.followerCount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aktuelles Level-Badge im Profil-Header (Tipp → Erklärung).
class _ProfileBadgeButton extends StatelessWidget {
  const _ProfileBadgeButton({
    required this.milestone,
    this.badgeSize = 44,
    this.labelFontSize = 13,
  });

  final LevelMilestone milestone;
  final double badgeSize;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = LevelBadgeTheme.forLevel(milestone.level);
    return InkWell(
      onTap: () => showLevelMilestoneDetails(
        context,
        milestone,
        unlocked: true,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LevelBadgeImage(milestone: milestone, size: badgeSize),
            const SizedBox(width: 8),
            Text(
              milestone.name,
              style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.w800,
                fontSize: labelFontSize,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPhotoButton extends StatelessWidget {
  const _EditPhotoButton({
    required this.onTap,
    required this.tooltip,
    this.busy = false,
    this.compact = false,
  });

  final VoidCallback onTap;
  final String tooltip;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 40.0;
    final iconSize = compact ? 16.0 : 18.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: busy ? null : onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.edit_outlined,
                    size: iconSize,
                    color: AppColors.brandNavy,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Dezenter Zurück-Button für Banner-Overlays (Quiet Luxury).
class _QuietBackButton extends StatelessWidget {
  const _QuietBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          } else if (context.canPop()) {
            context.pop();
          }
        },
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back,
            size: 22,
            color: AppColors.brandNavy,
          ),
        ),
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({
    required this.activities,
    required this.friends,
    required this.groups,
    required this.rating,
    required this.reviewCount,
    this.friendsLabel = '',
    this.hideGroups = false,
    this.onActivitiesTap,
    this.onFriendsTap,
    this.onGroupsTap,
    this.onRatingTap,
  });

  final int activities;
  final int friends;
  final int groups;
  final double rating;
  final int reviewCount;
  final String friendsLabel;
  final bool hideGroups;
  final VoidCallback? onActivitiesTap;
  final VoidCallback? onFriendsTap;
  final VoidCallback? onGroupsTap;
  final VoidCallback? onRatingTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          _StatItem(
            label: l10n.activities,
            value: '$activities',
            onTap: onActivitiesTap,
          ),
          _StatItem(
            label: friendsLabel.isEmpty ? l10n.friends : friendsLabel,
            value: '$friends',
            onTap: onFriendsTap,
          ),
          if (!hideGroups)
            _StatItem(
              label: AppLocalizations.of(context).groups,
              value: '$groups',
              onTap: onGroupsTap,
            ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRatingTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      if (rating > 0) ...[
                        Text(
                          rating.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.seed,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        StarRating(
                          value: rating,
                          size: 14,
                          interactive: false,
                        ),
                      ] else
                        Text(
                          '–',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.seed,
                                  ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        reviewCount > 0
                            ? 'Bewertung ($reviewCount)'
                            : 'Bewertung',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.seed,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          Text(l10n.bio, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(profile.bio!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
        ],
        Text(l10n.topInterests, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (profile.interests.isEmpty)
          Text(
            l10n.noInterestsYet,
            style: theme.textTheme.bodyMedium,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.interests
                .map(
                  (i) => Chip(
                    label: Text(i),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ProfileActivitiesTab extends ConsumerWidget {
  const _ProfileActivitiesTab({
    required this.profileId,
    required this.isOwnProfile,
  });

  final String profileId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (profileId: profileId, isOwn: isOwnProfile);
    final activitiesAsync = ref.watch(profileActivitiesProvider(args));
    final l10n = AppLocalizations.of(context);

    return activitiesAsync.when(
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
                    ref.invalidate(profileActivitiesProvider(args)),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                isOwnProfile
                    ? l10n.noActivitiesYet
                    : l10n.noVisibleActivities,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final created = activities
            .where((a) => a.viewerAction == ViewerAction.host)
            .toList();
        final other = activities
            .where((a) => a.viewerAction != ViewerAction.host)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileActivitiesProvider(args));
            if (isOwnProfile) {
              ref.invalidate(myActivitiesProvider);
            }
            await ref.read(profileActivitiesProvider(args).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (isOwnProfile && created.isNotEmpty) ...[
                Text(
                  'Erstellt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...created.map((activity) => _activityTile(context, activity)),
              ],
              if (isOwnProfile && other.isNotEmpty) ...[
                if (created.isNotEmpty) const SizedBox(height: 8),
                Text(
                  'Zugesagt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...other.map((activity) => _activityTile(context, activity)),
              ],
              if (!isOwnProfile)
                ...activities.map(
                  (activity) => _activityTile(context, activity),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _activityTile(BuildContext context, DiscoverableActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ActivityCard(
        activity: activity,
        onTap: () => context.pushNamed(
          RouteNames.activityDetail,
          pathParameters: {'id': activity.id},
          extra: activity,
        ),
      ),
    );
  }
}

class _ProfileGalleryTab extends ConsumerWidget {
  const _ProfileGalleryTab({
    required this.profileId,
    required this.isOwnProfile,
    required this.galleryPublic,
  });

  final String profileId;
  final bool isOwnProfile;
  final bool galleryPublic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOwnProfile) {
      final privacyState = ref.watch(galleryPrivacyControllerProvider);
      final isSaving = privacyState.isLoading;
      return Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            value: galleryPublic,
            onChanged: isSaving
                ? null
                : (value) async {
                    await ref
                        .read(galleryPrivacyControllerProvider.notifier)
                        .setGalleryPublic(value);
                    if (!context.mounted) return;
                    final error =
                        ref.read(galleryPrivacyControllerProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error == null
                              ? (value
                                  ? 'Alle Erinnerungen sind jetzt öffentlich'
                                  : 'Erinnerungen sind privat')
                              : 'Fehler: $error',
                        ),
                      ),
                    );
                  },
            title: const Text('Erinnerungen öffentlich'),
            subtitle: Text(
              galleryPublic
                  ? 'Alle deine Erinnerungen sind für andere sichtbar.'
                  : 'Wenn aktiv, werden alle Erinnerungen automatisch öffentlich.',
            ),
            secondary: Icon(
              galleryPublic ? Icons.public : Icons.lock_outline,
              color: AppColors.seed,
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: PastActivitiesGalleryScreen(embedded: true)),
        ],
      );
    }

    if (!galleryPublic) {
      return _PlaceholderTab(
        icon: Icons.lock_outline,
        text: AppLocalizations.of(context).memoriesPrivateHint,
      );
    }

    final galleryAsync = ref.watch(publicGalleryForProfileProvider(profileId));
    return galleryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) {
        if (items.isEmpty) {
          return _PlaceholderTab(
            icon: Icons.photo_library_outlined,
            text: AppLocalizations.of(context).noPublicMemories,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.5),
                ),
              ),
              leading: const Icon(Icons.public, color: AppColors.seed),
              title: Text(item.title),
              subtitle: Text(
                '${item.photoCount} '
                '${item.photoCount == 1 ? AppLocalizations.of(context).photoSingular : AppLocalizations.of(context).photoPlural}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(
                RouteNames.activityGallery,
                pathParameters: {'id': item.id},
                queryParameters: {'owner': profileId},
                extra: item.title,
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileReviewsTab extends ConsumerStatefulWidget {
  const _ProfileReviewsTab({
    required this.profileId,
    required this.isOwnProfile,
    required this.username,
    required this.canReview,
  });

  final String profileId;
  final bool isOwnProfile;
  final String username;
  final bool canReview;

  @override
  ConsumerState<_ProfileReviewsTab> createState() => _ProfileReviewsTabState();
}

class _ProfileReviewsTabState extends ConsumerState<_ProfileReviewsTab> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  var _hydratedMyReview = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _hydrateFromMyReview(UserReview? myReview) {
    if (_hydratedMyReview || myReview == null) return;
    _hydratedMyReview = true;
    _selectedRating = myReview.rating;
    _commentController.text = myReview.comment ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewsAsync = ref.watch(profileReviewsProvider(widget.profileId));
    final myReviewAsync = widget.isOwnProfile
        ? const AsyncValue<UserReview?>.data(null)
        : ref.watch(myReviewForProfileProvider(widget.profileId));
    final isSaving = ref.watch(reviewControllerProvider).isLoading;

    final myReview = myReviewAsync.valueOrNull;
    _hydrateFromMyReview(myReview);
    final displayRating =
        _selectedRating > 0 ? _selectedRating : (myReview?.rating ?? 0);

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (reviews) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (!widget.isOwnProfile && widget.canReview) ...[
              Text(
                myReview == null
                    ? '${widget.username} bewerten'
                    : 'Deine Bewertung aktualisieren',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sterne tippen zum Bewerten',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: StarRating(
                  value: displayRating.toDouble(),
                  size: 44,
                  interactive: true,
                  color: const Color(0xFFFFC107),
                  emptyColor: const Color(0xFFB0B8C4),
                  onChanged: (value) {
                    setState(() => _selectedRating = value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 280,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).optionalComment,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: isSaving || displayRating < 1
                    ? null
                    : () => _submit(displayRating),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        myReview == null
                            ? 'Bewertung absenden'
                            : 'Bewertung speichern',
                      ),
              ),
              const SizedBox(height: 28),
              Divider(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
            ] else if (!widget.isOwnProfile && !widget.canReview) ...[
              Text(
                AppLocalizations.of(context).reviewConnectedOnly,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Divider(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              AppLocalizations.of(context).allReviews,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  widget.isOwnProfile
                      ? AppLocalizations.of(context).noReviewsReceived
                      : AppLocalizations.of(context).noReviewsBeFirst,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...reviews.map((review) => _ReviewTile(review: review)),
          ],
        );
      },
    );
  }

  Future<void> _submit(int rating) async {
    if (rating < 1) return;

    await ref.read(reviewControllerProvider.notifier).submit(
          targetUserId: widget.profileId,
          rating: rating,
          comment: _commentController.text,
        );

    if (!mounted) return;
    final error = ref.read(reviewControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? 'Bewertung gespeichert' : 'Fehler: $error',
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final UserReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: review.reviewerAvatarUrl != null
                        ? CachedNetworkImageProvider(review.reviewerAvatarUrl!)
                        : null,
                    child: review.reviewerAvatarUrl == null
                        ? Text(review.reviewerUsername[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      review.reviewerUsername,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  StarRating(
                    value: review.rating.toDouble(),
                    size: 16,
                    interactive: false,
                  ),
                ],
              ),
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(review.comment!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: overlapsContent ? 1 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
