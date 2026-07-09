import 'package:flutter/material.dart';

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
  });

  final bool friends;
  final bool acquaintances;
  final bool strangers;
  final ValueChanged<bool> onFriendsChanged;
  final ValueChanged<bool> onAcquaintancesChanged;
  final ValueChanged<bool> onStrangersChanged;
  final double radiusKm;
  final ValueChanged<double> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
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
          Text('Entdeckungs-Radius: ${radiusKm.round()} km'),
          Slider(
            value: radiusKm,
            min: 5,
            max: 100,
            divisions: 19,
            label: '${radiusKm.round()} km',
            onChanged: onRadiusChanged,
          ),
        ],
      ],
    );
  }
}
