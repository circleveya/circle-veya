import 'package:equatable/equatable.dart';

class UserChallenge extends Equatable {
  const UserChallenge({
    required this.id,
    required this.title,
    required this.progress,
    required this.target,
    this.isActive = true,
  });

  final String id;
  final String title;
  final int progress;
  final int target;
  final bool isActive;

  double get progressRatio =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [id, title, progress, target, isActive];
}

class UserLevelStats extends Equatable {
  const UserLevelStats({
    required this.level,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.challenges,
    required this.interestScores,
  });

  final int level;
  final int currentXp;
  final int xpForNextLevel;
  final List<UserChallenge> challenges;
  final Map<String, double> interestScores;

  double get levelProgress =>
      xpForNextLevel > 0 ? (currentXp / xpForNextLevel).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props =>
      [level, currentXp, xpForNextLevel, challenges, interestScores];
}

/// Mock-Daten bis Supabase-Challenges-Tabelle existiert.
const kMockLevelStats = UserLevelStats(
  level: 23,
  currentXp: 2400,
  xpForNextLevel: 3300,
  challenges: [
    UserChallenge(
      id: '1',
      title: '3 Aktivitäten diese Woche',
      progress: 2,
      target: 3,
    ),
    UserChallenge(
      id: '2',
      title: 'Neue Freunde treffen',
      progress: 1,
      target: 4,
    ),
    UserChallenge(
      id: '3',
      title: 'Sport-Challenge',
      progress: 5,
      target: 10,
    ),
  ],
  interestScores: {
    'Sport': 0.85,
    'Outdoor': 0.7,
    'Kultur': 0.45,
    'Social': 0.6,
  },
);
