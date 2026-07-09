import 'package:equatable/equatable.dart';

import 'activity_enums.dart';
import 'activity_filters.dart';

class DiscoverableActivity extends Equatable {
  const DiscoverableActivity({
    required this.id,
    required this.hostId,
    required this.hostUsername,
    required this.hostIsCompany,
    required this.title,
    this.description,
    this.maxParticipants,
    required this.currentParticipants,
    this.dateTime,
    this.imageUrl,
    required this.locationType,
    required this.weatherCondition,
    this.locationName,
    this.distanceKm,
    required this.visibleAs,
    required this.viewerAction,
    this.isSponsored = false,
    this.isFeatured = false,
    this.source = ActivitySource.user,
    this.externalUrl,
    this.createdAt,
    this.participantAvatarUrls = const [],
  });

  final String id;
  final String hostId;
  final String hostUsername;
  final bool hostIsCompany;
  final String title;
  final String? description;
  final int? maxParticipants;
  final int currentParticipants;
  final DateTime? dateTime;
  final String? imageUrl;
  final LocationType locationType;
  final WeatherCondition weatherCondition;
  final String? locationName;
  final double? distanceKm;
  final VisibleAs visibleAs;
  final ViewerAction viewerAction;
  final bool isSponsored;
  final bool isFeatured;
  final ActivitySource source;
  final String? externalUrl;
  final DateTime? createdAt;
  final List<String> participantAvatarUrls;

  bool get isExternal => source == ActivitySource.external;

  bool get isNew {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!) < const Duration(hours: 48);
  }

  String get participantsLabel {
    if (maxParticipants != null) {
      return '$currentParticipants / $maxParticipants';
    }
    return '$currentParticipants';
  }

  @override
  List<Object?> get props => [
        id,
        hostId,
        hostUsername,
        hostIsCompany,
        title,
        description,
        maxParticipants,
        currentParticipants,
        dateTime,
        imageUrl,
        locationType,
        weatherCondition,
        locationName,
        distanceKm,
        visibleAs,
        viewerAction,
        isSponsored,
        isFeatured,
        source,
        externalUrl,
        createdAt,
        participantAvatarUrls,
      ];
}

enum ActivitySource {
  user,
  external;

  static ActivitySource fromDb(String? value) => switch (value) {
        'external' => ActivitySource.external,
        _ => ActivitySource.user,
      };
}

class CreateActivityInput extends Equatable {
  const CreateActivityInput({
    required this.title,
    this.description,
    required this.maxParticipants,
    this.dateTime,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.locationType,
    required this.weatherCondition,
    required this.visibleToFriends,
    required this.visibleToAcquaintances,
    required this.visibleToStrangers,
    this.discoveryRadiusKm = 20,
    this.isSponsored = false,
  });

  final String title;
  final String? description;
  final int maxParticipants;
  final DateTime? dateTime;
  final double latitude;
  final double longitude;
  final String? locationName;
  final LocationType locationType;
  final WeatherCondition weatherCondition;
  final bool visibleToFriends;
  final bool visibleToAcquaintances;
  final bool visibleToStrangers;
  final double discoveryRadiusKm;
  final bool isSponsored;

  @override
  List<Object?> get props => [
        title,
        description,
        maxParticipants,
        dateTime,
        latitude,
        longitude,
        locationName,
        locationType,
        weatherCondition,
        visibleToFriends,
        visibleToAcquaintances,
        visibleToStrangers,
        discoveryRadiusKm,
        isSponsored,
      ];
}

class ActivityInterest extends Equatable {
  const ActivityInterest({
    required this.id,
    required this.profileId,
    required this.username,
    this.avatarUrl,
    this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final String username;
  final String? avatarUrl;
  final String? message;
  final String status;
  final DateTime createdAt;

  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
        id,
        profileId,
        username,
        avatarUrl,
        message,
        status,
        createdAt,
      ];
}
