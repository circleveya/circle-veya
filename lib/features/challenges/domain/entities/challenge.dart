import 'package:equatable/equatable.dart';

import '../../../../l10n/app_localizations.dart';

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
    this.resetCadence = 'none',
    this.periodKey,
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
  final String resetCadence;
  final String? periodKey;

  double get progressRatio =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  bool get isComplete => progress >= target;

  bool get isWeekly => resetCadence == 'weekly' || challengeType == 'weekly';

  bool get isMonthly =>
      resetCadence == 'monthly' ||
      challengeType == 'monthly' ||
      challengeType == 'social' ||
      challengeType == 'sport';

  String localizedPeriodBadge(AppLocalizations l10n) => switch (resetCadence) {
        'weekly' => l10n.weekly,
        'monthly' => l10n.monthly,
        _ => switch (challengeType) {
            'weekly' => l10n.weekly,
            'monthly' || 'social' || 'sport' => l10n.monthly,
            _ => l10n.challenge,
          },
      };

  @Deprecated('Use localizedPeriodBadge(AppLocalizations)')
  String get periodBadgeLabel => switch (resetCadence) {
        'weekly' => 'Wöchentlich',
        'monthly' => 'Monatlich',
        _ => switch (challengeType) {
            'weekly' => 'Wöchentlich',
            'monthly' || 'social' || 'sport' => 'Monatlich',
            _ => 'Challenge',
          },
      };

  String localizedResetHint(AppLocalizations l10n) => switch (resetCadence) {
        'weekly' => l10n.weeklyReset,
        'monthly' => l10n.monthlyReset,
        _ => switch (challengeType) {
            'weekly' => l10n.weeklyReset,
            'monthly' || 'social' || 'sport' => l10n.monthlyReset,
            _ => l10n.onceOnly,
          },
      };

  @Deprecated('Use localizedResetHint(AppLocalizations)')
  String get resetHint => switch (resetCadence) {
        'weekly' => 'Reset jeden Montag',
        'monthly' => 'Reset am 1. des Monats',
        _ => switch (challengeType) {
            'weekly' => 'Reset jeden Montag',
            'monthly' || 'social' || 'sport' => 'Reset am 1. des Monats',
            _ => 'Einmalig',
          },
      };

  String localizedHowTo(AppLocalizations l10n) {
    return switch (challengeType) {
      'weekly' => l10n.challengeHowToWeekly,
      'monthly' => l10n.challengeHowToMonthly,
      'social' => l10n.challengeHowToSocial,
      'sport' => l10n.challengeHowToSport,
      _ => (howTo != null && howTo!.trim().isNotEmpty)
          ? howTo!
          : l10n.challengeHowToDefault,
    };
  }

  String localizedTitle(AppLocalizations l10n) => switch (challengeType) {
        'weekly' => l10n.challengeTitleWeekly(target),
        'monthly' => l10n.challengeTitleMonthly(target),
        'social' => l10n.challengeTitleSocial(target),
        'sport' => l10n.challengeTitleSport(target),
        _ => title,
      };

  String localizedDescription(AppLocalizations l10n) =>
      switch (challengeType) {
        'weekly' => l10n.challengeDescWeekly,
        'monthly' => l10n.challengeDescMonthly,
        'social' => l10n.challengeDescSocial,
        'sport' => l10n.challengeDescSport,
        _ => (description != null && description!.trim().isNotEmpty)
            ? description!
            : localizedHowTo(l10n),
      };

  @Deprecated('Use localizedHowTo(AppLocalizations)')
  String get resolvedHowTo {
    if (howTo != null && howTo!.trim().isNotEmpty) return howTo!;
    return switch (challengeType) {
      'weekly' =>
        'Erstelle oder nimm an Aktivitäten teil – zählt diese Woche (Reset Montag).',
      'monthly' =>
        'Erstelle oder nimm an Aktivitäten teil – zählt diesen Monat (Reset am 1.).',
      'social' =>
        'Schließe neue Freundschaften – zählt diesen Monat (Reset am 1.).',
      'sport' =>
        'Nimm an Sport-/Outdoor-Aktivitäten teil – zählt diesen Monat (Reset am 1.).',
      _ => 'Erfülle das Ziel, um die Belohnung abzuholen.',
    };
  }

  @Deprecated('Use localizedDescription(AppLocalizations)')
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
        resetCadence,
        periodKey,
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

  List<UserChallenge> get weeklyChallenges =>
      challenges.where((c) => c.isWeekly).toList();

  List<UserChallenge> get monthlyChallenges =>
      challenges.where((c) => c.isMonthly && !c.isWeekly).toList();

  List<UserChallenge> get otherChallenges =>
      challenges.where((c) => !c.isWeekly && !c.isMonthly).toList();

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
      resetCadence: 'weekly',
      xpReward: 150,
      description:
          'Nimm diese Woche an Aktivitäten teil oder erstelle eigene. Reset jeden Montag.',
      howTo:
          'Erstelle oder nimm an Aktivitäten teil – zählt diese Woche (Reset Montag).',
    ),
    UserChallenge(
      id: '2',
      title: '5 Aktivitäten diesen Monat',
      progress: 0,
      target: 5,
      challengeType: 'monthly',
      resetCadence: 'monthly',
      xpReward: 250,
      description:
          'Nimm diesen Monat an Aktivitäten teil. Reset am 1. des Monats.',
      howTo:
          'Erstelle oder nimm an Aktivitäten teil – zählt diesen Monat (Reset am 1.).',
    ),
    UserChallenge(
      id: '3',
      title: '4 neue Freunde diesen Monat',
      progress: 0,
      target: 4,
      challengeType: 'social',
      resetCadence: 'monthly',
      xpReward: 200,
      description:
          'Erweitere deinen Kreis und lerne neue Leute kennen. Reset am 1. des Monats.',
      howTo:
          'Schließe neue Freundschaften – zählt diesen Monat (Reset am 1.).',
    ),
  ],
  interestScores: {},
);
