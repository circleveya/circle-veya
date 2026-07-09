import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/sidebar_remote_datasource.dart';

final sidebarRemoteDatasourceProvider = Provider<SidebarRemoteDatasource>((ref) {
  return SidebarRemoteDatasource(ref.watch(supabaseClientProvider));
});

final trendingActivitiesProvider =
    FutureProvider.autoDispose<List<TrendingActivityItem>>((ref) async {
  return ref.watch(sidebarRemoteDatasourceProvider).getTrending();
});

final recommendedActivitiesProvider =
    FutureProvider.autoDispose<List<RecommendedActivityItem>>((ref) async {
  return ref.watch(sidebarRemoteDatasourceProvider).getRecommended();
});

final onlineFriendsProvider =
    FutureProvider.autoDispose<List<OnlineFriendItem>>((ref) async {
  return ref.watch(sidebarRemoteDatasourceProvider).getOnlineFriends();
});

final presenceHeartbeatProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.watch(sidebarRemoteDatasourceProvider).heartbeatPresence();
});
