import 'package:equatable/equatable.dart';

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
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final ConnectionType? connectionStatus;

  bool get isConnected => connectionStatus != null;

  @override
  List<Object?> get props => [id, username, avatarUrl, bio, connectionStatus];
}
