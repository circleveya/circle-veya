import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Legacy-Hero – Entdecken nutzt [DiscoverSearchHeader].
/// Behalten für Kompatibilität / visuelle Referenz.
class DiscoverHero extends StatelessWidget {
  const DiscoverHero({
    super.key,
    this.onSearch,
  });

  final ValueChanged<String>? onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            onChanged: onSearch,
            onSubmitted: onSearch,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Was möchtest du heute erleben?',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              border: OutlineInputBorder(
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
