import 'package:flutter/foundation.dart';

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
