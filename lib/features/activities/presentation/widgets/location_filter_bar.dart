import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/discover_filters.dart';
import '../providers/activity_provider.dart';

/// Standortauswahl + Entfernungsradius für den Activity-Feed.
class LocationFilterBar extends ConsumerWidget {
  const LocationFilterBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  final ActivityDiscoverFilters filters;
  final ValueChanged<ActivityDiscoverFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locationAsync = ref.watch(userLocationProvider);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place_outlined, size: 20, color: AppColors.seed),
                const SizedBox(width: 8),
                Text(
                  'Standort',
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
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _LocationChip(
                    label: 'Aktueller Standort',
                    icon: Icons.my_location,
                    selected: locationAsync.valueOrNull?.source ==
                        LocationSource.gps,
                    onTap: () async {
                      await ref
                          .read(userLocationProvider.notifier)
                          .requestGps();
                      ref.invalidate(discoverActivitiesProvider);
                    },
                  ),
                  for (final preset in LocationPreset.values)
                    _LocationChip(
                      label: preset.label,
                      selected: locationAsync.valueOrNull?.source ==
                          preset.source,
                      onTap: () async {
                        await ref
                            .read(userLocationProvider.notifier)
                            .selectPreset(preset);
                        ref.invalidate(discoverActivitiesProvider);
                      },
                    ),
                ],
              ),
            ),
            locationAsync.maybeWhen(
              data: (location) => location.isMock
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _InfoBanner(
                        icon: Icons.info_outline,
                        text: location.source == LocationSource.mock
                            ? 'Test-Modus (USE_MOCK_LOCATION): Events werden um '
                                '${location.displayLabel} geladen.'
                            : 'GPS nicht verfügbar – Fallback ${location.displayLabel}.',
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            Text(
              'Entfernung',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in DistanceFilterOption.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(option.label),
                        selected: filters.distanceOption == option,
                        onSelected: (_) {
                          onFiltersChanged(
                            filters.copyWith(
                              distanceOption: option,
                              maxDistanceKm: option.maxKm,
                              clearMaxDistance: option.maxKm == null,
                            ),
                          );
                          ref.invalidate(discoverActivitiesProvider);
                        },
                        selectedColor: AppColors.seed.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.seed,
                        labelStyle: TextStyle(
                          color: filters.distanceOption == option
                              ? AppColors.seed
                              : theme.colorScheme.onSurface,
                          fontWeight: filters.distanceOption == option
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: icon != null ? Icon(icon, size: 16) : null,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.seed.withValues(alpha: 0.15),
        checkmarkColor: AppColors.seed,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.seed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.seed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.seed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
