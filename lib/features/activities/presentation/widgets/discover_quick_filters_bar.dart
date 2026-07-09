import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/user_location.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/discover_date_filter.dart';
import '../../domain/entities/discover_filters.dart';

/// Immer sichtbare Schnellfilter: Zeitraum + Entfernung (oben im Entdecken-Feed).
class DiscoverQuickFiltersBar extends ConsumerWidget {
  const DiscoverQuickFiltersBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  final ActivityDiscoverFilters filters;
  final ValueChanged<ActivityDiscoverFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: AppColors.seed),
                const SizedBox(width: 6),
                Text(
                  'Wann?',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in DiscoverDateFilterOption.quickFilters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuickFilterChip(
                        label: option.label,
                        selected: filters.dateFilter == option,
                        onTap: () => _toggleDateFilter(option),
                      ),
                    ),
                  if (filters.dateFilter != DiscoverDateFilterOption.all &&
                      !DiscoverDateFilterOption.quickFilters
                          .contains(filters.dateFilter))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuickFilterChip(
                        label: filters.dateFilter.label,
                        selected: true,
                        onTap: () => _clearDateFilter(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.straighten_outlined, size: 18, color: AppColors.seed),
                const SizedBox(width: 6),
                Text(
                  'Entfernung',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in DistanceFilterOption.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuickFilterChip(
                        label: option.label,
                        selected: filters.distanceOption == option,
                        onTap: () {
                          onFiltersChanged(
                            filters.copyWith(
                              distanceOption: option,
                              maxDistanceKm: option.maxKm,
                              clearMaxDistance: option.maxKm == null,
                            ),
                          );
                        },
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

  void _toggleDateFilter(DiscoverDateFilterOption option) {
    final next = filters.dateFilter == option
        ? DiscoverDateFilterOption.all
        : option;
    onFiltersChanged(
      filters.copyWith(
        dateFilter: next,
        clearCustomDateRange: true,
      ),
    );
  }

  void _clearDateFilter() {
    onFiltersChanged(
      filters.copyWith(
        dateFilter: DiscoverDateFilterOption.all,
        clearCustomDateRange: true,
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? AppColors.seed
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
