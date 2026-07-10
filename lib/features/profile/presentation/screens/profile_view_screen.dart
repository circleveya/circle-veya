import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../friends/domain/entities/connection.dart';
import '../../../friends/presentation/providers/friends_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';

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

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (profile) => _ProfileBody(
        profile: profile,
        isOwnProfile: widget.isOwnProfile,
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
    final activityCount = isOwnProfile
        ? ref.watch(hostedActivitiesProvider).valueOrNull?.length ?? 0
        : 0;

    final level = statsAsync.valueOrNull?.level ?? 1;
    final rating = ratingAsync.valueOrNull?.avgRating ?? 0.0;

    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileCoverHeader(
            profile: profile,
            isOwnProfile: isOwnProfile,
            level: level,
          ),
        ),
        SliverToBoxAdapter(
          child: _ProfileStatsRow(
            activities: activityCount,
            friends: friendCount,
            groups: 0,
            rating: rating,
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
              _PlaceholderTab(
                icon: Icons.event_outlined,
                text: 'Aktivitäten des Users – bald verfügbar.',
              ),
              _PlaceholderTab(
                icon: Icons.photo_library_outlined,
                text: 'Erinnerungen – unter Erinnerungen in der Navigation.',
              ),
              _PlaceholderTab(
                icon: Icons.star_outline,
                text: 'Bewertungen – Phase 2.',
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
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                          Text(
                            profile.username,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({
    required this.activities,
    required this.friends,
    required this.groups,
    required this.rating,
  });

  final int activities;
  final int friends;
  final int groups;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          _StatItem(label: 'Aktivitäten', value: '$activities'),
          _StatItem(label: 'Freunde', value: '$friends'),
          _StatItem(label: 'Gruppen', value: '$groups'),
          _StatItem(label: 'Bewertung', value: rating > 0 ? rating.toStringAsFixed(1) : '–'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
