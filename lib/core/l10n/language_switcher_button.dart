import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/locale_provider.dart';
import '../../l10n/app_localizations.dart';

/// Sprachwahl DE / EN (Header oben rechts).
class LanguageSwitcherButton extends ConsumerWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final isEnglish = locale.languageCode == 'en';

    return PopupMenuButton<String>(
      tooltip: l10n.language,
      offset: const Offset(0, 44),
      onSelected: (code) {
        ref.read(localeProvider.notifier).setLocale(
              code == 'en' ? const Locale('en') : const Locale('de', 'CH'),
            );
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'de',
          checked: !isEnglish,
          child: Text(l10n.german),
        ),
        CheckedPopupMenuItem(
          value: 'en',
          checked: isEnglish,
          child: Text(l10n.english),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 22,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              isEnglish ? 'EN' : 'DE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
