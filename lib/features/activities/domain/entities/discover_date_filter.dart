import '../../../../l10n/app_localizations.dart';

/// Schnell-Auswahl für den Zeitraum im Entdecken-Feed.
enum DiscoverDateFilterOption {
  all('Alle'),
  today('Heute'),
  tomorrow('Morgen'),
  thisWeekend('Dieses Wochenende'),
  thisWeek('Diese Woche'),
  custom('Datum wählen');

  const DiscoverDateFilterOption(this.label);

  final String label;

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        all => l10n.all,
        today => l10n.today,
        tomorrow => l10n.tomorrow,
        thisWeekend => l10n.thisWeekend,
        thisWeek => l10n.thisWeek,
        custom => l10n.pickDate,
      };

  static const quickFilters = [
    DiscoverDateFilterOption.today,
    DiscoverDateFilterOption.tomorrow,
    DiscoverDateFilterOption.thisWeekend,
  ];

  /// Liefert [start, end] in lokaler Zeit (inklusiv), oder `null` für „alle“.
  ({DateTime? start, DateTime? end}) resolveRange({
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? reference,
  }) {
    if (this == all) {
      return (start: null, end: null);
    }

    final now = reference ?? DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);

    switch (this) {
      case all:
        return (start: null, end: null);
      case today:
        return _dayRange(dayStart);
      case tomorrow:
        return _dayRange(dayStart.add(const Duration(days: 1)));
      case thisWeekend:
        final saturday = _weekendSaturday(dayStart, now.weekday);
        return (
          start: saturday,
          end: saturday
              .add(const Duration(days: 2))
              .subtract(const Duration(microseconds: 1)),
        );
      case thisWeek:
        final monday =
            dayStart.subtract(Duration(days: now.weekday - DateTime.monday));
        return (
          start: monday,
          end: monday
              .add(const Duration(days: 7))
              .subtract(const Duration(microseconds: 1)),
        );
      case custom:
        DateTime? start;
        DateTime? end;
        if (customStart != null) {
          start = DateTime(
            customStart.year,
            customStart.month,
            customStart.day,
          );
        }
        if (customEnd != null) {
          end = DateTime(customEnd.year, customEnd.month, customEnd.day)
              .add(const Duration(days: 1))
              .subtract(const Duration(microseconds: 1));
        }
        return (start: start, end: end);
    }
  }

  static ({DateTime start, DateTime end}) _dayRange(DateTime dayStart) {
    return (
      start: dayStart,
      end: dayStart
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1)),
    );
  }

  static DateTime _weekendSaturday(DateTime dayStart, int weekday) {
    if (weekday == DateTime.saturday) return dayStart;
    if (weekday == DateTime.sunday) {
      return dayStart.subtract(const Duration(days: 1));
    }
    final daysUntilSaturday = DateTime.saturday - weekday;
    return dayStart.add(Duration(days: daysUntilSaturday));
  }
}
