/// The four areas of the app. Each has its own page in the Main Feed.
enum Bereich {
  training('Training'),
  ernaehrung('Ernährung'),
  schlaf('Schlaf'),
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

/// Short label for the week overview, e.g. "Oberkörper" from
/// "Oberkörper: Bankdrücken 3x8". Empty days are "frei".
String shortDay(String text) {
  final t = text.trim();
  if (t.isEmpty) return 'frei';
  return t.split(RegExp(r'[:,.\n]')).first.trim();
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
