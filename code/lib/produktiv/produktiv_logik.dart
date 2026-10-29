import '../checkin/checkin.dart';
import '../mindset/mindset_logik.dart' show wannText, wocheVon;
import 'produktiv_data.dart';

/// Minutes in focus (blocks and Fokus-Knopf) on a day.
int fokusMinuten(ProduktivDaten d, String tag) => [
  for (final l in d.laeufe)
    if (dayKey(l.start) == tag) l.geschafft,
].fold(0, (a, b) => a + b);

/// Produktivität 1..10 for a day, null when nothing was tracked (Claude's
/// rule: the one thing done, minutes in focus against 50, phone-free
/// morning kept).
int? produktivWert(ProduktivDaten d, String tag) {
  final f = d.fokusAm(tag);
  final min = fokusMinuten(d, tag);
  final frei = d.handyfreiTage.contains(tag);
  if (f == null && min == 0 && !frei) return null;
  final teile = <double>[
    if (f != null) f.erledigt ? 1 : .3,
    (min / 50).clamp(0, 1).toDouble(),
    frei ? 1 : 0,
  ];
  final m = teile.reduce((a, b) => a + b) / teile.length;
  return (1 + 9 * m).round().clamp(1, 10);
}

/// The last [n] days' values, oldest first.
List<int?> produktivVerlauf(ProduktivDaten d, DateTime heute, [int n = 30]) => [
  for (var i = n - 1; i >= 0; i--)
    produktivWert(d, dayKey(heute.subtract(Duration(days: i)))),
];

/// Block length by energy right now (0..1): 75, 50 or 25 minutes.
int blockVorschlag(double? energie) {
  if (energie == null) return 50;
  if (energie >= .8) return 75;
  if (energie >= .55) return 50;
  return 25;
}

/// The energy forecast value at [minute] of the day.
double? energieUm(List<(int, double)> werte, int minute) {
  if (werte.isEmpty) return null;
  var best = werte.first;
  for (final w in werte) {
    if ((w.$1 - minute).abs() < (best.$1 - minute).abs()) best = w;
  }
  return best.$2;
}

List<Drang> drangAm(ProduktivDaten d, String tag) => [
  for (final x in d.drang)
    if (dayKey(x.zeit) == tag) x,
];

/// When the urge usually comes and the most frequent reason.
({String? wann, String? grund, int n}) drangMuster(ProduktivDaten d) {
  final g = <String, int>{};
  for (final x in d.drang) {
    if (x.grund != null) g[x.grund!] = (g[x.grund!] ?? 0) + 1;
  }
  final top = g.entries.toList()..sort((a, b) => b.value - a.value);
  return (
    wann: d.drang.length < 5
        ? null
        : wannText([for (final x in d.drang) x.zeit]),
    grund: top.isEmpty || top.first.value < 2 ? null : top.first.key,
    n: d.drang.length,
  );
}

/// The urge happens most in which hour (e.g. "14 bis 15 Uhr"), from 5 taps.
String? drangStunde(ProduktivDaten d) {
  if (d.drang.length < 5) return null;
  final h = <int, int>{};
  for (final x in d.drang) {
    h[x.zeit.hour] = (h[x.zeit.hour] ?? 0) + 1;
  }
  final top = h.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return '${top.key} bis ${top.key + 1} Uhr';
}

const drangGruende = ['Langeweile', 'Aufgabe unklar', 'Müde', 'Gewohnheit'];

/// The last 7 days, oldest first: true kept, false not, for a list of days.
List<bool> letzte7(List<String> tage, DateTime heute) => [
  for (var i = 6; i >= 0; i--)
    tage.contains(dayKey(heute.subtract(Duration(days: i)))),
];

/// Fokus für heute over the last 7 days: true done, false not, null unset.
List<bool?> fokus7(ProduktivDaten d, DateTime heute) => [
  for (var i = 6; i >= 0; i--)
    d.fokusAm(dayKey(heute.subtract(Duration(days: i))))?.erledigt,
];

/// Minutes in focus per day this week, Monday first.
List<int> fokusWoche(ProduktivDaten d, DateTime heute) {
  final mo = DateTime.parse(wocheVon(heute));
  return [
    for (var i = 0; i < 7; i++)
      fokusMinuten(d, dayKey(mo.add(Duration(days: i)))),
  ];
}

/// The habit being built now (the first that does not run by itself yet).
Andock? aktiverAndock(ProduktivDaten d) {
  for (final a in d.andocken) {
    if (!a.laeuft) return a;
  }
  return null;
}

List<Andock> laufende(ProduktivDaten d) => [
  for (final a in d.andocken)
    if (a.laeuft) a,
];

const anker = [
  'Nach dem Aufstehen',
  'Nach dem Kaffee',
  'Nach dem Mittagessen',
  'Nach dem Training',
  'Nach dem Zähneputzen',
];

/// "3:12 h" for minutes.
String stundenText(int minuten) =>
    '${minuten ~/ 60}:${(minuten % 60).toString().padLeft(2, '0')} h';

const wochentageKurz = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
