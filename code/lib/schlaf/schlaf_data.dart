import '../checkin/checkin.dart';

/// Everything the Schlaf & Energie page keeps (vault Umsetzung/Schlaf und
/// Energie komplett.md, Phillip 2026-10-27). Stored on the device.

List<String> _strings(Object? v) => [
  for (final x in v as List? ?? const []) '$x',
];

/// The morning entry: how the user woke up and the sleep score from it.
class Morgen {
  const Morgen({
    required this.tag,
    required this.himmel,
    this.tags = const [],
    required this.stunden,
    required this.wert,
    this.teile = const {},
    this.satz,
  });

  /// Day of waking up (dayKey).
  final String tag;

  /// The Aufwach-Himmel slider: 0 fog .. 100 sunrise.
  final int himmel;
  final List<String> tags;
  final double stunden;

  /// Sleep score 1..100.
  final int wert;

  /// laenge, erholung, durchschlafen, rhythmus: 0..100 each.
  final Map<String, int> teile;

  /// The coach's line for today after this night.
  final String? satz;

  Morgen copyWith({String? satz}) => Morgen(
    tag: tag,
    himmel: himmel,
    tags: tags,
    stunden: stunden,
    wert: wert,
    teile: teile,
    satz: satz ?? this.satz,
  );

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'himmel': himmel,
    'tags': tags,
    'stunden': stunden,
    'wert': wert,
    'teile': teile,
    if (satz != null) 'satz': satz,
  };

  factory Morgen.fromJson(Map<String, dynamic> j) => Morgen(
    tag: j['tag'] as String,
    himmel: (j['himmel'] as num?)?.toInt() ?? 50,
    tags: _strings(j['tags']),
    stunden: (j['stunden'] as num?)?.toDouble() ?? 0,
    wert: (j['wert'] as num?)?.toInt() ?? 0,
    teile: {
      for (final e in ((j['teile'] as Map?) ?? const {}).entries)
        '${e.key}': (e.value as num).toInt(),
    },
    satz: j['satz'] as String?,
  );
}

/// The evening journal: 3 things grateful for, 3 to do better tomorrow,
/// and when the user said "Gute Nacht".
class Journal {
  const Journal({
    required this.tag,
    required this.dankbar,
    required this.besser,
    this.guteNacht,
  });

  final String tag;
  final List<String> dankbar;
  final List<String> besser;
  final DateTime? guteNacht;

  bool get fertig =>
      dankbar.length == 3 &&
      besser.length == 3 &&
      [...dankbar, ...besser].every((x) => x.trim().isNotEmpty);

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'dankbar': dankbar,
    'besser': besser,
    if (guteNacht != null) 'gute_nacht': guteNacht!.toIso8601String(),
  };

  factory Journal.fromJson(Map<String, dynamic> j) => Journal(
    tag: j['tag'] as String,
    dankbar: _strings(j['dankbar']),
    besser: _strings(j['besser']),
    guteNacht: j['gute_nacht'] == null
        ? null
        : DateTime.parse(j['gute_nacht'] as String),
  );
}

/// How the energy really was compared with the forecast.
class EnergieMeldung {
  const EnergieMeldung({required this.tag, required this.wie});
  final String tag;

  /// "Wie vorhergesagt", "Besser" or "Schlechter".
  final String wie;

  Map<String, dynamic> toJson() => {'tag': tag, 'wie': wie};
  factory EnergieMeldung.fromJson(Map<String, dynamic> j) =>
      EnergieMeldung(tag: j['tag'] as String, wie: j['wie'] as String);
}

/// The personal alarm. It rings for real only in the phone version.
class Wecker {
  const Wecker({
    this.sonne = true,
    this.klang = 'Vögel',
    this.schlummern = true,
    this.aufgabe = 'foto',
  });

  /// Screen turns warm bright 10 minutes before.
  final bool sonne;
  final String klang;

  /// At most once, 5 minutes.
  final bool schlummern;

  /// foto (sky photo), frage (Aufwach-Himmel) or schritte (30 steps).
  final String aufgabe;

  static const klaenge = ['Vögel', 'Gong', 'Regen', 'Leise Gitarre'];

  Wecker copyWith({
    bool? sonne,
    String? klang,
    bool? schlummern,
    String? aufgabe,
  }) => Wecker(
    sonne: sonne ?? this.sonne,
    klang: klang ?? this.klang,
    schlummern: schlummern ?? this.schlummern,
    aufgabe: aufgabe ?? this.aufgabe,
  );

  Map<String, dynamic> toJson() => {
    'sonne': sonne,
    'klang': klang,
    'schlummern': schlummern,
    'aufgabe': aufgabe,
  };

  factory Wecker.fromJson(Map<String, dynamic> j) => Wecker(
    sonne: j['sonne'] as bool? ?? true,
    klang: j['klang'] as String? ?? 'Vögel',
    schlummern: j['schlummern'] as bool? ?? true,
    aufgabe: j['aufgabe'] as String? ?? 'foto',
  );
}

/// Something that clearly holds only for this user, found by the coach.
class SchlafMuster {
  const SchlafMuster({
    required this.text,
    required this.gut,
    this.beleg,
    this.abgelehnt = false,
  });

  final String text;

  /// Gives energy (true) or takes it (false).
  final bool gut;

  /// "aus 9 Wochen", "6 von 7 Mal".
  final String? beleg;
  final bool abgelehnt;

  SchlafMuster ablehnen() =>
      SchlafMuster(text: text, gut: gut, beleg: beleg, abgelehnt: true);

  Map<String, dynamic> toJson() => {
    'text': text,
    'gut': gut,
    if (beleg != null) 'beleg': beleg,
    'abgelehnt': abgelehnt,
  };

  factory SchlafMuster.fromJson(Map<String, dynamic> j) => SchlafMuster(
    text: j['text'] as String,
    gut: j['gut'] as bool? ?? true,
    beleg: j['beleg'] as String?,
    abgelehnt: j['abgelehnt'] as bool? ?? false,
  );
}

/// One point of the coach's day plan.
class AblaufPunkt {
  const AblaufPunkt({
    required this.minute,
    required this.was,
    this.warum,
    this.neu = false,
  });

  final int minute;
  final String was;
  final String? warum;

  /// Added by the coach (not the user's own appointment or plan).
  final bool neu;

  Map<String, dynamic> toJson() => {
    'minute': minute,
    'was': was,
    if (warum != null) 'warum': warum,
    'neu': neu,
  };

  factory AblaufPunkt.fromJson(Map<String, dynamic> j) => AblaufPunkt(
    minute: (j['minute'] as num).toInt(),
    was: j['was'] as String,
    warum: j['warum'] as String?,
    neu: j['neu'] as bool? ?? false,
  );
}

/// The coach's best day for one date.
class Tagesablauf {
  const Tagesablauf({
    required this.tag,
    required this.punkte,
    this.satz,
    this.uebernommen = false,
  });

  final String tag;
  final List<AblaufPunkt> punkte;
  final String? satz;
  final bool uebernommen;

  Tagesablauf mit({required bool uebernommen}) => Tagesablauf(
    tag: tag,
    punkte: punkte,
    satz: satz,
    uebernommen: uebernommen,
  );

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'punkte': [for (final p in punkte) p.toJson()],
    if (satz != null) 'satz': satz,
    'uebernommen': uebernommen,
  };

  factory Tagesablauf.fromJson(Map<String, dynamic> j) => Tagesablauf(
    tag: j['tag'] as String,
    punkte: [
      for (final p in j['punkte'] as List? ?? const [])
        AblaufPunkt.fromJson(p as Map<String, dynamic>),
    ],
    satz: j['satz'] as String?,
    uebernommen: j['uebernommen'] as bool? ?? false,
  );
}

class SchlafDaten {
  const SchlafDaten({
    this.morgen = const [],
    this.journal = const [],
    this.energie = const [],
    this.wecker = const Wecker(),
    this.lampe = false,
    this.muster = const [],
    this.besteZeit,
    this.musterTag,
    this.ablauf,
    this.energieSatz,
    this.ruheBis,
  });

  final List<Morgen> morgen;
  final List<Journal> journal;
  final List<EnergieMeldung> energie;
  final Wecker wecker;

  /// The user has a daylight lamp: its timer starts on dark mornings.
  final bool lampe;
  final List<SchlafMuster> muster;

  /// "Eher Morgenmensch" and one line why, from the coach.
  final ({String typ, String text})? besteZeit;

  /// Last day the coach looked for patterns.
  final String? musterTag;
  final Tagesablauf? ablauf;

  /// The coach's forecast line for one day.
  final ({String tag, String satz})? energieSatz;

  /// After "Gute Nacht": dark rest mode until this time.
  final DateTime? ruheBis;

  Morgen? morgenAm(String tag) {
    for (final m in morgen.reversed) {
      if (m.tag == tag) return m;
    }
    return null;
  }

  Journal? journalAm(String tag) {
    for (final j in journal.reversed) {
      if (j.tag == tag) return j;
    }
    return null;
  }

  String? energieAm(String tag) {
    for (final e in energie.reversed) {
      if (e.tag == tag) return e.wie;
    }
    return null;
  }

  SchlafDaten mitMorgen(Morgen m) => copyWith(
    morgen: [
      for (final x in morgen)
        if (x.tag != m.tag) x,
      m,
    ],
  );

  SchlafDaten mitJournal(Journal j) => copyWith(
    journal: [
      for (final x in journal)
        if (x.tag != j.tag) x,
      j,
    ],
  );

  SchlafDaten mitEnergie(EnergieMeldung e) => copyWith(
    energie: [
      for (final x in energie)
        if (x.tag != e.tag) x,
      e,
    ],
  );

  SchlafDaten copyWith({
    List<Morgen>? morgen,
    List<Journal>? journal,
    List<EnergieMeldung>? energie,
    Wecker? wecker,
    bool? lampe,
    List<SchlafMuster>? muster,
    ({String typ, String text})? besteZeit,
    String? musterTag,
    Tagesablauf? ablauf,
    ({String tag, String satz})? energieSatz,
    DateTime? ruheBis,
    bool ruheAus = false,
  }) => SchlafDaten(
    morgen: morgen ?? this.morgen,
    journal: journal ?? this.journal,
    energie: energie ?? this.energie,
    wecker: wecker ?? this.wecker,
    lampe: lampe ?? this.lampe,
    muster: muster ?? this.muster,
    besteZeit: besteZeit ?? this.besteZeit,
    musterTag: musterTag ?? this.musterTag,
    ablauf: ablauf ?? this.ablauf,
    energieSatz: energieSatz ?? this.energieSatz,
    ruheBis: ruheAus ? null : (ruheBis ?? this.ruheBis),
  );

  Map<String, dynamic> toJson() => {
    'morgen': [for (final m in morgen) m.toJson()],
    'journal': [for (final j in journal) j.toJson()],
    'energie': [for (final e in energie) e.toJson()],
    'wecker': wecker.toJson(),
    'lampe': lampe,
    'muster': [for (final m in muster) m.toJson()],
    if (besteZeit != null)
      'beste_zeit': {'typ': besteZeit!.typ, 'text': besteZeit!.text},
    if (musterTag != null) 'muster_tag': musterTag,
    if (ablauf != null) 'ablauf': ablauf!.toJson(),
    if (energieSatz != null)
      'energie_satz': {'tag': energieSatz!.tag, 'satz': energieSatz!.satz},
    if (ruheBis != null) 'ruhe_bis': ruheBis!.toIso8601String(),
  };

  factory SchlafDaten.fromJson(Map<String, dynamic> j) {
    final b = j['beste_zeit'] as Map<String, dynamic>?;
    final e = j['energie_satz'] as Map<String, dynamic>?;
    return SchlafDaten(
      morgen: [
        for (final m in j['morgen'] as List? ?? const [])
          Morgen.fromJson(m as Map<String, dynamic>),
      ],
      journal: [
        for (final x in j['journal'] as List? ?? const [])
          Journal.fromJson(x as Map<String, dynamic>),
      ],
      energie: [
        for (final x in j['energie'] as List? ?? const [])
          EnergieMeldung.fromJson(x as Map<String, dynamic>),
      ],
      wecker: j['wecker'] == null
          ? const Wecker()
          : Wecker.fromJson(j['wecker'] as Map<String, dynamic>),
      lampe: j['lampe'] as bool? ?? false,
      muster: [
        for (final x in j['muster'] as List? ?? const [])
          SchlafMuster.fromJson(x as Map<String, dynamic>),
      ],
      besteZeit: b == null
          ? null
          : (typ: b['typ'] as String, text: b['text'] as String),
      musterTag: j['muster_tag'] as String?,
      ablauf: j['ablauf'] == null
          ? null
          : Tagesablauf.fromJson(j['ablauf'] as Map<String, dynamic>),
      energieSatz: e == null
          ? null
          : (tag: e['tag'] as String, satz: e['satz'] as String),
      ruheBis: j['ruhe_bis'] == null
          ? null
          : DateTime.parse(j['ruhe_bis'] as String),
    );
  }

  /// The day before [tag] as dayKey.
  static String gestern(DateTime heute) =>
      dayKey(DateTime(heute.year, heute.month, heute.day - 1));
}
