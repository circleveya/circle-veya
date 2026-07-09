import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final premiumState = ref.watch(premiumSimulationControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Einstellungen',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Circle Premium (Test)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Simuliere Premium-Status für UI-Tests. Das Premium-Banner '
                  'in der Sidebar wird ausgeblendet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                profileAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (profile) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.isPremium
                              ? 'Premium aktiv'
                              : 'Premium inaktiv',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      FilledButton(
                        onPressed: premiumState.isLoading
                            ? null
                            : () => ref
                                .read(premiumSimulationControllerProvider.notifier)
                                .setPremium(!profile.isPremium),
                        child: Text(
                          profile.isPremium ? 'Deaktivieren' : 'Simulieren',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
