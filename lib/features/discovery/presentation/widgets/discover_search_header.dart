import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/entities/discover_filters.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../activities/presentation/widgets/discover_quick_filters_bar.dart';
import '../../../activities/presentation/widgets/location_filter_bar.dart';

/// Entdecken-Header: Suche + dezenter Filter-Toggle mit Animation.
class DiscoverSearchHeader extends ConsumerStatefulWidget {
  const DiscoverSearchHeader({
    super.key,
    this.onSearch,
  });

  final ValueChanged<String>? onSearch;

  @override
  ConsumerState<DiscoverSearchHeader> createState() =>
      _DiscoverSearchHeaderState();
}

class _DiscoverSearchHeaderState extends ConsumerState<DiscoverSearchHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _filtersOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _filtersOpen = !_filtersOpen);
    if (_filtersOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(discoverFiltersProvider);
    final hasActive = filters.hasActiveFilters;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  onSubmitted: widget.onSearch,
                  decoration: InputDecoration(
                    hintText: 'Was möchtest du heute erleben?',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.brandNavy.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.seed.withValues(alpha: 0.5),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FilterToggleButton(
                isOpen: _filtersOpen,
                hasActiveFilters: hasActive,
                onPressed: _toggleFilters,
              ),
            ],
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            axis: Axis.vertical,
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _FilterPanel(
                  filters: filters,
                  onFiltersChanged: (next) {
                    ref.read(discoverFiltersProvider.notifier).state = next;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.isOpen,
    required this.hasActiveFilters,
    required this.onPressed,
  });

  final bool isOpen;
  final bool hasActiveFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isOpen
          ? AppColors.brandNavy.withValues(alpha: 0.06)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOpen
              ? AppColors.brandNavy.withValues(alpha: 0.18)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppColors.brandNavy.withValues(alpha: 0.75),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.seed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                'Filter',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.filters,
    required this.onFiltersChanged,
  });

  final ActivityDiscoverFilters filters;
  final ValueChanged<ActivityDiscoverFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Standort ohne äußeres Padding-Duplikat
          LocationFilterBar(
            filters: filters,
            onFiltersChanged: onFiltersChanged,
            embedded: true,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          // Wann + Entfernung – ohne laute Elevation
          DiscoverQuickFiltersBar(
            filters: filters,
            onFiltersChanged: onFiltersChanged,
            compact: true,
          ),
          if (filters.hasActiveFilters)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    onFiltersChanged(const ActivityDiscoverFilters.empty()),
                child: const Text('Filter zurücksetzen'),
              ),
            ),
        ],
      ),
    );
  }
}
