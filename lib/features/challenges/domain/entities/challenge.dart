import 'package:equatable/equatable.dart';

class UserChallenge extends Equatable {
  const UserChallenge({
    required this.id,
    required this.title,
    required this.progress,
    required this.target,
    this.isActive = true,
    this.challengeType = 'weekly',
    this.xpReward = 100,
    this.description,
    this.howTo,
  });

  final String id;
  final String title;
  final int progress;
  final int target;
  final bool isActive;
  final String challengeType;
  final int xpReward;
  final String? description;
  final String? howTo;

  double get progressRatio =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  bool get isComplete => progress >= target;

  String get resolvedHowTo {
    if (howTo != null && howTo!.trim().isNotEmpty) return howTo!;
    return switch (challengeType) {
      'weekly' => 'Erstelle oder nimm an Aktivitäten teil – zählt diese Woche.',
      'social' => 'Schließe neue Freundschaften und triff dich über Circle.',
      'sport' => 'Nimm an Sport-/Outdoor-Aktivitäten teil.',
      _ => 'Erfülle das Ziel, um die Belohnung abzuholen.',
    };
  }

  String get resolvedDescription {
    if (description != null && description!.trim().isNotEmpty) {
      return description!;
    }
    return resolvedHowTo;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        progress,
        target,
        isActive,
        challengeType,
        xpReward,
        description,
        howTo,
      ];
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

/// Fallback, falls Stats noch nicht geladen werden können.
const kMockLevelStats = UserLevelStats(
  level: 1,
  currentXp: 0,
  xpForNextLevel: 1000,
  challenges: [
    UserChallenge(
      id: '1',
      title: '3 Aktivitäten diese Woche',
      progress: 0,
      target: 3,
      challengeType: 'weekly',
      xpReward: 150,
      description: 'Nimm diese Woche an Aktivitäten teil oder erstelle eigene.',
      howTo: 'Erstelle oder nimm an Aktivitäten teil – zählt diese Woche.',
    ),
    UserChallenge(
      id: '2',
      title: 'Neue Freunde treffen',
      progress: 0,
      target: 4,
      challengeType: 'social',
      xpReward: 200,
      description: 'Erweitere deinen Kreis und lerne neue Leute kennen.',
      howTo: 'Schließe neue Freundschaften und triff dich über Circle.',
    ),
    UserChallenge(
      id: '3',
      title: 'Sport-Challenge',
      progress: 0,
      target: 10,
      challengeType: 'sport',
      xpReward: 300,
      description: 'Bleib aktiv mit Sport- und Outdoor-Aktivitäten.',
      howTo: 'Nimm an Sport-/Outdoor-Aktivitäten teil.',
    ),
  ],
  interestScores: {},
);
