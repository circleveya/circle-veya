import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  /// Event aus Share-Link oder Chat-Vorschau oeffnen.
  static void open(BuildContext context, {required String activityId, String? url}) {
    final uri = url != null ? Uri.tryParse(url) : null;
    final path = uri?.path;
    if (path != null &&
        path.startsWith('/activity/') &&
        path.split('/').where((s) => s.isNotEmpty).length >= 2) {
      context.push(path);
      return;
    }
    context.push('/activity/${Uri.encodeComponent(activityId)}');
  }
}
