import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lädt Bilder plattformübergreifend (Web + Mobile) nach Supabase Storage.
class SupabaseStorageHelper {
  SupabaseStorageHelper(this._client);

  final SupabaseClient _client;

  Future<String> uploadImage({
    required String bucket,
    required String path,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeFor(file);

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  String _contentTypeFor(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  static String extensionFrom(XFile file) {
    final parts = file.name.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return kIsWeb ? 'jpg' : 'jpg';
  }
}
