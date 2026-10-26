import 'dart:math' as math;

import '../checkin/checkin.dart';

/// Training logging (vault Umsetzung/Training eintragen.md, Phillip
/// 2026-10-26): the plan holds exercises with settings, every session is
/// logged set by set, targets and records come from the logs.

/// How an exercise is measured.
enum UebungArt {
  gewicht('Gewicht'),
  koerpergewicht('Körpergewicht'),
  zusatzgewicht('Zusatzgewicht'),
  zeit('Zeit'),
  strecke('Strecke');

  const UebungArt(this.label);
  final String label;

  /// Unit of the first field (weight or distance), null when there is none.
  String? get wertEinheit => switch (this) {
    gewicht => 'kg',
    zusatzgewicht => '+kg',
    strecke => 'km',
    _ => null,
  };

  /// Unit of the second field: repetitions, seconds or minutes.
  String get mengeEinheit => switch (this) {
    zeit => 's',
    strecke => 'min',
    _ => 'Wdh',
  };

  bool get ausdauer => this == zeit || this == strecke;

  static UebungArt byName(String? n) =>
      values.firstWhere((a) => a.name == n, orElse: () => UebungArt.gewicht);
}

/// How the repetitions are set.
enum WdhModus {
  fest('Fest'),
  bereich('Bereich'),
  rir('Bis kurz vor Schluss');

  const WdhModus(this.label);
  final String label;

  static WdhModus byName(String? n) =>
      values.firstWhere((a) => a.name == n, orElse: () => WdhModus.fest);
}

/// How the target goes up from session to session.
enum Steigerung {
  coach('Coach entscheidet'),
  kg('+2,5 kg'),
  wdh('+1 Wdh'),
  selbst('Ich selbst');

  const Steigerung(this.label);
  final String label;

  static Steigerung byName(String? n) =>
      values.firstWhere((a) => a.name == n, orElse: () => Steigerung.coach);
}

/// The sports to pick on the plan (Phillip's draft, 2026-10-26); own ones
/// can be added.
const sportartenAuswahl = [
  'Krafttraining',
  'Laufen',
  'Radfahren',
  'Schwimmen',
  'Kampfsport',
  'Fußball',
  'Yoga',
  'Klettern',
];

/// One target or logged value pair: [wert] is kg (or km), [menge] is
/// repetitions, seconds or minutes, depending on the exercise's art.
class SatzWert {
  const SatzWert(this.wert, this.menge);

  final double? wert;
  final double? menge;

  Map<String, dynamic> toJson() => {'w': wert, 'm': menge};

  factory SatzWert.fromJson(Map<String, dynamic> j) =>
      SatzWert((j['w'] as num?)?.toDouble(), (j['m'] as num?)?.toDouble());

  @override
  bool operator ==(Object other) =>
      other is SatzWert && other.wert == wert && other.menge == menge;

  @override
  int get hashCode => Object.hash(wert, menge);
}

/// One exercise in the plan with all its settings.
class PlanUebung {
  const PlanUebung({
    required this.name,
    this.art = UebungArt.gewicht,
    this.saetze = 3,
    this.modus = WdhModus.fest,
    this.wdhVon = 8,
    this.wdhBis = 8,
    this.wert,
    this.pause = 90,
    this.aufwaermen = 0,
    this.steigerung = Steigerung.coach,
    this.jederSatz = const [],
    this.notiz = '',
  });

  final String name;
  final UebungArt art;
  final int saetze;
  final WdhModus modus;

  /// Repetitions (fest: both the same), seconds for [UebungArt.zeit],
  /// minutes for [UebungArt.strecke] (0 = no time set).
  final int wdhVon;
  final int wdhBis;

  /// Start weight in kg, or km for [UebungArt.strecke].
  final double? wert;

  /// Rest between sets in seconds.
  final int pause;
  final int aufwaermen;
  final Steigerung steigerung;

  /// "Jeder Satz anders": one value pair per set; empty when all sets are
  /// the same.
  final List<SatzWert> jederSatz;
  final String notiz;

  bool get hatWert => art.wertEinheit != null;

  PlanUebung copyWith({
    String? name,
    UebungArt? art,
    int? saetze,
    WdhModus? modus,
    int? wdhVon,
    int? wdhBis,
    double? wert,
    bool wertLeeren = false,
    int? pause,
    int? aufwaermen,
    Steigerung? steigerung,
    List<SatzWert>? jederSatz,
    String? notiz,
  }) => PlanUebung(
    name: name ?? this.name,
    art: art ?? this.art,
    saetze: saetze ?? this.saetze,
    modus: modus ?? this.modus,
    wdhVon: wdhVon ?? this.wdhVon,
    wdhBis: wdhBis ?? this.wdhBis,
    wert: wertLeeren ? null : (wert ?? this.wert),
    pause: pause ?? this.pause,
    aufwaermen: aufwaermen ?? this.aufwaermen,
    steigerung: steigerung ?? this.steigerung,
    jederSatz: jederSatz ?? this.jederSatz,
    notiz: notiz ?? this.notiz,
  );

  /// Short line for lists and the plan text, e.g. "3 × 6–8 · 80 kg".
  String get kurz {
    if (art == UebungArt.strecke) {
      return [
        if (wert != null) '${zahl(wert!)} km',
        if (wdhVon > 0) '$wdhVon min',
      ].join(' · ');
    }
    if (jederSatz.isNotEmpty) {
      return jederSatz.map((s) => satzText(art, s)).join(', ');
    }
    final w = switch (modus) {
      WdhModus.fest => '$wdhVon',
      WdhModus.bereich => '$wdhVon–$wdhBis',
      WdhModus.rir => 'max',
    };
    final menge = art == UebungArt.zeit ? '$wdhVon s' : w;
    final gewicht = switch (art) {
      UebungArt.gewicht => wert == null ? '' : ' · ${zahl(wert!)} kg',
      UebungArt.zusatzgewicht => wert == null ? '' : ' · +${zahl(wert!)} kg',
      UebungArt.koerpergewicht => ' · Körpergewicht',
      _ => '',
    };
    return '$saetze × $menge$gewicht';
  }

  /// The line that goes into the plan text, e.g. "Bankdrücken 3 × 8 · 80 kg".
  String get zeile =>
      kurz.isEmpty ? name : '$name ${kurz.replaceAll(' · ', ' ')}';

  Map<String, dynamic> toJson() => {
    'name': name,
    'art': art.name,
    'saetze': saetze,
    'modus': modus.name,
    'von': wdhVon,
    'bis': wdhBis,
    'wert': wert,
    'pause': pause,
    'aufw': aufwaermen,
    'steig': steigerung.name,
    if (jederSatz.isNotEmpty) 'jeder': [for (final s in jederSatz) s.toJson()],
    if (notiz.isNotEmpty) 'notiz': notiz,
  };

  factory PlanUebung.fromJson(Map<String, dynamic> j) => PlanUebung(
    name: j['name'] as String? ?? '',
    art: UebungArt.byName(j['art'] as String?),
    saetze: (j['saetze'] as num?)?.toInt() ?? 3,
    modus: WdhModus.byName(j['modus'] as String?),
    wdhVon: (j['von'] as num?)?.toInt() ?? 8,
    wdhBis: (j['bis'] as num?)?.toInt() ?? 8,
    wert: (j['wert'] as num?)?.toDouble(),
    pause: (j['pause'] as num?)?.toInt() ?? 90,
    aufwaermen: (j['aufw'] as num?)?.toInt() ?? 0,
    steigerung: Steigerung.byName(j['steig'] as String?),
    jederSatz: [
      for (final s in j['jeder'] as List? ?? const [])
        SatzWert.fromJson(s as Map<String, dynamic>),
    ],
    notiz: j['notiz'] as String? ?? '',
  );

  /// Reads an exercise written in own words, as older plans have them:
  /// "Bankdrücken 5x5 mit 80 kg", "Dips 3x10", "Laufen 5 km locker",
  /// "Plank 3x45s".
  static PlanUebung lesen(String zeile) {
    final t = zeile.trim();
    final sxw = RegExp(
      r'(\d+)\s*[x×]\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*(s|sek|sekunden)?\b',
      caseSensitive: false,
    ).firstMatch(t);
    final kg = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*kg',
      caseSensitive: false,
    ).firstMatch(t);
    final km = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*km',
      caseSensitive: false,
    ).firstMatch(t);
    final cut = [
      sxw?.start,
      kg?.start,
      km?.start,
    ].whereType<int>().fold<int>(t.length, math.min);
    var name = t
        .substring(0, cut)
        .replaceFirst(RegExp(r'\s*(mit|à|a|@)\s*$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'[:,\s]+$'), '')
        .trim();
    if (name.isEmpty) name = t;
    double? zahlAus(Match? m) =>
        m == null ? null : double.tryParse(m.group(1)!.replaceAll(',', '.'));
    if (km != null && sxw == null) {
      final min = RegExp(r'(\d+)\s*min', caseSensitive: false).firstMatch(t);
      return PlanUebung(
        name: name,
        art: UebungArt.strecke,
        saetze: 1,
        wert: zahlAus(km),
        wdhVon: min == null ? 0 : int.parse(min.group(1)!),
        wdhBis: min == null ? 0 : int.parse(min.group(1)!),
        pause: 0,
      );
    }
    if (sxw == null) return PlanUebung(name: name, wert: zahlAus(kg));
    final saetze = int.parse(sxw.group(1)!);
    final von = int.parse(sxw.group(2)!);
    final bis = sxw.group(3) == null ? von : int.parse(sxw.group(3)!);
    if (sxw.group(4) != null) {
      return PlanUebung(
        name: name,
        art: UebungArt.zeit,
        saetze: saetze,
        wdhVon: von,
        wdhBis: von,
      );
    }
    return PlanUebung(
      name: name,
      art: kg == null ? UebungArt.koerpergewicht : UebungArt.gewicht,
      saetze: saetze,
      modus: bis == von ? WdhModus.fest : WdhModus.bereich,
      wdhVon: von,
      wdhBis: bis,
      wert: zahlAus(kg),
    );
  }
}

/// "82,5" for 82.5, "80" for 80.0.
String zahl(double v) {
  final r = (v * 100).round() / 100;
  if (r == r.roundToDouble()) return r.toInt().toString();
  return r.toString().replaceAll('.', ',');
}

/// Seconds as "1:30".
String mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// One value pair as text, e.g. "82,5 kg × 8", "12 Wdh", "5 km in 28 min".
String satzText(UebungArt art, SatzWert s) {
  final w = s.wert, m = s.menge;
  switch (art) {
    case UebungArt.gewicht:
      return '${w == null ? '–' : zahl(w)} kg × ${m == null ? '–' : zahl(m)}';
    case UebungArt.zusatzgewicht:
      return '+${w == null ? '0' : zahl(w)} kg × ${m == null ? '–' : zahl(m)}';
    case UebungArt.koerpergewicht:
      return '${m == null ? '–' : zahl(m)} Wdh';
    case UebungArt.zeit:
      return '${m == null ? '–' : zahl(m)} s';
    case UebungArt.strecke:
      return [
        if (w != null) '${zahl(w)} km',
        if (m != null && m > 0) 'in ${zahl(m)} min',
      ].join(' ');
  }
}

/// One set as logged.
class SatzLog {
  const SatzLog({this.wert, this.menge, this.fertig = false});

  final double? wert;
  final double? menge;
  final bool fertig;

  SatzWert get werte => SatzWert(wert, menge);

  SatzLog copyWith({double? wert, double? menge, bool? fertig}) => SatzLog(
    wert: wert ?? this.wert,
    menge: menge ?? this.menge,
    fertig: fertig ?? this.fertig,
  );

  Map<String, dynamic> toJson() => {'w': wert, 'm': menge, 'f': fertig};

  factory SatzLog.fromJson(Map<String, dynamic> j) => SatzLog(
    wert: (j['w'] as num?)?.toDouble(),
    menge: (j['m'] as num?)?.toDouble(),
    fertig: j['f'] == true,
  );
}

/// One exercise of a session as logged.
class UebungLog {
  const UebungLog({
    required this.name,
    required this.art,
    required this.saetze,
    this.aufwaermen = const [],
    this.gefuehl,
  });

  final String name;
  final UebungArt art;
  final List<SatzLog> saetze;

  /// Ticked warm-up sets (they do not count for records).
  final List<bool> aufwaermen;

  /// "leicht", "passt" or "schwer"; null when not tapped.
  final String? gefuehl;

  List<SatzLog> get fertige => [
    for (final s in saetze)
      if (s.fertig) s,
  ];

  /// The best finished set (for "Letztes Mal" and records).
  SatzWert? get bester {
    SatzWert? best;
    for (final s in fertige) {
      if (best == null || besser(art, s.werte, best)) best = s.werte;
    }
    return best;
  }

  UebungLog copyWith({
    List<SatzLog>? saetze,
    List<bool>? aufwaermen,
    String? gefuehl,
    bool gefuehlLeeren = false,
  }) => UebungLog(
    name: name,
    art: art,
    saetze: saetze ?? this.saetze,
    aufwaermen: aufwaermen ?? this.aufwaermen,
    gefuehl: gefuehlLeeren ? null : (gefuehl ?? this.gefuehl),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'art': art.name,
    'saetze': [for (final s in saetze) s.toJson()],
    if (aufwaermen.isNotEmpty) 'aufw': aufwaermen,
    'gefuehl': gefuehl,
  };

  factory UebungLog.fromJson(Map<String, dynamic> j) => UebungLog(
    name: j['name'] as String? ?? '',
    art: UebungArt.byName(j['art'] as String?),
    saetze: [
      for (final s in j['saetze'] as List? ?? const [])
        SatzLog.fromJson(s as Map<String, dynamic>),
    ],
    aufwaermen: [for (final a in j['aufw'] as List? ?? const []) a == true],
    gefuehl: j['gefuehl'] as String?,
  );
}

/// Whether [a] beats [b] for this kind of exercise.
bool besser(UebungArt art, SatzWert a, SatzWert b) {
  final aw = a.wert ?? 0, bw = b.wert ?? 0;
  final am = a.menge ?? 0, bm = b.menge ?? 0;
  switch (art) {
    case UebungArt.gewicht:
    case UebungArt.zusatzgewicht:
      return aw > bw || (aw == bw && am > bm);
    case UebungArt.koerpergewicht:
    case UebungArt.zeit:
      return am > bm;
    case UebungArt.strecke:
      // Farther, or the same distance faster.
      if (aw != bw) return aw > bw;
      return am > 0 && (bm == 0 || am < bm);
  }
}

enum EinheitStatus { laeuft, fertig, uebersprungen }

/// One training day as logged: running, finished or skipped.
class TrainingEinheit {
  const TrainingEinheit({
    required this.datum,
    required this.name,
    this.status = EinheitStatus.laeuft,
    this.uebungen = const [],
    this.grund,
    this.verschobenAuf,
  });

  final DateTime datum;

  /// The day's name from the plan, e.g. "Push".
  final String name;
  final EinheitStatus status;
  final List<UebungLog> uebungen;

  /// Why it was skipped.
  final String? grund;

  /// Day the skipped session was moved to, null when it is dropped.
  final DateTime? verschobenAuf;

  TrainingEinheit copyWith({
    EinheitStatus? status,
    List<UebungLog>? uebungen,
  }) => TrainingEinheit(
    datum: datum,
    name: name,
    status: status ?? this.status,
    uebungen: uebungen ?? this.uebungen,
    grund: grund,
    verschobenAuf: verschobenAuf,
  );

  Map<String, dynamic> toJson() => {
    'datum': dayKey(datum),
    'name': name,
    'status': status.name,
    'uebungen': [for (final u in uebungen) u.toJson()],
    'grund': grund,
    'verschoben': verschobenAuf == null ? null : dayKey(verschobenAuf!),
  };

  factory TrainingEinheit.fromJson(Map<String, dynamic> j) => TrainingEinheit(
    datum: DateTime.parse(j['datum'] as String),
    name: j['name'] as String? ?? '',
    status: EinheitStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => EinheitStatus.laeuft,
    ),
    uebungen: [
      for (final u in j['uebungen'] as List? ?? const [])
        UebungLog.fromJson(u as Map<String, dynamic>),
    ],
    grund: j['grund'] as String?,
    verschobenAuf: j['verschoben'] == null
        ? null
        : DateTime.parse(j['verschoben'] as String),
  );
}

/// What the coach said about today before training: the "Tagesform" and
/// at most one change for today, which the user can undo.
class Tagesform {
  const Tagesform({
    required this.tag,
    required this.satz,
    this.anpassung,
    this.rueckgaengig = false,
  });

  final String tag;
  final String satz;
  final Anpassung? anpassung;
  final bool rueckgaengig;

  Anpassung? get aktiv => rueckgaengig ? null : anpassung;

  Tagesform zurueck() =>
      Tagesform(tag: tag, satz: satz, anpassung: anpassung, rueckgaengig: true);

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'satz': satz,
    'anpassung': anpassung?.toJson(),
    'zurueck': rueckgaengig,
  };

  factory Tagesform.fromJson(Map<String, dynamic> j) => Tagesform(
    tag: j['tag'] as String,
    satz: j['satz'] as String? ?? '',
    anpassung: j['anpassung'] == null
        ? null
        : Anpassung.fromJson(j['anpassung'] as Map<String, dynamic>),
    rueckgaengig: j['zurueck'] == true,
  );
}

/// The coach's change for today: fewer sets or repetitions for one
/// exercise, with the reason.
class Anpassung {
  const Anpassung({
    required this.uebung,
    this.saetze,
    this.menge,
    required this.grund,
  });

  final String uebung;
  final int? saetze;
  final int? menge;
  final String grund;

  Map<String, dynamic> toJson() => {
    'uebung': uebung,
    'saetze': saetze,
    'menge': menge,
    'grund': grund,
  };

  factory Anpassung.fromJson(Map<String, dynamic> j) => Anpassung(
    uebung: j['uebung'] as String? ?? '',
    saetze: (j['saetze'] as num?)?.toInt(),
    menge: (j['menge'] as num?)?.toInt(),
    grund: j['grund'] as String? ?? '',
  );
}

/// The Stagnations-Check for one exercise: when it was asked, the user's
/// own guess, the coach's view and whether the change was taken.
class StagnationsCheck {
  const StagnationsCheck({
    required this.uebung,
    required this.tag,
    this.grund,
    this.sicht,
    this.vorschlag,
    this.aenderung,
    this.status = 'offen',
    this.vorher,
  });

  final String uebung;
  final String tag;
  final String? grund;
  final String? sicht;
  final String? vorschlag;

  /// The new plan values for the exercise; [zuerst] moves it to the front.
  final ({bool zuerst, PlanUebung uebung})? aenderung;

  /// 'offen', 'uebernommen' or 'gelassen'.
  final String status;

  /// The exercise before the change, for "Rückgängig".
  final PlanUebung? vorher;

  StagnationsCheck copyWith({
    String? grund,
    String? sicht,
    String? vorschlag,
    ({bool zuerst, PlanUebung uebung})? aenderung,
    String? status,
    PlanUebung? vorher,
  }) => StagnationsCheck(
    uebung: uebung,
    tag: tag,
    grund: grund ?? this.grund,
    sicht: sicht ?? this.sicht,
    vorschlag: vorschlag ?? this.vorschlag,
    aenderung: aenderung ?? this.aenderung,
    status: status ?? this.status,
    vorher: vorher ?? this.vorher,
  );

  Map<String, dynamic> toJson() => {
    'uebung': uebung,
    'tag': tag,
    'grund': grund,
    'sicht': sicht,
    'vorschlag': vorschlag,
    if (aenderung != null)
      'aenderung': {
        'zuerst': aenderung!.zuerst,
        'uebung': aenderung!.uebung.toJson(),
      },
    'status': status,
    if (vorher != null) 'vorher': vorher!.toJson(),
  };

  factory StagnationsCheck.fromJson(Map<String, dynamic> j) {
    final a = j['aenderung'] as Map<String, dynamic>?;
    return StagnationsCheck(
      uebung: j['uebung'] as String,
      tag: j['tag'] as String,
      grund: j['grund'] as String?,
      sicht: j['sicht'] as String?,
      vorschlag: j['vorschlag'] as String?,
      aenderung: a == null
          ? null
          : (
              zuerst: a['zuerst'] == true,
              uebung: PlanUebung.fromJson(a['uebung'] as Map<String, dynamic>),
            ),
      status: j['status'] as String? ?? 'offen',
      vorher: j['vorher'] == null
          ? null
          : PlanUebung.fromJson(j['vorher'] as Map<String, dynamic>),
    );
  }
}

/// Everything training-related that is not the plan itself.
class TrainingDaten {
  const TrainingDaten({
    this.sportarten = const [],
    this.einheiten = const [],
    this.vorschlaege = const {},
    this.tagesform,
    this.stagnation = const [],
    this.balance,
    this.verlaufSaetze = const {},
  });

  final List<String> sportarten;

  /// All sessions, oldest first.
  final List<TrainingEinheit> einheiten;

  /// The user's own target for the next session per exercise (idea 6).
  final Map<String, SatzWert> vorschlaege;
  final Tagesform? tagesform;
  final List<StagnationsCheck> stagnation;

  /// The coach's sentence on the week's balance: (Monday key, sentence).
  final ({String woche, String satz})? balance;

  /// Coach sentence per exercise on its history page: name -> (day, text).
  final Map<String, ({String tag, String satz})> verlaufSaetze;

  TrainingDaten copyWith({
    List<String>? sportarten,
    List<TrainingEinheit>? einheiten,
    Map<String, SatzWert>? vorschlaege,
    Tagesform? tagesform,
    List<StagnationsCheck>? stagnation,
    ({String woche, String satz})? balance,
    Map<String, ({String tag, String satz})>? verlaufSaetze,
  }) => TrainingDaten(
    sportarten: sportarten ?? this.sportarten,
    einheiten: einheiten ?? this.einheiten,
    vorschlaege: vorschlaege ?? this.vorschlaege,
    tagesform: tagesform ?? this.tagesform,
    stagnation: stagnation ?? this.stagnation,
    balance: balance ?? this.balance,
    verlaufSaetze: verlaufSaetze ?? this.verlaufSaetze,
  );

  /// The session logged on [day], if any.
  TrainingEinheit? einheitAm(DateTime day) {
    final k = dayKey(day);
    for (final e in einheiten.reversed) {
      if (dayKey(e.datum) == k) return e;
    }
    return null;
  }

  /// Replaces (or adds) the session of the same day.
  TrainingDaten mitEinheit(TrainingEinheit e) => copyWith(
    einheiten: [
      for (final x in einheiten)
        if (dayKey(x.datum) != dayKey(e.datum)) x,
      e,
    ]..sort((a, b) => a.datum.compareTo(b.datum)),
  );

  TrainingDaten ohneEinheit(DateTime day) => copyWith(
    einheiten: [
      for (final x in einheiten)
        if (dayKey(x.datum) != dayKey(day)) x,
    ],
  );

  /// Finished logs of [uebung] before [vor], oldest first, with their day.
  List<(DateTime, UebungLog)> verlauf(String uebung, {DateTime? vor}) => [
    for (final e in einheiten)
      if (e.status == EinheitStatus.fertig &&
          (vor == null || dayKey(e.datum).compareTo(dayKey(vor)) < 0))
        for (final u in e.uebungen)
          if (_gleich(u.name, uebung) && u.fertige.isNotEmpty) (e.datum, u),
  ];

  /// Every exercise name that was ever logged, newest first.
  List<String> get geloggteUebungen {
    final seen = <String>{};
    final out = <String>[];
    for (final e in einheiten.reversed) {
      for (final u in e.uebungen) {
        if (u.fertige.isNotEmpty && seen.add(u.name.toLowerCase())) {
          out.add(u.name);
        }
      }
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
    'sportarten': sportarten,
    'einheiten': [for (final e in einheiten) e.toJson()],
    'vorschlaege': {
      for (final e in vorschlaege.entries) e.key: e.value.toJson(),
    },
    if (tagesform != null) 'tagesform': tagesform!.toJson(),
    'stagnation': [for (final s in stagnation) s.toJson()],
    if (balance != null)
      'balance': {'woche': balance!.woche, 'satz': balance!.satz},
    'verlauf': {
      for (final e in verlaufSaetze.entries)
        e.key: {'tag': e.value.tag, 'satz': e.value.satz},
    },
  };

  factory TrainingDaten.fromJson(Map<String, dynamic> j) {
    final b = j['balance'] as Map<String, dynamic>?;
    return TrainingDaten(
      sportarten: [for (final s in j['sportarten'] as List? ?? const []) '$s'],
      einheiten: [
        for (final e in j['einheiten'] as List? ?? const [])
          TrainingEinheit.fromJson(e as Map<String, dynamic>),
      ],
      vorschlaege: {
        for (final e
            in (j['vorschlaege'] as Map<String, dynamic>? ?? const {}).entries)
          e.key: SatzWert.fromJson(e.value as Map<String, dynamic>),
      },
      tagesform: j['tagesform'] == null
          ? null
          : Tagesform.fromJson(j['tagesform'] as Map<String, dynamic>),
      stagnation: [
        for (final s in j['stagnation'] as List? ?? const [])
          StagnationsCheck.fromJson(s as Map<String, dynamic>),
      ],
      balance: b == null
          ? null
          : (woche: b['woche'] as String, satz: b['satz'] as String),
      verlaufSaetze: {
        for (final e
            in (j['verlauf'] as Map<String, dynamic>? ?? const {}).entries)
          e.key: (
            tag: (e.value as Map)['tag'] as String,
            satz: (e.value as Map)['satz'] as String,
          ),
      },
    );
  }
}

bool _gleich(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

/// "Letztes Mal" and "Ziel heute" for one exercise.
class UebungZiel {
  const UebungZiel({
    required this.saetze,
    this.letztes,
    this.bestes,
    this.angepasst,
  });

  /// One target per working set, already adjusted for today.
  final List<SatzWert> saetze;

  /// Best set of the last session.
  final SatzWert? letztes;

  /// Best set ever before today.
  final SatzWert? bestes;

  /// The coach's reason when today was changed.
  final String? angepasst;
}

const _schritt = 2.5;

/// Today's targets for [u] (idea 1): from the plan, the last session and
/// the chosen way of increasing, or the user's own suggestion (idea 6).
UebungZiel zielFuer(
  PlanUebung u,
  TrainingDaten d,
  DateTime heute, {
  Anpassung? anpassung,
}) {
  final hist = d.verlauf(u.name, vor: heute);
  final last = hist.isEmpty ? null : hist.last.$2;
  SatzWert? best;
  for (final (_, l) in hist) {
    final b = l.bester;
    if (b != null && (best == null || besser(u.art, b, best))) best = b;
  }
  final basis = <SatzWert>[
    if (u.jederSatz.isNotEmpty)
      ...u.jederSatz
    else
      for (var i = 0; i < u.saetze; i++)
        SatzWert(
          u.hatWert ? u.wert : null,
          u.art == UebungArt.strecke
              ? (u.wdhVon > 0 ? u.wdhVon.toDouble() : null)
              : u.wdhVon.toDouble(),
        ),
  ];
  var ziele = basis;
  final eigener = d.vorschlaege[u.name.toLowerCase()];
  if (eigener != null && last != null) {
    ziele = [
      for (final b in basis) SatzWert(eigener.wert ?? b.wert, eigener.menge),
    ];
  } else if (last != null && u.jederSatz.isEmpty) {
    final top = last.bester!;
    final alleGeschafft =
        last.fertige.length >= u.saetze &&
        last.fertige.every(
          (s) => (s.menge ?? 0) >= (top.menge ?? 0) || u.modus == WdhModus.rir,
        );
    final schwer = last.gefuehl == 'schwer';
    double? w = top.wert ?? (u.hatWert ? u.wert : null);
    double? m = top.menge;
    final minMenge = last.fertige
        .map((s) => s.menge ?? 0)
        .fold<double>(double.infinity, math.min);
    switch (u.steigerung) {
      case Steigerung.selbst:
        break;
      case Steigerung.kg:
        if (alleGeschafft && !schwer && u.hatWert) w = (w ?? 0) + _schritt;
      case Steigerung.wdh:
        if (alleGeschafft && !schwer && m != null) m = m + 1;
      case Steigerung.coach:
        if (schwer || u.art == UebungArt.strecke) break;
        if (u.art == UebungArt.zeit) {
          if (alleGeschafft) m = (m ?? 0) + 5;
        } else if (u.art == UebungArt.koerpergewicht) {
          if (alleGeschafft) m = (m ?? 0) + 1;
        } else if (u.modus == WdhModus.bereich) {
          if (minMenge >= u.wdhBis) {
            w = (w ?? 0) + _schritt;
            m = u.wdhVon.toDouble();
          } else {
            m = math.min(minMenge + 1, u.wdhBis.toDouble());
          }
        } else if (u.modus == WdhModus.fest) {
          if (minMenge >= u.wdhVon) {
            w = (w ?? 0) + _schritt;
            m = u.wdhVon.toDouble();
          }
        }
    }
    ziele = [for (var i = 0; i < u.saetze; i++) SatzWert(w, m)];
  }
  String? grund;
  if (anpassung != null && _gleich(anpassung.uebung, u.name)) {
    grund = anpassung.grund;
    if (anpassung.saetze != null && anpassung.saetze! < ziele.length) {
      ziele = ziele.take(math.max(1, anpassung.saetze!)).toList();
    }
    if (anpassung.menge != null) {
      ziele = [
        for (final z in ziele) SatzWert(z.wert, anpassung.menge!.toDouble()),
      ];
    }
  }
  return UebungZiel(
    saetze: ziele,
    letztes: last?.bester,
    bestes: best,
    angepasst: grund,
  );
}

/// Warm-up sets: about 60 % of the first target, 8 repetitions.
List<SatzWert> aufwaermSaetze(PlanUebung u, UebungZiel z) {
  if (u.aufwaermen == 0 || !u.hatWert || z.saetze.isEmpty) return const [];
  final ziel = z.saetze.first.wert ?? u.wert ?? 0;
  return [
    for (var i = 0; i < u.aufwaermen; i++)
      SatzWert(
        ((ziel * (0.5 + 0.15 * i)) / _schritt).round() * _schritt,
        (8 - 2 * i).clamp(3, 8).toDouble(),
      ),
  ];
}

/// The records of one exercise (idea 2).
class Rekorde {
  const Rekorde({this.bester, this.meisteWdh, this.geschaetzt, this.weitest});

  /// Heaviest (or longest, farthest) set.
  final SatzWert? bester;

  /// Most repetitions in one set.
  final SatzWert? meisteWdh;

  /// Estimated one-repetition maximum in kg (weights only).
  final double? geschaetzt;

  /// For distances: the fastest pace in minutes per km.
  final double? weitest;
}

Rekorde rekorde(UebungArt art, List<UebungLog> logs) {
  SatzWert? best, reps;
  double? e1rm, tempo;
  for (final l in logs) {
    for (final s in l.fertige) {
      final v = s.werte;
      if (best == null || besser(art, v, best)) best = v;
      if ((v.menge ?? 0) > (reps?.menge ?? -1)) reps = v;
      if ((art == UebungArt.gewicht) &&
          v.wert != null &&
          v.menge != null &&
          v.menge! > 0 &&
          v.menge! <= 12) {
        final e = v.wert! * (1 + v.menge! / 30);
        if (e1rm == null || e > e1rm) e1rm = e;
      }
      if (art == UebungArt.strecke && (v.wert ?? 0) > 0 && (v.menge ?? 0) > 0) {
        final t = v.menge! / v.wert!;
        if (tempo == null || t < tempo) tempo = t;
      }
    }
  }
  return Rekorde(
    bester: best,
    meisteWdh: reps,
    geschaetzt: e1rm,
    weitest: tempo,
  );
}

/// The new records of a finished session: exercise name -> best set, for
/// every exercise that beat its best before (not on the first session).
Map<String, SatzWert> neueRekorde(TrainingDaten d, TrainingEinheit e) {
  final out = <String, SatzWert>{};
  for (final u in e.uebungen) {
    final heute = u.bester;
    if (heute == null) continue;
    final vorher = d.verlauf(u.name, vor: e.datum);
    if (vorher.isEmpty) continue;
    final alt = rekorde(u.art, [for (final (_, l) in vorher) l]).bester;
    if (alt == null || besser(u.art, heute, alt)) out[u.name] = heute;
  }
  return out;
}

/// A comparable number for progress, higher is better.
double fortschrittsWert(UebungArt art, SatzWert s) {
  final w = s.wert ?? 0, m = s.menge ?? 0;
  return switch (art) {
    UebungArt.gewicht || UebungArt.zusatzgewicht => w * (1 + m / 30),
    UebungArt.koerpergewicht || UebungArt.zeit => m,
    UebungArt.strecke => m > 0 && w > 0 ? w * 100 - m / w : w * 100,
  };
}

/// Idea 7: the exercise has not moved for 3 weeks, at least 3 sessions in
/// that time and none better than the first of them.
bool stagniert(TrainingDaten d, String uebung, DateTime heute) {
  final h = d.verlauf(uebung);
  if (h.length < 3) return false;
  final art = h.last.$2.art;
  final seit = DateTime(heute.year, heute.month, heute.day - 21);
  final drin = [
    for (final x in h)
      if (!x.$1.isBefore(seit)) x,
  ];
  // The first log of the window must be at least 2 weeks old.
  if (drin.length < 3 || heute.difference(drin.first.$1).inDays < 14) {
    return false;
  }
  final start = fortschrittsWert(art, drin.first.$2.bester!);
  return drin
      .skip(1)
      .every((x) => fortschrittsWert(art, x.$2.bester!) <= start + 0.01);
}

/// The first exercise that needs a Stagnations-Check now: stuck and not
/// asked about in the last 3 weeks.
String? stagnationFaellig(
  TrainingDaten d,
  Iterable<String> uebungen,
  DateTime heute,
) {
  for (final u in uebungen) {
    final frueher = d.stagnation.where((s) => _gleich(s.uebung, u));
    final zuletzt = frueher.isEmpty ? null : DateTime.parse(frueher.last.tag);
    if (zuletzt != null && heute.difference(zuletzt).inDays < 21) continue;
    if (stagniert(d, u, heute)) return u;
  }
  return null;
}

/// Mo..So of the week of [day].
DateTime montagVon(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - 1));

const wochentage = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

final _ruhe = RegExp(r'^(ruhe|pause|frei|off\b)', caseSensitive: false);

/// Whether a plan day is a training day.
bool istTrainingstag(String tag) {
  final t = tag.trim();
  return t.isNotEmpty && !_ruhe.hasMatch(t);
}

/// Where a skipped session goes (idea 3): the next free day of the same
/// week after today that has not got a moved session yet; null when it is
/// dropped (ill, or no free day left).
DateTime? verschiebeZiel(
  List<String> tage,
  TrainingDaten d,
  DateTime heute,
  String grund,
) {
  if (grund == 'Krank') return null;
  final belegt = {
    for (final e in d.einheiten)
      if (e.verschobenAuf != null) dayKey(e.verschobenAuf!),
  };
  for (var i = heute.weekday; i < 7; i++) {
    final tag = DateTime(
      heute.year,
      heute.month,
      heute.day + i - heute.weekday + 1,
    );
    if (!istTrainingstag(tage[i]) && !belegt.contains(dayKey(tag))) return tag;
  }
  return null;
}

/// What the coach says after a skip, kept short and in its style.
String verschiebeText(String name, String grund, DateTime? ziel) {
  if (grund == 'Krank') {
    return 'Gute Besserung. $name fällt diese Woche aus, nächstes Mal geht '
        'es mit den gleichen Zielen weiter. Bei Fieber nicht trainieren, und '
        'wenn es nicht besser wird: geh zum Arzt.';
  }
  if (ziel == null) {
    return 'Diese Woche ist kein Tag mehr frei, also fällt $name aus. '
        'Nächstes Mal geht es mit den gleichen Zielen weiter.';
  }
  final tag = wochentage[ziel.weekday - 1];
  final vorne = switch (grund) {
    'Müde' => 'Verständlich, mit Kraft im Tank trainierst du besser. ',
    'Keine Zeit' || 'Termin' => '',
    _ => '',
  };
  return '$vorne$name rutscht auf $tag. Deine Ziele bleiben gleich.';
}

/// Kraft or Ausdauer for the balance (idea 8).
({bool kraft, bool ausdauer}) artDesTages(String text, List<PlanUebung> u) {
  final name = text.split('\n').first.toLowerCase();
  final ausdauerWort = RegExp(r'lauf|rad|schwimm|rudern|cardio|ausdauer|bike');
  final a =
      u.any((x) => x.art.ausdauer) ||
      (u.isEmpty && ausdauerWort.hasMatch(name));
  final k =
      u.any((x) => !x.art.ausdauer) ||
      (u.isEmpty && !ausdauerWort.hasMatch(name));
  return (kraft: k, ausdauer: a);
}
