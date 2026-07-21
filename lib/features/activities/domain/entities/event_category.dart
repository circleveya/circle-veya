import '../../../../l10n/app_localizations.dart';

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

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        all => l10n.catAll,
        concerts => l10n.catConcerts,
        parties => l10n.catParties,
        festivals => l10n.catFestivals,
        theater => l10n.catTheater,
        comedy => l10n.catComedy,
        sport => l10n.catSport,
        kids => l10n.catKids,
        courses => l10n.catCourses,
        markets => l10n.catMarkets,
        classic => l10n.catClassic,
        leisure => l10n.catLeisure,
        other => l10n.catOther,
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

  String localizedFilterPhrase(AppLocalizations l10n) => switch (this) {
        all => l10n.phraseAll,
        concerts => l10n.phraseConcerts,
        parties => l10n.phraseParties,
        festivals => l10n.phraseFestivals,
        theater => l10n.phraseTheater,
        comedy => l10n.phraseComedy,
        sport => l10n.phraseSport,
        kids => l10n.phraseKids,
        courses => l10n.phraseCourses,
        markets => l10n.phraseMarkets,
        classic => l10n.phraseClassic,
        leisure => l10n.phraseLeisure,
        other => l10n.phraseOther,
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
