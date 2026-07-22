import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'swiss_places.dart';

/// OpenStreetMap-Nominatim für freie Ortseingabe (CH).
class PlaceGeocoder {
  PlaceGeocoder._();

  static Future<PlaceSuggestion?> lookup(String query) async {
    final q = query.trim();
    if (q.length < 2) return null;

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': q,
          'countrycodes': 'ch',
          'format': 'json',
          'limit': '1',
          'addressdetails': '0',
        },
      );

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'CircleVeya/1.0 (https://circleveya.vercel.app)',
          'Accept-Language': 'de',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final rows = jsonDecode(response.body);
      if (rows is! List || rows.isEmpty) return null;

      final row = rows.first;
      if (row is! Map<String, dynamic>) return null;

      final lat = double.tryParse('${row['lat']}');
      final lon = double.tryParse('${row['lon']}');
      if (lat == null || lon == null) return null;

      final name = (row['display_name'] as String?)?.split(',').first.trim();
      if (name == null || name.isEmpty) return null;

      return PlaceSuggestion(name: name, latitude: lat, longitude: lon);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('CircleVeya: Geocoding fehlgeschlagen ($query): $error\n$stackTrace');
      }
      return null;
    }
  }
}
