import '../checkin/checkin.dart';
import 'feed_data.dart';

/// "Fokus der Woche" (see vault Umsetzung/Fokus der Woche.md): one thing
/// for 7 days from the day it was chosen, ticked off on "Heute".
class Wochenfokus {
  const Wochenfokus({
    required this.start,
    required this.text,
    this.geschafft = const {},
  });

  /// Day 1 of the 7.
  final DateTime start;
  final String text;

  /// Day keys (see [dayKey]) the user tapped "Heute geschafft".
  final Set<String> geschafft;

  static const tage = 7;

  /// 1..7 while running, more than 7 once the week is over.
  int tag(DateTime today) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(today.year, today.month, today.day);
    // Rounded so a clock change does not shift the day.
    return (b.difference(a).inHours / 24).round() + 1;
  }

  bool vorbei(DateTime today) => tag(today) > tage;

  /// The key of day [i] (1..7).
  String tagKey(int i) =>
      dayKey(DateTime(start.year, start.month, start.day + i - 1));

  /// Which of the 7 days are ticked off.
  List<bool> get striche => [
    for (var i = 1; i <= tage; i++) geschafft.contains(tagKey(i)),
  ];

  int get anzahlGeschafft => striche.where((x) => x).length;

  bool heuteGeschafft(DateTime today) => geschafft.contains(dayKey(today));

  /// Ticks today off, or takes it back.
  Wochenfokus umschalten(DateTime today) {
    final key = dayKey(today);
    final neu = {...geschafft};
    neu.contains(key) ? neu.remove(key) : neu.add(key);
    return Wochenfokus(start: start, text: text, geschafft: neu);
  }

  Map<String, Object> toJson() => {
    'start': start.toIso8601String(),
    'text': text,
    'geschafft': geschafft.toList()..sort(),
  };

  factory Wochenfokus.fromJson(Map<String, dynamic> json) => Wochenfokus(
    start: DateTime.parse(json['start'] as String),
    text: json['text'] as String? ?? '',
    geschafft: {for (final k in json['geschafft'] as List? ?? const []) '$k'},
  );
}

/// One of the coach's three suggestions.
class FokusVorschlag {
  const FokusVorschlag({
    required this.text,
    this.warum = '',
    this.behalten = false,
  });

  final String text;
  final String warum;

  /// The old focus, offered to keep.
  final bool behalten;

  Map<String, Object> toJson() => {
    'text': text,
    'warum': warum,
    'behalten': behalten,
  };

  factory FokusVorschlag.fromJson(Map<String, dynamic> json) => FokusVorschlag(
    text: json['text'] as String? ?? '',
    warum: json['warum'] as String? ?? '',
    behalten: json['behalten'] == true,
  );
}

/// Planned vs. done training days in the week of a focus, for the
/// Reality Check (see vault Umsetzung/Reality Check.md).
class TrainingWoche {
  const TrainingWoche({required this.geplant, required this.gemacht});

  /// Days in the plan that are not empty or a rest day. 0 without a plan.
  final int geplant;

  /// Days whose check-in says trained ("Gut trainiert", "Lief zäh").
  final int gemacht;

  static final _ruhe = RegExp(
    r'^\s*(ruhe|pause|frei|off\b)',
    caseSensitive: false,
  );

  /// Counts the 7 days of [fokus] (from its start day).
  factory TrainingWoche.aus(
    Wochenfokus fokus,
    TrainingPlan plan,
    List<CheckIn> checkIns,
  ) {
    final keys = {for (var i = 1; i <= Wochenfokus.tage; i++) fokus.tagKey(i)};
    var geplant = 0;
    for (var i = 0; i < Wochenfokus.tage; i++) {
      final s = fokus.start;
      final t = plan.forDay(DateTime(s.year, s.month, s.day + i)).trim();
      if (t.isNotEmpty && !_ruhe.hasMatch(t)) geplant++;
    }
    final gemacht = {
      for (final c in checkIns)
        if (keys.contains(dayKey(c.datum)) &&
            c.training.isNotEmpty &&
            !c.training.startsWith('Pause'))
          dayKey(c.datum),
    }.length;
    return TrainingWoche(geplant: geplant, gemacht: gemacht);
  }
}

/// The suggestions waiting for a choice, kept until the user picks one so
/// the coach is not asked again on every start. After a focus week it also
/// holds that week's Reality Check.
class FokusAuswahl {
  const FokusAuswahl({
    required this.vorschlaege,
    this.rueckblick,
    this.geschafft,
    this.fokusText,
    this.start,
    this.bremse,
    this.training,
  });

  /// After a week the first one is "die eine Veränderung".
  final List<FokusVorschlag> vorschlaege;

  /// The coach's sentence about the week that just ended, if any.
  final String? rueckblick;

  /// Days ticked off in that week, shown as "Letzte Woche 5 von 7."
  final int? geschafft;

  /// The focus of the week that ended and its first day.
  final String? fokusText;
  final DateTime? start;

  /// "Was dich ausgebremst hat", from the coach.
  final String? bremse;

  final TrainingWoche? training;

  /// A week just ended: Heute shows the small Reality Check field.
  bool get istRealityCheck => geschafft != null;

  Map<String, Object?> toJson() => {
    'vorschlaege': [for (final v in vorschlaege) v.toJson()],
    'rueckblick': rueckblick,
    'geschafft': geschafft,
    'fokusText': fokusText,
    'start': start?.toIso8601String(),
    'bremse': bremse,
    if (training != null)
      'training': {'geplant': training!.geplant, 'gemacht': training!.gemacht},
  };

  factory FokusAuswahl.fromJson(Map<String, dynamic> json) {
    final t = json['training'];
    return FokusAuswahl(
      vorschlaege: [
        for (final v in json['vorschlaege'] as List? ?? const [])
          FokusVorschlag.fromJson(v as Map<String, dynamic>),
      ],
      rueckblick: json['rueckblick'] as String?,
      geschafft: (json['geschafft'] as num?)?.toInt(),
      fokusText: json['fokusText'] as String?,
      start: json['start'] == null
          ? null
          : DateTime.tryParse(json['start'] as String),
      bremse: json['bremse'] as String?,
      training: t is Map
          ? TrainingWoche(
              geplant: (t['geplant'] as num? ?? 0).toInt(),
              gemacht: (t['gemacht'] as num? ?? 0).toInt(),
            )
          : null,
    );
  }
}
