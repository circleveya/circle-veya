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
    this.galleryPublic = false,
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
  final bool galleryPublic;

  ProfileAccountType get accountType => ProfileAccountType.fromDb(userType);

  /// Legacy: Business/Event-Partner (Sponsoring etc.).
  bool get isCompany => accountType.isEventOrganizer;

  bool get isEventOrganizer => accountType.isEventOrganizer;

  bool get isMarketing => accountType.isMarketing;

  bool get isDev => accountType.isDev;

  bool get isTeam => accountType.isTeam;

  String get ageLabel => age != null ? '$age Jahre' : 'Alter nicht angegeben';

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    int? age,
    List<String>? interests,
    bool? galleryPublic,
    bool clearBio = false,
    bool clearAge = false,
    bool clearAvatar = false,
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
      galleryPublic: galleryPublic ?? this.galleryPublic,
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
        galleryPublic,
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
