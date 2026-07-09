import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/providers/profile_provider.dart';
import '../theme/app_colors.dart';
import 'web_shell_destination.dart';

/// Feste linke Navigationsleiste für die Web-App.
class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final WebShellDestination selected;
  final ValueChanged<WebShellDestination> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(myProfileProvider).valueOrNull?.isPremium ?? false;

    return Container(
      width: AppColors.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: BorderSide(color: AppColors.sidebarBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const _CircleLogo(),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CreateActivityButton(
              isSelected: selected == WebShellDestination.create,
              onTap: () => onSelected(WebShellDestination.create),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final dest in kWebSidebarMainNav)
                  _SidebarNavItem(
                    destination: dest,
                    isSelected: selected == dest,
                    onTap: () => onSelected(dest),
                  ),
                const SizedBox(height: 12),
                Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                for (final dest in kWebSidebarFooterNav)
                  _SidebarNavItem(
                    destination: dest,
                    isSelected: selected == dest,
                    onTap: () => onSelected(dest),
                  ),
              ],
            ),
          ),
          if (!isPremium) const _PremiumUpsellCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CircleLogo extends StatelessWidget {
  const _CircleLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.brightness_7, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Circle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.seed,
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _CreateActivityButton extends StatelessWidget {
  const _CreateActivityButton({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.seed.withValues(alpha: 0.9) : AppColors.seed,
      borderRadius: BorderRadius.circular(14),
      elevation: isSelected ? 0 : 2,
      shadowColor: AppColors.seed.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aktivität erstellen',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final WebShellDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? AppColors.seed : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppColors.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.seed.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: 22,
                  color: color,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destination.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? AppColors.seed
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
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

class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.premiumGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.seed.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Circle Premium',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Mehr Sichtbarkeit, unbegrenzte Aktivitäten & exklusive Features.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.seed,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Jetzt upgraden',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
