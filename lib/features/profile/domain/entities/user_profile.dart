import 'package:equatable/equatable.dart';

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

  bool get isCompany => userType == 'company';

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
