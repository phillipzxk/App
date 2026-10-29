// Everything the Produktivität & Fokus page keeps (vault Umsetzung/
// Produktivität und Fokus komplett.md, Phillip "sehr gut" 2026-10-29).
// Stored on the device.

List<String> _strings(Object? v) => [
  for (final x in v as List? ?? const []) '$x',
];

List<T> _liste<T>(Object? v, T Function(Map<String, dynamic>) f) => [
  for (final x in v as List? ?? const [])
    if (x is Map) f(x.cast<String, dynamic>()),
];

/// The one thing that counts today.
class TagesFokus {
  const TagesFokus({
    required this.tag,
    required this.text,
    required this.gesetzt,
    this.erledigt = false,
  });

  final String tag;
  final String text;
  final DateTime gesetzt;
  final bool erledigt;

  TagesFokus umschalten() =>
      TagesFokus(tag: tag, text: text, gesetzt: gesetzt, erledigt: !erledigt);

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'text': text,
    'gesetzt': gesetzt.toIso8601String(),
    'erledigt': erledigt,
  };

  factory TagesFokus.fromJson(Map<String, dynamic> j) => TagesFokus(
    tag: '${j['tag']}',
    text: '${j['text']}',
    gesetzt: DateTime.parse('${j['gesetzt']}'),
    erledigt: j['erledigt'] == true,
  );
}

/// One focus block (or a Fokus-Knopf run when [knopf]).
class FokusLauf {
  const FokusLauf({
    required this.start,
    required this.minuten,
    this.geschafft = 0,
    this.knopf = false,
  });

  final DateTime start;

  /// Planned length.
  final int minuten;

  /// Minutes actually done.
  final int geschafft;
  final bool knopf;

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'minuten': minuten,
    'geschafft': geschafft,
    'knopf': knopf,
  };

  factory FokusLauf.fromJson(Map<String, dynamic> j) => FokusLauf(
    start: DateTime.parse('${j['start']}'),
    minuten: (j['minuten'] as num?)?.toInt() ?? 0,
    geschafft: (j['geschafft'] as num?)?.toInt() ?? 0,
    knopf: j['knopf'] == true,
  );
}

/// A tap on the Drang button: the urge to reach for the phone.
class Drang {
  const Drang({required this.zeit, this.grund});

  final DateTime zeit;
  final String? grund;

  Map<String, dynamic> toJson() => {
    'zeit': zeit.toIso8601String(),
    if (grund != null) 'grund': grund,
  };

  factory Drang.fromJson(Map<String, dynamic> j) =>
      Drang(zeit: DateTime.parse('${j['zeit']}'), grund: j['grund'] as String?);
}

/// A new habit hung onto something the user does anyway.
class Andock {
  const Andock({
    required this.anker,
    required this.neu,
    required this.start,
    this.tage = const [],
  });

  /// "Nach dem Kaffee".
  final String anker;

  /// "5 Minuten Tag planen".
  final String neu;
  final String start;

  /// Days it was done (dayKey).
  final List<String> tage;

  /// After 21 days it runs by itself.
  bool get laeuft => tage.length >= 21;

  Andock umschalten(String tag) => Andock(
    anker: anker,
    neu: neu,
    start: start,
    tage: tage.contains(tag)
        ? [
            for (final t in tage)
              if (t != tag) t,
          ]
        : [...tage, tag],
  );

  Map<String, dynamic> toJson() => {
    'anker': anker,
    'neu': neu,
    'start': start,
    'tage': tage,
  };

  factory Andock.fromJson(Map<String, dynamic> j) => Andock(
    anker: '${j['anker']}',
    neu: '${j['neu']}',
    start: '${j['start']}',
    tage: _strings(j['tage']),
  );
}

class ProduktivDaten {
  const ProduktivDaten({
    this.fokus = const [],
    this.laeufe = const [],
    this.drang = const [],
    this.bildschirm = const {},
    this.handyfreiMinuten = 45,
    this.handyfreiTage = const [],
    this.andocken = const [],
  });

  final List<TagesFokus> fokus;
  final List<FokusLauf> laeufe;
  final List<Drang> drang;

  /// Screen time the user read off the phone, per day (minutes). Read
  /// automatically in the phone build.
  final Map<String, int> bildschirm;

  /// Phone-free time right after getting up, in minutes.
  final int handyfreiMinuten;

  /// Mornings the phone-free time was kept (dayKey).
  final List<String> handyfreiTage;
  final List<Andock> andocken;

  ProduktivDaten copyWith({
    List<TagesFokus>? fokus,
    List<FokusLauf>? laeufe,
    List<Drang>? drang,
    Map<String, int>? bildschirm,
    int? handyfreiMinuten,
    List<String>? handyfreiTage,
    List<Andock>? andocken,
  }) => ProduktivDaten(
    fokus: fokus ?? this.fokus,
    laeufe: laeufe ?? this.laeufe,
    drang: drang ?? this.drang,
    bildschirm: bildschirm ?? this.bildschirm,
    handyfreiMinuten: handyfreiMinuten ?? this.handyfreiMinuten,
    handyfreiTage: handyfreiTage ?? this.handyfreiTage,
    andocken: andocken ?? this.andocken,
  );

  TagesFokus? fokusAm(String tag) {
    for (final f in fokus) {
      if (f.tag == tag) return f;
    }
    return null;
  }

  ProduktivDaten mitFokus(TagesFokus f) => copyWith(
    fokus: [
      for (final x in fokus)
        if (x.tag != f.tag) x,
      f,
    ],
  );

  Map<String, dynamic> toJson() => {
    'fokus': [for (final f in fokus) f.toJson()],
    'laeufe': [for (final l in laeufe) l.toJson()],
    'drang': [for (final d in drang) d.toJson()],
    'bildschirm': bildschirm,
    'handyfrei_minuten': handyfreiMinuten,
    'handyfrei_tage': handyfreiTage,
    'andocken': [for (final a in andocken) a.toJson()],
  };

  factory ProduktivDaten.fromJson(Map<String, dynamic> j) => ProduktivDaten(
    fokus: _liste(j['fokus'], TagesFokus.fromJson),
    laeufe: _liste(j['laeufe'], FokusLauf.fromJson),
    drang: _liste(j['drang'], Drang.fromJson),
    bildschirm: {
      for (final e in ((j['bildschirm'] as Map?) ?? const {}).entries)
        '${e.key}': (e.value as num).toInt(),
    },
    handyfreiMinuten: (j['handyfrei_minuten'] as num?)?.toInt() ?? 45,
    handyfreiTage: _strings(j['handyfrei_tage']),
    andocken: _liste(j['andocken'], Andock.fromJson),
  );
}
