import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_image_crop_editor.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _interestController = TextEditingController();
  final List<String> _interests = [];

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  void _loadProfile(UserProfile profile) {
    if (_usernameController.text.isNotEmpty) return;
    _usernameController.text = profile.username;
    _bioController.text = profile.bio ?? '';
    if (profile.age != null) {
      _ageController.text = profile.age.toString();
    }
    _interests
      ..clear()
      ..addAll(profile.interests);
  }

  Future<void> _pickAvatar() async {
    final cropped = await pickAndCropProfileImage(
      context,
      kind: ProfileCropKind.avatar,
    );
    if (cropped == null || !mounted) return;

    await ref
        .read(profileEditControllerProvider.notifier)
        .uploadAvatar(cropped.toXFile());
    if (!mounted) return;

    final error = ref.read(profileEditControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profilbild aktualisiert')),
    );
  }

  Future<void> _pickCover() async {
    final cropped = await pickAndCropProfileImage(
      context,
      kind: ProfileCropKind.cover,
    );
    if (cropped == null || !mounted) return;

    await ref
        .read(profileEditControllerProvider.notifier)
        .uploadCover(cropped.toXFile());
    if (!mounted) return;

    final error = ref.read(profileEditControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Banner aktualisiert')),
    );
  }

  void _addInterest() {
    final value = _interestController.text.trim();
    if (value.isEmpty || _interests.contains(value)) return;
    setState(() {
      _interests.add(value);
      _interestController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final age = int.tryParse(_ageController.text.trim());

    await ref.read(profileEditControllerProvider.notifier).save(
          UpdateProfileInput(
            username: _usernameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            age: age,
            interests: _interests,
          ),
        );

    if (!mounted) return;
    final error = ref.read(profileEditControllerProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil gespeichert')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final isLoading = ref.watch(profileEditControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil bearbeiten')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) {
          _loadProfile(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 6,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primaryContainer,
                                  Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                ],
                              ),
                              image: profile.coverUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        profile.coverUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                          Material(
                            color: Colors.black.withValues(alpha: 0.18),
                            child: InkWell(
                              onTap: isLoading ? null : _pickCover,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLoading
                                          ? Icons.hourglass_empty
                                          : Icons.photo_camera_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      profile.coverUrl == null
                                          ? 'Banner hinzufügen'
                                          : 'Banner ändern',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Banner und Profilbild getrennt wählbar',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: isLoading ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundImage: profile.avatarUrl != null
                              ? CachedNetworkImageProvider(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? Text(
                                  profile.username[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 18,
                            child: Icon(
                              isLoading
                                  ? Icons.hourglass_empty
                                  : Icons.camera_alt,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Profilbild tippen zum Ändern'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Benutzername'),
                    validator: (v) =>
                        v == null || v.trim().length < 3 ? 'Min. 3 Zeichen' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'Alter'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final age = int.tryParse(v ?? '');
                      if (age == null || age < 13 || age > 120) {
                        return '13–120';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Erzähl kurz etwas über dich …',
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Interessen',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _interestController,
                          decoration: const InputDecoration(
                            hintText: 'z.B. Go-Kart, Fußball',
                          ),
                          onSubmitted: (_) => _addInterest(),
                        ),
                      ),
                      IconButton(
                        onPressed: _addInterest,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interests
                        .map(
                          (i) => InputChip(
                            label: Text(i),
                            onDeleted: () => setState(() => _interests.remove(i)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading ? null : _save,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Speichern'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
