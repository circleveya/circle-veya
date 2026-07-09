import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity_filters.dart';
import '../../domain/entities/discover_filters.dart';

class DiscoverFilterBar extends StatefulWidget {
  const DiscoverFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
    this.initiallyExpanded = false,
  });

  final ActivityDiscoverFilters filters;
  final ValueChanged<ActivityDiscoverFilters> onChanged;
  final bool initiallyExpanded;

  @override
  State<DiscoverFilterBar> createState() => _DiscoverFilterBarState();
}

class _DiscoverFilterBarState extends State<DiscoverFilterBar> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded || widget.filters.hasActiveFilters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = widget.filters.hasActiveFilters;

    return Material(
      elevation: 2,
      color: _expanded ? null : theme.colorScheme.surface,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: _expanded ? AppColors.filterExpanded : null,
          color: _expanded ? null : theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 22,
                      color: _expanded ? Colors.white : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: _expanded
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_expanded && hasFilters)
                            Text(
                              _activeFilterSummary(widget.filters),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (hasFilters)
                      TextButton(
                        onPressed: () {
                          widget.onChanged(const ActivityDiscoverFilters.empty());
                          setState(() => _expanded = false);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              _expanded ? Colors.white : theme.colorScheme.primary,
                        ),
                        child: const Text('Zurücksetzen'),
                      ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _expanded
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ort',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: LocationType.values.map((type) {
                        final selected = widget.filters.locationType == type;
                        return FilterChip(
                          label: Text(type.label),
                          avatar: Icon(type.icon, size: 16),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? theme.colorScheme.primary
                                : Colors.white,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          side: BorderSide(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                          ),
                          onSelected: (value) => widget.onChanged(
                            widget.filters.copyWith(
                              locationType: value ? type : null,
                              clearLocationType: !value,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Wetter',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: WeatherCondition.values.map((condition) {
                        final selected =
                            widget.filters.weatherCondition == condition;
                        return FilterChip(
                          label: Text(condition.label),
                          avatar: Icon(condition.icon, size: 16),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? theme.colorScheme.primary
                                : Colors.white,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          side: BorderSide(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                          ),
                          onSelected: (value) => widget.onChanged(
                            widget.filters.copyWith(
                              weatherCondition: value ? condition : null,
                              clearWeatherCondition: !value,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _activeFilterSummary(ActivityDiscoverFilters filters) {
    final parts = <String>[];
    if (filters.locationType != null) {
      parts.add(filters.locationType!.label);
    }
    if (filters.weatherCondition != null) {
      parts.add(filters.weatherCondition!.label);
    }
    if (filters.maxDistanceKm != null) {
      parts.add('max. ${filters.maxDistanceKm!.round()} km');
    }
    return parts.join(' · ');
  }
}
