import 'package:supabase_flutter/supabase_flutter.dart';

class TrendingActivityItem {
  const TrendingActivityItem({
    required this.activityId,
    required this.title,
    required this.participantCount,
    this.source = 'user',
    this.externalProvider,
  });

  final String activityId;
  final String title;
  final int participantCount;
  final String source;
  final String? externalProvider;

  String get subtitle {
    if (source == 'external') {
      final provider = externalProvider ?? 'Automatisch';
      return 'Automatisch · $provider · $participantCount Interessenten';
    }
    return '$participantCount Teilnehmer';
  }
}

class RecommendedActivityItem {
  const RecommendedActivityItem({
    required this.activityId,
    required this.title,
    required this.matchScore,
    this.distanceKm,
  });

  final String activityId;
  final String title;
  final int matchScore;
  final double? distanceKm;
}

class OnlineFriendItem {
  const OnlineFriendItem({
    required this.profileId,
    required this.username,
    this.avatarUrl,
  });

  final String profileId;
  final String username;
  final String? avatarUrl;
}

class SidebarRemoteDatasource {
  SidebarRemoteDatasource(this._client);

  final SupabaseClient _client;

  Future<List<TrendingActivityItem>> getTrending({int limit = 3}) async {
    final response = await _client.rpc(
      'get_trending_activities',
      params: {'p_limit': limit},
    );

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return TrendingActivityItem(
        activityId: map['activity_id'] as String,
        title: map['title'] as String,
        participantCount: map['participant_count'] as int? ?? 0,
        source: map['source'] as String? ?? 'user',
        externalProvider: map['external_provider'] as String?,
      );
    }).toList();
  }

  Future<List<RecommendedActivityItem>> getRecommended({int limit = 5}) async {
    final response = await _client.rpc(
      'get_recommended_activities',
      params: {'p_limit': limit},
    );

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return RecommendedActivityItem(
        activityId: map['activity_id'] as String,
        title: map['title'] as String,
        matchScore: map['match_score'] as int? ?? 0,
        distanceKm: (map['distance_km'] as num?)?.toDouble(),
      );
    }).toList();
  }

  Future<List<OnlineFriendItem>> getOnlineFriends() async {
    final response = await _client.rpc('get_online_friends');

    return (response as List).map((row) {
      final map = row as Map<String, dynamic>;
      return OnlineFriendItem(
        profileId: map['profile_id'] as String,
        username: map['username'] as String,
        avatarUrl: map['avatar_url'] as String?,
      );
    }).toList();
  }

  Future<void> heartbeatPresence() async {
    await _client.rpc('heartbeat_presence');
  }

  Future<void> leavePresence() async {
    await _client.rpc('leave_presence');
  }
}
