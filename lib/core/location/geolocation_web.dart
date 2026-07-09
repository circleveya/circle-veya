// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// HTML5 Geolocation API – Fallback/Ergänzung zu geolocator auf Flutter Web.
Future<({double lat, double lng})?> getNativeBrowserPosition() async {
  try {
    final position = await html.window.navigator.geolocation.getCurrentPosition(
      enableHighAccuracy: false,
      timeout: const Duration(seconds: 12),
    );
    final coords = position.coords;
    if (coords?.latitude == null || coords?.longitude == null) {
      return null;
    }
    return (
      lat: coords!.latitude!.toDouble(),
      lng: coords.longitude!.toDouble(),
    );
  } catch (_) {
    return null;
  }
}
