import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/gallery_provider.dart';

/// Persönliche Erinnerungen: nur abgeschlossene eigene Aktivitäten + eigene Fotos.
class PastActivitiesGalleryScreen extends ConsumerWidget {
  const PastActivitiesGalleryScreen({
    super.key,
    this.embedded = false,
  });

  /// Wenn true: ohne großen Seiten-Header (z. B. Profil-Tab Galerie).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastAsync = ref.watch(pastActivitiesGalleryProvider);
    final isPrivacySaving =
        ref.watch(memoryPrivacyControllerProvider).isLoading;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return pastAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(pastActivitiesGalleryProvider),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      ),
      data: (activities) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pastActivitiesGalleryProvider);
            await ref.read(pastActivitiesGalleryProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              if (!embedded)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.memories,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jede Erinnerung einzeln öffentlich oder privat stellen',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                    child: Text(
                      'Mit dem Schalter oben alle öffnen – oder hier einzeln steuern',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              if (activities.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.galleryEmptyPast,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  sliver: SliverList.separated(
                    itemCount: activities.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final subtitle = StringBuffer(
                        dateFormat.format(activity.dateTime.toLocal()),
                      );
                      if (activity.locationName != null &&
                          activity.locationName!.isNotEmpty) {
                        subtitle.write(' · ${activity.locationName}');
                      }
                      subtitle.write(
                        '\n${activity.photoCount} '
                        '${activity.photoCount == 1 ? l10n.photoSingular : l10n.photoPlural}',
                      );
                      if (activity.isHost) {
                        subtitle.write(' · von dir erstellt');
                      } else {
                        subtitle.write(' · zugesagt');
                      }

                      return Material(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => context.pushNamed(
                                    RouteNames.activityGallery,
                                    pathParameters: {'id': activity.id},
                                    extra: activity.title,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            activity.isPublic
                                                ? Icons.public
                                                : Icons.lock_outline,
                                            color: theme.colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                activity.title,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitle.toString(),
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Switch(
                                    value: activity.isPublic,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.seed,
                                    onChanged: isPrivacySaving
                                        ? null
                                        : (value) async {
                                            await ref
                                                .read(
                                                  memoryPrivacyControllerProvider
                                                      .notifier,
                                                )
                                                .setMemoryPublic(
                                                  activityId: activity.id,
                                                  isPublic: value,
                                                );
                                            if (!context.mounted) return;
                                            final error = ref
                                                .read(
                                                  memoryPrivacyControllerProvider,
                                                )
                                                .error;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  error == null
                                                      ? (value
                                                          ? 'Erinnerung ist öffentlich'
                                                          : 'Erinnerung ist privat')
                                                      : 'Fehler: $error',
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                  Text(
                                    activity.isPublic ? 'Öffentlich' : 'Privat',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: activity.isPublic
                                          ? AppColors.seed
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ActivityGalleryScreen extends ConsumerWidget {
  const ActivityGalleryScreen({
    super.key,
    required this.activityId,
    this.activityTitle,
    this.ownerId,
  });

  final String activityId;
  final String? activityTitle;
  final String? ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosKey = activityPhotosKey(activityId, ownerId: ownerId);
    final photosAsync = ref.watch(activityPhotosProvider(photosKey));
    final canUploadAsync = ownerId == null
        ? ref.watch(canUploadPhotoProvider(activityId))
        : const AsyncValue<bool>.data(false);
    final isUploading = ref.watch(galleryUploadControllerProvider).isLoading;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(activityTitle ?? l10n.memories),
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
                label: Text(l10n.addPhoto),
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
                      ? l10n.noPhotosYetUpload
                      : l10n.noPhotosInMemory,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () =>
                    _showPhoto(context, photo.publicUrl, photo.caption),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: photo.publicUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (_, _, _) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
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
          file: image,
        );

    if (!context.mounted) return;
    final error = ref.read(galleryUploadControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto gespeichert')),
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
