import 'dart:math' as math;

import '../checkin/checkin.dart';
import '../sleep/schlafzeiten.dart';
import 'schlaf_data.dart';

/// What the user can tap after waking up.
const aufwachTags = [
  'Gut eingeschlafen',
  'Lange wach gelegen',
  'Einmal wach',
  'Öfter wach',
  'Geträumt',
  'Kopf voll',
  'Zu warm',
];

/// The word for the Aufwach-Himmel slider.
String himmelWort(int v) => v < 25
    ? 'Nebel'
    : v < 50
    ? 'Grau'
    : v < 75
    ? 'Klar'
    : 'Sonnenaufgang';

/// Hours slept: from "Gute Nacht" (or the planned bedtime) plus the time
/// to fall asleep, to getting up. Null when nothing is known.
double? geschlafen({
  DateTime? guteNacht,
  int? bettPlan,
  required int aufstehen,
  required DateTime heute,
  List<String> tags = const [],
}) {
  final auf = DateTime(heute.year, heute.month, heute.day, 0, aufstehen);
  DateTime? start = guteNacht;
  if (start == null && bettPlan != null) {
    final g = DateTime(heute.year, heute.month, heute.day - 1, 0, bettPlan);
    start = g.isAfter(auf) ? g.subtract(const Duration(days: 1)) : g;
    // A bedtime after midnight belongs to the same night.
    if (auf.difference(start).inHours > 16) {
      start = start.add(const Duration(days: 1));
    }
  }
  if (start == null) return null;
  var min = auf.difference(start).inMinutes - 15;
  if (tags.contains('Lange wach gelegen')) min -= 30;
  if (tags.contains('Öfter wach')) min -= 30;
  if (tags.contains('Einmal wach')) min -= 10;
  if (min < 60 || min > 16 * 60) return null;
  return (min / 15).round() * 15 / 60;
}

/// The sleep score 1..100 and its four parts, from what the user entered.
/// Later the phone version adds health data (vault: "alles was möglich").
({int wert, Map<String, int> teile}) schlafwert({
  required double stunden,
  required double brauch,
  required int himmel,
  required List<String> tags,
  int? abweichung,
}) {
  final verhaeltnis = stunden / brauch;
  final laenge = verhaeltnis >= 1
      ? (100 - (verhaeltnis - 1) * 60).clamp(80, 100).round()
      : (verhaeltnis * 100 - (1 - verhaeltnis) * 60).clamp(5, 100).round();
  var durch = 100;
  if (tags.contains('Einmal wach')) durch -= 20;
  if (tags.contains('Öfter wach')) durch -= 45;
  if (tags.contains('Lange wach gelegen')) durch -= 25;
  if (tags.contains('Kopf voll')) durch -= 5;
  if (tags.contains('Zu warm')) durch -= 5;
  durch = durch.clamp(5, 100);
  final rhythmus = abweichung == null
      ? 80
      : (100 - math.max(0, abweichung.abs() - 15) * 0.8).clamp(30, 100).round();
  final erholung = himmel.clamp(1, 100);
  final wert =
      (0.35 * laenge + 0.30 * erholung + 0.20 * durch + 0.15 * rhythmus)
          .round()
          .clamp(1, 100);
  return (
    wert: wert,
    teile: {
      'laenge': laenge,
      'erholung': erholung,
      'durchschlafen': durch,
      'rhythmus': rhythmus,
    },
  );
}

/// The short words next to each part.
String teilText(String teil, Morgen m) => switch (teil) {
  'laenge' => formatDauer(m.stunden),
  'erholung' => switch (m.himmel) {
    < 25 => 'schwer',
    < 50 => 'zäh',
    < 75 => 'fast klar',
    _ => 'frisch',
  },
  'durchschlafen' =>
    m.tags.contains('Öfter wach')
        ? 'öfter wach'
        : m.tags.contains('Einmal wach')
        ? '1 × wach'
        : m.tags.contains('Lange wach gelegen')
        ? 'spät eingeschlafen'
        : 'durch',
  // 80 = no Gute Nacht yesterday, so the rhythm is only estimated.
  _ => switch (m.teile['rhythmus'] ?? 80) {
    >= 85 => 'im Plan',
    80 => 'geschätzt',
    _ => 'verschoben',
  },
};

const teilNamen = {
  'laenge': 'Länge',
  'erholung': 'Erholung',
  'durchschlafen': 'Durchschlafen',
  'rhythmus': 'Rhythmus',
};

/// "6 h 25"
String formatDauer(double stunden) {
  final min = (stunden * 60).round();
  final m = min % 60;
  return m == 0 ? '${min ~/ 60} h' : '${min ~/ 60} h ${'$m'.padLeft(2, '0')}';
}

/// The Schlaf-Mond: the average score of the last 7 nights (0..1), null
/// without any entry.
double? mondFuell(List<Morgen> morgen, DateTime heute) {
  final grenze = DateTime(heute.year, heute.month, heute.day - 6);
  final w = [
    for (final m in morgen)
      if (!DateTime.parse(m.tag).isBefore(grenze)) m.wert,
  ];
  if (w.isEmpty) return null;
  return w.reduce((a, b) => a + b) / w.length / 100;
}

/// A coach line for the moon without the coach.
String mondSatz(double fuell) => fuell >= .85
    ? 'Dein Mond ist fast voll. So kann es weitergehen.'
    : fuell >= .7
    ? 'Ein Abend 30 Minuten früher ins Bett und dein Mond ist bald voll.'
    : 'Dein Mond ist schmal. Die nächsten zwei Abende zur Bettzeit ins Bett, '
          'dann füllt er sich wieder.';

/// The coach's line after the morning entry, without the coach.
String morgenSatzOhneCoach(int wert, {String? training}) {
  if (wert >= 80) {
    return 'Gute Nacht gehabt. Heute ist ein Tag für schwere Sachen'
        '${training == null ? '' : ', auch beim Training'}.';
  }
  if (wert >= 60) {
    return 'Okay-Nacht. Wichtige Sachen am besten bis Mittag erledigen und '
        'heute pünktlich ins Bett.';
  }
  return 'Kurze oder unruhige Nacht. Heute nicht zu viel vornehmen'
      '${training == null ? '' : ', Training eher locker'}, und heute früher '
      'ins Bett.';
}

/// Expected energy (0..1) at [minute] of the day: up after getting up,
/// a high a few hours later, a dip in the early afternoon, a second smaller
/// high, then down towards bedtime. A better night lifts it; feedback
/// ("Besser" or "Schlechter") shifts the user's own curve.
double energieAm(
  double minute, {
  required int aufstehen,
  required int bett,
  int? wert,
  int? training,
  double lernen = 0,
}) {
  final t = (minute - aufstehen) / 60; // hours awake
  if (t < 0) return 0.15;
  final wach = (bett - aufstehen) / 60;
  final rise = 1 - math.exp(-t / 1.3);
  final hoch = math.exp(-math.pow((t - 4) / 2.6, 2));
  final dip = math.exp(-math.pow((t - 7.5) / 1.3, 2));
  final zweit = math.exp(-math.pow((t - 10.5) / 1.8, 2));
  final ende = t > wach - 3 ? (t - (wach - 3)) / 3 : 0.0;
  var e = 0.25 + 0.35 * rise + 0.3 * hoch - 0.22 * dip + 0.18 * zweit;
  e -= 0.35 * ende;
  final s = wert == null ? 0.85 : 0.65 + 0.35 * wert / 100;
  e = e * s + lernen * 0.08;
  if (training != null) {
    final d = (minute - training) / 60;
    if (d > 0 && d < 2.5) e -= 0.12 * math.exp(-d);
  }
  return e.clamp(0.05, 1.0).toDouble();
}

/// The forecast over the day in 30-minute steps, with the high window and
/// the low point.
({List<(int, double)> werte, (int, int) hoch, int tief}) energieTag({
  required int aufstehen,
  required int bett,
  int? wert,
  int? training,
  double lernen = 0,
}) {
  var b = bett;
  if (b <= aufstehen) b += 1440;
  final werte = <(int, double)>[
    for (var m = aufstehen; m <= b; m += 30)
      (
        m,
        energieAm(
          m.toDouble(),
          aufstehen: aufstehen,
          bett: b,
          wert: wert,
          training: training,
          lernen: lernen,
        ),
      ),
  ];
  final max = werte.map((w) => w.$2).reduce(math.max);
  final imHoch = [
    for (final w in werte)
      if (w.$2 >= max - 0.05 && w.$1 - aufstehen < 8 * 60) w.$1,
  ];
  final tiefKandidaten = [
    for (final w in werte)
      if (w.$1 - aufstehen >= 5 * 60 && w.$1 - aufstehen <= 10 * 60) w,
  ];
  final tief = tiefKandidaten.isEmpty
      ? aufstehen + 7 * 60
      : tiefKandidaten.reduce((a, c) => c.$2 < a.$2 ? c : a).$1;
  return (
    werte: werte,
    hoch: imHoch.isEmpty
        ? (aufstehen + 3 * 60, aufstehen + 5 * 60)
        : (imHoch.first, imHoch.last + 30),
    tief: tief,
  );
}

/// What the user said about past forecasts: -1..1.
double energieLernen(List<EnergieMeldung> e) {
  final letzte = e.length > 14 ? e.sublist(e.length - 14) : e;
  if (letzte.isEmpty) return 0;
  final s = letzte.fold<double>(
    0,
    (a, x) =>
        a +
        switch (x.wie) {
          'Besser' => 1,
          'Schlechter' => -1,
          _ => 0,
        },
  );
  return (s / letzte.length).clamp(-1, 1).toDouble();
}

/// The forecast in one or two sentences, without the coach.
String energieSatzOhneCoach({
  required (int, int) hoch,
  required int tief,
  int? training,
  int? wert,
}) {
  final h =
      'Dein Hoch heute: ${formatUhrzeit(hoch.$1 % 1440)} bis '
      '${formatUhrzeit(hoch.$2 % 1440)}. Ab etwa ${formatUhrzeit(tief % 1440)} '
      'wird es zäher.';
  if (training == null) {
    return '$h Leg wichtige Sachen ins Hoch.';
  }
  final imHoch = training >= hoch.$1 && training <= hoch.$2;
  return imHoch
      ? '$h Dein Training liegt genau richtig.'
      : '$h Dein Training um ${formatUhrzeit(training % 1440)} geht, schwer '
            'wäre es im Hoch am leichtesten.';
}

/// About when the sun rises in Germany on [tag] (local time, minutes).
int sonnenaufgang(DateTime tag) {
  final doy = tag.difference(DateTime(tag.year)).inDays;
  final sommerzeit = tag.month > 3 && tag.month < 11;
  final cet = 375 + 125 * math.cos(2 * math.pi * (doy + 10) / 365);
  return (cet + (sommerzeit ? 60 : 0)).round();
}

/// Still dark at getting up: the Licht-Modus and lamp card show.
bool nochDunkel(DateTime tag, int aufstehen) =>
    sonnenaufgang(tag) > aufstehen + 15;

/// The phase of the area's own sky (vault: eigener Himmel).
enum HimmelPhase { morgen, tag, abend }

HimmelPhase himmelPhase(DateTime jetzt, int? aufstehen) {
  final m = jetzt.hour * 60 + jetzt.minute;
  final a = aufstehen ?? 7 * 60;
  if (m >= 18 * 60 || m < a - 60) return HimmelPhase.abend;
  if (m < a + 3 * 60) return HimmelPhase.morgen;
  return HimmelPhase.tag;
}

/// The coach's best day without the coach: light after waking, the high
/// for the hardest task, a walk in the dip, meals, training, the evening.
List<AblaufPunkt> ablaufOhneCoach({
  required int aufstehen,
  required int bett,
  required (int, int) hoch,
  required int tief,
  int? training,
  String? trainingName,
  List<(int, String)> mahlzeiten = const [],
  List<(int, String)> termine = const [],
  String? routineAb,
  bool dunkel = false,
}) {
  final p = <AblaufPunkt>[
    AblaufPunkt(minute: aufstehen, was: 'Aufstehen'),
    AblaufPunkt(
      minute: aufstehen + 5,
      was: dunkel ? 'Licht-Modus oder Tageslichtlampe' : '5 Min Sonnenlicht',
      warum: 'Macht dich wach und stellt deine innere Uhr.',
      neu: true,
    ),
    for (final t in termine) AblaufPunkt(minute: t.$1, was: t.$2),
    for (final m in mahlzeiten) AblaufPunkt(minute: m.$1, was: m.$2),
    if (!_belegt(termine, hoch.$1))
      AblaufPunkt(
        minute: hoch.$1,
        was: 'Schwerste Aufgabe des Tages',
        warum:
            'Dein Energie-Hoch heute: ${formatUhrzeit(hoch.$1 % 1440)} bis '
            '${formatUhrzeit(hoch.$2 % 1440)}.',
        neu: true,
      ),
    if (!_belegt(termine, tief) &&
        (training == null || (training - tief).abs() > 60))
      AblaufPunkt(
        minute: tief,
        was: 'Kurz raus, 10 Min gehen',
        warum: 'Hier kommt dein Tief. Bewegung hilft mehr als Kaffee.',
        neu: true,
      ),
    if (training != null)
      AblaufPunkt(
        minute: training,
        was: 'Training${trainingName == null ? '' : ': $trainingName'}',
      ),
    if (routineAb != null && parseUhrzeit(routineAb) != null)
      AblaufPunkt(
        minute: parseUhrzeit(routineAb)!,
        was: 'Abendroutine und Journal',
        warum: '3 Sachen dankbar, 3 Sachen morgen besser.',
      )
    else
      AblaufPunkt(
        minute: bett - 45,
        was: 'Abend-Journal',
        warum: 'Den Tag abschließen, dann Gute Nacht.',
        neu: true,
      ),
    AblaufPunkt(minute: bett, was: 'Gute Nacht'),
  ];
  p.sort((a, b) => a.minute.compareTo(b.minute));
  return p;
}

bool _belegt(List<(int, String)> termine, int minute) =>
    termine.any((t) => (t.$1 - minute).abs() < 60);

/// Everything about sleep and energy as lines for the coach.
String schlafKontext(SchlafDaten d, DateTime heute) {
  final grenze = DateTime(heute.year, heute.month, heute.day - 28);
  return [
    for (final m in d.morgen)
      if (!DateTime.parse(m.tag).isBefore(grenze))
        'Morgen ${m.tag}: Schlafwert ${m.wert}, ${formatDauer(m.stunden)}, '
            'aufgewacht ${himmelWort(m.himmel)}${m.tags.isEmpty ? '' : ', ${m.tags.join(', ')}'}',
    for (final e in d.energie)
      if (!DateTime.parse(e.tag).isBefore(grenze))
        'Energie ${e.tag}: ${e.wie} als vorhergesagt',
    for (final j in d.journal)
      if (!DateTime.parse(j.tag).isBefore(grenze) && j.guteNacht != null)
        'Gute Nacht ${j.tag} um ${formatUhrzeit(j.guteNacht!.hour * 60 + j.guteNacht!.minute)}',
  ].join('\n');
}

/// The patterns the user has not rejected.
List<SchlafMuster> sichtbareSchlafMuster(SchlafDaten d) => [
  for (final m in d.muster)
    if (!m.abgelehnt) m,
];

/// The coach looks for patterns at most once a week and only with enough
/// mornings (14).
bool musterFaellig(SchlafDaten d, DateTime heute) {
  if (d.morgen.length < 14) return false;
  final t = d.musterTag;
  if (t == null) return true;
  return heute.difference(DateTime.parse(t)).inDays >= 7;
}

String heuteKey(DateTime d) => dayKey(d);
