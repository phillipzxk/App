// Everything the Business & Beruf page keeps (vault Umsetzung/Business und
// Beruf komplett.md, Phillip "jo passt" 2026-10-29). Stored on the device.

List<String> _strings(Object? v) => [
  for (final x in v as List? ?? const []) '$x',
];

List<T> _liste<T>(Object? v, T Function(Map<String, dynamic>) f) => [
  for (final x in v as List? ?? const [])
    if (x is Map) f(x.cast<String, dynamic>()),
];

int _int(Object? v, [int d = 0]) => (v as num?)?.toInt() ?? d;

/// A line with a tick, used for lists that get ticked off.
class Punkt {
  const Punkt(this.text, {this.erledigt});

  final String text;

  /// When it was done (dayKey), null while open.
  final String? erledigt;

  bool get an => erledigt != null;

  Punkt umschalten(String tag) => Punkt(text, erledigt: an ? null : tag);

  Map<String, dynamic> toJson() => {
    'text': text,
    if (erledigt != null) 'erledigt': erledigt,
  };

  factory Punkt.fromJson(Map<String, dynamic> j) =>
      Punkt('${j['text']}', erledigt: j['erledigt'] as String?);
}

/// A short tip from the coach: a bold line and one sentence under it.
class Tipp {
  const Tipp(this.titel, this.text);

  final String titel;
  final String text;

  Map<String, dynamic> toJson() => {'titel': titel, 'text': text};

  factory Tipp.fromJson(Map<String, dynamic> j) =>
      Tipp('${j['titel']}', '${j['text'] ?? ''}');
}

/// The one action that moves the most this week.
class Hebel {
  const Hebel({
    required this.woche,
    required this.text,
    this.punkte = const [],
    this.tipps = const [],
  });

  /// Monday of the week (dayKey).
  final String woche;
  final String text;

  /// The single steps, e.g. the three customers to ask.
  final List<Punkt> punkte;
  final List<Tipp> tipps;

  int get erledigt => punkte.where((p) => p.an).length;

  Hebel copyWith({List<Punkt>? punkte, List<Tipp>? tipps}) => Hebel(
    woche: woche,
    text: text,
    punkte: punkte ?? this.punkte,
    tipps: tipps ?? this.tipps,
  );

  Map<String, dynamic> toJson() => {
    'woche': woche,
    'text': text,
    'punkte': [for (final p in punkte) p.toJson()],
    'tipps': [for (final t in tipps) t.toJson()],
  };

  factory Hebel.fromJson(Map<String, dynamic> j) => Hebel(
    woche: '${j['woche']}',
    text: '${j['text']}',
    punkte: _liste(j['punkte'], Punkt.fromJson),
    tipps: _liste(j['tipps'], Tipp.fromJson),
  );
}

/// The smallest version someone pays for.
class ErsterEuro {
  const ErsterEuro({this.angebot, this.preis, this.geschickt = false, this.da});

  /// The offer in one sentence.
  final String? angebot;
  final int? preis;

  /// Sent to 3 people.
  final bool geschickt;

  /// The day the first euro came in.
  final String? da;

  /// Steps done of four.
  int get schritte =>
      (angebot != null ? 1 : 0) +
      (preis != null ? 1 : 0) +
      (geschickt ? 1 : 0) +
      (da != null ? 1 : 0);

  ErsterEuro copyWith({
    String? angebot,
    int? preis,
    bool? geschickt,
    String? da,
  }) => ErsterEuro(
    angebot: angebot ?? this.angebot,
    preis: preis ?? this.preis,
    geschickt: geschickt ?? this.geschickt,
    da: da ?? this.da,
  );

  Map<String, dynamic> toJson() => {
    'angebot': ?angebot,
    'preis': ?preis,
    'geschickt': geschickt,
    'da': ?da,
  };

  factory ErsterEuro.fromJson(Map<String, dynamic> j) => ErsterEuro(
    angebot: j['angebot'] as String?,
    preis: (j['preis'] as num?)?.toInt(),
    geschickt: j['geschickt'] == true,
    da: j['da'] as String?,
  );
}

/// Money that came in.
class Eingang {
  const Eingang({required this.tag, required this.betrag, this.wofuer});

  final String tag;
  final int betrag;
  final String? wofuer;

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'betrag': betrag,
    'wofuer': ?wofuer,
  };

  factory Eingang.fromJson(Map<String, dynamic> j) => Eingang(
    tag: '${j['tag']}',
    betrag: _int(j['betrag']),
    wofuer: j['wofuer'] as String?,
  );
}

class SparZiel {
  const SparZiel({
    required this.name,
    required this.ziel,
    this.stand = 0,
    this.monatlich = 0,
  });

  final String name;
  final int ziel;
  final int stand;
  final int monatlich;

  double get anteil => ziel <= 0 ? 0 : (stand / ziel).clamp(0, 1).toDouble();

  SparZiel copyWith({int? stand, int? monatlich}) => SparZiel(
    name: name,
    ziel: ziel,
    stand: stand ?? this.stand,
    monatlich: monatlich ?? this.monatlich,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'ziel': ziel,
    'stand': stand,
    'monatlich': monatlich,
  };

  factory SparZiel.fromJson(Map<String, dynamic> j) => SparZiel(
    name: '${j['name']}',
    ziel: _int(j['ziel']),
    stand: _int(j['stand']),
    monatlich: _int(j['monatlich']),
  );
}

/// One kind of work and what it brought this month.
class Taetigkeit {
  const Taetigkeit({required this.name, this.euro = 0, this.stunden = 0});

  final String name;
  final int euro;
  final double stunden;

  /// Euro per hour, null without hours.
  int? get proStunde => stunden <= 0 ? null : (euro / stunden).round();

  Map<String, dynamic> toJson() => {
    'name': name,
    'euro': euro,
    'stunden': stunden,
  };

  factory Taetigkeit.fromJson(Map<String, dynamic> j) => Taetigkeit(
    name: '${j['name']}',
    euro: _int(j['euro']),
    stunden: (j['stunden'] as num?)?.toDouble() ?? 0,
  );
}

/// A thought dropped into the Gedanken-Ablage.
class Gedanke {
  const Gedanke({required this.text, required this.zeit, this.kern = false});

  final String text;
  final DateTime zeit;

  /// A core idea (gold).
  final bool kern;

  Gedanke umschalten() => Gedanke(text: text, zeit: zeit, kern: !kern);

  Map<String, dynamic> toJson() => {
    'text': text,
    'zeit': zeit.toIso8601String(),
    'kern': kern,
  };

  factory Gedanke.fromJson(Map<String, dynamic> j) => Gedanke(
    text: '${j['text']}',
    zeit: DateTime.parse('${j['zeit']}'),
    kern: j['kern'] == true,
  );
}

/// A core idea worked out with the coach: a goal and a plan from start to
/// end.
class IdeenPlan {
  const IdeenPlan({
    required this.idee,
    required this.ziel,
    this.schritte = const [],
  });

  final String idee;
  final String ziel;
  final List<Punkt> schritte;

  IdeenPlan mitSchritten(List<Punkt> s) =>
      IdeenPlan(idee: idee, ziel: ziel, schritte: s);

  Map<String, dynamic> toJson() => {
    'idee': idee,
    'ziel': ziel,
    'schritte': [for (final s in schritte) s.toJson()],
  };

  factory IdeenPlan.fromJson(Map<String, dynamic> j) => IdeenPlan(
    idee: '${j['idee']}',
    ziel: '${j['ziel']}',
    schritte: _liste(j['schritte'], Punkt.fromJson),
  );
}

/// One hard question of the Ideen-Prüfer and the user's answer.
class Frage {
  const Frage(this.frage, [this.antwort]);

  final String frage;
  final String? antwort;

  bool get beantwortet => antwort != null && antwort!.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {'frage': frage, 'antwort': ?antwort};

  factory Frage.fromJson(Map<String, dynamic> j) =>
      Frage('${j['frage']}', j['antwort'] as String?);
}

class IdeePruefung {
  const IdeePruefung({
    required this.idee,
    this.fragen = const [],
    this.reife,
    this.satz,
  });

  final String idee;
  final List<Frage> fragen;

  /// How ripe the idea is, 0..100, from the coach after the answers.
  final int? reife;
  final String? satz;

  /// The coach's ripeness, or the share of answered questions until then.
  int get reifeJetzt {
    if (reife != null) return reife!;
    if (fragen.isEmpty) return 0;
    return (fragen.where((f) => f.beantwortet).length / fragen.length * 60)
        .round();
  }

  int get offen => fragen.where((f) => !f.beantwortet).length;

  IdeePruefung copyWith({List<Frage>? fragen, int? reife, String? satz}) =>
      IdeePruefung(
        idee: idee,
        fragen: fragen ?? this.fragen,
        reife: reife ?? this.reife,
        satz: satz ?? this.satz,
      );

  Map<String, dynamic> toJson() => {
    'idee': idee,
    'fragen': [for (final f in fragen) f.toJson()],
    'reife': ?reife,
    'satz': ?satz,
  };

  factory IdeePruefung.fromJson(Map<String, dynamic> j) => IdeePruefung(
    idee: '${j['idee']}',
    fragen: _liste(j['fragen'], Frage.fromJson),
    reife: (j['reife'] as num?)?.toInt(),
    satz: j['satz'] as String?,
  );
}

/// An objection and the answer to it.
class Einwand {
  const Einwand(this.sagt, this.antwort);

  final String sagt;
  final String antwort;

  Map<String, dynamic> toJson() => {'sagt': sagt, 'antwort': antwort};

  factory Einwand.fromJson(Map<String, dynamic> j) =>
      Einwand('${j['sagt']}', '${j['antwort']}');
}

/// A guide for an important conversation.
class Gespraech {
  const Gespraech({
    required this.mit,
    required this.ziel,
    this.wann,
    this.schritte = const [],
    this.einwaende = const [],
  });

  final String mit;
  final String ziel;
  final String? wann;
  final List<Tipp> schritte;
  final List<Einwand> einwaende;

  Map<String, dynamic> toJson() => {
    'mit': mit,
    'ziel': ziel,
    'wann': ?wann,
    'schritte': [for (final s in schritte) s.toJson()],
    'einwaende': [for (final e in einwaende) e.toJson()],
  };

  factory Gespraech.fromJson(Map<String, dynamic> j) => Gespraech(
    mit: '${j['mit']}',
    ziel: '${j['ziel']}',
    wann: j['wann'] as String?,
    schritte: _liste(j['schritte'], Tipp.fromJson),
    einwaende: _liste(j['einwaende'], Einwand.fromJson),
  );
}

/// One skill, step by step: seven steps, each builds on the last.
class Skill {
  const Skill({required this.name, this.stufen = const [], this.erreicht = 0});

  final String name;

  /// Name and this-week task per step.
  final List<Tipp> stufen;

  /// Steps reached.
  final int erreicht;

  Tipp? get naechste => erreicht < stufen.length ? stufen[erreicht] : null;

  Skill weiter() => Skill(
    name: name,
    stufen: stufen,
    erreicht: (erreicht + 1).clamp(0, stufen.length),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'stufen': [for (final s in stufen) s.toJson()],
    'erreicht': erreicht,
  };

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
    name: '${j['name']}',
    stufen: _liste(j['stufen'], Tipp.fromJson),
    erreicht: _int(j['erreicht']),
  );
}

class BusinessDaten {
  const BusinessDaten({
    this.hebel = const [],
    this.anfragen = const [],
    this.euro = const ErsterEuro(),
    this.ziele = const {},
    this.eingaenge = const [],
    this.spar,
    this.sparTipps = const [],
    this.taetigkeiten = const [],
    this.stundenSatz,
    this.gedanken = const [],
    this.plan,
    this.pruefung,
    this.gespraech,
    this.meilensteine = const [],
    this.vorschlaege = const [],
    this.skill,
  });

  /// One lever per week, newest last.
  final List<Hebel> hebel;

  /// Things that are hard to ask for.
  final List<Punkt> anfragen;
  final ErsterEuro euro;

  /// Monthly turnover goal: "2026-10" -> euro.
  final Map<String, int> ziele;
  final List<Eingang> eingaenge;
  final SparZiel? spar;

  /// The coach's tips to save more.
  final List<Tipp> sparTipps;
  final List<Taetigkeit> taetigkeiten;

  /// The coach's sentence what to focus on, from the hourly values.
  final String? stundenSatz;
  final List<Gedanke> gedanken;
  final IdeenPlan? plan;
  final IdeePruefung? pruefung;
  final Gespraech? gespraech;

  /// Milestones: each is a branch on the Business-Baum.
  final List<Punkt> meilensteine;

  /// The coach's suggestions for the next milestones.
  final List<String> vorschlaege;
  final Skill? skill;

  Hebel? hebelIn(String woche) {
    for (final h in hebel.reversed) {
      if (h.woche == woche) return h;
    }
    return null;
  }

  BusinessDaten mitHebel(Hebel h) => copyWith(
    hebel: [
      for (final x in hebel)
        if (x.woche != h.woche) x,
      h,
    ],
  );

  BusinessDaten copyWith({
    List<Hebel>? hebel,
    List<Punkt>? anfragen,
    ErsterEuro? euro,
    Map<String, int>? ziele,
    List<Eingang>? eingaenge,
    SparZiel? spar,
    List<Tipp>? sparTipps,
    List<Taetigkeit>? taetigkeiten,
    String? stundenSatz,
    List<Gedanke>? gedanken,
    IdeenPlan? plan,
    IdeePruefung? pruefung,
    Gespraech? gespraech,
    List<Punkt>? meilensteine,
    List<String>? vorschlaege,
    Skill? skill,
  }) => BusinessDaten(
    hebel: hebel ?? this.hebel,
    anfragen: anfragen ?? this.anfragen,
    euro: euro ?? this.euro,
    ziele: ziele ?? this.ziele,
    eingaenge: eingaenge ?? this.eingaenge,
    spar: spar ?? this.spar,
    sparTipps: sparTipps ?? this.sparTipps,
    taetigkeiten: taetigkeiten ?? this.taetigkeiten,
    stundenSatz: stundenSatz ?? this.stundenSatz,
    gedanken: gedanken ?? this.gedanken,
    plan: plan ?? this.plan,
    pruefung: pruefung ?? this.pruefung,
    gespraech: gespraech ?? this.gespraech,
    meilensteine: meilensteine ?? this.meilensteine,
    vorschlaege: vorschlaege ?? this.vorschlaege,
    skill: skill ?? this.skill,
  );

  Map<String, dynamic> toJson() => {
    'hebel': [for (final h in hebel) h.toJson()],
    'anfragen': [for (final a in anfragen) a.toJson()],
    'euro': euro.toJson(),
    'ziele': ziele,
    'eingaenge': [for (final e in eingaenge) e.toJson()],
    'spar': ?spar?.toJson(),
    'spar_tipps': [for (final t in sparTipps) t.toJson()],
    'taetigkeiten': [for (final t in taetigkeiten) t.toJson()],
    'stunden_satz': ?stundenSatz,
    'gedanken': [for (final g in gedanken) g.toJson()],
    'plan': ?plan?.toJson(),
    'pruefung': ?pruefung?.toJson(),
    'gespraech': ?gespraech?.toJson(),
    'meilensteine': [for (final m in meilensteine) m.toJson()],
    'vorschlaege': vorschlaege,
    'skill': ?skill?.toJson(),
  };

  factory BusinessDaten.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic>? m(String k) =>
        (j[k] as Map?)?.cast<String, dynamic>();
    return BusinessDaten(
      hebel: _liste(j['hebel'], Hebel.fromJson),
      anfragen: _liste(j['anfragen'], Punkt.fromJson),
      euro: m('euro') == null
          ? const ErsterEuro()
          : ErsterEuro.fromJson(m('euro')!),
      ziele: {
        for (final e in ((j['ziele'] as Map?) ?? const {}).entries)
          '${e.key}': (e.value as num).toInt(),
      },
      eingaenge: _liste(j['eingaenge'], Eingang.fromJson),
      spar: m('spar') == null ? null : SparZiel.fromJson(m('spar')!),
      sparTipps: _liste(j['spar_tipps'], Tipp.fromJson),
      taetigkeiten: _liste(j['taetigkeiten'], Taetigkeit.fromJson),
      stundenSatz: j['stunden_satz'] as String?,
      gedanken: _liste(j['gedanken'], Gedanke.fromJson),
      plan: m('plan') == null ? null : IdeenPlan.fromJson(m('plan')!),
      pruefung: m('pruefung') == null
          ? null
          : IdeePruefung.fromJson(m('pruefung')!),
      gespraech: m('gespraech') == null
          ? null
          : Gespraech.fromJson(m('gespraech')!),
      meilensteine: _liste(j['meilensteine'], Punkt.fromJson),
      vorschlaege: _strings(j['vorschlaege']),
      skill: m('skill') == null ? null : Skill.fromJson(m('skill')!),
    );
  }
}
