import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/ghost_location_field.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/location/swiss_places.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/discover_filters.dart';
import '../providers/activity_provider.dart';

/// Kompakte Standortleiste – nur im Feed-Inhalt, ohne globales Layout zu beeinflussen.
class LocationFilterBar extends ConsumerStatefulWidget {
  const LocationFilterBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.embedded = false,
  });

  final ActivityDiscoverFilters filters;
  final ValueChanged<ActivityDiscoverFilters> onFiltersChanged;

  /// Ohne Card/Rahmen – für eingebettete Filter-Panels.
  final bool embedded;

  @override
  ConsumerState<LocationFilterBar> createState() => _LocationFilterBarState();
}

class _LocationFilterBarState extends ConsumerState<LocationFilterBar> {
  final _searchController = TextEditingController();
  bool _gpsLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleGps() async {
    if (_gpsLoading) return;
    setState(() => _gpsLoading = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(userLocationProvider.notifier).requestGps();
      ref.invalidate(discoverActivitiesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gpsTaken),
          duration: const Duration(seconds: 2),
        ),
      );
    } on LocationPermissionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  void _applyPlace(PlaceSuggestion place) {
    ref.read(userLocationProvider.notifier).selectPlace(
          label: place.name,
          latitude: place.latitude,
          longitude: place.longitude,
        );
    _searchController.text = place.name;
    ref.invalidate(discoverActivitiesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).locationApplied(place.name)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applySearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final l10n = AppLocalizations.of(context);

    final preset = LocationPreset.tryMatch(query);
    if (preset != null) {
      ref.read(userLocationProvider.notifier).selectPreset(preset);
      _searchController.text = preset.label;
      ref.invalidate(discoverActivitiesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.locationApplied(preset.label)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final place = findPlaceSuggestion(query);
    if (place != null &&
        (place.name.toLowerCase() == query.toLowerCase() ||
            place.name.toLowerCase().startsWith(query.toLowerCase()))) {
      _applyPlace(place);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.placeNotFound(query))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locationAsync = ref.watch(userLocationProvider);
    final activeSource = locationAsync.valueOrNull?.source;
    final embedded = widget.embedded;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 18,
              color: AppColors.brandNavy.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.location,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.brandNavy.withValues(alpha: 0.9),
              ),
            ),
            const Spacer(),
            locationAsync.when(
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (location) => Text(
                location.displayLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.seed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GhostLocationField(
          controller: _searchController,
          hintText: l10n.searchPlaceHint,
          onConfirm: _applySearch,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _gpsLoading ? null : _handleGps,
            icon: _gpsLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(l10n.currentLocationGps),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final preset in LocationPreset.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(preset.label),
                    onPressed: () {
                      ref
                          .read(userLocationProvider.notifier)
                          .selectPreset(preset);
                      _searchController.text = preset.label;
                      ref.invalidate(discoverActivitiesProvider);
                    },
                    backgroundColor: activeSource == preset.source
                        ? AppColors.seed.withValues(alpha: 0.15)
                        : null,
                  ),
                ),
            ],
          ),
        ),
        if (locationAsync.valueOrNull?.isMock == true &&
            activeSource != LocationSource.gps)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l10n.mockLocationHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: body,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: body,
        ),
      ),
    );
  }
}
