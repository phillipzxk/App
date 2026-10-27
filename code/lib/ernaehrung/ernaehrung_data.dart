/// Data of the Ernährung page (vault Umsetzung/Ernährung komplett.md,
/// Phillip 2026-10-27): meals of each day, cravings, the cookbook with the
/// coach's rescue dishes, the shopping list and the weight check. Nothing
/// is counted: the plate and the photo hints are in words.
library;

double? _zahl(Object? v) => (v as num?)?.toDouble();

/// One ingredient for one portion.
class Zutat {
  const Zutat({
    required this.name,
    this.menge,
    this.einheit = '',
    this.gruppe = 'Sonstiges',
  });

  final String name;
  final double? menge;
  final String einheit;

  /// Eiweiß, Gemüse, Obst, Kühlregal, Vorrat or Sonstiges.
  final String gruppe;

  static const gruppen = [
    'Eiweiß',
    'Gemüse',
    'Obst',
    'Kühlregal',
    'Vorrat',
    'Sonstiges',
  ];

  Map<String, dynamic> toJson() => {
    'name': name,
    'menge': menge,
    'einheit': einheit,
    'gruppe': gruppe,
  };

  factory Zutat.fromJson(Map<String, dynamic> j) => Zutat(
    name: j['name'] as String? ?? '',
    menge: _zahl(j['menge']),
    einheit: j['einheit'] as String? ?? '',
    gruppe: gruppen.contains(j['gruppe']) ? j['gruppe'] as String : 'Sonstiges',
  );
}

/// A dish in the cookbook: the user's own, a rescue dish from the coach or
/// one the coach built from the fridge.
class Gericht {
  const Gericht({
    required this.id,
    required this.name,
    this.art = 'Hauptmahlzeit',
    this.dauer,
    this.gegen,
    this.warum,
    this.zutaten = const [],
    this.schritte = const [],
    this.quelle = 'eigen',
    this.gekocht = 0,
    this.bewertung,
    this.freiAb,
  });

  final String id;
  final String name;

  /// Frühstück, Hauptmahlzeit or Snack.
  final String art;

  /// Minutes.
  final int? dauer;

  /// The pattern it is against, e.g. "gegen deinen 21-Uhr-Heißhunger".
  final String? gegen;

  /// Why it fits this user.
  final String? warum;
  final List<Zutat> zutaten;
  final List<String> schritte;

  /// "eigen", "coach" or "kuehlschrank".
  final String quelle;
  final int gekocht;

  /// "lecker", "geht so" or "nicht meins".
  final String? bewertung;

  /// Locked until the user has cooked this many times in total.
  final int? freiAb;

  /// A leaf on the tree: cooked and not thrown out.
  bool get imKochbuch => gekocht > 0 && bewertung != 'nicht meins';

  /// Cooked often enough to know it by heart.
  bool get sitzt => gekocht >= 4;

  Gericht copyWith({
    String? name,
    int? gekocht,
    String? bewertung,
    bool freigeben = false,
    List<Zutat>? zutaten,
    List<String>? schritte,
  }) => Gericht(
    id: id,
    name: name ?? this.name,
    art: art,
    dauer: dauer,
    gegen: gegen,
    warum: warum,
    zutaten: zutaten ?? this.zutaten,
    schritte: schritte ?? this.schritte,
    quelle: quelle,
    gekocht: gekocht ?? this.gekocht,
    bewertung: bewertung ?? this.bewertung,
    freiAb: freigeben ? null : freiAb,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'art': art,
    'dauer': dauer,
    'gegen': gegen,
    'warum': warum,
    'zutaten': [for (final z in zutaten) z.toJson()],
    'schritte': schritte,
    'quelle': quelle,
    'gekocht': gekocht,
    'bewertung': bewertung,
    'frei_ab': freiAb,
  };

  factory Gericht.fromJson(Map<String, dynamic> j) => Gericht(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    art: j['art'] as String? ?? 'Hauptmahlzeit',
    dauer: (j['dauer'] as num?)?.toInt(),
    gegen: j['gegen'] as String?,
    warum: j['warum'] as String?,
    zutaten: [
      for (final z in j['zutaten'] as List? ?? const [])
        Zutat.fromJson(z as Map<String, dynamic>),
    ],
    schritte: [for (final s in j['schritte'] as List? ?? const []) '$s'],
    quelle: j['quelle'] as String? ?? 'eigen',
    gekocht: (j['gekocht'] as num?)?.toInt() ?? 0,
    bewertung: j['bewertung'] as String?,
    freiAb: (j['frei_ab'] as num?)?.toInt(),
  );
}

/// The coach's rough read of a plate photo: 0 (nothing) to 3 (fits).
class TellerHinweis {
  const TellerHinweis({
    required this.eiweiss,
    required this.gemuese,
    required this.groesse,
    this.eiweissText,
    this.gemueseText,
    this.groesseText,
    this.tipp,
  });

  final int eiweiss, gemuese, groesse;
  final String? eiweissText, gemueseText, groesseText, tipp;

  Map<String, dynamic> toJson() => {
    'eiweiss': eiweiss,
    'gemuese': gemuese,
    'groesse': groesse,
    'eiweiss_text': eiweissText,
    'gemuese_text': gemueseText,
    'groesse_text': groesseText,
    'tipp': tipp,
  };

  factory TellerHinweis.fromJson(Map<String, dynamic> j) {
    int s(Object? v) => ((v as num?)?.round() ?? 0).clamp(0, 3);
    return TellerHinweis(
      eiweiss: s(j['eiweiss']),
      gemuese: s(j['gemuese']),
      groesse: s(j['groesse']),
      eiweissText: j['eiweiss_text'] as String?,
      gemueseText: j['gemuese_text'] as String?,
      groesseText: j['groesse_text'] as String?,
      tipp: j['tipp'] as String?,
    );
  }
}

/// What happened with one meal of a day.
class MahlzeitEintrag {
  const MahlzeitEintrag({
    this.gegessen = false,
    this.gefuehl,
    this.teller,
    this.bild,
  });

  final bool gegessen;

  /// "satt", "okay" or "noch Hunger".
  final String? gefuehl;
  final TellerHinweis? teller;

  /// The plate photo (JPEG, base64), kept for a week.
  final String? bild;

  MahlzeitEintrag copyWith({
    bool? gegessen,
    String? gefuehl,
    bool gefuehlLeeren = false,
    TellerHinweis? teller,
    String? bild,
  }) => MahlzeitEintrag(
    gegessen: gegessen ?? this.gegessen,
    gefuehl: gefuehlLeeren ? null : (gefuehl ?? this.gefuehl),
    teller: teller ?? this.teller,
    bild: bild ?? this.bild,
  );

  MahlzeitEintrag ohneBild() =>
      MahlzeitEintrag(gegessen: gegessen, gefuehl: gefuehl, teller: teller);

  Map<String, dynamic> toJson() => {
    'gegessen': gegessen,
    'gefuehl': gefuehl,
    if (teller != null) 'teller': teller!.toJson(),
    if (bild != null) 'bild': bild,
  };

  factory MahlzeitEintrag.fromJson(Map<String, dynamic> j) => MahlzeitEintrag(
    gegessen: j['gegessen'] == true,
    gefuehl: j['gefuehl'] as String?,
    teller: j['teller'] == null
        ? null
        : TellerHinweis.fromJson(j['teller'] as Map<String, dynamic>),
    bild: j['bild'] as String?,
  );
}

/// One craving: when, why, the coach's step and whether it helped.
class Heisshunger {
  const Heisshunger({
    required this.zeit,
    required this.grund,
    this.schritt,
    this.geholfen,
  });

  final DateTime zeit;
  final String grund;
  final String? schritt;
  final bool? geholfen;

  Heisshunger mit({String? schritt, bool? geholfen}) => Heisshunger(
    zeit: zeit,
    grund: grund,
    schritt: schritt ?? this.schritt,
    geholfen: geholfen ?? this.geholfen,
  );

  Map<String, dynamic> toJson() => {
    'zeit': zeit.toIso8601String(),
    'grund': grund,
    'schritt': schritt,
    'geholfen': geholfen,
  };

  factory Heisshunger.fromJson(Map<String, dynamic> j) => Heisshunger(
    zeit: DateTime.parse(j['zeit'] as String),
    grund: j['grund'] as String? ?? '',
    schritt: j['schritt'] as String?,
    geholfen: j['geholfen'] as bool?,
  );
}

/// One Gewichts-Check: the user's guess first, then the coach's view and
/// a new kcal target to take over or leave.
class GewichtsCheck {
  const GewichtsCheck({
    required this.tag,
    required this.lage,
    required this.kcalAlt,
    this.grund,
    this.sicht,
    this.vorschlag,
    this.kcalNeu,
    this.status = 'offen',
  });

  final String tag;

  /// "steht", "zu schnell" or "weg".
  final String lage;
  final int kcalAlt;
  final String? grund, sicht, vorschlag;
  final int? kcalNeu;

  /// "offen", "uebernommen" or "gelassen".
  final String status;

  GewichtsCheck copyWith({
    String? grund,
    String? sicht,
    String? vorschlag,
    int? kcalNeu,
    String? status,
  }) => GewichtsCheck(
    tag: tag,
    lage: lage,
    kcalAlt: kcalAlt,
    grund: grund ?? this.grund,
    sicht: sicht ?? this.sicht,
    vorschlag: vorschlag ?? this.vorschlag,
    kcalNeu: kcalNeu ?? this.kcalNeu,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'lage': lage,
    'kcal_alt': kcalAlt,
    'grund': grund,
    'sicht': sicht,
    'vorschlag': vorschlag,
    'kcal_neu': kcalNeu,
    'status': status,
  };

  factory GewichtsCheck.fromJson(Map<String, dynamic> j) => GewichtsCheck(
    tag: j['tag'] as String? ?? '',
    lage: j['lage'] as String? ?? 'steht',
    kcalAlt: (j['kcal_alt'] as num?)?.toInt() ?? 0,
    grund: j['grund'] as String?,
    sicht: j['sicht'] as String?,
    vorschlag: j['vorschlag'] as String?,
    kcalNeu: (j['kcal_neu'] as num?)?.toInt(),
    status: j['status'] as String? ?? 'offen',
  );
}

/// The shopping list: dishes of the week with how often, ticked items and
/// the user's own items.
class Einkauf {
  const Einkauf({
    this.auswahl = const {},
    this.erledigt = const {},
    this.eigene = const [],
  });

  /// Dish id -> how often this week.
  final Map<String, int> auswahl;
  final Set<String> erledigt;
  final List<String> eigene;

  Einkauf copyWith({
    Map<String, int>? auswahl,
    Set<String>? erledigt,
    List<String>? eigene,
  }) => Einkauf(
    auswahl: auswahl ?? this.auswahl,
    erledigt: erledigt ?? this.erledigt,
    eigene: eigene ?? this.eigene,
  );

  Map<String, dynamic> toJson() => {
    'auswahl': auswahl,
    'erledigt': erledigt.toList(),
    'eigene': eigene,
  };

  factory Einkauf.fromJson(Map<String, dynamic> j) => Einkauf(
    auswahl: {
      for (final e in ((j['auswahl'] as Map?) ?? const {}).entries)
        '${e.key}': (e.value as num).toInt(),
    },
    erledigt: {for (final x in j['erledigt'] as List? ?? const []) '$x'},
    eigene: [for (final x in j['eigene'] as List? ?? const []) '$x'],
  );
}

class ErnaehrungDaten {
  const ErnaehrungDaten({
    this.tage = const {},
    this.verschoben = const {},
    this.heisshunger = const [],
    this.gerichte = const [],
    this.einkauf = const Einkauf(),
    this.gewicht = const [],
    this.kcalAnpassung = 0,
    this.zusammenhang,
  });

  /// Day key -> meal id -> entry.
  final Map<String, Map<String, MahlzeitEintrag>> tage;

  /// Day key -> meal id -> minute the user dragged it to.
  final Map<String, Map<String, int>> verschoben;
  final List<Heisshunger> heisshunger;
  final List<Gericht> gerichte;
  final Einkauf einkauf;
  final List<GewichtsCheck> gewicht;

  /// Change to the kcal target from a Gewichts-Check.
  final int kcalAnpassung;

  /// The coach's Zusammenhang sentence of a day (satz null: nothing seen).
  final ({String tag, String? satz})? zusammenhang;

  ErnaehrungDaten copyWith({
    Map<String, Map<String, MahlzeitEintrag>>? tage,
    Map<String, Map<String, int>>? verschoben,
    List<Heisshunger>? heisshunger,
    List<Gericht>? gerichte,
    Einkauf? einkauf,
    List<GewichtsCheck>? gewicht,
    int? kcalAnpassung,
    ({String tag, String? satz})? zusammenhang,
  }) => ErnaehrungDaten(
    tage: tage ?? this.tage,
    verschoben: verschoben ?? this.verschoben,
    heisshunger: heisshunger ?? this.heisshunger,
    gerichte: gerichte ?? this.gerichte,
    einkauf: einkauf ?? this.einkauf,
    gewicht: gewicht ?? this.gewicht,
    kcalAnpassung: kcalAnpassung ?? this.kcalAnpassung,
    zusammenhang: zusammenhang ?? this.zusammenhang,
  );

  Map<String, MahlzeitEintrag> tag(String key) => tage[key] ?? const {};

  ErnaehrungDaten mitEintrag(String tag, String id, MahlzeitEintrag e) =>
      copyWith(
        tage: {
          ...tage,
          tag: {...this.tag(tag), id: e},
        },
      );

  ErnaehrungDaten mitZeit(String tag, String id, int minute) => copyWith(
    verschoben: {
      ...verschoben,
      tag: {...verschoben[tag] ?? const {}, id: minute},
    },
  );

  ErnaehrungDaten mitGericht(Gericht g) => copyWith(
    gerichte: [
      for (final x in gerichte)
        if (x.id != g.id) x,
      g,
    ],
  );

  Gericht? gericht(String id) {
    for (final g in gerichte) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Drops plate photos older than a week so storage stays small.
  ErnaehrungDaten aufgeraeumt(DateTime heute) {
    final grenze = DateTime(heute.year, heute.month, heute.day - 7);
    return copyWith(
      tage: {
        for (final e in tage.entries)
          e.key: DateTime.parse(e.key).isBefore(grenze)
              ? {for (final m in e.value.entries) m.key: m.value.ohneBild()}
              : e.value,
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'tage': {
      for (final t in tage.entries)
        t.key: {for (final m in t.value.entries) m.key: m.value.toJson()},
    },
    'verschoben': verschoben,
    'heisshunger': [for (final h in heisshunger) h.toJson()],
    'gerichte': [for (final g in gerichte) g.toJson()],
    'einkauf': einkauf.toJson(),
    'gewicht': [for (final g in gewicht) g.toJson()],
    'kcal_anpassung': kcalAnpassung,
    if (zusammenhang != null)
      'zusammenhang': {'tag': zusammenhang!.tag, 'satz': zusammenhang!.satz},
  };

  factory ErnaehrungDaten.fromJson(Map<String, dynamic> j) {
    final z = j['zusammenhang'] as Map<String, dynamic>?;
    return ErnaehrungDaten(
      tage: {
        for (final t in ((j['tage'] as Map?) ?? const {}).entries)
          '${t.key}': {
            for (final m in (t.value as Map).entries)
              '${m.key}': MahlzeitEintrag.fromJson(
                m.value as Map<String, dynamic>,
              ),
          },
      },
      verschoben: {
        for (final t in ((j['verschoben'] as Map?) ?? const {}).entries)
          '${t.key}': {
            for (final m in (t.value as Map).entries)
              '${m.key}': (m.value as num).toInt(),
          },
      },
      heisshunger: [
        for (final h in j['heisshunger'] as List? ?? const [])
          Heisshunger.fromJson(h as Map<String, dynamic>),
      ],
      gerichte: [
        for (final g in j['gerichte'] as List? ?? const [])
          Gericht.fromJson(g as Map<String, dynamic>),
      ],
      einkauf: j['einkauf'] == null
          ? const Einkauf()
          : Einkauf.fromJson(j['einkauf'] as Map<String, dynamic>),
      gewicht: [
        for (final g in j['gewicht'] as List? ?? const [])
          GewichtsCheck.fromJson(g as Map<String, dynamic>),
      ],
      kcalAnpassung: (j['kcal_anpassung'] as num?)?.toInt() ?? 0,
      zusammenhang: z == null
          ? null
          : (tag: z['tag'] as String? ?? '', satz: z['satz'] as String?),
    );
  }
}
