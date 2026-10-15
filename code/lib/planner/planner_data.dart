import '../checkin/checkin.dart';

/// An appointment the user wrote into the day plan in their own words,
/// e.g. "Zahnarzt Donnerstag 17 Uhr". Work, school, private: everything
/// goes in here (see Umsetzung/Tages-Planer.md).
class Termin {
  const Termin({
    required this.datum,
    required this.text,
    required this.erstellt,
    this.zeit,
  });

  /// The day of the appointment (time of day ignored).
  final DateTime datum;

  /// E.g. "17:00", or null if the text names no time.
  final String? zeit;

  /// What the user wrote.
  final String text;

  /// When it was written; also tells two appointments apart.
  final DateTime erstellt;

  Map<String, dynamic> toJson() => {
    'datum': datum.toIso8601String(),
    'zeit': zeit,
    'text': text,
    'erstellt': erstellt.toIso8601String(),
  };

  factory Termin.fromJson(Map<String, dynamic> json) => Termin(
    datum: DateTime.parse(json['datum'] as String),
    zeit: json['zeit'] as String?,
    text: json['text'] as String,
    erstellt: DateTime.parse(json['erstellt'] as String),
  );
}

final _uhrPattern = RegExp(
  r'\b([01]?\d|2[0-3])(?:[:.]([0-5]\d))?\s*uhr\b',
  caseSensitive: false,
);
final _colonPattern = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b');
final _morgen = RegExp(r'\bmorgen\b');

const _weekdays = [
  'montag',
  'dienstag',
  'mittwoch',
  'donnerstag',
  'freitag',
  'samstag',
  'sonntag',
];

/// Turns what the user wrote into an appointment. Until the AI is
/// connected this only looks for a time ("17 Uhr", "17:30") and a day
/// ("heute", "morgen", "übermorgen" or a weekday, the next one coming);
/// without a day it is today. The AI will read the text properly later.
Termin parseTermin(String text, DateTime now) {
  final t = text.trim();
  final lower = t.toLowerCase();
  final today = DateTime(now.year, now.month, now.day);

  String? zeit;
  final m = _uhrPattern.firstMatch(t) ?? _colonPattern.firstMatch(t);
  if (m != null) {
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2) ?? '0');
    zeit = '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  var day = today;
  if (lower.contains('übermorgen')) {
    day = today.add(const Duration(days: 2));
  } else if (_morgen.hasMatch(lower)) {
    day = today.add(const Duration(days: 1));
  } else {
    for (var i = 0; i < 7; i++) {
      if (lower.contains(_weekdays[i])) {
        day = today.add(Duration(days: (i + 1 - today.weekday) % 7));
        break;
      }
    }
  }

  return Termin(datum: day, zeit: zeit, text: t, erstellt: now);
}

/// Appointments on [day], with a time first (earliest first), then the
/// ones without a time in the order they were written.
List<Termin> termineAm(List<Termin> all, DateTime day) {
  final key = dayKey(day);
  final list = [
    for (final t in all)
      if (dayKey(t.datum) == key) t,
  ];
  list.sort((a, b) {
    if (a.zeit == null && b.zeit == null) {
      return a.erstellt.compareTo(b.erstellt);
    }
    if (a.zeit == null) return 1;
    if (b.zeit == null) return -1;
    return a.zeit!.compareTo(b.zeit!);
  });
  return list;
}
