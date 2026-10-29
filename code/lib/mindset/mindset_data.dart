import '../checkin/checkin.dart';

/// Everything the Mindset page keeps (vault Umsetzung/Mindset komplett.md,
/// Entwurf 7, Phillip "Ja" 2026-10-29). Stored on the device.

List<String> _strings(Object? v) => [
  for (final x in v as List? ?? const []) '$x',
];

List<T> _liste<T>(Object? v, T Function(Map<String, dynamic>) f) => [
  for (final x in v as List? ?? const [])
    if (x is Map) f(x.cast<String, dynamic>()),
];

/// One thing the user avoids, a stone on the mountain path.
class Stein {
  const Stein({
    required this.id,
    required this.titel,
    required this.schritt,
    required this.seit,
    this.eigener = false,
    this.erledigt,
    this.danach = const [],
    this.starts = 0,
  });

  final String id;
  final String titel;

  /// The very first move, 2 minutes at most.
  final String schritt;

  /// True when the user named the step first and it fit (Selbstständig).
  final bool eigener;

  /// Day it was put on the mountain (dayKey).
  final String seit;

  /// Day it rolled away (dayKey), null while it is still there.
  final String? erledigt;

  /// The Danach-Plan: what comes right after, so no gap opens.
  final List<String> danach;

  /// How often "Jetzt anfangen" was pressed.
  final int starts;

  Stein copyWith({
    String? schritt,
    String? erledigt,
    List<String>? danach,
    int? starts,
  }) => Stein(
    id: id,
    titel: titel,
    schritt: schritt ?? this.schritt,
    eigener: eigener,
    seit: seit,
    erledigt: erledigt ?? this.erledigt,
    danach: danach ?? this.danach,
    starts: starts ?? this.starts,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titel': titel,
    'schritt': schritt,
    'eigener': eigener,
    'seit': seit,
    if (erledigt != null) 'erledigt': erledigt,
    'danach': danach,
    'starts': starts,
  };

  factory Stein.fromJson(Map<String, dynamic> j) => Stein(
    id: '${j['id']}',
    titel: '${j['titel']}',
    schritt: '${j['schritt'] ?? ''}',
    eigener: j['eigener'] == true,
    seit: '${j['seit']}',
    erledigt: j['erledigt'] as String?,
    danach: _strings(j['danach']),
    starts: (j['starts'] as num?)?.toInt() ?? 0,
  );
}

/// An excuse tapped when a stone was left lying.
class Ausrede {
  const Ausrede({required this.zeit, required this.text, this.stein});

  final DateTime zeit;
  final String text;
  final String? stein;

  Map<String, dynamic> toJson() => {
    'zeit': zeit.toIso8601String(),
    'text': text,
    if (stein != null) 'stein': stein,
  };

  factory Ausrede.fromJson(Map<String, dynamic> j) => Ausrede(
    zeit: DateTime.parse('${j['zeit']}'),
    text: '${j['text']}',
    stein: j['stein'] as String?,
  );
}

/// Something the user said they would do today, and whether they did.
class Vorsatz {
  const Vorsatz({required this.tag, required this.text, this.gehalten = false});

  final String tag;
  final String text;
  final bool gehalten;

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'text': text,
    'gehalten': gehalten,
  };

  factory Vorsatz.fromJson(Map<String, dynamic> j) => Vorsatz(
    tag: '${j['tag']}',
    text: '${j['text']}',
    gehalten: j['gehalten'] == true,
  );
}

/// One of the user's values, rated honestly once a week (1..5).
class Wert {
  const Wert({required this.name, this.wie = '', this.noten = const {}});

  final String name;

  /// Short line, e.g. "auch wenn es stressig wird".
  final String wie;

  /// Monday's dayKey of a week -> rating 1..5.
  final Map<String, int> noten;

  Wert mitNote(String woche, int n) =>
      Wert(name: name, wie: wie, noten: {...noten, woche: n});

  Map<String, dynamic> toJson() => {'name': name, 'wie': wie, 'noten': noten};

  factory Wert.fromJson(Map<String, dynamic> j) => Wert(
    name: '${j['name']}',
    wie: '${j['wie'] ?? ''}',
    noten: {
      for (final e in ((j['noten'] as Map?) ?? const {}).entries)
        '${e.key}': (e.value as num).toInt(),
    },
  );
}

/// A calm habit to tick off (meditation, reading, a walk without phone).
class RuheGewohnheit {
  const RuheGewohnheit({
    required this.name,
    this.wann = '',
    this.tage = const [],
  });

  final String name;
  final String wann;

  /// Days it was done (dayKey).
  final List<String> tage;

  RuheGewohnheit umschalten(String tag) => RuheGewohnheit(
    name: name,
    wann: wann,
    tage: tage.contains(tag)
        ? [
            for (final t in tage)
              if (t != tag) t,
          ]
        : [...tage, tag],
  );

  Map<String, dynamic> toJson() => {'name': name, 'wann': wann, 'tage': tage};

  factory RuheGewohnheit.fromJson(Map<String, dynamic> j) => RuheGewohnheit(
    name: '${j['name']}',
    wann: '${j['wann'] ?? ''}',
    tage: _strings(j['tage']),
  );
}

/// One worry, sorted by the coach into what the user can change and what
/// is not up to them.
class Sorge {
  const Sorge({
    required this.tag,
    required this.text,
    required this.aendern,
    required this.nicht,
  });

  final String tag;
  final String text;
  final String aendern;
  final String nicht;

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'text': text,
    'aendern': aendern,
    'nicht': nicht,
  };

  factory Sorge.fromJson(Map<String, dynamic> j) => Sorge(
    tag: '${j['tag']}',
    text: '${j['text']}',
    aendern: '${j['aendern'] ?? ''}',
    nicht: '${j['nicht'] ?? ''}',
  );
}

/// The evening question and the user's answer.
class Abendantwort {
  const Abendantwort({
    required this.tag,
    required this.frage,
    required this.antwort,
  });

  final String tag;
  final String frage;
  final String antwort;

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'frage': frage,
    'antwort': antwort,
  };

  factory Abendantwort.fromJson(Map<String, dynamic> j) => Abendantwort(
    tag: '${j['tag']}',
    frage: '${j['frage']}',
    antwort: '${j['antwort']}',
  );
}

/// The five big areas of the Lebensrad, in this order.
const radBereiche = [
  'Körper',
  'Produktivität',
  'Business',
  'Persönlichkeit',
  'Mindset',
];

/// One Lebensrad, filled every 3 months: each area 1..10.
class Lebensrad {
  const Lebensrad({required this.tag, required this.werte});

  final String tag;
  final Map<String, int> werte;

  double get schnitt {
    final w = [for (final b in radBereiche) ?werte[b]];
    return w.isEmpty ? 0 : w.reduce((a, b) => a + b) / w.length;
  }

  Map<String, dynamic> toJson() => {'tag': tag, 'werte': werte};

  factory Lebensrad.fromJson(Map<String, dynamic> j) => Lebensrad(
    tag: '${j['tag']}',
    werte: {
      for (final e in ((j['werte'] as Map?) ?? const {}).entries)
        '${e.key}': (e.value as num).toInt(),
    },
  );
}

/// A sealed letter to oneself that opens after 6 months.
class Brief {
  const Brief({
    required this.geschrieben,
    required this.oeffnet,
    required this.text,
    this.satz,
  });

  final String geschrieben;
  final String oeffnet;
  final String text;

  /// The coach's look at what changed, once it is open.
  final String? satz;

  bool offen(DateTime heute) => dayKey(heute).compareTo(oeffnet) >= 0;

  int tageBis(DateTime heute) {
    final o = DateTime.parse(oeffnet);
    final h = DateTime(heute.year, heute.month, heute.day);
    return o.difference(h).inDays.clamp(0, 9999);
  }

  Brief mitSatz(String s) =>
      Brief(geschrieben: geschrieben, oeffnet: oeffnet, text: text, satz: s);

  Map<String, dynamic> toJson() => {
    'geschrieben': geschrieben,
    'oeffnet': oeffnet,
    'text': text,
    if (satz != null) 'satz': satz,
  };

  factory Brief.fromJson(Map<String, dynamic> j) => Brief(
    geschrieben: '${j['geschrieben']}',
    oeffnet: '${j['oeffnet']}',
    text: '${j['text']}',
    satz: j['satz'] as String?,
  );
}

/// A life goal; everything else grows towards it.
class Lebensziel {
  const Lebensziel({required this.text, this.bereich = ''});

  final String text;

  /// One of [radBereiche], or empty.
  final String bereich;

  Map<String, dynamic> toJson() => {'text': text, 'bereich': bereich};

  factory Lebensziel.fromJson(Map<String, dynamic> j) =>
      Lebensziel(text: '${j['text']}', bereich: '${j['bereich'] ?? ''}');
}

class MindsetDaten {
  const MindsetDaten({
    this.steine = const [],
    this.ausreden = const [],
    this.ausredenPlan,
    this.vorsaetze = const [],
    this.werte = const [],
    this.gewohnheiten = const [],
    this.praxis = '',
    this.ruhe = const [],
    this.sorgen = const [],
    this.abend = const [],
    this.leitsatz,
    this.raeder = const [],
    this.briefe = const [],
    this.ziele = const [],
  });

  final List<Stein> steine;
  final List<Ausrede> ausreden;

  /// The coach's plan against the most frequent excuse: (excuse, plan).
  final ({String ausrede, String plan, bool uebernommen})? ausredenPlan;
  final List<Vorsatz> vorsaetze;
  final List<Wert> werte;
  final List<RuheGewohnheit> gewohnheiten;

  /// What gives the user hold (faith, prayer, silence), in their words.
  final String praxis;

  /// When the Ruhe-Knopf ran to the end.
  final List<DateTime> ruhe;
  final List<Sorge> sorgen;
  final List<Abendantwort> abend;

  /// The guiding sentence formed from the evening answers.
  final String? leitsatz;
  final List<Lebensrad> raeder;
  final List<Brief> briefe;
  final List<Lebensziel> ziele;

  MindsetDaten copyWith({
    List<Stein>? steine,
    List<Ausrede>? ausreden,
    ({String ausrede, String plan, bool uebernommen})? ausredenPlan,
    List<Vorsatz>? vorsaetze,
    List<Wert>? werte,
    List<RuheGewohnheit>? gewohnheiten,
    String? praxis,
    List<DateTime>? ruhe,
    List<Sorge>? sorgen,
    List<Abendantwort>? abend,
    String? leitsatz,
    List<Lebensrad>? raeder,
    List<Brief>? briefe,
    List<Lebensziel>? ziele,
  }) => MindsetDaten(
    steine: steine ?? this.steine,
    ausreden: ausreden ?? this.ausreden,
    ausredenPlan: ausredenPlan ?? this.ausredenPlan,
    vorsaetze: vorsaetze ?? this.vorsaetze,
    werte: werte ?? this.werte,
    gewohnheiten: gewohnheiten ?? this.gewohnheiten,
    praxis: praxis ?? this.praxis,
    ruhe: ruhe ?? this.ruhe,
    sorgen: sorgen ?? this.sorgen,
    abend: abend ?? this.abend,
    leitsatz: leitsatz ?? this.leitsatz,
    raeder: raeder ?? this.raeder,
    briefe: briefe ?? this.briefe,
    ziele: ziele ?? this.ziele,
  );

  /// Stones still on the mountain, oldest first.
  List<Stein> get offeneSteine => [
    for (final s in steine)
      if (s.erledigt == null) s,
  ]..sort((a, b) => a.seit.compareTo(b.seit));

  Stein? stein(String id) {
    for (final s in steine) {
      if (s.id == id) return s;
    }
    return null;
  }

  MindsetDaten mitStein(Stein s) => copyWith(
    steine: [
      for (final x in steine)
        if (x.id != s.id) x,
      s,
    ],
  );

  List<Vorsatz> vorsaetzeAm(String tag) => [
    for (final v in vorsaetze)
      if (v.tag == tag) v,
  ];

  Map<String, dynamic> toJson() => {
    'steine': [for (final s in steine) s.toJson()],
    'ausreden': [for (final a in ausreden) a.toJson()],
    if (ausredenPlan case final p?)
      'ausreden_plan': {
        'ausrede': p.ausrede,
        'plan': p.plan,
        'uebernommen': p.uebernommen,
      },
    'vorsaetze': [for (final v in vorsaetze) v.toJson()],
    'werte': [for (final w in werte) w.toJson()],
    'gewohnheiten': [for (final g in gewohnheiten) g.toJson()],
    'praxis': praxis,
    'ruhe': [for (final r in ruhe) r.toIso8601String()],
    'sorgen': [for (final s in sorgen) s.toJson()],
    'abend': [for (final a in abend) a.toJson()],
    if (leitsatz != null) 'leitsatz': leitsatz,
    'raeder': [for (final r in raeder) r.toJson()],
    'briefe': [for (final b in briefe) b.toJson()],
    'ziele': [for (final z in ziele) z.toJson()],
  };

  factory MindsetDaten.fromJson(Map<String, dynamic> j) {
    final p = j['ausreden_plan'];
    return MindsetDaten(
      steine: _liste(j['steine'], Stein.fromJson),
      ausreden: _liste(j['ausreden'], Ausrede.fromJson),
      ausredenPlan: p is Map
          ? (
              ausrede: '${p['ausrede']}',
              plan: '${p['plan']}',
              uebernommen: p['uebernommen'] == true,
            )
          : null,
      vorsaetze: _liste(j['vorsaetze'], Vorsatz.fromJson),
      werte: _liste(j['werte'], Wert.fromJson),
      gewohnheiten: _liste(j['gewohnheiten'], RuheGewohnheit.fromJson),
      praxis: '${j['praxis'] ?? ''}',
      ruhe: [
        for (final r in j['ruhe'] as List? ?? const []) DateTime.parse('$r'),
      ],
      sorgen: _liste(j['sorgen'], Sorge.fromJson),
      abend: _liste(j['abend'], Abendantwort.fromJson),
      leitsatz: j['leitsatz'] as String?,
      raeder: _liste(j['raeder'], Lebensrad.fromJson),
      briefe: _liste(j['briefe'], Brief.fromJson),
      ziele: _liste(j['ziele'], Lebensziel.fromJson),
    );
  }
}
