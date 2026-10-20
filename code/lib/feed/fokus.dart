import '../checkin/checkin.dart';

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

/// The suggestions waiting for a choice, kept until the user picks one so
/// the coach is not asked again on every start.
class FokusAuswahl {
  const FokusAuswahl({
    required this.vorschlaege,
    this.rueckblick,
    this.geschafft,
  });

  final List<FokusVorschlag> vorschlaege;

  /// The coach's sentence about the week that just ended, if any.
  final String? rueckblick;

  /// Days ticked off in that week, shown as "Letzte Woche 5 von 7."
  final int? geschafft;

  Map<String, Object?> toJson() => {
    'vorschlaege': [for (final v in vorschlaege) v.toJson()],
    'rueckblick': rueckblick,
    'geschafft': geschafft,
  };

  factory FokusAuswahl.fromJson(Map<String, dynamic> json) => FokusAuswahl(
    vorschlaege: [
      for (final v in json['vorschlaege'] as List? ?? const [])
        FokusVorschlag.fromJson(v as Map<String, dynamic>),
    ],
    rueckblick: json['rueckblick'] as String?,
    geschafft: (json['geschafft'] as num?)?.toInt(),
  );
}
