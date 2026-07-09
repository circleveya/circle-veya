/// Standort-Modell und Schweizer Presets für CircleVeya.
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.isMock = false,
    this.label,
  });

  final double latitude;
  final double longitude;
  final LocationSource source;
  final bool isMock;
  final String? label;

  String get displayLabel =>
      label ?? source.defaultLabel;

  /// Standard-Fallback für Tests (Frauenfeld, CH).
  static const mockFrauenfeld = UserLocation(
    latitude: 47.5569,
    longitude: 8.8982,
    source: LocationSource.mock,
    isMock: true,
    label: 'Frauenfeld (Test)',
  );

  @Deprecated('Use mockFrauenfeld')
  static const mock = mockFrauenfeld;

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    LocationSource? source,
    bool? isMock,
    String? label,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      source: source ?? this.source,
      isMock: isMock ?? this.isMock,
      label: label ?? this.label,
    );
  }
}

enum LocationSource {
  gps,
  mock,
  zurich,
  basel,
  bern,
  frauenfeld,
  manual;

  String get defaultLabel => switch (this) {
        LocationSource.gps => 'Aktueller Standort',
        LocationSource.mock => 'Test-Standort',
        LocationSource.zurich => 'Zürich',
        LocationSource.basel => 'Basel',
        LocationSource.bern => 'Bern',
        LocationSource.frauenfeld => 'Frauenfeld',
        LocationSource.manual => 'Manuell',
      };
}

enum LocationPreset {
  zurich('Zürich', 47.3769, 8.5417, LocationSource.zurich),
  basel('Basel', 47.5596, 7.5886, LocationSource.basel),
  bern('Bern', 46.9480, 7.4474, LocationSource.bern),
  frauenfeld('Frauenfeld', 47.5569, 8.8982, LocationSource.frauenfeld);

  const LocationPreset(
    this.label,
    this.latitude,
    this.longitude,
    this.source,
  );

  final String label;
  final double latitude;
  final double longitude;
  final LocationSource source;

  UserLocation toLocation({bool isMock = false}) => UserLocation(
        latitude: latitude,
        longitude: longitude,
        source: source,
        isMock: isMock,
        label: label,
      );
}

/// Entfernungs-Filter für den Feed.
enum DistanceFilterOption {
  km1('1 km', 1),
  km5('5 km', 5),
  km10('10 km', 10),
  km25('25 km', 25),
  km50('50 km', 50),
  everywhere('Überall', null);

  const DistanceFilterOption(this.label, this.maxKm);

  final String label;
  final double? maxKm;
}
