import 'package:flutter/material.dart';

import '../branding/circleveya_brand.dart';
import '../theme/app_colors.dart';
import 'web_nav_item.dart';

class WebSidebar extends StatelessWidget {
  const WebSidebar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onPremiumTap,
  });

  final WebNavItem selected;
  final ValueChanged<WebNavItem> onSelected;
  final VoidCallback? onPremiumTap;

  static const _width = 248.0;

  static double get width => _width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: _width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CircleVeyaBrand.minLogoExtent,
                maxHeight: 44,
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: CircleVeyaBrand(logoHeight: 40),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final item in WebNavItem.mainItems)
                  if (item.isPrimary)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 4),
                      child: FilledButton.icon(
                        onPressed: () => onSelected(item),
                        icon: Icon(item.icon, size: 20),
                        label: Text(item.label),
                        style: FilledButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    _NavTile(
                      item: item,
                      selected: selected == item,
                      onTap: () => onSelected(item),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onPremiumTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Circle Premium',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mehr Sichtbarkeit & exklusive Features',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final WebNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
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
