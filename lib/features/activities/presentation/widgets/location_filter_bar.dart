import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/ghost_location_field.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/location/place_geocoder.dart';
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
    this.onReady,
  });

  final ActivityDiscoverFilters filters;
  final ValueChanged<ActivityDiscoverFilters> onFiltersChanged;

  /// Ohne Card/Rahmen – für eingebettete Filter-Panels.
  final bool embedded;

  /// Registriert [applyPendingLocation] für „Fertig“ im Filter-Sheet.
  final void Function(Future<void> Function() apply)? onReady;

  @override
  ConsumerState<LocationFilterBar> createState() => LocationFilterBarState();
}

class LocationFilterBarState extends ConsumerState<LocationFilterBar> {
  final _searchController = TextEditingController();
  bool _gpsLoading = false;
  bool _geocodeLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllerFromLocation();
      widget.onReady?.call(applyPendingLocation);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncControllerFromLocation() {
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location == null || location.source == LocationSource.gps) return;
    final label = location.label ?? location.displayLabel;
    if (label.isEmpty || label.startsWith('Test-')) return;
    if (_searchController.text.trim().isEmpty) {
      _searchController.text = label;
    }
  }

  Future<void> _handleGps() async {
    if (_gpsLoading) return;
    setState(() => _gpsLoading = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(userLocationProvider.notifier).requestGps();
      _searchController.clear();
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

  void _setLocation({
    required String label,
    required double latitude,
    required double longitude,
    bool silent = false,
  }) {
    ref.read(userLocationProvider.notifier).selectPlace(
          label: label,
          latitude: latitude,
          longitude: longitude,
        );
    _searchController.text = label;
    ref.invalidate(discoverActivitiesProvider);

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).locationApplied(label)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _applyPlace(PlaceSuggestion place, {bool silent = false}) {
    _setLocation(
      label: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
      silent: silent,
    );
  }

  Future<void> applyPendingLocation({bool silent = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final current = ref.read(userLocationProvider).valueOrNull;
    if (current != null &&
        current.source != LocationSource.gps &&
        (current.label ?? current.displayLabel).toLowerCase() ==
            query.toLowerCase()) {
      return;
    }

    final preset = LocationPreset.tryMatch(query);
    if (preset != null) {
      _setLocation(
        label: preset.label,
        latitude: preset.latitude,
        longitude: preset.longitude,
        silent: silent,
      );
      return;
    }

    final place = findPlaceSuggestion(query);
    if (place != null && placeQueryMatches(place.name, query)) {
      _applyPlace(place, silent: silent);
      return;
    }

    if (_geocodeLoading) return;
    setState(() => _geocodeLoading = true);
    try {
      final geocoded = await PlaceGeocoder.lookup(query);
      if (geocoded != null) {
        _applyPlace(geocoded, silent: silent);
        return;
      }
    } finally {
      if (mounted) setState(() => _geocodeLoading = false);
    }

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.placeNotFound(query))),
      );
    }
  }

  Future<void> _applySearch() => applyPendingLocation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locationAsync = ref.watch(userLocationProvider);
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
            if (_geocodeLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
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
        if (locationAsync.valueOrNull?.isMock == true &&
            locationAsync.valueOrNull?.source != LocationSource.gps)
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
