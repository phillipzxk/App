import '../checkin/checkin.dart' show dayKey;
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

/// The JSON for the widgets. [punkte] are today's points from "Dein Tag";
/// getting up is left out because it is over when the day starts.
Map<String, Object?> widgetDaten({
  required DateTime jetzt,
  required String name,
  required List<BogenPunkt> punkte,
  required bool checkinHeute,
  required Wochenfokus? fokus,
  required String coachAntwort,
  required double? schnitt,
  required double? trend,
  required int serie,
}) {
  final tag = DateTime(jetzt.year, jetzt.month, jetzt.day);
  final liste = [
    for (final p in punkte)
      if (p.art != 'Aufstehen') p,
  ]..sort((a, b) => a.minute.compareTo(b.minute));
  String? zeitVon(String art, {String? id}) {
    for (final p in liste) {
      if (p.art == art && (id == null || p.id == id)) {
        final m = p.minute % 1440;
        return '${(m ~/ 60).toString().padLeft(2, '0')}:'
            '${(m % 60).toString().padLeft(2, '0')}';
      }
    }
    return null;
  }

  String? trainingName;
  for (final p in liste) {
    if (p.art == 'Training') trainingName = p.titel;
  }
  final f = fokus != null && !fokus.vorbei(jetzt) ? fokus : null;
  return {
    'tag': dayKey(jetzt),
    'name': name,
    'checkin': checkinHeute,
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
    'fokus': f == null
        ? null
        : {
            'text': f.text,
            'start': dayKey(f.start),
            'geschafft': f.geschafft.toList()..sort(),
          },
    'coach': kernSatz(coachAntwort),
    'schnitt': schnitt,
    'trend': trend,
    'serie': serie,
    'training': trainingName,
    'trainingZeit': zeitVon('Training'),
    'bett': zeitVon('Schlaf', id: 'bett'),
  };
}
