import '../bereiche/aufbau_logik.dart';
import '../checkin/checkin.dart';
import '../feed/fokus.dart';
import '../home/sonnenbogen.dart' show BogenPunkt;

/// What the widgets on the phone's home and lock screen show (vault
/// Umsetzung/Widgets.md, confirmed 2026-11-14). The app writes this as one
/// JSON text; the widget reads it and works out by itself what is next, so
/// it stays right during the day without the app being opened.

/// Where a tap on a point of the day leads.
String widgetZiel(String art) => switch (art) {
  'Training' => 'training',
  'Essen' || 'Supplement' => 'ernaehrung',
  'Schlaf' => 'schlaf',
  _ => 'tag',
};

/// The coach's key point for the wide widget: the first sentence of the
/// reply, with the second one if both are short.
String kernSatz(String antwort, {int max = 110}) {
  final t = antwort.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.isEmpty) return '';
  final saetze = [
    for (final m in RegExp(r'[^.!?]+[.!?]+').allMatches(t)) m[0]!.trim(),
  ];
  var s = saetze.isEmpty ? t : saetze.first;
  if (saetze.length > 1 && s.length + 1 + saetze[1].length <= max) {
    s = '$s ${saetze[1]}';
  }
  return s.length <= max ? s : '${s.substring(0, max - 1)}…';
}

/// Monday to Sunday of the week of [tag]: a day counts when it has a
/// check-in and, while the week's focus ran on it, the focus was ticked.
List<bool> wochenKreise(
  List<CheckIn> checkIns,
  Wochenfokus? fokus,
  DateTime tag,
) {
  final da = {for (final c in checkIns) dayKey(c.datum)};
  final fokusTage = {
    if (fokus != null)
      for (var i = 1; i <= Wochenfokus.tage; i++) fokus.tagKey(i),
  };
  final mo = DateTime(tag.year, tag.month, tag.day - (tag.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      () {
        final k = dayKey(DateTime(mo.year, mo.month, mo.day + i));
        return da.contains(k) &&
            (!fokusTage.contains(k) || fokus!.geschafft.contains(k));
      }(),
  ];
}

double? _tagesSchnitt(CheckIn c) {
  final w = c.werte.values.toList();
  if (w.isEmpty) return null;
  return w.reduce((a, b) => a + b) / w.length;
}

const _wochentage = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

/// The evening's honest comparison with yourself: today's mean score
/// against the same weekday of the weeks before. Null unless today beats
/// at least the last two.
String? abendVergleich(List<CheckIn> checkIns, DateTime jetzt) {
  final nachTag = {for (final c in checkIns) dayKey(c.datum): c};
  final heute = nachTag[dayKey(jetzt)];
  final h = heute == null ? null : _tagesSchnitt(heute);
  if (h == null) return null;
  var n = 0;
  for (var w = 1; w <= 12; w++) {
    final c =
        nachTag[dayKey(DateTime(jetzt.year, jetzt.month, jetzt.day - 7 * w))];
    final s = c == null ? null : _tagesSchnitt(c);
    if (s == null || s >= h) break;
    n++;
  }
  if (n < 2) return null;
  return 'Dein bester ${_wochentage[jetzt.weekday - 1]} '
      'der letzten ${n + 1} Wochen.';
}

/// The JSON for the widgets. [punkte] are today's points from "Dein Tag";
/// getting up is left out because it is over when the day starts. [lob]
/// is what was just done, praised until its time.
Map<String, Object?> widgetDaten({
  required DateTime jetzt,
  required String name,
  required List<BogenPunkt> punkte,
  required List<CheckIn> checkIns,
  required Wochenfokus? fokus,
  required String ziel,
  required String grund,
  ({String titel, DateTime bis})? lob,
}) {
  final tag = DateTime(jetzt.year, jetzt.month, jetzt.day);
  final liste = [
    for (final p in punkte)
      if (p.art != 'Aufstehen') p,
  ]..sort((a, b) => a.minute.compareTo(b.minute));
  CheckIn? heute;
  for (final c in checkIns) {
    if (dayKey(c.datum) == dayKey(jetzt)) heute = c;
  }
  final serie = serieTage([for (final c in checkIns) dayKey(c.datum)], jetzt);
  final f = fokus != null && !fokus.vorbei(jetzt) ? fokus : null;
  final vorwoche = DateTime(jetzt.year, jetzt.month, jetzt.day - 7);
  return {
    'tag': dayKey(jetzt),
    'name': name,
    'checkin': heute != null,
    'punkte': [
      for (final p in liste)
        {
          't':
              tag.add(Duration(minutes: p.minute)).millisecondsSinceEpoch ~/
              1000,
          'titel': p.titel,
          'ziel': widgetZiel(p.art),
          'erledigt': p.erledigt,
        },
    ],
    'serie': serie.jetzt,
    'rekord': serie.rekord,
    'wurzeln': f?.anzahlGeschafft ?? 0,
    'lob': lob == null || !lob.bis.isAfter(jetzt)
        ? null
        : {'titel': lob.titel, 'bis': lob.bis.millisecondsSinceEpoch ~/ 1000},
    'ziel': ziel,
    'grund': grund,
    'coach': kernSatz(heute?.kiAntwort ?? ''),
    'fokus': f == null ? null : {'text': f.text, 'start': dayKey(f.start)},
    'abend': abendVergleich(checkIns, jetzt),
    'woche': wochenKreise(checkIns, fokus, jetzt),
    'letzteWoche': wochenKreise(
      checkIns,
      fokus,
      vorwoche,
    ).where((x) => x).length,
  };
}
