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
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../friends/domain/entities/connection.dart';
import '../../../friends/presentation/providers/friends_provider.dart';
import '../../../gallery/presentation/providers/gallery_provider.dart';
import '../../../gallery/presentation/screens/activity_gallery_screen.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_review.dart';
import '../providers/profile_provider.dart';
import '../widgets/star_rating.dart';

class ProfileViewScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(widget.profileId));
    final sessionUserId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final isOwnProfile = widget.isOwnProfile ||
        (sessionUserId != null && sessionUserId == widget.profileId);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (profile) => _ProfileBody(
        profile: profile,
        isOwnProfile: isOwnProfile,
        embedded: widget.embedded,
        tabController: _tabController,
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
    required this.profile,
    required this.isOwnProfile,
    required this.embedded,
    required this.tabController,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final bool embedded;
  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final level = statsAsync.valueOrNull?.level ?? 1;
    final rating = ratingAsync.valueOrNull?.avgRating ?? 0.0;
    final reviewCount = ratingAsync.valueOrNull?.reviewCount ?? 0;

    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileCoverHeader(
            profile: profile,
            isOwnProfile: isOwnProfile,
            level: level,
            showBackButton: !embedded,
          ),
        ),
        SliverToBoxAdapter(
          child: _ProfileStatsRow(
            activities: activityCount,
            friends: friendCount,
            groups: groupCount,
            rating: rating,
            reviewCount: reviewCount,
            onActivitiesTap: () => tabController.animateTo(1),
            onFriendsTap: isOwnProfile
                ? () {
                    ref
                        .read(shellDestinationRequestProvider.notifier)
                        .goTo(WebShellDestination.friends);
                    if (!embedded) {
                      context.goNamed(RouteNames.home);
                    }
                  }
                : null,
            onGroupsTap: isOwnProfile
                ? () {
                    ref
                        .read(shellDestinationRequestProvider.notifier)
                        .goTo(WebShellDestination.groups);
                    if (!embedded) {
                      context.goNamed(RouteNames.home);
                    }
                  }
                : null,
            onRatingTap: () => tabController.animateTo(3),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Über mich'),
                Tab(text: 'Aktivitäten'),
                Tab(text: 'Galerie'),
                Tab(text: 'Bewertungen'),
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
              _ProfileGalleryTab(
                profileId: profile.id,
                isOwnProfile: isOwnProfile,
                galleryPublic: profile.galleryPublic,
              ),
              _ProfileReviewsTab(
                profileId: profile.id,
                isOwnProfile: isOwnProfile,
                username: profile.username,
              ),
            ],
          ),
        ),
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
              label: const Text('Bearbeiten'),
            )
          : null,
    );
  }
}

class _ProfileCoverHeader extends StatelessWidget {
  const _ProfileCoverHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.level,
    this.showBackButton = false,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final int level;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 280,
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
                    : profile.avatarUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(profile.avatarUrl!),
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
          Positioned(
            left: 24,
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
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
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.username,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (profile.isPremium) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium,
                                    size: 14,
                                    color: AppColors.brandNavy,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: AppColors.brandNavy,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (profile.isCompany) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.white),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.ageLabel,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          'Level $level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
  final VoidCallback? onActivitiesTap;
  final VoidCallback? onFriendsTap;
  final VoidCallback? onGroupsTap;
  final VoidCallback? onRatingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          _StatItem(
            label: 'Aktivitäten',
            value: '$activities',
            onTap: onActivitiesTap,
          ),
          _StatItem(
            label: 'Freunde',
            value: '$friends',
            onTap: onFriendsTap,
          ),
          _StatItem(
            label: 'Kreise',
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          Text('Bio', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(profile.bio!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
        ],
        Text('Top Interessen', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (profile.interests.isEmpty)
          Text(
            'Noch keine Interessen hinterlegt.',
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
                child: const Text('Erneut versuchen'),
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
                    ? 'Noch keine Aktivitäten.\n'
                        'Erstelle eine oder sage bei Freunden zu.'
                    : 'Keine sichtbaren Aktivitäten.',
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
                                  ? 'Erinnerungen sind öffentlich'
                                  : 'Erinnerungen sind privat')
                              : 'Fehler: $error',
                        ),
                      ),
                    );
                  },
            title: const Text('Erinnerungen öffentlich'),
            subtitle: Text(
              galleryPublic
                  ? 'Andere sehen nur Erinnerungen, die du einzeln freigibst.'
                  : 'Wenn aktiv, können andere freigegebene Erinnerungen sehen.',
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
      return const _PlaceholderTab(
        icon: Icons.lock_outline,
        text: 'Erinnerungen sind privat und nur für den Account-Inhaber sichtbar.',
      );
    }

    final galleryAsync = ref.watch(publicGalleryForProfileProvider(profileId));
    return galleryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) {
        if (items.isEmpty) {
          return const _PlaceholderTab(
            icon: Icons.photo_library_outlined,
            text: 'Noch keine öffentlichen Erinnerungen.',
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
              subtitle: Text('${item.photoCount} Fotos'),
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
  });

  final String profileId;
  final bool isOwnProfile;
  final String username;

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
            if (!widget.isOwnProfile) ...[
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
                decoration: const InputDecoration(
                  hintText: 'Optionaler Kommentar',
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
            ],
            Text(
              'Alle Bewertungen',
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
                      ? 'Noch keine Bewertungen erhalten.'
                      : 'Noch keine Bewertungen – sei die erste Person.',
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
