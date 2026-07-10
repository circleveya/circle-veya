import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/location/user_location.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/discover_date_filter.dart';
import '../../domain/entities/discover_filters.dart';

/// Immer sichtbare Schnellfilter: Zeitraum (Chips + Von/Bis) + Entfernung.
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
    final dateFormat = DateFormat('dd.MM.yyyy');

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
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateFieldButton(
                    label: 'Von',
                    value: filters.customDateFrom == null
                        ? null
                        : dateFormat.format(filters.customDateFrom!),
                    onTap: () => _pickFrom(context),
                    onClear: filters.customDateFrom == null
                        ? null
                        : () {
                            final stillHasTo = filters.customDateTo != null;
                            onFiltersChanged(
                              filters.copyWith(
                                clearCustomDateFrom: true,
                                dateFilter: stillHasTo
                                    ? DiscoverDateFilterOption.custom
                                    : DiscoverDateFilterOption.all,
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateFieldButton(
                    label: 'Bis',
                    value: filters.customDateTo == null
                        ? null
                        : dateFormat.format(filters.customDateTo!),
                    onTap: () => _pickTo(context),
                    onClear: filters.customDateTo == null
                        ? null
                        : () {
                            final stillHasFrom = filters.customDateFrom != null;
                            onFiltersChanged(
                              filters.copyWith(
                                clearCustomDateTo: true,
                                dateFilter: stillHasFrom
                                    ? DiscoverDateFilterOption.custom
                                    : DiscoverDateFilterOption.all,
                              ),
                            );
                          },
                  ),
                ),
              ],
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

  Future<void> _pickFrom(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: filters.customDateFrom ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    var to = filters.customDateTo;
    if (to != null && to.isBefore(picked)) to = picked;

    onFiltersChanged(
      filters.copyWith(
        dateFilter: DiscoverDateFilterOption.custom,
        customDateFrom: DateTime(picked.year, picked.month, picked.day),
        customDateTo: to,
      ),
    );
  }

  Future<void> _pickTo(BuildContext context) async {
    final now = DateTime.now();
    final initial = filters.customDateTo ??
        filters.customDateFrom ??
        now.add(const Duration(days: 7));
    final first = filters.customDateFrom ?? now.subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    onFiltersChanged(
      filters.copyWith(
        dateFilter: DiscoverDateFilterOption.custom,
        customDateFrom: filters.customDateFrom,
        customDateTo: DateTime(picked.year, picked.month, picked.day),
      ),
    );
  }
}

class _DateFieldButton extends StatelessWidget {
  const _DateFieldButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: hasValue && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                  tooltip: 'Leeren',
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value ?? 'Gesamtzeit',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: hasValue
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
