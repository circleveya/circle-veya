import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

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
    isScrollControlled: true,
    builder: (sheetContext) {
      final sheetL10n = AppLocalizations.of(sheetContext);
      final theme = Theme.of(sheetContext);

      Future<void> openShare(Uri uri) async {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && sheetContext.mounted) {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            SnackBar(content: Text(sheetL10n.errorGeneric)),
          );
        }
      }

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sheetL10n.shareActivity,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                sheetL10n.share,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ShareTarget(
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      icon: Icons.chat,
                      onTap: () => openShare(
                        Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent(text)}',
                        ),
                      ),
                    ),
                    _ShareTarget(
                      label: 'Telegram',
                      color: const Color(0xFF229ED9),
                      icon: Icons.send_rounded,
                      onTap: () => openShare(
                        Uri.parse(
                          'https://t.me/share/url'
                          '?url=${Uri.encodeComponent(url)}'
                          '&text=${Uri.encodeComponent(title)}',
                        ),
                      ),
                    ),
                    _ShareTarget(
                      label: 'X',
                      color: const Color(0xFF0F1419),
                      icon: Icons.close_rounded,
                      glyph: '𝕏',
                      onTap: () => openShare(
                        Uri.parse(
                          'https://twitter.com/intent/tweet'
                          '?text=${Uri.encodeComponent(title)}'
                          '&url=${Uri.encodeComponent(url)}',
                        ),
                      ),
                    ),
                    _ShareTarget(
                      label: 'Reddit',
                      color: const Color(0xFFFF4500),
                      icon: Icons.reddit,
                      onTap: () => openShare(
                        Uri.parse(
                          'https://www.reddit.com/submit'
                          '?url=${Uri.encodeComponent(url)}'
                          '&title=${Uri.encodeComponent(title)}',
                        ),
                      ),
                    ),
                    _ShareTarget(
                      label: 'LinkedIn',
                      color: const Color(0xFF0A66C2),
                      icon: Icons.business_center,
                      onTap: () => openShare(
                        Uri.parse(
                          'https://www.linkedin.com/sharing/share-offsite/'
                          '?url=${Uri.encodeComponent(url)}',
                        ),
                      ),
                    ),
                    _ShareTarget(
                      label: 'E-Mail',
                      color: const Color(0xFF5F6368),
                      icon: Icons.email_outlined,
                      onTap: () => openShare(
                        Uri.parse(
                          'mailto:?subject=${Uri.encodeComponent(title)}'
                          '&body=${Uri.encodeComponent(text)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.linkCopied)),
                        );
                      },
                      child: Text(sheetL10n.copyLink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.seed.withValues(alpha: 0.15),
                  child: const Icon(Icons.link, color: AppColors.seed),
                ),
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
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.seed.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.seed,
                  ),
                ),
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

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.glyph,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String? glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: glyph != null
                    ? Text(
                        glyph!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
