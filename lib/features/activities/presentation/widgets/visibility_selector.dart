import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/premium_limits.dart';

class VisibilitySelector extends StatelessWidget {
  const VisibilitySelector({
    super.key,
    required this.friends,
    required this.acquaintances,
    required this.strangers,
    required this.onFriendsChanged,
    required this.onAcquaintancesChanged,
    required this.onStrangersChanged,
    required this.radiusKm,
    required this.onRadiusChanged,
    this.maxRadiusKm = PremiumLimits.freeRadiusKm,
    this.isPremium = false,
  });

  final bool friends;
  final bool acquaintances;
  final bool strangers;
  final ValueChanged<bool> onFriendsChanged;
  final ValueChanged<bool> onAcquaintancesChanged;
  final ValueChanged<bool> onStrangersChanged;
  final double radiusKm;
  final ValueChanged<double> onRadiusChanged;
  final double maxRadiusKm;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clamped = radiusKm.clamp(PremiumLimits.minRadiusKm, maxRadiusKm);
    final divisions =
        ((maxRadiusKm - PremiumLimits.minRadiusKm) / 5).round().clamp(1, 40);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.targetAudiences,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: friends,
          onChanged: (v) => onFriendsChanged(v ?? false),
          title: Text(l10n.friends),
          subtitle: Text(l10n.friendsCanJoin),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: acquaintances,
          onChanged: (v) => onAcquaintancesChanged(v ?? false),
          title: Text(l10n.acquaintances),
          subtitle: Text(l10n.acquaintancesCanInterest),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: strangers,
          onChanged: (v) => onStrangersChanged(v ?? false),
          title: Text(l10n.strangersAudience),
          subtitle: Text(l10n.strangersSubtitle),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (strangers) ...[
          const SizedBox(height: 8),
          Text(l10n.discoveryRadius(clamped.round())),
          Slider(
            value: clamped.toDouble(),
            min: PremiumLimits.minRadiusKm,
            max: maxRadiusKm,
            divisions: divisions,
            label: '${clamped.round()} km',
            onChanged: onRadiusChanged,
          ),
          if (!isPremium)
            Text(
              l10n.radiusFreePremiumHint(
                PremiumLimits.freeRadiusKm.round(),
                PremiumLimits.premiumRadiusKm.round(),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ],
    );
  }
}
