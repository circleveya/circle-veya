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
    if (name.isEmpty) {
      // ignore: avoid_print
      print('CircleVeya ImageService: leerer activityName – Abbruch');
      return null;
    }

    // ignore: avoid_print
    print('CircleVeya ImageService: rufe fetch-activity-image für "$name"');

    try {
      final response = await _client.functions.invoke(
        'fetch-activity-image',
        body: {'activityName': name},
      );

      // ignore: avoid_print
      print(
        'CircleVeya ImageService: Status ${response.status}, data=${response.data}',
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map) {
          final url = data['image_url'];
          if (url is String && url.trim().isNotEmpty) {
            // ignore: avoid_print
            print('CircleVeya ImageService: OK → $url');
            return url.trim();
          }
          // ignore: avoid_print
          print(
            'CircleVeya ImageService: 200 ohne image_url – data=$data',
          );
        } else {
          // ignore: avoid_print
          print(
            'CircleVeya ImageService: 200 aber data ist kein Map (${data.runtimeType})',
          );
        }
      } else {
        // ignore: avoid_print
        print(
          'CircleVeya ImageService: Fehler-Status ${response.status} '
          'data=${response.data}',
        );
      }
    } on FunctionException catch (error, stackTrace) {
      // ignore: avoid_print
      print(
        'CircleVeya ImageService: FunctionException '
        'status=${error.status} details=${error.details} '
        'reason=${error.reasonPhrase}\n$stackTrace',
      );
    } catch (error, stackTrace) {
      // ignore: avoid_print
      print(
        'CircleVeya ImageService: Exception $error\n$stackTrace',
      );
      if (kDebugMode) {
        debugPrint(
          'CircleVeya: fetchActivityImage fehlgeschlagen: $error\n$stackTrace',
        );
      }
    }

    return null;
  }
}
