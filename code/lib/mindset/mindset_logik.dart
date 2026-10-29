import '../checkin/checkin.dart';
import '../training/training_data.dart' show montagVon;
import 'mindset_data.dart';

/// Monday's dayKey of the week of [d].
String wocheVon(DateTime d) => dayKey(montagVon(d));

const _wochentage = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Days since a dayKey (0 = today).
int tageSeit(String tag, DateTime heute) {
  final t = DateTime.parse(tag);
  final h = DateTime(heute.year, heute.month, heute.day);
  return h.difference(t).inDays.clamp(0, 99999);
}

/// "seit heute", "seit 9 Tagen", "seit 2 Wochen".
String seitText(String tag, DateTime heute) {
  final n = tageSeit(tag, heute);
  if (n == 0) return 'seit heute';
  if (n == 1) return 'seit gestern';
  if (n >= 14) return 'seit ${n ~/ 7} Wochen';
  return 'seit $n Tagen';
}

/// Selbstständig-Stufe: every 3 own first steps that fit lift the level,
/// 1 to 5 (Claude's rule for the decided idea, vault Mindset komplett).
({int stufe, int eigene, int bisNaechste}) selbststaendig(MindsetDaten d) {
  final eigene = d.steine.where((s) => s.eigener).length;
  final stufe = (1 + eigene ~/ 3).clamp(1, 5);
  return (
    stufe: stufe,
    eigene: eigene,
    bisNaechste: stufe >= 5 ? 0 : 3 - eigene % 3,
  );
}

/// Kept and planned promises in the week of [heute].
({int gehalten, int vorgenommen}) wortWoche(MindsetDaten d, DateTime heute) {
  final w = wocheVon(heute);
  final diese = [
    for (final v in d.vorsaetze)
      if (wocheVon(DateTime.parse(v.tag)) == w) v,
  ];
  return (
    gehalten: diese.where((v) => v.gehalten).length,
    vorgenommen: diese.length,
  );
}

/// Percent kept per week for the last [n] weeks (oldest first), null for a
/// week without any promise.
List<int?> wortVerlauf(MindsetDaten d, DateTime heute, [int n = 6]) {
  final mo = montagVon(heute);
  return [
    for (var i = n - 1; i >= 0; i--)
      () {
        final w = dayKey(mo.subtract(Duration(days: 7 * i)));
        final v = [
          for (final x in d.vorsaetze)
            if (wocheVon(DateTime.parse(x.tag)) == w) x,
        ];
        if (v.isEmpty) return null;
        return (v.where((x) => x.gehalten).length * 100 / v.length).round();
      }(),
  ];
}

/// "meist Di, Do · nach 18 Uhr" from the times something happened.
String? wannText(List<DateTime> zeiten) {
  if (zeiten.length < 2) return null;
  final tage = <int, int>{};
  for (final z in zeiten) {
    tage[z.weekday] = (tage[z.weekday] ?? 0) + 1;
  }
  final top = tage.entries.toList()..sort((a, b) => b.value - a.value);
  final oft = [
    for (final e in top.take(2))
      if (e.value >= 2) e.key,
  ]..sort();
  final stunden = [for (final z in zeiten) z.hour]..sort();
  final h = stunden[stunden.length ~/ 2];
  final zeit = h >= 17
      ? 'abends'
      : h >= 12
      ? 'nachmittags'
      : 'vormittags';
  final teile = [
    if (oft.isNotEmpty) oft.map((t) => _wochentage[t - 1]).join(', '),
    zeit,
  ];
  return 'meist ${teile.join(' · ')}';
}

/// Every excuse with how often it came and when, most frequent first.
List<({String text, int n, String? wann})> ausredenListe(MindsetDaten d) {
  final g = <String, List<DateTime>>{};
  for (final a in d.ausreden) {
    (g[a.text] ??= []).add(a.zeit);
  }
  return [
    for (final e in g.entries)
      (text: e.key, n: e.value.length, wann: wannText(e.value)),
  ]..sort((a, b) => b.n - a.n);
}

/// The fixed choice when leaving a stone lying.
const ausredenWahl = [
  'Bin zu müde',
  'Keine Zeit',
  'Mach ich morgen',
  'Lohnt sich nicht',
  'Weiß nicht, wie',
];

/// One question per evening, after the Abend-Journal. The list runs through
/// in order, so no question comes twice in a row.
const abendFragen = [
  'Wofür willst du in 10 Jahren bekannt sein?',
  'Wann warst du heute am meisten du selbst?',
  'Was würdest du tun, wenn dich keiner bewertet?',
  'Wofür bist du heute dankbar, das du sonst übersiehst?',
  'Was soll man über dich sagen, wenn du nicht im Raum bist?',
  'Wovor hast du gerade am meisten Respekt, und warum?',
  'Was hat dir heute Ruhe gegeben?',
  'Welche Entscheidung von heute würdest du wieder so treffen?',
  'Was willst du in einem Jahr nicht mehr mit dir herumtragen?',
  'Wer hat dich heute weitergebracht, ohne es zu wissen?',
  'Wann hast du zuletzt etwas nur für dich gemacht?',
  'Was ist dir wichtiger, als du zugibst?',
  'Welcher Moment heute war es wert?',
  'Woran merkst du, dass du auf dem richtigen Weg bist?',
];

String abendFrage(MindsetDaten d, DateTime heute) {
  final heuteKey = dayKey(heute);
  for (final a in d.abend) {
    if (a.tag == heuteKey) return a.frage;
  }
  return abendFragen[d.abend.length % abendFragen.length];
}

Abendantwort? abendHeute(MindsetDaten d, DateTime heute) {
  final k = dayKey(heute);
  for (final a in d.abend) {
    if (a.tag == k) return a;
  }
  return null;
}

/// Days until the next Lebensrad (every 3 months), 0 = due now.
int tageBisRad(MindsetDaten d, DateTime heute) {
  if (d.raeder.isEmpty) return 0;
  final letztes = d.raeder.last.tag;
  return (91 - tageSeit(letztes, heute)).clamp(0, 91);
}

/// The Lebensrad before the newest one, for the dashed comparison.
Lebensrad? radVorher(MindsetDaten d) =>
    d.raeder.length < 2 ? null : d.raeder[d.raeder.length - 2];

/// The letter that opens next (or one that is open and not read yet).
Brief? naechsterBrief(MindsetDaten d, DateTime heute) {
  final zu = [
    for (final b in d.briefe)
      if (!b.offen(heute)) b,
  ]..sort((a, b) => a.oeffnet.compareTo(b.oeffnet));
  return zu.isEmpty ? null : zu.first;
}

List<Brief> offeneBriefe(MindsetDaten d, DateTime heute) => [
  for (final b in d.briefe)
    if (b.offen(heute)) b,
];

/// The date 6 months after [d] (end of month clamps).
DateTime sechsMonate(DateTime d) {
  final m = d.month + 6;
  final y = d.year + (m - 1) ~/ 12;
  final mm = (m - 1) % 12 + 1;
  final last = DateTime(y, mm + 1, 0).day;
  return DateTime(y, mm, d.day.clamp(1, last));
}

/// Ruhe-Knopf runs this week and when they mostly were.
({int n, String? wann}) ruheWoche(MindsetDaten d, DateTime heute) {
  final w = wocheVon(heute);
  final z = [
    for (final r in d.ruhe)
      if (wocheVon(r) == w) r,
  ];
  return (n: z.length, wann: wannText(z));
}

/// Average of this week's value ratings (1..5), null if none yet.
double? werteSchnitt(MindsetDaten d, DateTime heute) {
  final w = wocheVon(heute);
  final n = [for (final x in d.werte) ?x.noten[w]];
  if (n.isEmpty) return null;
  return n.reduce((a, b) => a + b) / n.length;
}

/// Text for the coach about the whole Mindset area.
String mindsetKontext(MindsetDaten d, DateTime heute) {
  final b = StringBuffer();
  final s = d.offeneSteine;
  if (s.isNotEmpty) {
    b.writeln('Steine auf dem Berg (wovor sie sich drückt):');
    for (final x in s) {
      b.writeln(
        '- ${x.titel} (${seitText(x.seit, heute)}), Schritt: ${x.schritt}',
      );
    }
  }
  final erl = d.steine.where((x) => x.erledigt != null).length;
  if (erl > 0) b.writeln('Schon erledigte Steine: $erl');
  final a = ausredenListe(d);
  if (a.isNotEmpty) {
    b.writeln(
      'Ausreden: ${[for (final x in a) '${x.text} ${x.n}x${x.wann == null ? '' : ' (${x.wann})'}'].join('; ')}',
    );
  }
  final w = wortWoche(d, heute);
  if (w.vorgenommen > 0) {
    b.writeln('Wort gehalten diese Woche: ${w.gehalten} von ${w.vorgenommen}');
  }
  if (d.werte.isNotEmpty) {
    b.writeln('Werte: ${d.werte.map((x) => x.name).join(', ')}');
  }
  if (d.leitsatz != null) b.writeln('Leitsatz: ${d.leitsatz}');
  if (d.ziele.isNotEmpty) {
    b.writeln('Lebensziele: ${d.ziele.map((z) => z.text).join('; ')}');
  }
  if (d.raeder.isNotEmpty) {
    final r = d.raeder.last;
    b.writeln(
      'Lebensrad (${r.tag}): ${[for (final x in radBereiche) '$x ${r.werte[x] ?? '-'}'].join(', ')}',
    );
  }
  return b.toString();
}
