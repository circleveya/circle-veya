import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity.dart';
import '../providers/activity_provider.dart';

/// Quiet-Luxury-Formular zum Bearbeiten von Titel, Ort, Datum, Beschreibung.
class EditActivityScreen extends ConsumerStatefulWidget {
  const EditActivityScreen({
    super.key,
    required this.activity,
  });

  final DiscoverableActivity activity;

  @override
  ConsumerState<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends ConsumerState<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  DateTime? _dateTime;
  bool _hasDate = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _titleController = TextEditingController(text: a.title);
    _descriptionController = TextEditingController(text: a.description ?? '');
    _locationController = TextEditingController(text: a.locationName ?? '');
    _dateTime = a.dateTime;
    _hasDate = a.dateTime != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _dateTime ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _hasDate = true;
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    final input = UpdateActivityInput(
      activityId: widget.activity.id,
      title: title,
      description: description.isEmpty ? null : description,
      locationName: location.isEmpty ? null : location,
      dateTime: _hasDate ? _dateTime : null,
      clearDateTime: !_hasDate,
    );

    await ref.read(activityActionsProvider.notifier).updateActivity(input);

    if (!mounted) return;
    setState(() => _saving = false);

    final error = ref.read(activityActionsProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
      return;
    }

    final updated = widget.activity.copyWith(
      title: title,
      description: description.isEmpty ? null : description,
      clearDescription: description.isEmpty,
      locationName: location.isEmpty ? null : location,
      clearLocationName: location.isEmpty,
      dateTime: _hasDate ? _dateTime : null,
      clearDateTime: !_hasDate,
    );

    context.pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, dd.MM.yyyy · HH:mm', 'de_CH');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bearbeiten'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Speichern'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
          children: [
            Text(
              'Details anpassen',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.brandNavy,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Titel, Ort, Datum und Beschreibung – klar und ruhig.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 36),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Titel',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Titel erforderlich' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ort',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Datum & Uhrzeit',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasDate)
                        IconButton(
                          tooltip: 'Datum entfernen',
                          onPressed: () => setState(() {
                            _hasDate = false;
                            _dateTime = null;
                          }),
                          icon: const Icon(Icons.clear, size: 20),
                        ),
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                child: Text(
                  _hasDate && _dateTime != null
                      ? dateFormat.format(_dateTime!.toLocal())
                      : 'Kein Datum',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _hasDate
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Änderungen speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
