import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_filters.dart';
import '../providers/activity_provider.dart';
import '../providers/event_selection_provider.dart';
import '../widgets/visibility_selector.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '10');
  final _locationNameController = TextEditingController();

  bool _hasDate = true;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  XFile? _coverImage;
  String? _prefilledImageUrl;
  String? _sourceEventId;
  String? _sourceEventTitle;
  LocationType _locationType = LocationType.outdoor;
  WeatherCondition _weatherCondition = WeatherCondition.sun;
  bool _visibleToFriends = true;
  bool _visibleToAcquaintances = false;
  bool _visibleToStrangers = false;
  bool _isSponsored = false;
  double _radiusKm = 20;
  bool _appliedSelection = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  void _applyEventSelection(EventSelection selection) {
    _titleController.text = selection.title;
    if (selection.locationName != null) {
      _locationNameController.text = selection.locationName!;
    }
    final dateTime = selection.dateTime;
    setState(() {
      _sourceEventId = selection.sourceEventId;
      _sourceEventTitle = selection.title;
      _prefilledImageUrl = selection.imageUrl;
      _coverImage = null;
      if (dateTime != null) {
        _hasDate = true;
        _selectedDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
        _selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      }
      _visibleToFriends = true;
      _appliedSelection = true;
    });
  }

  void _clearEventSelectionState() {
    setState(() {
      _sourceEventId = null;
      _sourceEventTitle = null;
      _prefilledImageUrl = null;
      _appliedSelection = false;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _coverImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_visibleToFriends != true &&
        _visibleToAcquaintances != true &&
        _visibleToStrangers != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte mindestens eine Zielgruppe auswählen.'),
        ),
      );
      return;
    }

    final location = await ref.read(userLocationProvider.future);
    if (location.isMock == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test-Standort (${location.displayLabel}) wird verwendet – '
            'GPS ist deaktiviert oder nicht verfügbar.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    DateTime? dateTime;
    if (_hasDate == true) {
      dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
    }

    await ref.read(createActivityProvider.notifier).create(
          CreateActivityInput(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            maxParticipants: int.parse(_maxParticipantsController.text),
            dateTime: dateTime,
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: _locationNameController.text.trim().isEmpty
                ? null
                : _locationNameController.text.trim(),
            locationType: _locationType,
            weatherCondition: _weatherCondition,
            visibleToFriends: _visibleToFriends,
            visibleToAcquaintances: _visibleToAcquaintances,
            visibleToStrangers: _visibleToStrangers,
            discoveryRadiusKm: _radiusKm,
            isSponsored: _isSponsored,
            imageUrl: _prefilledImageUrl,
            sourceEventId: _sourceEventId,
            sourceEventTitle: _sourceEventTitle,
          ),
          coverImage: _coverImage,
        );

    if (!mounted) return;

    final state = ref.read(createActivityProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$state.error')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aktivität erstellt!')),
    );

    ref.read(eventSelectionProvider.notifier).clear();
    _formKey.currentState!.reset();
    _titleController.clear();
    _descriptionController.clear();
    _locationNameController.clear();
    setState(() {
      _hasDate = true;
      _coverImage = null;
      _prefilledImageUrl = null;
      _sourceEventId = null;
      _sourceEventTitle = null;
      _appliedSelection = false;
      _visibleToFriends = true;
      _visibleToAcquaintances = false;
      _visibleToStrangers = false;
      _isSponsored = false;
      _radiusKm = 20;
      _locationType = LocationType.outdoor;
      _weatherCondition = WeatherCondition.sun;
    });

    ref.invalidate(hostedActivitiesProvider);
    ref.invalidate(myActivitiesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createActivityProvider).isLoading;
    final isCompany = ref.watch(isCompanyPartnerProvider);
    final theme = Theme.of(context);
    final eventSelection = ref.watch(eventSelectionProvider);

    ref.listen(eventSelectionProvider, (previous, next) {
      if (next != null && next != previous) {
        _applyEventSelection(next);
      }
    });

    if (!_appliedSelection && eventSelection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _appliedSelection) return;
        final current = ref.read(eventSelectionProvider);
        if (current != null) _applyEventSelection(current);
      });
    }

    final planningTitle = _sourceEventTitle ?? eventSelection?.title;
    final showEventBanner =
        planningTitle != null && planningTitle.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showEventBanner) ...[
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.confirmation_number_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Du planst gerade: $planningTitle',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandNavy,
                    ),
                  ),
                  subtitle: const Text(
                    'Titel, Datum und Bild sind vorausgefüllt – du kannst alles anpassen.',
                  ),
                  trailing: IconButton(
                    tooltip: 'Übernahme verwerfen',
                    onPressed: isLoading
                        ? null
                        : () {
                            ref.read(eventSelectionProvider.notifier).clear();
                            _clearEventSelectionState();
                          },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isCompany)
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: const ListTile(
                  leading: Icon(Icons.business),
                  title: Text('Community Partner'),
                  subtitle: Text(
                    'Du kannst Aktivitäten als gesponsert markieren '
                    'und im Feed featured werden.',
                  ),
                ),
              ),
            if (isCompany) const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isLoading ? null : _pickCoverImage,
                    child: _coverPreview(theme),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                hintText: 'z.B. Go-Kart fahren',
              ),
              validator: (v) {
                if (v == null || v.trim().length < 3) {
                  return 'Mindestens 3 Zeichen';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxParticipantsController,
              decoration: const InputDecoration(
                labelText: 'Max. Teilnehmer',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 2) return 'Mindestens 2';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationNameController,
              decoration: const InputDecoration(
                labelText: 'Ort (optional)',
                hintText: 'z.B. Berlin Mitte',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hasDate,
              onChanged: (v) => setState(() => _hasDate = v),
              title: const Text('Termin festlegen'),
              subtitle: Text(
                _hasDate
                    ? 'Datum und Uhrzeit für die Aktivität'
                    : 'Flexibel – ohne festes Datum',
              ),
              secondary: Icon(
                _hasDate ? Icons.event : Icons.event_busy_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            if (_hasDate == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<LocationType>(
              initialValue: _locationType,
              decoration: const InputDecoration(labelText: 'Ort-Typ'),
              items: LocationType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _locationType = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WeatherCondition>(
              initialValue: _weatherCondition,
              decoration: const InputDecoration(labelText: 'Wetter'),
              items: WeatherCondition.values
                  .map(
                    (condition) => DropdownMenuItem(
                      value: condition,
                      child: Text(condition.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _weatherCondition = v);
              },
            ),
            if (isCompany) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isSponsored,
                onChanged: (v) => setState(() => _isSponsored = v),
                title: const Text('Als gesponsert markieren'),
                subtitle: const Text(
                  'Wird im Entdecken-Feed featured und nach oben gepusht.',
                ),
                secondary: const Icon(Icons.star_outline),
              ),
            ],
            const SizedBox(height: 24),
            VisibilitySelector(
              friends: _visibleToFriends,
              acquaintances: _visibleToAcquaintances,
              strangers: _visibleToStrangers,
              onFriendsChanged: (v) => setState(() => _visibleToFriends = v),
              onAcquaintancesChanged: (v) =>
                  setState(() => _visibleToAcquaintances = v),
              onStrangersChanged: (v) => setState(() => _visibleToStrangers = v),
              radiusKm: _radiusKm,
              onRadiusChanged: (v) => setState(() => _radiusKm = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Aktivität erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPreview(ThemeData theme) {
    if (_coverImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List>(
            future: _coverImage!.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: () => setState(() => _coverImage = null),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.55),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    final prefilled = _prefilledImageUrl?.trim();
    if (prefilled != null && prefilled.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: prefilled,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, _) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (_, _, _) => ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Event-Bild',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: () => setState(() => _prefilledImageUrl = null),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.55),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          'Titelbild hinzufügen (optional)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
