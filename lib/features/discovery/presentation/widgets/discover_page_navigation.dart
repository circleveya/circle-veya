import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/entities/discover_activities_state.dart';

/// Klassische Seitennavigation: Zurück · 1 2 3 … · Weiter
class DiscoverPageNavigation extends StatelessWidget {
  const DiscoverPageNavigation({
    super.key,
    required this.state,
    required this.onPageSelected,
  });

  final DiscoverActivitiesState state;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    if (state.totalCount == 0 && !state.isLoading) {
      return const SizedBox(height: 24);
    }

    final theme = Theme.of(context);
    final pages = _visiblePages(state.page, state.totalPages);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        children: [
          Text(
            state.totalCount == 0
                ? 'Keine Events'
                : 'Seite ${state.page} von ${state.totalPages} · ${state.totalCount} Events',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (state.isLoading)
            const SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                _NavButton(
                  label: 'Zurück',
                  enabled: state.hasPreviousPage,
                  onTap: () => onPageSelected(state.page - 1),
                ),
                for (final page in pages)
                  if (page == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('…', style: theme.textTheme.labelLarge),
                    )
                  else
                    _PageNumberButton(
                      page: page,
                      selected: page == state.page,
                      onTap: () => onPageSelected(page),
                    ),
                _NavButton(
                  label: 'Weiter',
                  enabled: state.hasNextPage,
                  onTap: () => onPageSelected(state.page + 1),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Liefert Seitenzahlen mit optionalen `null`-Lücken für „…“.
  List<int?> _visiblePages(int current, int total) {
    if (total <= 7) {
      return [for (var i = 1; i <= total; i++) i];
    }

    final pages = <int?>{1, total, current};
    for (var i = current - 1; i <= current + 1; i++) {
      if (i > 1 && i < total) pages.add(i);
    }

    final sorted = pages.whereType<int>().toList()..sort();
    final result = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) {
        result.add(null);
      }
      result.add(sorted[i]);
    }
    return result;
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        foregroundColor: AppColors.seed,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.seed : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.seed
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
