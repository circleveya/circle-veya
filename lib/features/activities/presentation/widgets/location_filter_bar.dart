import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/discover_date_filter.dart';
import '../../domain/entities/discover_filters.dart';
import '../providers/activity_provider.dart';

/// Kompakte Standortleiste – nur im Feed-Inhalt, ohne globales Layout zu beeinflussen.
class LocationFilterBar extends ConsumerStatefulWidget {
  const LocationFilterBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  final ActivityDiscoverFilters filters;
  final ValueChanged<ActivityDiscoverFilters> onFiltersChanged;

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
    try {
      await ref.read(userLocationProvider.notifier).requestGps();
      ref.invalidate(discoverActivitiesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standort per GPS übernommen.'),
          duration: Duration(seconds: 2),
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

  void _applySearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final preset = LocationPreset.tryMatch(query);
    if (preset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('„$query“ nicht gefunden. Wähle einen Ort-Chip.')),
      );
      return;
    }

    ref.read(userLocationProvider.notifier).selectPreset(preset);
    ref.invalidate(discoverActivitiesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationAsync = ref.watch(userLocationProvider);
    final activeSource = locationAsync.valueOrNull?.source;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 20, color: AppColors.seed),
                  const SizedBox(width: 8),
                  Text(
                    'Standort & Entfernung',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
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
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Ort suchen (Zürich, Basel, Bern…)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _applySearch,
                    tooltip: 'Ort übernehmen',
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _applySearch(),
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
                  label: const Text('Aktueller Standort (GPS)'),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 20, color: AppColors.seed),
                  const SizedBox(width: 8),
                  Text(
                    'Zeitraum',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final option in DiscoverDateFilterOption.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(option.label),
                          selected: widget.filters.dateFilter == option,
                          onSelected: (_) => _applyDateFilter(option),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.filters.dateFilter == DiscoverDateFilterOption.custom &&
                  widget.filters.customDateFrom != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _customDateLabel(widget.filters),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.seed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final option in DistanceFilterOption.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(option.label),
                          selected: widget.filters.distanceOption == option,
                          onSelected: (_) {
                            widget.onFiltersChanged(
                              widget.filters.copyWith(
                                distanceOption: option,
                                maxDistanceKm: option.maxKm,
                                clearMaxDistance: option.maxKm == null,
                              ),
                            );
                            ref.invalidate(discoverActivitiesProvider);
                          },
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
                    'Test-Standort aktiv. GPS oder Ort-Chip überschreibt den Mock.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyDateFilter(DiscoverDateFilterOption option) async {
    if (option == DiscoverDateFilterOption.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
        initialDateRange: widget.filters.customDateFrom != null
            ? DateTimeRange(
                start: widget.filters.customDateFrom!,
                end: widget.filters.customDateTo ?? widget.filters.customDateFrom!,
              )
            : DateTimeRange(
                start: now,
                end: now.add(const Duration(days: 7)),
              ),
        locale: const Locale('de'),
      );
      if (!mounted || picked == null) return;

      widget.onFiltersChanged(
        widget.filters.copyWith(
          dateFilter: DiscoverDateFilterOption.custom,
          customDateFrom: picked.start,
          customDateTo: picked.end,
        ),
      );
      ref.invalidate(discoverActivitiesProvider);
      return;
    }

    widget.onFiltersChanged(
      widget.filters.copyWith(
        dateFilter: option,
        clearCustomDateRange: option != DiscoverDateFilterOption.custom,
      ),
    );
    ref.invalidate(discoverActivitiesProvider);
  }

  String _customDateLabel(ActivityDiscoverFilters filters) {
    final from = filters.customDateFrom!;
    final to = filters.customDateTo ?? from;
    final format = 'dd.MM.yyyy';
    if (from.year == to.year &&
        from.month == to.month &&
        from.day == to.day) {
      return 'Gewählt: ${_formatDate(from, format)}';
    }
    return 'Gewählt: ${_formatDate(from, format)} – ${_formatDate(to, format)}';
  }

  String _formatDate(DateTime date, String pattern) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    if (pattern == 'dd.MM.yyyy') return '$day.$month.$year';
    return '$day.$month.$year';
  }
}
