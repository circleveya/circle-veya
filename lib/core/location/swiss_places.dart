/// Ortsvorschläge für Standort-Autovervollständigung (CH-fokussiert).
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

/// Bekannte Orte für Ghost-Text-Vervollständigung beim Tippen.
const kSwissPlaceSuggestions = <PlaceSuggestion>[
  PlaceSuggestion(name: 'Zürich', latitude: 47.3769, longitude: 8.5417),
  PlaceSuggestion(name: 'Basel', latitude: 47.5596, longitude: 7.5886),
  PlaceSuggestion(name: 'Bern', latitude: 46.9480, longitude: 7.4474),
  PlaceSuggestion(name: 'Frauenfeld', latitude: 47.5569, longitude: 8.8982),
  PlaceSuggestion(name: 'Genf', latitude: 46.2044, longitude: 6.1432),
  PlaceSuggestion(name: 'Lausanne', latitude: 46.5197, longitude: 6.6323),
  PlaceSuggestion(name: 'Luzern', latitude: 47.0502, longitude: 8.3093),
  PlaceSuggestion(name: 'Winterthur', latitude: 47.4988, longitude: 8.7237),
  PlaceSuggestion(name: 'St. Gallen', latitude: 47.4245, longitude: 9.3767),
  PlaceSuggestion(name: 'Lugano', latitude: 46.0037, longitude: 8.9511),
  PlaceSuggestion(name: 'Biel', latitude: 47.1368, longitude: 7.2467),
  PlaceSuggestion(name: 'Thun', latitude: 46.7580, longitude: 7.6280),
  PlaceSuggestion(name: 'Köniz', latitude: 46.9244, longitude: 7.4144),
  PlaceSuggestion(name: 'La Chaux-de-Fonds', latitude: 47.1036, longitude: 6.8326),
  PlaceSuggestion(name: 'Schaffhausen', latitude: 47.6969, longitude: 8.6345),
  PlaceSuggestion(name: 'Fribourg', latitude: 46.8065, longitude: 7.1620),
  PlaceSuggestion(name: 'Chur', latitude: 46.8499, longitude: 9.5329),
  PlaceSuggestion(name: 'Neuchâtel', latitude: 46.9900, longitude: 6.9293),
  PlaceSuggestion(name: 'Vernier', latitude: 46.2170, longitude: 6.0849),
  PlaceSuggestion(name: 'Uster', latitude: 47.3507, longitude: 8.7177),
  PlaceSuggestion(name: 'Sion', latitude: 46.2331, longitude: 7.3601),
  PlaceSuggestion(name: 'Zug', latitude: 47.1662, longitude: 8.5155),
  PlaceSuggestion(name: 'Yverdon-les-Bains', latitude: 46.7785, longitude: 6.6410),
  PlaceSuggestion(name: 'Emmen', latitude: 47.0782, longitude: 8.2998),
  PlaceSuggestion(name: 'Dübendorf', latitude: 47.3972, longitude: 8.6187),
  PlaceSuggestion(name: 'Dietikon', latitude: 47.4017, longitude: 8.4001),
  PlaceSuggestion(name: 'Rapperswil-Jona', latitude: 47.2256, longitude: 8.8223),
  PlaceSuggestion(name: 'Wetzikon', latitude: 47.3264, longitude: 8.7977),
  PlaceSuggestion(name: 'Baar', latitude: 47.1954, longitude: 8.5295),
  PlaceSuggestion(name: 'Wil', latitude: 47.4615, longitude: 9.0424),
  PlaceSuggestion(name: 'Bulle', latitude: 46.6195, longitude: 7.0569),
  PlaceSuggestion(name: 'Aarau', latitude: 47.3925, longitude: 8.0444),
  PlaceSuggestion(name: 'Riehen', latitude: 47.5788, longitude: 7.6512),
  PlaceSuggestion(name: 'Allschwil', latitude: 47.5507, longitude: 7.5360),
  PlaceSuggestion(name: 'Horw', latitude: 47.0169, longitude: 8.3103),
  PlaceSuggestion(name: 'Kreuzlingen', latitude: 47.6505, longitude: 9.1750),
  PlaceSuggestion(name: 'Wettingen', latitude: 47.4659, longitude: 8.3261),
  PlaceSuggestion(name: 'Baden', latitude: 47.4733, longitude: 8.3060),
  PlaceSuggestion(name: 'Kloten', latitude: 47.4515, longitude: 8.5847),
  PlaceSuggestion(name: 'Carouge', latitude: 46.1809, longitude: 6.1392),
  PlaceSuggestion(name: 'Renens', latitude: 46.5398, longitude: 6.5881),
  PlaceSuggestion(name: 'Nyon', latitude: 46.3832, longitude: 6.2396),
  PlaceSuggestion(name: 'Vevey', latitude: 46.4628, longitude: 6.8435),
  PlaceSuggestion(name: 'Montreux', latitude: 46.4312, longitude: 6.9107),
  PlaceSuggestion(name: 'Bellinzona', latitude: 46.1928, longitude: 9.0170),
  PlaceSuggestion(name: 'Locarno', latitude: 46.1670, longitude: 8.7943),
  PlaceSuggestion(name: 'Olten', latitude: 47.3499, longitude: 7.9033),
  PlaceSuggestion(name: 'Solothurn', latitude: 47.2088, longitude: 7.5371),
  PlaceSuggestion(name: 'Langenthal', latitude: 47.2153, longitude: 7.7963),
  PlaceSuggestion(name: 'Wädenswil', latitude: 47.2268, longitude: 8.6699),
  PlaceSuggestion(name: 'Horgen', latitude: 47.2598, longitude: 8.5978),
  PlaceSuggestion(name: 'Thalwil', latitude: 47.2945, longitude: 8.5636),
  PlaceSuggestion(name: 'Adliswil', latitude: 47.3125, longitude: 8.5246),
  PlaceSuggestion(name: 'Schlieren', latitude: 47.3967, longitude: 8.4476),
  PlaceSuggestion(name: 'Opfikon', latitude: 47.4316, longitude: 8.5719),
  PlaceSuggestion(name: 'Wallisellen', latitude: 47.4149, longitude: 8.5967),
  PlaceSuggestion(name: 'Meilen', latitude: 47.2703, longitude: 8.6438),
  PlaceSuggestion(name: 'Pfäffikon SZ', latitude: 47.2011, longitude: 8.7783),
  PlaceSuggestion(name: 'Rorschach', latitude: 47.4780, longitude: 9.4903),
  PlaceSuggestion(name: 'Interlaken', latitude: 46.6863, longitude: 7.8632),
  PlaceSuggestion(name: 'Davos', latitude: 46.8027, longitude: 9.8360),
  PlaceSuggestion(name: 'St. Moritz', latitude: 46.4908, longitude: 9.8355),
  PlaceSuggestion(name: 'Zermatt', latitude: 46.0207, longitude: 7.7491),
  PlaceSuggestion(name: 'Grindelwald', latitude: 46.6242, longitude: 8.0414),
];

PlaceSuggestion? findPlaceSuggestion(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return null;

  final prefixMatches = kSwissPlaceSuggestions
      .where((p) => p.name.toLowerCase().startsWith(q))
      .toList()
    ..sort((a, b) => a.name.length.compareTo(b.name.length));
  if (prefixMatches.isNotEmpty) return prefixMatches.first;

  final containsMatches = kSwissPlaceSuggestions
      .where((p) => p.name.toLowerCase().contains(q))
      .toList()
    ..sort((a, b) => a.name.length.compareTo(b.name.length));
  if (containsMatches.isNotEmpty) return containsMatches.first;

  return null;
}

/// Ghost-Text-Rest: nur bei Prefix-Match (z. B. „zü“ → „rich“).
String? ghostCompletionSuffix(String typed) {
  final q = typed; // keep trailing spaces out
  if (q.trim().isEmpty || q.endsWith(' ')) return null;
  final suggestion = findPlaceSuggestion(q);
  if (suggestion == null) return null;
  final name = suggestion.name;
  if (!name.toLowerCase().startsWith(q.toLowerCase())) return null;
  if (name.length <= q.length) return null;
  return name.substring(q.length);
}
