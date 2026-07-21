import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// Öffentliche Share-Links für CircleVeya (Web).
abstract final class CircleShareLinks {
  /// Optional: `--dart-define=APP_WEB_URL=https://circleveya.vercel.app`
  static const _configuredBase = String.fromEnvironment('APP_WEB_URL');

  static const fallbackBase = 'https://circleveya.vercel.app';

  static String get webBase {
    final configured = _configuredBase.trim();
    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') return origin;
    }
    return fallbackBase;
  }

  static String activity(String activityId) =>
      '$webBase/activity/${Uri.encodeComponent(activityId)}';
}

Future<void> shareActivityLink(
  BuildContext context, {
  required String activityId,
  required String title,
}) async {
  final url = CircleShareLinks.activity(activityId);
  final text = '$title\n$url';
  final l10n = AppLocalizations.of(context);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final sheetL10n = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sheetL10n.shareActivity,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                url,
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(sheetL10n.copyLink),
                subtitle: Text(sheetL10n.copyLinkSubtitle),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.linkCopied)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(sheetL10n.copyAsText),
                subtitle: Text(sheetL10n.copyAsTextSubtitle),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.textCopied)),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
