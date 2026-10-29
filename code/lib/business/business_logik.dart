import '../checkin/checkin.dart';
import '../mindset/mindset_logik.dart' show wocheVon;
import 'business_data.dart';

const _monate = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

/// "2026-10".
String monatVon(DateTime d) => dayKey(d).substring(0, 7);

String monatName(DateTime d) => _monate[d.month - 1];

int tageImMonat(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

/// Days left in the month after today.
int restTage(DateTime d) => tageImMonat(d) - d.day;

/// "2.140 €".
String euro(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '−' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '$b €';
}

/// A number the user typed, "1.200", "1200 €" or "12,5".
num? zahl(String t) {
  final s = t.replaceAll('€', '').replaceAll(' ', '').trim();
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    return num.tryParse(s.replaceAll('.', '').replaceAll(',', '.'));
  }
  return num.tryParse(s.replaceAll('.', ''));
}

/// What came in during a month, up to and including [bis] when given.
int umsatzIm(BusinessDaten d, String monat, {String? bis}) => [
  for (final e in d.eingaenge)
    if (e.tag.startsWith(monat) && (bis == null || e.tag.compareTo(bis) <= 0))
      e.betrag,
].fold(0, (a, b) => a + b);

/// Hourly value over all kinds of work, null without hours.
int? stundenwert(BusinessDaten d) {
  final h = d.taetigkeiten.fold<double>(0, (a, t) => a + t.stunden);
  if (h <= 0) return null;
  final e = d.taetigkeiten.fold<int>(0, (a, t) => a + t.euro);
  return (e / h).round();
}

double stundenGesamt(BusinessDaten d) =>
    d.taetigkeiten.fold<double>(0, (a, t) => a + t.stunden);

/// The kind of work that brings the most per hour.
Taetigkeit? besteTaetigkeit(BusinessDaten d) {
  Taetigkeit? best;
  for (final t in d.taetigkeiten) {
    if (t.proStunde == null) continue;
    if (best == null || t.proStunde! > best.proStunde!) best = t;
  }
  return best;
}

/// When the savings goal is reached ("im Januar"), null without a rate.
String? sparFertig(SparZiel s, DateTime heute) {
  if (s.stand >= s.ziel) return 'erreicht';
  if (s.monatlich <= 0) return null;
  final n = ((s.ziel - s.stand) / s.monatlich).ceil();
  final m = DateTime(heute.year, heute.month + n);
  return m.year == heute.year
      ? 'fertig im ${monatName(m)}'
      : 'fertig im ${monatName(m)} ${m.year}';
}

/// The first milestone not reached yet.
int? naechsterAst(BusinessDaten d) {
  for (var i = 0; i < d.meilensteine.length; i++) {
    if (!d.meilensteine[i].an) return i;
  }
  return null;
}

/// How far the user is towards a milestone like "3.000 € im Monat":
/// this month's income against the number in it. Null for other kinds.
double? astAnteil(String text, BusinessDaten d, DateTime heute) {
  final m = RegExp(r'(\d[\d.]*)\s*€').firstMatch(text);
  if (m == null || !text.contains('Monat')) return null;
  final n = zahl(m.group(1)!);
  if (n == null || n <= 0) return null;
  return (umsatzIm(d, monatVon(heute)) / n).clamp(0, 1).toDouble();
}

/// Business 1..10 for a day, null when nothing was tracked (Claude's rule:
/// the lever's steps, income against the month's goal so far, and bold
/// asks done this week).
int? businessWert(BusinessDaten d, DateTime tag) {
  final k = dayKey(tag);
  final woche = wocheVon(tag);
  final teile = <double>[];
  final h = d.hebelIn(woche);
  if (h != null && h.punkte.isNotEmpty) {
    teile.add(
      h.punkte.where((p) => p.an && p.erledigt!.compareTo(k) <= 0).length /
          h.punkte.length,
    );
  }
  final monat = monatVon(tag);
  final ziel = d.ziele[monat];
  if (ziel != null && ziel > 0) {
    final soll = ziel * tag.day / tageImMonat(tag);
    teile.add((umsatzIm(d, monat, bis: k) / soll).clamp(0, 1).toDouble());
  }
  final mutig = [
    for (final a in d.anfragen)
      if (a.an &&
          a.erledigt!.compareTo(woche) >= 0 &&
          a.erledigt!.compareTo(k) <= 0)
        a,
  ].length;
  if (d.anfragen.any(
    (a) => a.erledigt == null || a.erledigt!.compareTo(k) <= 0,
  )) {
    teile.add((mutig / 2).clamp(0, 1).toDouble());
  }
  if (teile.isEmpty) return null;
  final m = teile.reduce((a, b) => a + b) / teile.length;
  return (1 + 9 * m).round().clamp(1, 10);
}

/// The last [n] days' values, oldest first.
List<int?> businessVerlauf(BusinessDaten d, DateTime heute, [int n = 30]) => [
  for (var i = n - 1; i >= 0; i--)
    businessWert(d, heute.subtract(Duration(days: i))),
];

/// The default hard questions when the coach is not reachable.
const pruefFragen = [
  'Wer genau kauft das?',
  'Würden 3 Leute heute dafür zahlen?',
  'Was kostet dich das an Zeit?',
  'Warum bei dir und nicht kostenlos woanders?',
];

/// A simple conversation guide when the coach is not reachable.
const gespraechLeitfaden = [
  ('Einstieg', 'Kurz sagen, warum gerade sie.'),
  ('Dein Angebot', 'In einem Satz, was du machst und was es ihnen bringt.'),
  ('Beweis', 'Eine Arbeit zeigen, die schon fertig ist.'),
  (
    'Abschluss',
    'Einen kleinen nächsten Schritt vorschlagen und Termin festmachen.',
  ),
];

/// Text for the coach about the user's business.
String businessKontext(BusinessDaten d, DateTime heute) {
  final monat = monatVon(heute);
  final h = d.hebelIn(wocheVon(heute));
  final ziel = d.ziele[monat];
  final w = stundenwert(d);
  final ast = naechsterAst(d);
  return [
    if (h != null)
      'Hebel der Woche: ${h.text} (${h.erledigt} von ${h.punkte.length}).',
    if (ziel != null)
      'Umsatz ${monatName(heute)}: ${euro(umsatzIm(d, monat))} von ${euro(ziel)}.',
    if (w != null) 'Stundenwert: $w € pro Stunde.',
    for (final t in d.taetigkeiten)
      if (t.proStunde != null) '${t.name}: ${t.proStunde} € pro Stunde.',
    if (d.euro.angebot != null) 'Erster Euro: ${d.euro.angebot}.',
    if (d.spar != null)
      'Spar-Ziel ${d.spar!.name}: ${euro(d.spar!.stand)} von ${euro(d.spar!.ziel)}.',
    for (final g in d.gedanken.where((g) => g.kern)) 'Kernidee: ${g.text}.',
    if (ast != null) 'Nächster Meilenstein: ${d.meilensteine[ast].text}.',
    if (d.skill != null)
      'Skill ${d.skill!.name}: Stufe ${d.skill!.erreicht} von ${d.skill!.stufen.length}.',
  ].join('\n');
}
