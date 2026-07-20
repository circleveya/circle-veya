import 'package:flutter/material.dart';

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
    final clamped = radiusKm.clamp(PremiumLimits.minRadiusKm, maxRadiusKm);
    final divisions =
        ((maxRadiusKm - PremiumLimits.minRadiusKm) / 5).round().clamp(1, 40);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zielgruppen',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: friends,
          onChanged: (v) => onFriendsChanged(v ?? false),
          title: const Text('Freunde'),
          subtitle: const Text('Direkt zusagen möglich'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: acquaintances,
          onChanged: (v) => onAcquaintancesChanged(v ?? false),
          title: const Text('Bekannte'),
          subtitle: const Text('Können Interesse bekunden'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: strangers,
          onChanged: (v) => onStrangersChanged(v ?? false),
          title: const Text('Fremde / Gleichgesinnte'),
          subtitle: const Text('Radius-basiert, Interesse bekunden'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (strangers) ...[
          const SizedBox(height: 8),
          Text('Entdeckungs-Radius: ${clamped.round()} km'),
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
              'Free: max. ${PremiumLimits.freeRadiusKm.round()} km · '
              'Premium: bis ${PremiumLimits.premiumRadiusKm.round()} km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ],
    );
  }
}
