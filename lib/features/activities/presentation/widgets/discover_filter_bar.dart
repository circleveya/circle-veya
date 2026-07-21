import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/activity_filters.dart';
import '../../domain/entities/discover_date_filter.dart';
import '../../domain/entities/discover_filters.dart';
import '../../domain/entities/event_category.dart';

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
    final l10n = AppLocalizations.of(context);
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
                            l10n.filter,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: _expanded
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_expanded && hasFilters)
                            Text(
                              _activeFilterSummary(widget.filters, l10n),
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
                        child: Text(l10n.reset),
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
                      l10n.location,
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
                      l10n.weather,
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
                          label: Text(condition.localizedLabel(l10n)),
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

  String _activeFilterSummary(
    ActivityDiscoverFilters filters,
    AppLocalizations l10n,
  ) {
    final parts = <String>[];
    if (filters.category != EventCategory.all) {
      parts.add(filters.category.localizedLabel(l10n));
    }
    if (filters.locationType != null) {
      parts.add(filters.locationType!.label);
    }
    if (filters.weatherCondition != null) {
      parts.add(filters.weatherCondition!.localizedLabel(l10n));
    }
    if (filters.maxDistanceKm != null) {
      parts.add(l10n.maxDistanceKm(filters.maxDistanceKm!.round()));
    }
    if (filters.dateFilter != DiscoverDateFilterOption.all) {
      parts.add(filters.dateFilter.localizedLabel(l10n));
    }
    return parts.join(' · ');
  }
}
