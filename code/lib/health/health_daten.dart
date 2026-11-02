import '../checkin/checkin.dart';

/// What Apple Health measured (vault Umsetzung/Apple Health.md). Groundset
/// only reads; what the user enters always counts first.

enum PhaseArt { wach, rem, kern, tief }

/// One stretch of the night.
class SchlafPhase {
  const SchlafPhase(this.von, this.bis, this.art);

  final DateTime von;
  final DateTime bis;
  final PhaseArt art;

  int get minuten => bis.difference(von).inMinutes;

  Map<String, dynamic> toJson() => {
    'von': von.toIso8601String(),
    'bis': bis.toIso8601String(),
    'art': art.name,
  };

  factory SchlafPhase.fromJson(Map<String, dynamic> j) => SchlafPhase(
    DateTime.parse(j['von'] as String),
    DateTime.parse(j['bis'] as String),
    PhaseArt.values.asNameMap()[j['art']] ?? PhaseArt.kern,
  );
}

/// The measured night: from falling asleep to waking up.
class HealthNacht {
  const HealthNacht(this.phasen);

  /// Sorted by time.
  final List<SchlafPhase> phasen;

  DateTime get start => phasen.first.von;
  DateTime get ende => phasen.last.bis;

  int _min(bool Function(PhaseArt a) welche) =>
      phasen.where((p) => welche(p.art)).fold(0, (s, p) => s + p.minuten);

  /// Hours asleep, without the time awake.
  double get stunden => _min((a) => a != PhaseArt.wach) / 60;
  int get wachMinuten => _min((a) => a == PhaseArt.wach);
  int get tiefMinuten => _min((a) => a == PhaseArt.tief);
  int get remMinuten => _min((a) => a == PhaseArt.rem);

  /// Times awake in between (not before falling asleep or at the end).
  int get wachMal {
    var n = 0;
    for (var i = 1; i < phasen.length - 1; i++) {
      if (phasen[i].art == PhaseArt.wach) n++;
    }
    return n;
  }

  /// Phases known (REM, deep) or only "asleep" (older watches, iPhone).
  bool get mitPhasen =>
      phasen.any((p) => p.art == PhaseArt.rem || p.art == PhaseArt.tief);

  Map<String, dynamic> toJson() => {
    'phasen': [for (final p in phasen) p.toJson()],
  };

  static HealthNacht? fromJson(Map<String, dynamic>? j) {
    final p = [
      for (final x in (j?['phasen'] as List?) ?? const [])
        SchlafPhase.fromJson(x as Map<String, dynamic>),
    ];
    return p.isEmpty ? null : HealthNacht(p);
  }
}

/// A workout the watch recorded.
class UhrTraining {
  const UhrTraining({
    required this.art,
    required this.start,
    required this.minuten,
  });

  /// German name, e.g. "Laufen".
  final String art;
  final DateTime start;
  final int minuten;

  String get id => start.toIso8601String();
  String get text => '$art, $minuten Min.';

  Map<String, dynamic> toJson() => {
    'art': art,
    'start': start.toIso8601String(),
    'minuten': minuten,
  };

  factory UhrTraining.fromJson(Map<String, dynamic> j) => UhrTraining(
    art: j['art'] as String? ?? 'Training',
    start: DateTime.parse(j['start'] as String),
    minuten: (j['minuten'] as num?)?.round() ?? 0,
  );
}

/// Everything measured for one day (the night before belongs to it).
class HealthTag {
  const HealthTag({
    required this.tag,
    this.nacht,
    this.ruhepuls,
    this.ruhepulsSchnitt,
    this.hrv,
    this.hrvSchnitt,
    this.schritte,
    this.tageslicht,
    this.gewicht,
    this.gewichtZeit,
    this.trainings = const [],
  });

  /// dayKey.
  final String tag;
  final HealthNacht? nacht;

  /// Beats per minute, and the average of the last 30 days.
  final int? ruhepuls;
  final int? ruhepulsSchnitt;

  /// Heart rate variability in ms, and its 30-day average.
  final int? hrv;
  final int? hrvSchnitt;
  final int? schritte;

  /// Minutes in daylight today (Apple Watch).
  final int? tageslicht;
  final double? gewicht;
  final DateTime? gewichtZeit;
  final List<UhrTraining> trainings;

  bool get leer =>
      nacht == null &&
      ruhepuls == null &&
      hrv == null &&
      schritte == null &&
      tageslicht == null &&
      gewicht == null &&
      trainings.isEmpty;

  Map<String, dynamic> toJson() => {
    'tag': tag,
    if (nacht != null) 'nacht': nacht!.toJson(),
    'ruhepuls': ?ruhepuls,
    'ruhepuls_schnitt': ?ruhepulsSchnitt,
    'hrv': ?hrv,
    'hrv_schnitt': ?hrvSchnitt,
    'schritte': ?schritte,
    'tageslicht': ?tageslicht,
    'gewicht': ?gewicht,
    if (gewichtZeit != null) 'gewicht_zeit': gewichtZeit!.toIso8601String(),
    'trainings': [for (final t in trainings) t.toJson()],
  };

  factory HealthTag.fromJson(Map<String, dynamic> j) => HealthTag(
    tag: j['tag'] as String,
    nacht: HealthNacht.fromJson(j['nacht'] as Map<String, dynamic>?),
    ruhepuls: (j['ruhepuls'] as num?)?.round(),
    ruhepulsSchnitt: (j['ruhepuls_schnitt'] as num?)?.round(),
    hrv: (j['hrv'] as num?)?.round(),
    hrvSchnitt: (j['hrv_schnitt'] as num?)?.round(),
    schritte: (j['schritte'] as num?)?.round(),
    tageslicht: (j['tageslicht'] as num?)?.round(),
    gewicht: (j['gewicht'] as num?)?.toDouble(),
    gewichtZeit: j['gewicht_zeit'] == null
        ? null
        : DateTime.parse(j['gewicht_zeit'] as String),
    trainings: [
      for (final t in (j['trainings'] as List?) ?? const [])
        UhrTraining.fromJson(t as Map<String, dynamic>),
    ],
  );

  /// From what the iPhone sends (times in milliseconds). Sleep samples
  /// overlap when several sources wrote them: the watch's phases win over a
  /// plain "asleep", and samples "in bed" are left out.
  factory HealthTag.ausHandy(DateTime tag, Map<Object?, Object?> m) {
    DateTime zeit(Object? v) =>
        DateTime.fromMillisecondsSinceEpoch((v as num).round());
    int? ganz(Object? v) => v is num ? v.round() : null;
    final roh = <SchlafPhase>[];
    final nurSchlaf = <SchlafPhase>[];
    for (final s in (m['schlaf'] as List?) ?? const []) {
      final x = s as Map<Object?, Object?>;
      final von = zeit(x['von']);
      final bis = zeit(x['bis']);
      if (!bis.isAfter(von)) continue;
      switch (x['art']) {
        case 'wach':
          roh.add(SchlafPhase(von, bis, PhaseArt.wach));
        case 'rem':
          roh.add(SchlafPhase(von, bis, PhaseArt.rem));
        case 'tief':
          roh.add(SchlafPhase(von, bis, PhaseArt.tief));
        case 'kern':
          roh.add(SchlafPhase(von, bis, PhaseArt.kern));
        case 'schlaf':
          nurSchlaf.add(SchlafPhase(von, bis, PhaseArt.kern));
      }
    }
    final mitPhasen = roh.any((p) => p.art != PhaseArt.wach);
    final phasen = mitPhasen ? roh : [...roh, ...nurSchlaf];
    phasen.sort((a, b) => a.von.compareTo(b.von));
    // Overlaps: a later phase starts where the earlier one ends.
    final sauber = <SchlafPhase>[];
    for (final p in phasen) {
      if (sauber.isNotEmpty && p.von.isBefore(sauber.last.bis)) {
        if (!p.bis.isAfter(sauber.last.bis)) continue;
        sauber.add(SchlafPhase(sauber.last.bis, p.bis, p.art));
      } else {
        sauber.add(p);
      }
    }
    // Leading and trailing "awake" are not part of the night.
    while (sauber.isNotEmpty && sauber.first.art == PhaseArt.wach) {
      sauber.removeAt(0);
    }
    while (sauber.isNotEmpty && sauber.last.art == PhaseArt.wach) {
      sauber.removeLast();
    }
    final g = m['gewicht'] as Map<Object?, Object?>?;
    return HealthTag(
      tag: dayKey(tag),
      nacht: sauber.isEmpty ? null : HealthNacht(sauber),
      ruhepuls: ganz(m['ruhepuls']),
      ruhepulsSchnitt: ganz(m['ruhepuls_schnitt']),
      hrv: ganz(m['hrv']),
      hrvSchnitt: ganz(m['hrv_schnitt']),
      schritte: ganz(m['schritte']),
      tageslicht: ganz(m['tageslicht']),
      gewicht: g == null ? null : (g['kg'] as num).toDouble(),
      gewichtZeit: g == null ? null : zeit(g['zeit']),
      trainings: [
        for (final t in (m['trainings'] as List?) ?? const [])
          if (t case final Map<Object?, Object?> x)
            UhrTraining(
              art: x['art'] as String? ?? 'Training',
              start: zeit(x['start']),
              minuten: ganz(x['minuten']) ?? 0,
            ),
      ],
    );
  }
}
