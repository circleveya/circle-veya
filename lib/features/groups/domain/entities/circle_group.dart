class CircleGroup {
  const CircleGroup({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.sourceActivityId,
    required this.memberCount,
    required this.myRole,
    required this.createdAt,
    this.imageUrl,
    this.membersCanPost = true,
  });

  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String? sourceActivityId;
  final int memberCount;
  final String myRole;
  final DateTime createdAt;
  final String? imageUrl;
  final bool membersCanPost;

  bool get isOwner => myRole == 'owner';

  bool get isAdmin => myRole == 'admin' || myRole == 'owner';
}

class CircleGroupMember {
  const CircleGroupMember({
    required this.profileId,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  final String profileId;
  final String username;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;
}

class ActivityParticipant {
  const ActivityParticipant({
    required this.profileId,
    required this.username,
    this.avatarUrl,
    required this.joinedVia,
    required this.joinedAt,
  });

  final String profileId;
  final String username;
  final String? avatarUrl;
  final String joinedVia;
  final DateTime joinedAt;
}
