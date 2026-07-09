import 'package:flutter/material.dart';

/// Platzhalter für zukünftige Gruppen-Funktion.
class GroupsPlaceholderScreen extends StatelessWidget {
  const GroupsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderBody(
      icon: Icons.groups_outlined,
      title: 'Gruppen',
      subtitle: 'Circle-Gruppen kommen in einer späteren Phase.',
    );
  }
}

class ChallengesPlaceholderScreen extends StatelessWidget {
  const ChallengesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderBody(
      icon: Icons.emoji_events_outlined,
      title: 'Challenges',
      subtitle: 'Level, Fortschritt und Belohnungen – bald verfügbar.',
    );
  }
}

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderBody(
      icon: Icons.settings_outlined,
      title: 'Einstellungen',
      subtitle: 'App-Einstellungen werden hier konfiguriert.',
    );
  }
}

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
