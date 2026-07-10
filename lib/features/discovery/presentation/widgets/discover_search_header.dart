import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/entities/discover_filters.dart';
import '../../../activities/presentation/providers/activity_provider.dart';
import '../../../activities/presentation/widgets/discover_quick_filters_bar.dart';
import '../../../activities/presentation/widgets/location_filter_bar.dart';

/// Entdecken-Hero: Gradient-Banner + Event-Suche + Filter-Sheet.
/// Nur auf der Discover-Page – andere Tabs bleiben unberührt.
class DiscoverSearchHeader extends ConsumerWidget {
  const DiscoverSearchHeader({
    super.key,
    required this.controller,
    this.onSearch,
  });

  /// Vom Parent gehalten – bleibt beim Wechsel Ergebnis/Leerzustand erhalten.
  final TextEditingController controller;
  final ValueChanged<String>? onSearch;

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final initial = ref.read(discoverFiltersProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _DiscoverFiltersSheet(
          initialFilters: initial,
          onApply: (next) {
            ref.read(discoverFiltersProvider.notifier).state = next;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasActive = ref.watch(discoverFiltersProvider).hasActiveFilters;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.seed.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find people. Create memories.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entdecke Aktivitäten in deiner Nähe – mit Freunden, '
            'der Community und Events aus deiner Region.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: controller,
            onChanged: onSearch,
            onSubmitted: onSearch,
            style: const TextStyle(color: Colors.black87),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Was möchtest du heute erleben?',
              hintStyle: TextStyle(
                color: Colors.black.withValues(alpha: 0.38),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (value.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Leeren',
                          onPressed: () {
                            controller.clear();
                            onSearch?.call('');
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                        ),
                      IconButton(
                        tooltip: 'Filter',
                        onPressed: () => _openFilters(context, ref),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: AppColors.brandNavy.withValues(alpha: 0.7),
                            ),
                            if (hasActive)
                              Positioned(
                                right: -1,
                                top: -1,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.seed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverFiltersSheet extends StatefulWidget {
  const _DiscoverFiltersSheet({
    required this.initialFilters,
    required this.onApply,
  });

  final ActivityDiscoverFilters initialFilters;
  final ValueChanged<ActivityDiscoverFilters> onApply;

  @override
  State<_DiscoverFiltersSheet> createState() => _DiscoverFiltersSheetState();
}

class _DiscoverFiltersSheetState extends State<_DiscoverFiltersSheet> {
  late ActivityDiscoverFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  void _update(ActivityDiscoverFilters next) {
    setState(() => _filters = next);
    widget.onApply(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'Filter',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandNavy,
                        ),
                      ),
                      const Spacer(),
                      if (_filters.hasActiveFilters)
                        TextButton(
                          onPressed: () =>
                              _update(const ActivityDiscoverFilters.empty()),
                          child: const Text('Zurücksetzen'),
                        ),
                    ],
                  ),
                ),
                LocationFilterBar(
                  filters: _filters,
                  onFiltersChanged: _update,
                  embedded: true,
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                DiscoverQuickFiltersBar(
                  filters: _filters,
                  onFiltersChanged: _update,
                  compact: true,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Fertig'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
