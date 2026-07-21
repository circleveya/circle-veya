import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../data/gif_catalog.dart';

final gifSearchServiceProvider = Provider<GifSearchService>((ref) {
  return GifSearchService(ref.watch(supabaseClientProvider));
});

class GifSearchService {
  GifSearchService(this._client);

  final SupabaseClient _client;

  /// Sucht GIFs: Giphy via Edge Function wenn verfügbar, sonst lokaler Katalog.
  Future<List<CatalogGif>> search(String query) async {
    final q = query.trim();
    try {
      final response = await _client.functions.invoke(
        'search-gifs',
        body: {'query': q, 'limit': 24},
      );
      if (response.status == 200 && response.data is Map) {
        final map = response.data as Map;
        final source = map['source']?.toString();
        final raw = map['gifs'];
        if (source == 'giphy' && raw is List && raw.isNotEmpty) {
          final remote = <CatalogGif>[];
          for (final item in raw) {
            if (item is! Map) continue;
            final id = item['id']?.toString();
            final url = item['url']?.toString();
            final preview = item['preview_url']?.toString() ?? url;
            if (id == null || url == null || url.isEmpty) continue;
            remote.add(
              CatalogGif(
                id: id,
                url: url,
                previewUrl: preview ?? url,
                tags: const [],
              ),
            );
          }
          if (remote.isNotEmpty) return remote;
        }
      }
    } catch (_) {
      // Fallback unten
    }

    if (q.isEmpty) return List<CatalogGif>.from(kCatalogGifs);
    return kCatalogGifs.where((g) => g.matches(q)).toList(growable: false);
  }
}
