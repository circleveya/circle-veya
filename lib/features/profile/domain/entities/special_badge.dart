import 'user_profile.dart';

/// Sonder-Badges (Founder, Event, Team, Premium) neben dem Level-System.
enum SpecialBadgeType { founder, event, team, premium }

class SpecialBadge {
  const SpecialBadge({
    required this.type,
    required this.name,
    required this.descriptionDe,
    required this.descriptionEn,
    required this.assetPath,
  });

  final SpecialBadgeType type;
  final String name;
  final String descriptionDe;
  final String descriptionEn;
  final String assetPath;

  String descriptionFor(String languageCode) =>
      languageCode.startsWith('en') ? descriptionEn : descriptionDe;

  static const founder = SpecialBadge(
    type: SpecialBadgeType.founder,
    name: 'Veya Founder',
    assetPath: 'assets/badges/v3/founder.png',
    descriptionDe:
        'Mitgründer von CircleVeya – von Anfang an dabei und prägt die Plattform.',
    descriptionEn:
        'Co-founder of CircleVeya – here from the start and shaping the platform.',
  );

  static const event = SpecialBadge(
    type: SpecialBadgeType.event,
    name: 'Event Company',
    assetPath: 'assets/badges/v3/event_company.png',
    descriptionDe:
        'Offizielles Event-Profil – organisiert und bewirbt Aktivitäten auf CircleVeya.',
    descriptionEn:
        'Official event profile – organizes and promotes activities on CircleVeya.',
  );

  static const team = SpecialBadge(
    type: SpecialBadgeType.team,
    name: 'Veya Team',
    assetPath: 'assets/badges/v3/team.png',
    descriptionDe:
        'Mitglied des CircleVeya-Teams – unterstützt Community und Plattform.',
    descriptionEn:
        'Member of the CircleVeya team – supports the community and platform.',
  );

  static const premium = SpecialBadge(
    type: SpecialBadgeType.premium,
    name: 'Veya Premium',
    assetPath: 'assets/badges/v3/premium.png',
    descriptionDe:
        'Premium-Mitglied mit erweiterten Funktionen und größerer Reichweite.',
    descriptionEn:
        'Premium member with extended features and greater reach.',
  );

  /// Welche Sonder-Badges ein Profil anzeigen soll.
  static List<SpecialBadge> forProfile(UserProfile profile) {
    final badges = <SpecialBadge>[];

    if (profile.isFounder) {
      badges.add(founder);
    }
    if (profile.isBusinessProfile) {
      badges.add(event);
    }
    // Team-Badge folgt später für das Circle-Team.
    if (profile.isPremium) {
      badges.add(premium);
    }

    return badges;
  }
}
