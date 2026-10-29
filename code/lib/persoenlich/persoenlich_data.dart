// Everything the Persönlichkeit page keeps (vault Umsetzung/Persönlichkeit
// komplett.md, Phillip "passt" 2026-10-29). Stored on the device.

import '../business/business_data.dart' show Tipp;

export '../business/business_data.dart' show Tipp, Punkt;

List<String> _strings(Object? v) => [
  for (final x in v as List? ?? const []) '$x',
];

List<T> _liste<T>(Object? v, T Function(Map<String, dynamic>) f) => [
  for (final x in v as List? ?? const [])
    if (x is Map) f(x.cast<String, dynamic>()),
];

int _int(Object? v, [int d = 0]) => (v as num?)?.toInt() ?? d;

Map<String, dynamic>? _map(Object? v) => (v as Map?)?.cast<String, dynamic>();

/// A multiple choice question (lesson check or book quiz).
class Quiz {
  const Quiz({
    required this.frage,
    required this.antworten,
    required this.richtig,
  });

  final String frage;
  final List<String> antworten;
  final int richtig;

  Map<String, dynamic> toJson() => {
    'frage': frage,
    'antworten': antworten,
    'richtig': richtig,
  };

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
    frage: '${j['frage']}',
    antworten: _strings(j['antworten']),
    richtig: _int(j['richtig']),
  );
}

/// One lesson of the skill course; [text] and [quiz] come from the coach
/// when the lesson opens.
class Lektion {
  const Lektion({required this.titel, this.text, this.quiz});

  final String titel;
  final String? text;
  final Quiz? quiz;

  Map<String, dynamic> toJson() => {
    'titel': titel,
    'text': ?text,
    'quiz': ?quiz?.toJson(),
  };

  factory Lektion.fromJson(Map<String, dynamic> j) => Lektion(
    titel: '${j['titel']}',
    text: j['text'] as String?,
    quiz: _map(j['quiz']) == null ? null : Quiz.fromJson(_map(j['quiz'])!),
  );
}

/// The skill as a linear course: 12 lessons, the next opens after the
/// question sits.
class Kurs {
  const Kurs({
    required this.skill,
    this.lektionen = const [],
    this.erreicht = 0,
  });

  final String skill;
  final List<Lektion> lektionen;

  /// Lessons passed.
  final int erreicht;

  Lektion? get aktuelle =>
      erreicht < lektionen.length ? lektionen[erreicht] : null;

  Kurs mitLektion(int i, Lektion l) => Kurs(
    skill: skill,
    lektionen: [
      for (var k = 0; k < lektionen.length; k++) k == i ? l : lektionen[k],
    ],
    erreicht: erreicht,
  );

  Kurs weiter() => Kurs(
    skill: skill,
    lektionen: lektionen,
    erreicht: (erreicht + 1).clamp(0, lektionen.length),
  );

  Map<String, dynamic> toJson() => {
    'skill': skill,
    'lektionen': [for (final l in lektionen) l.toJson()],
    'erreicht': erreicht,
  };

  factory Kurs.fromJson(Map<String, dynamic> j) => Kurs(
    skill: '${j['skill']}',
    lektionen: _liste(j['lektionen'], Lektion.fromJson),
    erreicht: _int(j['erreicht']),
  );
}

/// What the coach read from a photo: Look (3 levers), Stil (passt, ändern,
/// colours) or Haltung (finding and exercises).
class FotoBefund {
  const FotoBefund({
    required this.tag,
    required this.titel,
    this.punkte = const [],
    this.passt,
    this.aendern,
    this.farben = const [],
  });

  final String tag;

  /// Look: "Bart, Brauen, Kragen"; Stil: "Gut, eine Sache"; Haltung: the
  /// finding.
  final String titel;

  /// Look: the 3 levers; Haltung: the exercises (titel = name, text =
  /// how much and when).
  final List<Tipp> punkte;
  final String? passt;
  final String? aendern;

  /// Colours that suit the user, as hex ("#1f2a3a").
  final List<String> farben;

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'titel': titel,
    'punkte': [for (final p in punkte) p.toJson()],
    'passt': ?passt,
    'aendern': ?aendern,
    'farben': farben,
  };

  factory FotoBefund.fromJson(Map<String, dynamic> j) => FotoBefund(
    tag: '${j['tag']}',
    titel: '${j['titel']}',
    punkte: _liste(j['punkte'], Tipp.fromJson),
    passt: j['passt'] as String?,
    aendern: j['aendern'] as String?,
    farben: _strings(j['farben']),
  );
}

/// An 8-week skin plan.
class HautPlan {
  const HautPlan({
    required this.problem,
    required this.start,
    this.phasen = const [],
  });

  final String problem;
  final String start;

  /// "Woche 1–2" and what to do.
  final List<Tipp> phasen;

  Map<String, dynamic> toJson() => {
    'problem': problem,
    'start': start,
    'phasen': [for (final p in phasen) p.toJson()],
  };

  factory HautPlan.fromJson(Map<String, dynamic> j) => HautPlan(
    problem: '${j['problem']}',
    start: '${j['start']}',
    phasen: _liste(j['phasen'], Tipp.fromJson),
  );
}

class Frisur {
  const Frisur({
    required this.empfehlung,
    required this.friseur,
    this.styling,
    this.wochen = 4,
    this.letzterSchnitt,
  });

  final String empfehlung;

  /// The text to show the barber.
  final String friseur;
  final String? styling;
  final int wochen;
  final String? letzterSchnitt;

  Frisur geschnitten(String tag) => Frisur(
    empfehlung: empfehlung,
    friseur: friseur,
    styling: styling,
    wochen: wochen,
    letzterSchnitt: tag,
  );

  Map<String, dynamic> toJson() => {
    'empfehlung': empfehlung,
    'friseur': friseur,
    'styling': ?styling,
    'wochen': wochen,
    'letzter': ?letzterSchnitt,
  };

  factory Frisur.fromJson(Map<String, dynamic> j) => Frisur(
    empfehlung: '${j['empfehlung']}',
    friseur: '${j['friseur']}',
    styling: j['styling'] as String?,
    wochen: _int(j['wochen'], 4),
    letzterSchnitt: j['letzter'] as String?,
  );
}

/// One of the small things (Zahnseide, Nägel, …) every [alle] days.
class KleinesDing {
  const KleinesDing({
    required this.name,
    required this.wie,
    this.alle = 1,
    this.zuletzt,
  });

  final String name;
  final String wie;
  final int alle;
  final String? zuletzt;

  KleinesDing gemacht(String? tag) =>
      KleinesDing(name: name, wie: wie, alle: alle, zuletzt: tag);

  Map<String, dynamic> toJson() => {
    'name': name,
    'wie': wie,
    'alle': alle,
    'zuletzt': ?zuletzt,
  };

  factory KleinesDing.fromJson(Map<String, dynamic> j) => KleinesDing(
    name: '${j['name']}',
    wie: '${j['wie'] ?? ''}',
    alle: _int(j['alle'], 1),
    zuletzt: j['zuletzt'] as String?,
  );
}

const kleineStart = [
  KleinesDing(name: 'Zahnseide', wie: 'jeden Abend', alle: 1),
  KleinesDing(name: 'Duft', wie: 'morgens, ein Sprüher reicht', alle: 1),
  KleinesDing(name: 'Nägel', wie: 'einmal pro Woche', alle: 7),
  KleinesDing(
    name: 'Brauen',
    wie: 'alle zwei Wochen, nur zwischen den Brauen',
    alle: 14,
  ),
];

class Buch {
  const Buch({
    required this.titel,
    this.fertig = false,
    this.quiz = const [],
    this.richtig,
  });

  final String titel;
  final bool fertig;
  final List<Quiz> quiz;

  /// Right answers in the last quiz.
  final int? richtig;

  Buch copyWith({bool? fertig, List<Quiz>? quiz, int? richtig}) => Buch(
    titel: titel,
    fertig: fertig ?? this.fertig,
    quiz: quiz ?? this.quiz,
    richtig: richtig ?? this.richtig,
  );

  Map<String, dynamic> toJson() => {
    'titel': titel,
    'fertig': fertig,
    'quiz': [for (final q in quiz) q.toJson()],
    'richtig': ?richtig,
  };

  factory Buch.fromJson(Map<String, dynamic> j) => Buch(
    titel: '${j['titel']}',
    fertig: j['fertig'] == true,
    quiz: _liste(j['quiz'], Quiz.fromJson),
    richtig: (j['richtig'] as num?)?.toInt(),
  );
}

/// A small step made from a book or podcast.
class Umsetzung {
  const Umsetzung({required this.quelle, required this.schritt, this.erledigt});

  final String quelle;
  final String schritt;
  final String? erledigt;

  Umsetzung umschalten(String tag) => Umsetzung(
    quelle: quelle,
    schritt: schritt,
    erledigt: erledigt == null ? tag : null,
  );

  Map<String, dynamic> toJson() => {
    'quelle': quelle,
    'schritt': schritt,
    'erledigt': ?erledigt,
  };

  factory Umsetzung.fromJson(Map<String, dynamic> j) => Umsetzung(
    quelle: '${j['quelle']}',
    schritt: '${j['schritt']}',
    erledigt: j['erledigt'] as String?,
  );
}

const morgensStart = ['Gesicht waschen', 'Feuchtigkeitscreme', 'Sonnenschutz'];
const abendsStart = ['Gesicht reinigen', 'Nachtcreme'];

class PersoenlichDaten {
  const PersoenlichDaten({
    this.morgens = morgensStart,
    this.abends = abendsStart,
    this.pflege = const {},
    this.lernMinuten = const {},
    this.kurs,
    this.look,
    this.stil,
    this.haltung,
    this.haltungImTraining = false,
    this.haut,
    this.frisur,
    this.kleine = kleineStart,
    this.buecher = const [],
    this.umsetzen = const [],
  });

  final List<String> morgens;
  final List<String> abends;

  /// Day -> ticked steps ("m0", "a1").
  final Map<String, List<String>> pflege;
  final Map<String, int> lernMinuten;
  final Kurs? kurs;
  final FotoBefund? look;
  final FotoBefund? stil;
  final FotoBefund? haltung;
  final bool haltungImTraining;
  final HautPlan? haut;
  final Frisur? frisur;
  final List<KleinesDing> kleine;
  final List<Buch> buecher;
  final List<Umsetzung> umsetzen;

  List<String> pflegeAm(String tag) => pflege[tag] ?? const [];

  PersoenlichDaten pflegeUmschalten(String tag, String id) {
    final l = [...pflegeAm(tag)];
    l.contains(id) ? l.remove(id) : l.add(id);
    return copyWith(pflege: {...pflege, tag: l});
  }

  PersoenlichDaten copyWith({
    List<String>? morgens,
    List<String>? abends,
    Map<String, List<String>>? pflege,
    Map<String, int>? lernMinuten,
    Kurs? kurs,
    FotoBefund? look,
    FotoBefund? stil,
    FotoBefund? haltung,
    bool? haltungImTraining,
    HautPlan? haut,
    Frisur? frisur,
    List<KleinesDing>? kleine,
    List<Buch>? buecher,
    List<Umsetzung>? umsetzen,
  }) => PersoenlichDaten(
    morgens: morgens ?? this.morgens,
    abends: abends ?? this.abends,
    pflege: pflege ?? this.pflege,
    lernMinuten: lernMinuten ?? this.lernMinuten,
    kurs: kurs ?? this.kurs,
    look: look ?? this.look,
    stil: stil ?? this.stil,
    haltung: haltung ?? this.haltung,
    haltungImTraining: haltungImTraining ?? this.haltungImTraining,
    haut: haut ?? this.haut,
    frisur: frisur ?? this.frisur,
    kleine: kleine ?? this.kleine,
    buecher: buecher ?? this.buecher,
    umsetzen: umsetzen ?? this.umsetzen,
  );

  Map<String, dynamic> toJson() => {
    'morgens': morgens,
    'abends': abends,
    'pflege': pflege,
    'lern_minuten': lernMinuten,
    'kurs': ?kurs?.toJson(),
    'look': ?look?.toJson(),
    'stil': ?stil?.toJson(),
    'haltung': ?haltung?.toJson(),
    'haltung_im_training': haltungImTraining,
    'haut': ?haut?.toJson(),
    'frisur': ?frisur?.toJson(),
    'kleine': [for (final k in kleine) k.toJson()],
    'buecher': [for (final b in buecher) b.toJson()],
    'umsetzen': [for (final u in umsetzen) u.toJson()],
  };

  factory PersoenlichDaten.fromJson(Map<String, dynamic> j) {
    FotoBefund? f(String k) =>
        _map(j[k]) == null ? null : FotoBefund.fromJson(_map(j[k])!);
    return PersoenlichDaten(
      morgens: j['morgens'] == null ? morgensStart : _strings(j['morgens']),
      abends: j['abends'] == null ? abendsStart : _strings(j['abends']),
      pflege: {
        for (final e in ((j['pflege'] as Map?) ?? const {}).entries)
          '${e.key}': _strings(e.value),
      },
      lernMinuten: {
        for (final e in ((j['lern_minuten'] as Map?) ?? const {}).entries)
          '${e.key}': (e.value as num).toInt(),
      },
      kurs: _map(j['kurs']) == null ? null : Kurs.fromJson(_map(j['kurs'])!),
      look: f('look'),
      stil: f('stil'),
      haltung: f('haltung'),
      haltungImTraining: j['haltung_im_training'] == true,
      haut: _map(j['haut']) == null
          ? null
          : HautPlan.fromJson(_map(j['haut'])!),
      frisur: _map(j['frisur']) == null
          ? null
          : Frisur.fromJson(_map(j['frisur'])!),
      kleine: j['kleine'] == null
          ? kleineStart
          : _liste(j['kleine'], KleinesDing.fromJson),
      buecher: _liste(j['buecher'], Buch.fromJson),
      umsetzen: _liste(j['umsetzen'], Umsetzung.fromJson),
    );
  }
}
