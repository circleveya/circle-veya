import 'package:equatable/equatable.dart';

import '../../../../l10n/app_localizations.dart';

enum ConnectionType {
  friend,
  acquaintance;

  static ConnectionType? fromDb(String? value) {
    return switch (value) {
      'friend' => ConnectionType.friend,
      'acquaintance' => ConnectionType.acquaintance,
      _ => null,
    };
  }

  String get label => switch (this) {
        ConnectionType.friend => 'Freund',
        ConnectionType.acquaintance => 'Bekannter',
      };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        ConnectionType.friend => l10n.friend,
        ConnectionType.acquaintance => l10n.acquaintance,
      };
}

class UserConnection extends Equatable {
  const UserConnection({
    required this.profileId,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.type,
    required this.connectedAt,
  });

  final String profileId;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final ConnectionType type;
  final DateTime connectedAt;

  @override
  List<Object?> get props => [
        profileId,
        username,
        avatarUrl,
        bio,
        type,
        connectedAt,
      ];
}

class SearchableProfile extends Equatable {
  const SearchableProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.connectionStatus,
    this.userType = 'standard',
    this.isFollowing = false,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final ConnectionType? connectionStatus;
  final String userType;
  final bool isFollowing;

  bool get isConnected => connectionStatus != null;

  bool get isBusinessProfile =>
      userType == 'event' || userType == 'company';

  @override
  List<Object?> get props =>
      [id, username, avatarUrl, bio, connectionStatus, userType, isFollowing];
}

class FollowedCompany extends Equatable {
  const FollowedCompany({
    required this.profileId,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.userType = 'event',
    required this.followedAt,
  });

  final String profileId;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String userType;
  final DateTime followedAt;

  @override
  List<Object?> get props =>
      [profileId, username, avatarUrl, bio, userType, followedAt];
}
