import 'package:flutter/material.dart';

import '../../domain/entities/activity.dart';

/// „Neu“, „Gesponsert“ und „Automatisch“-Badges auf Aktivitätskarten.
class ActivityStatusBadges extends StatelessWidget {
  const ActivityStatusBadges({
    super.key,
    required this.activity,
  });

  final DiscoverableActivity activity;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (activity.isNew)
          const _Badge(
            label: 'Neu',
            color: Color(0xFF22C55E),
            icon: Icons.fiber_new,
          ),
        if (activity.isFeatured || activity.isSponsored)
          const _Badge(
            label: 'Gesponsert',
            color: Color(0xFFF59E0B),
            icon: Icons.star,
          ),
        if (activity.isExternal)
          const _Badge(
            label: 'Automatisch',
            color: Color(0xFF6366F1),
            icon: Icons.public,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
