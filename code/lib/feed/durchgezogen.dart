import '../checkin/checkin.dart';

/// One entry in "Durchgezogen" (see vault Umsetzung/Durchgezogen.md):
/// something done despite reluctance, from the coach or the user.
class Durchgezogen {
  const Durchgezogen({
    required this.datum,
    required this.text,
    required this.vonCoach,
    required this.erstellt,
  });

  /// The day it belongs to.
  final DateTime datum;
  final String text;
  final bool vonCoach;

  /// When it was written; tells two entries apart.
  final DateTime erstellt;

  Map<String, Object> toJson() => {
    'datum': dayKey(datum),
    'text': text,
    'von_coach': vonCoach,
    'erstellt': erstellt.toIso8601String(),
  };

  factory Durchgezogen.fromJson(Map<String, dynamic> json) => Durchgezogen(
    datum: DateTime.parse(json['datum'] as String),
    text: json['text'] as String? ?? '',
    vonCoach: json['von_coach'] == true,
    erstellt: DateTime.parse(
      json['erstellt'] as String? ?? json['datum'] as String,
    ),
  );
}

/// Monday of the week [d] is in.
DateTime wochenStart(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// Entries of the week [d] is in, oldest first.
List<Durchgezogen> inWoche(List<Durchgezogen> all, DateTime d) {
  final start = wochenStart(d);
  final end = DateTime(start.year, start.month, start.day + 7);
  return [
    for (final e in all)
      if (!e.datum.isBefore(start) && e.datum.isBefore(end)) e,
  ]..sort((a, b) {
    final c = a.datum.compareTo(b.datum);
    return c != 0 ? c : a.erstellt.compareTo(b.erstellt);
  });
}

/// All entries grouped by week, newest week first and newest entry first.
List<(DateTime, List<Durchgezogen>)> nachWochen(List<Durchgezogen> all) {
  final byWeek = <String, List<Durchgezogen>>{};
  for (final e in all) {
    byWeek.putIfAbsent(dayKey(wochenStart(e.datum)), () => []).add(e);
  }
  final keys = byWeek.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final k in keys)
      (
        DateTime.parse(k),
        byWeek[k]!..sort((a, b) {
          final c = b.datum.compareTo(a.datum);
          return c != 0 ? c : b.erstellt.compareTo(a.erstellt);
        }),
      ),
  ];
}
