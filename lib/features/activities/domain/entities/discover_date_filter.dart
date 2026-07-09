/// Zeitraum-Filter für den Entdecken-Feed.
enum DiscoverDateFilterOption {
  all('Alle Termine'),
  today('Heute'),
  thisWeekend('Dieses Wochenende'),
  thisWeek('Diese Woche'),
  custom('Datum wählen');

  const DiscoverDateFilterOption(this.label);

  final String label;

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
        return (
          start: dayStart,
          end: dayStart
              .add(const Duration(days: 1))
              .subtract(const Duration(microseconds: 1)),
        );
      case thisWeekend:
        final saturday = _weekendSaturday(dayStart, now.weekday);
        return (
          start: saturday,
          end: saturday
              .add(const Duration(days: 2))
              .subtract(const Duration(microseconds: 1)),
        );
      case thisWeek:
        final monday = dayStart.subtract(Duration(days: now.weekday - DateTime.monday));
        return (
          start: monday,
          end: monday
              .add(const Duration(days: 7))
              .subtract(const Duration(microseconds: 1)),
        );
      case custom:
        if (customStart == null) return (start: null, end: null);
        final start = DateTime(
          customStart.year,
          customStart.month,
          customStart.day,
        );
        final endBase = customEnd ?? customStart;
        final end = DateTime(endBase.year, endBase.month, endBase.day)
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1));
        return (start: start, end: end);
    }
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
