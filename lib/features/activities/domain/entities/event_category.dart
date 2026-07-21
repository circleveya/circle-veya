/// Kategorien für den Entdecken-Filter (angelehnt an Eventfrog-Rubriken).
enum EventCategory {
  all,
  concerts,
  parties,
  festivals,
  theater,
  comedy,
  sport,
  kids,
  courses,
  markets,
  classic,
  leisure,
  other;

  String get label => switch (this) {
        all => 'Alle Kategorien',
        concerts => 'Konzerte',
        parties => 'Parties',
        festivals => 'Festivals',
        theater => 'Theater & Bühne',
        comedy => 'Comedy',
        sport => 'Sport & Fitness',
        kids => 'Kinder & Familie',
        courses => 'Kurse & Seminare',
        markets => 'Märkte & Messen',
        classic => 'Klassik & Oper',
        leisure => 'Freizeit & Ausflüge',
        other => 'Sonstiges',
      };

  /// Dropdown-Text im Eventfrog-Stil („allen Rubriken“).
  String get filterPhrase => switch (this) {
        all => 'allen Kategorien',
        concerts => 'Konzerten',
        parties => 'Parties',
        festivals => 'Festivals',
        theater => 'Theater & Bühne',
        comedy => 'Comedy',
        sport => 'Sport & Fitness',
        kids => 'Kinder & Familie',
        courses => 'Kursen & Seminaren',
        markets => 'Märkten & Messen',
        classic => 'Klassik & Oper',
        leisure => 'Freizeit & Ausflügen',
        other => 'Sonstigem',
      };

  String? get dbValue => switch (this) {
        all => null,
        _ => name,
      };

  static EventCategory fromDb(String? value) {
    if (value == null || value.trim().isEmpty) return all;
    final key = value.trim().toLowerCase();
    return EventCategory.values.firstWhere(
      (c) => c.name == key,
      orElse: () => other,
    );
  }

  static const List<EventCategory> filterOptions = EventCategory.values;
}
