import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client.dart';

/// Ruft die Edge Function `fetch-activity-image` für Aktivitäts-Cover ab.
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService(ref.watch(supabaseClientProvider));
});

class ImageService {
  ImageService(this._client);

  final SupabaseClient _client;

  /// Liefert eine Pexels-Bild-URL oder `null`, wenn nichts Passendes kommt.
  ///
  /// UI zeigt bei `null` den Brand-Gradient (Quiet Luxury) statt eines Logos.
  Future<String?> fetchActivityImage(String activityName) async {
    final name = activityName.trim();
    if (name.isEmpty) return null;

    try {
      final response = await _client.functions.invoke(
        'fetch-activity-image',
        body: {'activityName': name},
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map) {
          final url = data['image_url'];
          if (url is String && url.trim().isNotEmpty) {
            return url.trim();
          }
        }
      } else if (kDebugMode) {
        debugPrint(
          'CircleVeya: fetch-activity-image Status ${response.status}',
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'CircleVeya: fetchActivityImage fehlgeschlagen: $error\n$stackTrace',
        );
      }
    }

    return null;
  }
}
