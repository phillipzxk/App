import '../checkin/checkin.dart';
import '../mindset/mindset_logik.dart' show tageSeit;
import 'persoenlich_data.dart';

/// All care steps of a day as ids: "m0".. for morning, "a0".. for evening.
List<String> pflegeIds(PersoenlichDaten d) => [
  for (var i = 0; i < d.morgens.length; i++) 'm$i',
  for (var i = 0; i < d.abends.length; i++) 'a$i',
];

bool pflegeVoll(PersoenlichDaten d, String tag) {
  final ids = pflegeIds(d);
  final an = d.pflegeAm(tag);
  return ids.isNotEmpty && ids.every(an.contains);
}

/// Days in a row with the whole routine, counting today only when done.
int pflegeAmStueck(PersoenlichDaten d, DateTime heute) {
  var n = 0;
  var t = heute;
  if (!pflegeVoll(d, dayKey(t))) t = t.subtract(const Duration(days: 1));
  while (pflegeVoll(d, dayKey(t)) && n < 999) {
    n++;
    t = t.subtract(const Duration(days: 1));
  }
  return n;
}

/// The last 21 days, oldest first: routine fully kept.
List<bool> pflege21(PersoenlichDaten d, DateTime heute) => [
  for (var i = 20; i >= 0; i--)
    pflegeVoll(d, dayKey(heute.subtract(Duration(days: i)))),
];

int morgensErledigt(PersoenlichDaten d, String tag) =>
    d.pflegeAm(tag).where((x) => x.startsWith('m')).length;

int abendsErledigt(PersoenlichDaten d, String tag) =>
    d.pflegeAm(tag).where((x) => x.startsWith('a')).length;

/// The first morning step still open today.
String? morgensOffen(PersoenlichDaten d, String tag) {
  final an = d.pflegeAm(tag);
  for (var i = 0; i < d.morgens.length; i++) {
    if (!an.contains('m$i')) return d.morgens[i];
  }
  return null;
}

/// The care step left open most often in the last 14 days.
String? meistVergessen(PersoenlichDaten d, DateTime heute) {
  final z = <String, int>{};
  var tage = 0;
  for (var i = 1; i <= 14; i++) {
    final k = dayKey(heute.subtract(Duration(days: i)));
    final an = d.pflegeAm(k);
    if (an.isEmpty) continue;
    tage++;
    for (var j = 0; j < d.morgens.length; j++) {
      if (!an.contains('m$j')) z[d.morgens[j]] = (z[d.morgens[j]] ?? 0) + 1;
    }
    for (var j = 0; j < d.abends.length; j++) {
      if (!an.contains('a$j')) z[d.abends[j]] = (z[d.abends[j]] ?? 0) + 1;
    }
  }
  if (tage < 5 || z.isEmpty) return null;
  final top = z.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return top.value >= 3 ? top.key : null;
}

bool kleinesFaellig(KleinesDing k, DateTime heute) =>
    k.zuletzt == null || tageSeit(k.zuletzt!, heute) >= k.alle;

bool kleinesHeute(KleinesDing k, DateTime heute) => k.zuletzt == dayKey(heute);

/// Week of the skin plan, 1..8.
int hautWoche(HautPlan h, DateTime heute) =>
    (tageSeit(h.start, heute) ~/ 7 + 1).clamp(1, 8);

/// Days until the next haircut, null without a last cut.
int? frisurTage(Frisur f, DateTime heute) {
  if (f.letzterSchnitt == null) return null;
  return f.wochen * 7 - tageSeit(f.letzterSchnitt!, heute);
}

/// Persönlichkeit 1..10 for a day, null when nothing was tracked (Claude's
/// rule: care routine steps done, and the 10 learning minutes).
int? persoenlichWert(PersoenlichDaten d, String tag) {
  final teile = <double>[];
  final ids = pflegeIds(d);
  final an = d.pflegeAm(tag);
  final lern = d.lernMinuten[tag] ?? 0;
  if (an.isEmpty && lern == 0) return null;
  if (ids.isNotEmpty) teile.add(an.where(ids.contains).length / ids.length);
  if (d.kurs != null || lern > 0) teile.add((lern / 10).clamp(0, 1).toDouble());
  if (teile.isEmpty) return null;
  final m = teile.reduce((a, b) => a + b) / teile.length;
  return (1 + 9 * m).round().clamp(1, 10);
}

List<int?> persoenlichVerlauf(
  PersoenlichDaten d,
  DateTime heute, [
  int n = 30,
]) => [
  for (var i = n - 1; i >= 0; i--)
    persoenlichWert(d, dayKey(heute.subtract(Duration(days: i)))),
];

String persoenlichKontext(PersoenlichDaten d, DateTime heute) {
  final k = d.kurs;
  return [
    'Pflege morgens: ${d.morgens.join(', ')}. Abends: ${d.abends.join(', ')}.',
    'Pflege am Stück: ${pflegeAmStueck(d, heute)} Tage.',
    if (k != null)
      'Skill-Kurs ${k.skill}: Lektion ${k.erreicht + 1} von ${k.lektionen.length}.',
    if (d.look != null)
      'Look-Hebel: ${d.look!.punkte.map((p) => p.titel).join(', ')}.',
    if (d.haltung != null) 'Haltung: ${d.haltung!.titel}.',
    if (d.haut != null)
      'Haut-Plan: ${d.haut!.problem}, Woche ${hautWoche(d.haut!, heute)} von 8.',
    if (d.frisur != null) 'Frisur: ${d.frisur!.empfehlung}.',
    for (final b in d.buecher)
      'Buch: ${b.titel}${b.fertig ? ' (gelesen)' : ''}.',
    for (final u in d.umsetzen)
      'Aus ${u.quelle}: ${u.schritt}${u.erledigt == null ? '' : ' (umgesetzt)'}.',
  ].join('\n');
}
