import 'package:equatable/equatable.dart';

import 'activity_enums.dart';
import 'activity_filters.dart';

class DiscoverableActivity extends Equatable {
  const DiscoverableActivity({
    required this.id,
    required this.hostId,
    required this.hostUsername,
    required this.hostIsCompany,
    this.hostAvatarUrl,
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
    this.sourceEventId,
    this.sourceEventTitle,
    this.createdAt,
    this.participantAvatarUrls = const [],
  });

  final String id;
  final String hostId;
  final String hostUsername;
  final bool hostIsCompany;
  final String? hostAvatarUrl;
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
  /// ID des übernommenen Entdecken-Events (z.B. external_events.id).
  final String? sourceEventId;
  /// Originaltitel des übernommenen Events (für Feed-Hinweis).
  final String? sourceEventTitle;
  final DateTime? createdAt;
  final List<String> participantAvatarUrls;

  bool get isExternal => source == ActivitySource.external;

  bool get isEventTakeover =>
      sourceEventId != null && sourceEventId!.trim().isNotEmpty;

  /// Fallback-Cover, wenn Eventfrog kein Bild liefert.
  static const defaultCoverImageUrl =
      'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop';

  String get effectiveImageUrl {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return defaultCoverImageUrl;
  }

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

  DiscoverableActivity copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    String? locationName,
    bool clearLocationName = false,
    DateTime? dateTime,
    bool clearDateTime = false,
    String? imageUrl,
  }) {
    return DiscoverableActivity(
      id: id,
      hostId: hostId,
      hostUsername: hostUsername,
      hostIsCompany: hostIsCompany,
      hostAvatarUrl: hostAvatarUrl,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants,
      dateTime: clearDateTime ? null : (dateTime ?? this.dateTime),
      imageUrl: imageUrl ?? this.imageUrl,
      locationType: locationType,
      weatherCondition: weatherCondition,
      locationName:
          clearLocationName ? null : (locationName ?? this.locationName),
      distanceKm: distanceKm,
      visibleAs: visibleAs,
      viewerAction: viewerAction,
      isSponsored: isSponsored,
      isFeatured: isFeatured,
      source: source,
      externalUrl: externalUrl,
      sourceEventId: sourceEventId,
      sourceEventTitle: sourceEventTitle,
      createdAt: createdAt,
      participantAvatarUrls: participantAvatarUrls,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hostId,
        hostUsername,
        hostIsCompany,
        hostAvatarUrl,
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
        sourceEventId,
        sourceEventTitle,
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
    this.imageUrl,
    this.sourceEventId,
    this.sourceEventTitle,
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
  /// Vorhandenes Cover (z.B. Eventfrog) – hat Vorrang vor Pexels/Upload.
  final String? imageUrl;
  final String? sourceEventId;
  final String? sourceEventTitle;

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
        imageUrl,
        sourceEventId,
        sourceEventTitle,
      ];
}

/// Teil-Update für Host-Bearbeitung (Titel, Ort, Datum, Beschreibung).
class UpdateActivityInput extends Equatable {
  const UpdateActivityInput({
    required this.activityId,
    required this.title,
    this.description,
    this.locationName,
    this.dateTime,
    this.clearDateTime = false,
  });

  final String activityId;
  final String title;
  final String? description;
  final String? locationName;
  final DateTime? dateTime;
  final bool clearDateTime;

  @override
  List<Object?> get props => [
        activityId,
        title,
        description,
        locationName,
        dateTime,
        clearDateTime,
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
