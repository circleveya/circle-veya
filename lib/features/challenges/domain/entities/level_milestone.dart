/// Level-Meilensteine (Badges) für CircleVeya.
class LevelMilestone {
  const LevelMilestone({
    required this.level,
    required this.name,
    required this.descriptionDe,
    required this.descriptionEn,
    this.assetPath,
  });

  final int level;
  final String name;
  final String descriptionDe;
  final String descriptionEn;

  /// Optionales Badge-Bild unter `assets/badges/`.
  final String? assetPath;

  bool get hasBadgeImage => assetPath != null && assetPath!.isNotEmpty;

  String descriptionFor(String languageCode) =>
      languageCode.startsWith('en') ? descriptionEn : descriptionDe;

  /// Alias für DE (Fallback).
  String get description => descriptionDe;

  static const List<LevelMilestone> all = [
    LevelMilestone(
      level: 5,
      name: 'Spark',
      assetPath: 'assets/badges/v3/spark_5.png',
      descriptionDe:
          'Du hast den ersten Funken gezündet und bist aktiv geworden.',
      descriptionEn: 'You’ve sparked your first flame and become active.',
    ),
    LevelMilestone(
      level: 10,
      name: 'Starter',
      assetPath: 'assets/badges/v3/starter_10.png',
      descriptionDe:
          'Du beginnst, Kontakte zu knüpfen und Aktivitäten zu entdecken.',
      descriptionEn:
          'You’re starting to make connections and discover activities.',
    ),
    LevelMilestone(
      level: 15,
      name: 'Gatherer',
      assetPath: 'assets/badges/v3/gatherer_15.png',
      descriptionDe:
          'Du bringst Menschen zusammen und sammelst erste gemeinsame Momente.',
      descriptionEn:
          'You bring people together and collect first shared moments.',
    ),
    LevelMilestone(
      level: 20,
      name: 'Explorer',
      assetPath: 'assets/badges/v3/explorer_20.png',
      descriptionDe: 'Du entdeckst neue Orte, Aktivitäten und Menschen.',
      descriptionEn: 'You discover new places, activities, and people.',
    ),
    LevelMilestone(
      level: 25,
      name: 'Builder',
      assetPath: 'assets/badges/v3/builder_25.png',
      descriptionDe:
          'Du baust eigene Verbindungen auf und kannst Communitys mitgestalten.',
      descriptionEn:
          'You build your own connections and help shape communities.',
    ),
    LevelMilestone(
      level: 30,
      name: 'Seeker',
      assetPath: 'assets/badges/v3/seeker_30.png',
      descriptionDe:
          'Du suchst aktiv nach neuen Erlebnissen und spannenden Events.',
      descriptionEn:
          'You actively look for new experiences and exciting events.',
    ),
    LevelMilestone(
      level: 35,
      name: 'Connector',
      assetPath: 'assets/badges/v3/connector_35.png',
      descriptionDe:
          'Du verbindest Menschen durch gemeinsame Interessen und Aktivitäten.',
      descriptionEn:
          'You connect people through shared interests and activities.',
    ),
    LevelMilestone(
      level: 40,
      name: 'Creator',
      assetPath: 'assets/badges/v3/creator_40.png',
      descriptionDe:
          'Du erstellst eigene Aktivitäten und sorgst für neue Erlebnisse.',
      descriptionEn:
          'You create your own activities and bring new experiences.',
    ),
    LevelMilestone(
      level: 45,
      name: 'Guide',
      assetPath: 'assets/badges/v3/guide_45.png',
      descriptionDe:
          'Du zeigst anderen gute Orte, Events und neue Möglichkeiten.',
      descriptionEn: 'You show others great places, events, and opportunities.',
    ),
    LevelMilestone(
      level: 50,
      name: 'Captain',
      assetPath: 'assets/badges/v3/captain_50.png',
      descriptionDe:
          'Du führst Gruppen an und bist ein aktiver Teil der Community.',
      descriptionEn:
          'You lead groups and are an active part of the community.',
    ),
    LevelMilestone(
      level: 55,
      name: 'Collector',
      descriptionDe:
          'Du hast viele Erinnerungen und gemeinsame Aktivitäten gesammelt.',
      descriptionEn:
          'You’ve collected many memories and shared activities.',
    ),
    LevelMilestone(
      level: 60,
      name: 'Pathfinder',
      descriptionDe:
          'Du findest neue Wege, Menschen und Erlebnisse zusammenzubringen.',
      descriptionEn:
          'You find new ways to bring people and experiences together.',
    ),
    LevelMilestone(
      level: 65,
      name: 'Ambassador',
      descriptionDe:
          'Du repräsentierst CircleVeya und hilfst der Community zu wachsen.',
      descriptionEn:
          'You represent CircleVeya and help the community grow.',
    ),
    LevelMilestone(
      level: 70,
      name: 'Master',
      descriptionDe:
          'Du hast viel Erfahrung mit Aktivitäten, Gruppen und Events gesammelt.',
      descriptionEn:
          'You’ve gained lots of experience with activities, groups, and events.',
    ),
    LevelMilestone(
      level: 75,
      name: 'Hero',
      descriptionDe:
          'Du bist eine wichtige Person in der Community und bringst echten Mehrwert.',
      descriptionEn:
          'You’re a key person in the community and create real value.',
    ),
    LevelMilestone(
      level: 80,
      name: 'Guardian',
      descriptionDe:
          'Du hilfst, die Community positiv, sicher und aktiv zu halten.',
      descriptionEn:
          'You help keep the community positive, safe, and active.',
    ),
    LevelMilestone(
      level: 85,
      name: 'Champion',
      descriptionDe:
          'Du gehörst zu den besonders aktiven und geschätzten Nutzern.',
      descriptionEn:
          'You’re among the most active and valued members.',
    ),
    LevelMilestone(
      level: 90,
      name: 'Host Legend',
      descriptionDe:
          'Deine Aktivitäten sind beliebt und bringen regelmäßig Menschen zusammen.',
      descriptionEn:
          'Your activities are popular and regularly bring people together.',
    ),
    LevelMilestone(
      level: 95,
      name: 'Circle Icon',
      descriptionDe:
          'Du bist ein bekanntes Gesicht innerhalb der CircleVeya-Community.',
      descriptionEn: 'You’re a familiar face in the CircleVeya community.',
    ),
    LevelMilestone(
      level: 100,
      name: 'Veya Legend',
      descriptionDe:
          'Die höchste Auszeichnung: Du bist eine echte CircleVeya-Legende.',
      descriptionEn:
          'The highest honor: you’re a true CircleVeya legend.',
    ),
  ];

  /// Höchster freigeschalteter Meilenstein für [userLevel], sonst `null`.
  static LevelMilestone? currentFor(int userLevel) {
    LevelMilestone? best;
    for (final m in all) {
      if (m.level <= userLevel) {
        best = m;
      } else {
        break;
      }
    }
    return best;
  }

  static List<LevelMilestone> unlocked(int userLevel) =>
      all.where((m) => m.level <= userLevel).toList();

  static List<LevelMilestone> locked(int userLevel) =>
      all.where((m) => m.level > userLevel).toList();

  bool isUnlockedFor(int userLevel) => level <= userLevel;
}
