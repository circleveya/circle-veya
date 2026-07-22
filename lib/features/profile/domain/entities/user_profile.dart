import 'package:equatable/equatable.dart';

/// Account-/Profiltypen in CircleVeya.
enum ProfileAccountType {
  standard,
  event,
  company,
  marketing,
  dev;

  static ProfileAccountType fromDb(String? value) => switch (value) {
        'event' => event,
        'company' => company,
        'marketing' => marketing,
        'dev' => dev,
        _ => standard,
      };

  String get dbValue => name;

  /// Für Auth-Signup-Metadaten (dev/marketing nie wählbar).
  String get signupValue => switch (this) {
        event || company => 'event',
        _ => 'standard',
      };

  String get label => switch (this) {
        standard => 'Privatperson',
        event => 'Event-Profil',
        company => 'Event-Profil',
        marketing => 'Marketing',
        dev => 'Developer',
      };

  String get shortBadge => switch (this) {
        standard => 'Mitglied',
        event => 'Event',
        company => 'Event',
        marketing => 'Marketing',
        dev => 'Dev',
      };

  String get description => switch (this) {
        standard => 'Für Leute, die mitmachen und Freunde treffen wollen.',
        event || company =>
          'Für Event-Manager und Geschäfte, die Events hochladen.',
        marketing => 'Marketing & Markenaufbau für CircleVeya.',
        dev => 'App-Besitzer / Developer',
      };

  bool get isEventOrganizer =>
      this == event || this == company || this == dev;

  bool get isMarketing => this == marketing;

  bool get isDev => this == dev;

  bool get isTeam => this == marketing || this == dev;

  /// Event-/Unternehmens-Profile (ohne persönliches Level).
  bool get isBusinessProfile => this == event || this == company;
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.age,
    this.interests = const [],
    this.userType = 'standard',
    this.isPremium = false,
    this.isFounder = false,
    this.galleryPublic = false,
    this.profilePrivate = false,
    this.canViewFullProfile = true,
    this.canReview = false,
    this.level = 1,
    this.followedByMe = false,
    this.followerCount = 0,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final int? age;
  final List<String> interests;
  final String userType;
  final bool isPremium;
  final bool isFounder;
  final bool galleryPublic;
  final bool profilePrivate;
  /// Ob der aktuelle Betrachter Bio, Aktivitäten, Level usw. sehen darf.
  final bool canViewFullProfile;
  /// Ob der aktuelle Betrachter eine Bewertung abgeben darf.
  final bool canReview;
  /// `null` bei Event-/Unternehmens-Profilen (kein Level-System).
  final int? level;
  final bool followedByMe;
  final int followerCount;

  ProfileAccountType get accountType => ProfileAccountType.fromDb(userType);

  /// Legacy: Business/Event-Partner (Sponsoring etc.).
  bool get isCompany => accountType.isEventOrganizer;

  bool get isEventOrganizer => accountType.isEventOrganizer;

  bool get isMarketing => accountType.isMarketing;

  bool get isDev => accountType.isDev;

  bool get isTeam => accountType.isTeam;

  bool get isBusinessProfile => accountType.isBusinessProfile;

  bool get hasLevelSystem => !isBusinessProfile;

  String get ageLabel => age != null ? '$age Jahre' : 'Alter nicht angegeben';

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    int? age,
    List<String>? interests,
    bool? galleryPublic,
    bool? profilePrivate,
    bool? canViewFullProfile,
    bool? canReview,
    int? level,
    bool? followedByMe,
    int? followerCount,
    bool clearBio = false,
    bool clearAge = false,
    bool clearAvatar = false,
    bool clearLevel = false,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      coverUrl: coverUrl ?? this.coverUrl,
      bio: clearBio ? null : (bio ?? this.bio),
      age: clearAge ? null : (age ?? this.age),
      interests: interests ?? this.interests,
      userType: userType,
      isPremium: isPremium,
      isFounder: isFounder,
      galleryPublic: galleryPublic ?? this.galleryPublic,
      profilePrivate: profilePrivate ?? this.profilePrivate,
      canViewFullProfile: canViewFullProfile ?? this.canViewFullProfile,
      canReview: canReview ?? this.canReview,
      level: clearLevel ? null : (level ?? this.level),
      followedByMe: followedByMe ?? this.followedByMe,
      followerCount: followerCount ?? this.followerCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        avatarUrl,
        coverUrl,
        bio,
        age,
        interests,
        userType,
        isPremium,
        isFounder,
        galleryPublic,
        profilePrivate,
        canViewFullProfile,
        canReview,
        level,
        followedByMe,
        followerCount,
      ];
}

class UpdateProfileInput extends Equatable {
  const UpdateProfileInput({
    required this.username,
    this.bio,
    this.age,
    this.interests = const [],
  });

  final String username;
  final String? bio;
  final int? age;
  final List<String> interests;

  @override
  List<Object?> get props => [username, bio, age, interests];
}
