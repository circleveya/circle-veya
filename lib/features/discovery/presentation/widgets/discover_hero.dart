import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Kompakter Such-Hero für Entdecken – ohne Slogan.
class DiscoverHero extends StatelessWidget {
  const DiscoverHero({
    super.key,
    this.onSearch,
  });

  final ValueChanged<String>? onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entdecken',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onSubmitted: onSearch,
            decoration: InputDecoration(
              hintText: 'Was möchtest du heute erleben?',
              filled: true,
              fillColor: theme.colorScheme.surface,
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.brandNavy.withValues(alpha: 0.55),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.seed.withValues(alpha: 0.55),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
