import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final premiumState = ref.watch(premiumSimulationControllerProvider);
    final privacyState = ref.watch(profilePrivacyControllerProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.settings,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.brandNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        profileAsync.when(
          loading: () => const _PremiumCardSkeleton(),
          error: (e, _) => _ErrorCard(message: '$e'),
          data: (profile) {
            if (!profile.isBusinessProfile) {
              return Column(
                children: [
                  _ProfilePrivacyCard(
                    isPrivate: profile.profilePrivate,
                    isLoading: privacyState.isLoading,
                    onToggle: () async {
                      await ref
                          .read(profilePrivacyControllerProvider.notifier)
                          .setProfilePrivate(!profile.profilePrivate);
                      if (!context.mounted) return;
                      final error =
                          ref.read(profilePrivacyControllerProvider).error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error == null
                                ? (profile.profilePrivate
                                    ? l10n.profileNowPublic
                                    : l10n.profileNowPrivate)
                                : 'Fehler: $error',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _PremiumTestCard(
                    isPremium: profile.isPremium,
                    isLoading: premiumState.isLoading,
                    onToggle: () async {
                      await ref
                          .read(premiumSimulationControllerProvider.notifier)
                          .setPremium(!profile.isPremium);
                      if (!context.mounted) return;
                      final error =
                          ref.read(premiumSimulationControllerProvider).error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error == null
                                ? (profile.isPremium
                                    ? 'Premium deaktiviert'
                                    : 'Premium aktiviert')
                                : 'Fehler: $error',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
            return _PremiumTestCard(
              isPremium: profile.isPremium,
              isLoading: premiumState.isLoading,
              onToggle: () async {
                await ref
                    .read(premiumSimulationControllerProvider.notifier)
                    .setPremium(!profile.isPremium);
                if (!context.mounted) return;
                final error = ref.read(premiumSimulationControllerProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error == null
                          ? (profile.isPremium
                              ? 'Premium deaktiviert'
                              : 'Premium aktiviert')
                          : 'Fehler: $error',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ProfilePrivacyCard extends StatelessWidget {
  const _ProfilePrivacyCard({
    required this.isPrivate,
    required this.isLoading,
    required this.onToggle,
  });

  final bool isPrivate;
  final bool isLoading;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(color: AppColors.sidebarBorder),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
        value: isPrivate,
        onChanged: isLoading ? null : (_) => onToggle(),
        secondary: Icon(
          isPrivate ? Icons.lock_outline : Icons.public_outlined,
          color: AppColors.brandNavy,
        ),
        title: Text(
          l10n.privateProfileSetting,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(l10n.privateProfileSettingSubtitle),
      ),
    );
  }
}

class _PremiumTestCard extends StatelessWidget {
  const _PremiumTestCard({
    required this.isPremium,
    required this.isLoading,
    required this.onToggle,
  });

  final bool isPremium;
  final bool isLoading;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isPremium
            ? AppColors.premiumGradient
            : LinearGradient(
                colors: [
                  AppColors.brandNavy.withValues(alpha: 0.06),
                  AppColors.brandPurple.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: isPremium
            ? null
            : Border.all(color: AppColors.sidebarBorder),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppColors.seed : AppColors.brandNavy)
                .withValues(alpha: isPremium ? 0.28 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPremium
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.seed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: isPremium ? Colors.white : AppColors.seed,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CircleVeya Premium',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isPremium ? Colors.white : AppColors.brandNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Testmodus · nur für UI-Checks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPremium
                              ? Colors.white.withValues(alpha: 0.85)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(active: isPremium),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              isPremium
                  ? 'Premium ist aktiv: größerer Radius, mehr Termine, Hervorheben und Badge.'
                  : 'Simuliere Premium für UI-Tests: Radius bis 100 km, bis 12 Termine, Hervorheben und Badge.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isPremium
                    ? Colors.white.withValues(alpha: 0.92)
                    : theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BenefitChip(label: 'Radius bis 100 km', active: isPremium),
                _BenefitChip(label: 'Bis 12 Termine', active: isPremium),
                _BenefitChip(
                  label: 'Hervorgehobene Aktivitäten',
                  active: isPremium,
                ),
                _BenefitChip(label: 'Premium-Badge', active: isPremium),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : onToggle,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isPremium ? Colors.white : AppColors.brandNavy,
                  foregroundColor:
                      isPremium ? AppColors.seed : Colors.white,
                  disabledBackgroundColor: Colors.white24,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: isPremium ? AppColors.seed : Colors.white,
                        ),
                      )
                    : Text(
                        isPremium ? 'Premium deaktivieren' : 'Premium simulieren',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.22)
            : AppColors.brandNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.pause_circle_outline,
            size: 14,
            color: active ? Colors.white : AppColors.brandNavy,
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Aktiv' : 'Inaktiv',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.brandNavy,
                ),
          ),
        ],
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.35)
              : AppColors.sidebarBorder,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: active ? Colors.white : AppColors.brandNavy,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _PremiumCardSkeleton extends StatelessWidget {
  const _PremiumCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.sidebarBorder.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    );
  }
}
