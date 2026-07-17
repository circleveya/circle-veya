import 'package:equatable/equatable.dart';

class PastActivityGallery extends Equatable {
  const PastActivityGallery({
    required this.id,
    required this.title,
    required this.dateTime,
    this.locationName,
    required this.isHost,
    required this.photoCount,
    required this.canUpload,
    this.isPublic = false,
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final String? locationName;
  final bool isHost;
  final int photoCount;
  final bool canUpload;
  final bool isPublic;

  @override
  List<Object?> get props => [
        id,
        title,
        dateTime,
        locationName,
        isHost,
        photoCount,
        canUpload,
        isPublic,
      ];
}

class ActivityPhoto extends Equatable {
  const ActivityPhoto({
    required this.id,
    required this.uploaderId,
    required this.uploaderUsername,
    required this.publicUrl,
    this.caption,
    required this.createdAt,
  });

  final String id;
  final String uploaderId;
  final String uploaderUsername;
  final String publicUrl;
  final String? caption;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        uploaderId,
        uploaderUsername,
        publicUrl,
        caption,
        createdAt,
      ];
}
