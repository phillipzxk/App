import '../checkin/checkin.dart';
import '../feed/feed_data.dart';
import '../feed/fokus.dart';
import '../future_me/future_me_data.dart';
import '../planner/planner_data.dart';
import '../sleep/schlafzeiten.dart';
import '../supplements/supplement_data.dart';
import '../training/training_data.dart';
import '../training/training_logik.dart';

/// The kinds of reminders (vault Umsetzung/Erinnerungen.md, Phillip
/// "übernehmen" 2026-11-01). Each one can be switched off on its own.
enum ErinnerungArt {
  wecker('Wecker', 'zu deiner Aufstehzeit'),
  checkin('Check-in am Morgen', '20 Min. nach dem Aufstehen'),
  supplements('Supplements', 'zu deinen Uhrzeiten'),
  termine('Termine', '30 Min. vorher'),
  training('Training', '1 Std. vorher'),
  fokus('Fokus am Abend', '20:00, nur wenn offen'),
  abend('Abendroutine', 'zum Start, aus deiner Bettzeit'),
  foto('Fototag', 'an deinem Fototag'),
  reality('Reality Check', 'am Tag vom Fokus-Wechsel');

  const ErinnerungArt(this.titel, this.wann);

  final String titel;
  final String wann;
}

/// Which kinds are on and whether the limit of 5 a day applies.
class ErinnerungEinstellungen {
  const ErinnerungEinstellungen({this.aus = const {}, this.grenze = true});

  final Set<ErinnerungArt> aus;

  /// "Höchstens 5 am Tag" (appointments and the alarm don't count).
  final bool grenze;

  bool an(ErinnerungArt a) => !aus.contains(a);

  ErinnerungEinstellungen mit(ErinnerungArt a, bool an) =>
      ErinnerungEinstellungen(
        aus: an ? (Set.of(aus)..remove(a)) : (Set.of(aus)..add(a)),
        grenze: grenze,
      );

  ErinnerungEinstellungen mitGrenze(bool g) =>
      ErinnerungEinstellungen(aus: aus, grenze: g);

  Map<String, dynamic> toJson() => {
    'aus': [for (final a in aus) a.name],
    'grenze': grenze,
  };

  factory ErinnerungEinstellungen.fromJson(Map<String, dynamic> j) =>
      ErinnerungEinstellungen(
        aus: {
          for (final n in (j['aus'] as List? ?? const []))
            ?ErinnerungArt.values.asNameMap()[n],
        },
        grenze: j['grenze'] as bool? ?? true,
      );
}

/// Where a tap on a reminder leads, and the buttons on it.
abstract final class Ziel {
  static const checkin = 'checkin';
  static const supplements = 'supplements';
  static const tag = 'tag';
  static const training = 'training';
  static const fokus = 'fokus';
  static const schlaf = 'schlaf';
  static const foto = 'foto';
  static const reality = 'reality';
}

/// Buttons right on the reminder.
abstract final class Knopf {
  static const abhaken = 'abhaken';
  static const geschafft = 'geschafft';
  static const heuteNicht = 'heute_nicht';
}

/// One reminder at one moment.
class Erinnerung {
  const Erinnerung({
    required this.art,
    required this.zeit,
    required this.titel,
    required this.text,
    required this.ziel,
    this.daten = '',
  });

  final ErinnerungArt art;
  final DateTime zeit;
  final String titel;
  final String text;

  /// See [Ziel].
  final String ziel;

  /// Extra for the target, e.g. the supplement ids to tick off.
  final String daten;

  /// "ziel|daten", handed back when the reminder is tapped.
  String get payload => daten.isEmpty ? ziel : '$ziel|$daten';

  /// Appointments and the alarm don't count towards the 5 a day.
  bool get zaehlt =>
      art != ErinnerungArt.termine && art != ErinnerungArt.wecker;

  @override
  String toString() => '${zeit.toIso8601String()} ${art.name}: $titel – $text';
}

/// Everything the plan needs to know about the user right now.
class ErinnerungsLage {
  const ErinnerungsLage({
    required this.jetzt,
    required this.name,
    this.einstellungen = const ErinnerungEinstellungen(),
    this.schlafzeiten = const Schlafzeiten(),
    this.termine = const [],
    this.plan,
    this.training = const TrainingDaten(),
    this.supplements = const [],
    this.genommenHeute = const {},
    this.checkinHeute = false,
    this.fokus,
    this.fotoEinstellungen,
    this.wochenFotos = const [],
    this.routine = const [],
    this.ruheBis,
  });

  final DateTime jetzt;
  final String name;
  final ErinnerungEinstellungen einstellungen;
  final Schlafzeiten schlafzeiten;
  final List<Termin> termine;
  final TrainingPlan? plan;
  final TrainingDaten training;
  final List<Supplement> supplements;
  final Set<String> genommenHeute;
  final bool checkinHeute;
  final Wochenfokus? fokus;
  final FotoEinstellungen? fotoEinstellungen;
  final List<WochenFoto> wochenFotos;
  final List<RoutineStep> routine;

  /// After "Gute Nacht": nothing until this time but the alarm.
  final DateTime? ruheBis;
}

/// How many days ahead are planned (today included). Planned again every
/// time the app opens or something changes.
const planTage = 3;

/// The most reminders a day (appointments and the alarm don't count).
const proTag = 5;

/// Which kind wins when there are more than [proTag] on a day; the first
/// one is the most important.
const _vorrang = [
  ErinnerungArt.training,
  ErinnerungArt.abend,
  ErinnerungArt.checkin,
  ErinnerungArt.supplements,
  ErinnerungArt.reality,
  ErinnerungArt.foto,
  ErinnerungArt.fokus,
];

/// All reminders from now for the next [planTage] days, with the rules:
/// only when something is still open, at most [proTag] a day, quiet from
/// bedtime ("Gute Nacht") until getting up.
List<Erinnerung> planeErinnerungen(ErinnerungsLage l) {
  final alle = <Erinnerung>[];
  final heute = DateTime(l.jetzt.year, l.jetzt.month, l.jetzt.day);
  for (var i = 0; i < planTage; i++) {
    final tag = DateTime(heute.year, heute.month, heute.day + i);
    alle.addAll(_tag(l, tag, i == 0));
  }
  final ergebnis = [
    for (final e in alle)
      if (e.zeit.isAfter(l.jetzt) && l.einstellungen.an(e.art)) e,
  ]..sort((a, b) => a.zeit.compareTo(b.zeit));
  return ergebnis;
}

List<Erinnerung> _tag(ErinnerungsLage l, DateTime tag, bool heute) {
  DateTime um(int minuten) =>
      DateTime(tag.year, tag.month, tag.day).add(Duration(minutes: minuten));
  final z = l.schlafzeiten;
  // An early appointment moves getting up (as in "Deine Schlafzeiten").
  final vortag = DateTime(tag.year, tag.month, tag.day - 1);
  final aufstehen =
      bettzeitFuer(z, vortag, l.termine)?.aufstehen ?? z.aufstehenAm(tag);
  final morgenFrueh = aufstehen ?? 8 * 60;
  final liste = <Erinnerung>[];

  // Alarm.
  if (aufstehen != null) {
    liste.add(
      Erinnerung(
        art: ErinnerungArt.wecker,
        zeit: um(aufstehen),
        titel: 'Guten Morgen, ${l.name}',
        text: 'Zeit aufzustehen. Erst raus, dann Licht.',
        ziel: Ziel.schlaf,
      ),
    );
  }

  // Check-in 20 minutes after getting up, only while it is not done.
  if (!(heute && l.checkinHeute)) {
    liste.add(
      Erinnerung(
        art: ErinnerungArt.checkin,
        zeit: um(morgenFrueh + 20),
        titel: 'Dein Check-in',
        text:
            'Morgen, ${l.name}. 30 Sekunden, dann sag ich dir, wo es '
            'heute hängt.',
        ziel: Ziel.checkin,
      ),
    );
  }

  // Supplements: one reminder per time, only what is still open.
  final proZeit = <String, List<Supplement>>{};
  for (final s in nachZeit(l.supplements)) {
    if (heute && l.genommenHeute.contains(s.id)) continue;
    proZeit.putIfAbsent(s.zeit, () => []).add(s);
  }
  for (final MapEntry(key: zeit, value: s) in proZeit.entries) {
    final m = parseUhrzeit(zeit);
    if (m == null) continue;
    liste.add(_supplements(um(m), s));
  }

  // Appointments 30 minutes before.
  for (final t in termineAm(l.termine, tag)) {
    final m = parseUhrzeit(t.zeit ?? '');
    if (m == null) continue;
    liste.add(
      Erinnerung(
        art: ErinnerungArt.termine,
        zeit: um(m - 30),
        titel: 'In 30 Minuten',
        text: '${t.text.trim()}, ${formatUhrzeit(m)}.',
        ziel: Ziel.tag,
      ),
    );
  }

  // Training one hour before the time in the day's name.
  final plan = l.plan;
  if (plan != null) {
    final woche = wochenPlan(plan, l.training, tag);
    final text = woche.forDay(tag).trim();
    final m = trainingZeit(text);
    final schonDa = l.training.einheitAm(tag) != null;
    if (m != null && istTrainingstag(text) && !schonDa) {
      liste.add(
        Erinnerung(
          art: ErinnerungArt.training,
          zeit: um(m - 60),
          titel: dayName(text),
          text: _trainingText(plan, l.training, tag),
          ziel: Ziel.training,
        ),
      );
    }
  }

  // Focus of the week at 20:00 while today is not ticked off.
  final f = l.fokus;
  if (f != null) {
    final t = f.tag(tag);
    if (t >= 1 && t <= Wochenfokus.tage && !f.heuteGeschafft(tag)) {
      liste.add(
        Erinnerung(
          art: ErinnerungArt.fokus,
          zeit: um(20 * 60),
          titel: 'Fokus der Woche',
          text: '${f.text.trim()}. Tag $t von 7. Heute geschafft?',
          ziel: Ziel.fokus,
        ),
      );
    }
    // Reality Check on the day the week is over (day 8).
    if (t == Wochenfokus.tage + 1) {
      final vor = 7;
      final ge = f.anzahlGeschafft;
      liste.add(
        Erinnerung(
          art: ErinnerungArt.reality,
          zeit: um(morgenFrueh + 90),
          titel: 'Dein Reality Check',
          text:
              'Die Woche ist rum. Vorgenommen $vor, geschafft $ge. '
              'Schauen wir, was gebremst hat.',
          ziel: Ziel.reality,
        ),
      );
    }
  }

  // Photo day, unless this week's photo is already there.
  final foto = l.fotoEinstellungen;
  if (foto != null && tag.weekday == foto.fototag) {
    final da = l.wochenFotos.any(
      (w) =>
          dayKey(w.fototag) == dayKey(tag) || dayKey(w.gemacht) == dayKey(tag),
    );
    if (!da) {
      liste.add(
        Erinnerung(
          art: ErinnerungArt.foto,
          zeit: um(morgenFrueh + 60),
          titel: 'Fototag',
          text:
              'Gleiche Stelle, gleiches Licht wie letzte Woche. Die Kamera '
              'zeigt dir den Umriss.',
          ziel: Ziel.foto,
        ),
      );
    }
  }

  // Evening routine and bedtime.
  final b = bettzeitFuer(z, tag, l.termine);
  // Bedtime after midnight belongs to this evening.
  int abends(int m) => m < 12 * 60 ? m + 1440 : m;
  final bett = b == null ? null : abends(b.bett);
  if (b != null) {
    final r = l.routine.isEmpty ? null : parseUhrzeit(l.routine.first.zeit);
    final ab = r == null ? null : abends(r);
    final start = ab != null && ab < bett! && bett - ab <= 180
        ? ab
        : bett! - 30;
    liste.add(
      Erinnerung(
        art: ErinnerungArt.abend,
        zeit: um(start),
        titel: 'Abendroutine startet',
        text:
            'Bettzeit ${formatUhrzeit(b.bett)}, morgen um '
            '${formatUhrzeit(b.aufstehen)} raus. Erst das Abend-Journal, '
            'dann Gute Nacht.',
        ziel: Ziel.schlaf,
      ),
    );
  }

  return _regeln(l, liste, bett == null ? null : um(bett));
}

Erinnerung _supplements(DateTime zeit, List<Supplement> s) {
  final namen = [for (final x in s) x.name.trim()];
  final text = namen.length == 1
      ? '${namen.first} ist noch offen.'
      : '${namen.sublist(0, namen.length - 1).join(', ')} und '
            '${namen.last} sind noch offen.';
  return Erinnerung(
    art: ErinnerungArt.supplements,
    zeit: zeit,
    titel: 'Supplements',
    text: text,
    ziel: Ziel.supplements,
    daten: [for (final x in s) x.id].join(';'),
  );
}

/// "Letztes Mal Bankdrücken 80 kg × 8. Heute 82,5 kg × 8 drin?"
String _trainingText(TrainingPlan plan, TrainingDaten d, DateTime tag) {
  final i = planTagFuer(plan, d, tag);
  final uebungen = i == null ? const <PlanUebung>[] : plan.uebungenAm(i);
  for (final u in uebungen) {
    if (!u.hatWert) continue;
    final z = zielFuer(u, d, tag);
    final last = z.letztes;
    if (last == null || z.saetze.isEmpty) continue;
    final ziel = z.saetze.first;
    final vorher = satzText(u.art, last);
    final jetzt = satzText(u.art, ziel);
    return vorher == jetzt
        ? 'Letztes Mal ${u.name} $vorher. Heute sauber wiederholen.'
        : 'Letztes Mal ${u.name} $vorher. Heute $jetzt drin?';
  }
  return 'In einer Stunde geht es los. Ein Tipp, und du bist im Training.';
}

/// Quiet at night, at most [proTag] a day; supplements are put together
/// first before anything is dropped.
List<Erinnerung> _regeln(
  ErinnerungsLage l,
  List<Erinnerung> liste,
  DateTime? bett,
) {
  final ruhe = l.ruheBis;
  bool still(Erinnerung e) =>
      (ruhe != null && e.zeit.isBefore(ruhe)) ||
      (bett != null && !e.zeit.isBefore(bett));
  var rest = [
    for (final e in liste)
      if (e.art == ErinnerungArt.wecker || !still(e)) e,
  ];
  if (!l.einstellungen.grenze) return rest;
  int zaehlen() =>
      rest.where((e) => e.zaehlt && l.einstellungen.an(e.art)).length;
  if (zaehlen() > proTag) {
    // Put all supplements of the day into the first one.
    final s = [
      for (final e in rest)
        if (e.art == ErinnerungArt.supplements) e,
    ];
    if (s.length > 1) {
      final namen = <Supplement>[];
      for (final e in s) {
        for (final id in e.daten.split(';')) {
          final teile = id.split('|');
          if (teile.length == 2) {
            namen.add(Supplement(zeit: teile[0], name: teile[1]));
          }
        }
      }
      rest = [
        for (final e in rest)
          if (e.art != ErinnerungArt.supplements) e,
        _supplements(s.first.zeit, namen),
      ];
    }
  }
  for (final art in _vorrang.reversed) {
    if (zaehlen() <= proTag) break;
    rest = [
      for (final e in rest)
        if (e.art != art) e,
    ];
  }
  return rest;
}
