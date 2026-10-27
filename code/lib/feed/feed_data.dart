import '../training/training_data.dart';

/// The four areas of the app. Each has its own page in the Main Feed.
enum Bereich {
  training('Training'),
  ernaehrung('Ernährung'),
  schlaf('Schlaf & Energie'),
  mindset('Mindset');

  const Bereich(this.label);

  final String label;
}

/// The user's own training plan, one entry per weekday (Monday first).
/// [tage] holds each day as text: the name (with time) on the first line,
/// the exercises below, e.g. "Push 17:30\nBankdrücken 3 × 8 80 kg". Since
/// 2026-10-26 the exercises are also kept with all their settings in
/// [uebungen] (vault Umsetzung/Training eintragen.md). An empty day is a
/// day off.
class TrainingPlan {
  TrainingPlan(List<String> tage, {List<List<PlanUebung>>? uebungen})
    : assert(tage.length == 7),
      tage = List.unmodifiable(tage),
      _uebungen = uebungen == null
          ? null
          : List<List<PlanUebung>>.unmodifiable([
              for (final u in uebungen) List<PlanUebung>.unmodifiable(u),
            ]);

  TrainingPlan.empty() : this(List.filled(7, ''));

  /// A plan from day names and exercises with settings; the text of each
  /// day is written from them.
  factory TrainingPlan.aus(
    List<String> namen,
    List<List<PlanUebung>> uebungen,
  ) => TrainingPlan([
    for (var i = 0; i < 7; i++)
      joinDay(namen[i], [for (final u in uebungen[i]) u.zeile].join('\n')),
  ], uebungen: uebungen);

  final List<String> tage;
  final List<List<PlanUebung>>? _uebungen;

  bool get isEmpty => tage.every((t) => t.trim().isEmpty);

  /// The plan for [day] (any time on that day).
  String forDay(DateTime day) => tage[day.weekday - 1];

  /// The exercises of weekday [i] (0 = Monday) with their settings. Older
  /// plans in own words are read line by line.
  List<PlanUebung> uebungenAm(int i) {
    final u = _uebungen;
    if (u != null) return u[i];
    return [
      for (final l in dayDetails(tage[i]).split('\n'))
        if (l.trim().isNotEmpty) PlanUebung.lesen(l),
    ];
  }

  /// The same plan with day [i] replaced (name and exercises).
  TrainingPlan mitTag(int i, String text, List<PlanUebung> uebungen) =>
      TrainingPlan(
        [for (var k = 0; k < 7; k++) k == i ? text : tage[k]],
        uebungen: [
          for (var k = 0; k < 7; k++) k == i ? uebungen : uebungenAm(k),
        ],
      );

  /// Changes every exercise called [name] on all days; [zuerst] moves it
  /// to the front of its day.
  TrainingPlan mitUebung(String name, PlanUebung neu, {bool zuerst = false}) {
    final namen = [for (final t in tage) dayName(t)];
    final alle = [
      for (var k = 0; k < 7; k++)
        () {
          final list = [
            for (final u in uebungenAm(k))
              u.name.trim().toLowerCase() == name.trim().toLowerCase()
                  ? neu
                  : u,
          ];
          if (zuerst) {
            final i = list.indexWhere((u) => identical(u, neu));
            if (i > 0) list.insert(0, list.removeAt(i));
          }
          return list;
        }(),
    ];
    return TrainingPlan.aus(namen, alle);
  }

  Object toJson() => _uebungen == null
      ? tage
      : {
          'tage': tage,
          'uebungen': [
            for (final d in _uebungen) [for (final u in d) u.toJson()],
          ],
        };

  factory TrainingPlan.fromJson(Object json) {
    if (json is List) return TrainingPlan([for (final t in json) t as String]);
    final m = json as Map<String, dynamic>;
    return TrainingPlan(
      [for (final t in m['tage'] as List) t as String],
      uebungen: [
        for (final d in m['uebungen'] as List)
          [
            for (final u in d as List)
              PlanUebung.fromJson(u as Map<String, dynamic>),
          ],
      ],
    );
  }
}

/// What the user puts first when the AI swaps or progresses sessions.
/// Since 2026-10-26: Kraft, Muskelaufbau, Ausdauer, Hybrid.
enum Schwerpunkt {
  kraft('Kraft'),
  muskelaufbau('Muskelaufbau'),
  ausdauer('Ausdauer'),
  hybrid('Hybrid');

  const Schwerpunkt(this.label);

  final String label;

  /// Also reads the names used before 2026-10-26.
  static Schwerpunkt? lesen(String? name) => switch (name) {
    'calisthenics' => kraft,
    'ausgeglichen' => hybrid,
    _ => values.where((s) => s.name == name).firstOrNull,
  };
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
