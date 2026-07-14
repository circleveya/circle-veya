class UserReview {
  const UserReview({
    required this.id,
    required this.targetUserId,
    required this.reviewerId,
    required this.reviewerUsername,
    required this.rating,
    this.reviewerAvatarUrl,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String targetUserId;
  final String reviewerId;
  final String reviewerUsername;
  final String? reviewerAvatarUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;
}
