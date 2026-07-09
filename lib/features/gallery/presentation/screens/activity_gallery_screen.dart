import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../providers/gallery_provider.dart';

class PastActivitiesGalleryScreen extends ConsumerWidget {
  const PastActivitiesGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastAsync = ref.watch(pastActivitiesGalleryProvider);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Event-Galerien')),
      body: pastAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Noch keine vergangenen Events.\n'
                  'Nach Teilnahme kannst du hier Fotos hochladen.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(activity.title),
                  subtitle: Text(
                    '${dateFormat.format(activity.dateTime.toLocal())}'
                    '${activity.locationName != null ? ' · ${activity.locationName}' : ''}'
                    '\n${activity.photoCount} Fotos'
                    '${activity.canUpload ? ' · Upload möglich' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(
                    RouteNames.activityGallery,
                    pathParameters: {'id': activity.id},
                    extra: activity.title,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ActivityGalleryScreen extends ConsumerWidget {
  const ActivityGalleryScreen({
    super.key,
    required this.activityId,
    this.activityTitle,
  });

  final String activityId;
  final String? activityTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(activityPhotosProvider(activityId));
    final canUploadAsync = ref.watch(canUploadPhotoProvider(activityId));
    final isUploading = ref.watch(galleryUploadControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(activityTitle ?? 'Event-Galerie'),
      ),
      floatingActionButton: canUploadAsync.maybeWhen(
        data: (canUpload) => canUpload
            ? FloatingActionButton.extended(
                onPressed: isUploading
                    ? null
                    : () => _pickAndUpload(context, ref),
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo),
                label: const Text('Foto hinzufügen'),
              )
            : null,
        orElse: () => null,
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (photos) {
          if (photos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  canUploadAsync.valueOrNull == true
                      ? 'Noch keine Fotos. Sei der Erste!'
                      : 'Noch keine Fotos in dieser Galerie.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () => _showPhoto(context, photo.publicUrl, photo.caption),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: photo.publicUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: Colors.black12),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            photo.uploaderUsername,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (image == null || !context.mounted) return;

    await ref.read(galleryUploadControllerProvider.notifier).upload(
          activityId: activityId,
          filePath: image.path,
        );

    if (!context.mounted) return;
    final error = ref.read(galleryUploadControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _showPhoto(BuildContext context, String url, String? caption) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(caption),
              ),
          ],
        ),
      ),
    );
  }
}
