/// The four areas of the app. Each has its own page in the Main Feed.
enum Bereich {
  training('Training'),
  ernaehrung('Ernährung'),
  schlaf('Schlaf & Energie'),
  mindset('Mindset');

  const Bereich(this.label);

  final String label;
}

/// The user's own training plan, one free-text entry per weekday
/// (Monday first). Any sport works, e.g. "Oberkörper: Bankdrücken 3x8"
/// or "Laufen 5 km". An empty day is a day off.
class TrainingPlan {
  TrainingPlan(List<String> tage)
    : assert(tage.length == 7),
      tage = List.unmodifiable(tage);

  TrainingPlan.empty() : this(List.filled(7, ''));

  final List<String> tage;

  bool get isEmpty => tage.every((t) => t.trim().isEmpty);

  /// The plan for [day] (any time on that day).
  String forDay(DateTime day) => tage[day.weekday - 1];

  List<String> toJson() => tage;

  factory TrainingPlan.fromJson(List<dynamic> json) =>
      TrainingPlan([for (final t in json) t as String]);
}

/// What the user puts first when the AI swaps or progresses sessions.
enum Schwerpunkt {
  kraft('Kraft'),
  calisthenics('Calisthenics'),
  ausdauer('Ausdauer'),
  ausgeglichen('Ausgeglichen');

  const Schwerpunkt(this.label);

  final String label;
}

/// A plan day is stored as "Name" on the first line and the exercises
/// below, e.g. "Push + Laufen\nBankdrücken 5x5\nLaufen 5 km".
/// Older plans are a single line like "Oberkörper: Bankdrücken 3x8".
String joinDay(String name, String uebungen) {
  final n = name.trim();
  final u = uebungen.trim();
  if (n.isEmpty) return u;
  if (u.isEmpty) return n;
  return '$n\n$u';
}

/// Short label for the week overview, e.g. "Push + Laufen", or
/// "Oberkörper" from "Oberkörper: Bankdrücken 3x8". Empty days are "frei".
String shortDay(String text) {
  final t = text.trim();
  if (t.isEmpty) return 'frei';
  if (t.contains('\n')) return _ohneZeit(t.split('\n').first);
  return _ohneZeit(t).split(RegExp(r'[:,.]')).first.trim();
}

/// A training time written in the day's name, e.g. "Push 17:30",
/// "Push um 17 Uhr" (see Umsetzung/Tages-Planer.md, 2026-10-25).
final _zeitImNamen = RegExp(
  r'\s*(?:um\s+)?\b([01]?\d|2[0-3])(?:[:.]([0-5]\d))(?:\s*Uhr)?\b'
  r'|\s*(?:um\s+)?\b([01]?\d|2[0-3])\s*Uhr\b',
);

String _ohneZeit(String name) {
  final n = name.replaceFirst(_zeitImNamen, '').trim();
  return n.isEmpty ? name.trim() : n;
}

/// The day's name as typed, with its time, e.g. "Push 17:30" (for the
/// plan editor).
String dayName(String text) {
  final t = text.trim();
  if (t.isEmpty) return '';
  if (t.contains('\n')) return t.split('\n').first.trim();
  final z = _zeitImNamen.firstMatch(t);
  final name = shortDay(t);
  return z == null ? name : '$name ${z.group(0)!.trim()}';
}

/// Minutes after midnight of the training time in the day's name, or null.
int? trainingZeit(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final m = _zeitImNamen.firstMatch(t.split('\n').first);
  if (m == null) return null;
  final h = int.parse(m.group(1) ?? m.group(3)!);
  return h * 60 + int.parse(m.group(2) ?? '0');
}

/// The exercises of a plan day without its name; empty if there are none.
String dayDetails(String text) {
  final roh = text.trim();
  if (roh.contains('\n')) return roh.substring(roh.indexOf('\n') + 1).trim();
  final t = _ohneZeit(roh);
  final name = shortDay(t);
  if (name == t || name == 'frei') return '';
  return t
      .substring(t.indexOf(name) + name.length)
      .replaceFirst(RegExp(r'^[:,.\s]+'), '');
}

/// One step of the evening routine, e.g. 22:15 "Handy weg".
class RoutineStep {
  const RoutineStep(this.zeit, this.was);

  final String zeit;
  final String was;

  Map<String, dynamic> toJson() => {'zeit': zeit, 'was': was};

  factory RoutineStep.fromJson(Map<String, dynamic> json) =>
      RoutineStep(json['zeit'] as String, json['was'] as String);
}

/// Something the user wrote into a field of the Main Feed, together with
/// the coach's answer (empty until the AI is connected).
class CoachFrage {
  const CoachFrage({
    required this.datum,
    required this.bereich,
    required this.text,
    this.antwort = '',
  });

  final DateTime datum;
  final Bereich bereich;
  final String text;
  final String antwort;

  Map<String, dynamic> toJson() => {
    'datum': datum.toIso8601String(),
    'bereich': bereich.name,
    'text': text,
    'antwort': antwort,
  };

  factory CoachFrage.fromJson(Map<String, dynamic> json) => CoachFrage(
    datum: DateTime.parse(json['datum'] as String),
    bereich: Bereich.values.byName(json['bereich'] as String),
    text: json['text'] as String,
    antwort: json['antwort'] as String? ?? '',
  );
}
