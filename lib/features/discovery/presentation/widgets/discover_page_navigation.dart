import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../activities/domain/entities/discover_activities_state.dart';

/// Klassische Seitennavigation: Zurück · Seite X · Weiter
class DiscoverPageNavigation extends StatelessWidget {
  const DiscoverPageNavigation({
    super.key,
    required this.state,
    required this.onPrevious,
    required this.onNext,
  });

  final DiscoverActivitiesState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (state.activities.isEmpty && !state.isLoading) {
      return const SizedBox(height: 24);
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        children: [
          if (state.isLoading)
            const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavButton(
                  label: 'Zurück',
                  enabled: state.hasPreviousPage,
                  onTap: onPrevious,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Seite ${state.displayPage}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandNavy,
                    ),
                  ),
                ),
                _NavButton(
                  label: 'Weiter',
                  enabled: state.hasNextPage,
                  onTap: onNext,
                ),
              ],
            ),
        ],
      ),
    );
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
