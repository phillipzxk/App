import 'dart:math' as math;

import '../sleep/schlafzeiten.dart';
import '../weight/weight.dart';
import 'ernaehrung_data.dart';

/// One planned meal of today.
class MahlzeitSlot {
  const MahlzeitSlot({
    required this.id,
    required this.name,
    required this.minute,
    required this.snack,
    required this.tipp,
  });

  final String id;
  final String name;

  /// Minutes after midnight (may pass 1440 for late evenings).
  final int minute;
  final bool snack;
  final String tipp;

  String get groesse => snack ? 'kleiner Snack' : 'Hauptmahlzeit';
  String get uhrzeit => formatUhrzeit(minute % 1440);
}

String _snackName(int m) {
  final h = (m % 1440) / 60;
  if (h < 11) return 'Zweites Frühstück';
  if (h < 17) return 'Snack am Nachmittag';
  return 'Snack am Abend';
}

String _tipp(String art, bool trainingstag, String name) => switch (art) {
  'fruehstueck' =>
    trainingstag
        ? 'Eiweiß rein, du trainierst heute.'
        : 'Ruhig starten, mit Eiweiß, dann hält es länger.',
  'mittag' => 'Normal essen, nicht zu schwer, dann bleibst du wach.',
  'vor' => 'Etwas Leichtes mit Kohlenhydraten, 1 bis 2 Stunden vorher.',
  'nach' => 'Viel Eiweiß, das hilft der Erholung.',
  'abend' => 'Nicht zu spät und nicht zu schwer, dann schläfst du besser.',
  _ =>
    name == 'Snack am Abend'
        ? 'Klein halten: Quark oder Obst reicht.'
        : 'Obst, Quark oder Nüsse, damit du nicht mit Riesenhunger ankommst.',
};

/// Today's meals (idea A, Phillip 2026-10-27): breakfast after getting up,
/// around training a snack before and a main meal after, otherwise dinner
/// 2.5 hours before bed; the rest fills the biggest gaps. Times the user
/// dragged win.
List<MahlzeitSlot> planeMahlzeiten({
  required int anzahl,
  required int start,
  required int ende,
  int? training,
  Map<String, int> verschoben = const {},
}) {
  if (anzahl <= 0) return const [];
  final von = start + 30;
  final bis = math.max(von + 60, ende - 150);
  var t = training;
  if (t != null && t < start) t += 1440;
  final mitTraining = t != null && t >= von + 90 && t + 60 <= ende - 60;
  final anker = <(int, String)>[];
  if (anzahl == 1) {
    anker.add(((von + bis) ~/ 2, 'mittag'));
  } else {
    anker.add((von, 'fruehstueck'));
    if (mitTraining) {
      if (anzahl >= 3) anker.add((t - 90, 'vor'));
      anker.add((math.min(t + 90, ende - 60), 'nach'));
    } else {
      anker.add((bis, 'abend'));
    }
  }
  var snacks = 0;
  while (anker.length < anzahl) {
    anker.sort((a, b) => a.$1.compareTo(b.$1));
    var gross = 0, bei = 0;
    for (var i = 0; i + 1 < anker.length; i++) {
      final g = anker[i + 1].$1 - anker[i].$1;
      if (g > gross) {
        gross = g;
        bei = i;
      }
    }
    final m = anker[bei].$1 + gross ~/ 2;
    final h = (m % 1440) / 60;
    final mittagFrei = !anker.any((a) => a.$2 == 'mittag');
    anker.add((m, mittagFrei && h >= 11 && h <= 14.5 ? 'mittag' : 'snack'));
  }
  final slots = <MahlzeitSlot>[];
  for (final (minute, art) in anker) {
    final id = art == 'snack' ? 'snack${++snacks}' : art;
    final name = switch (art) {
      'fruehstueck' => 'Frühstück',
      'mittag' => 'Mittag',
      'vor' => 'Vor dem Training',
      'nach' => 'Nach dem Training',
      'abend' => 'Abendessen',
      _ => _snackName(minute),
    };
    slots.add(
      MahlzeitSlot(
        id: id,
        name: name,
        minute: verschoben[id] ?? minute,
        snack: art == 'snack' || art == 'vor',
        tipp: _tipp(art, mitTraining, name),
      ),
    );
  }
  slots.sort((a, b) => a.minute.compareTo(b.minute));
  return slots;
}

/// The expected energy (0..1) at a minute of the day: up after getting up,
/// a small dip after lunch time, down before bed; every meal lifts it,
/// training uses it up, harder without food before.
double energieBei(
  double minute, {
  required List<MahlzeitSlot> mahlzeiten,
  required int start,
  required int ende,
  int? training,
  double? schlaf,
}) {
  final h = minute / 60;
  final s = start / 60, e = ende / 60;
  var x =
      0.35 +
      0.4 * ((h - s) / 2).clamp(0.0, 1.0) -
      0.1 * math.exp(-math.pow(h - 14.5, 2) / 1.2) -
      0.25 * math.max(0, (h - (e - 3)) / 3);
  if (schlaf != null && schlaf < 6) x -= 0.12;
  for (final m in mahlzeiten) {
    final d = h - m.minute / 60;
    if (d > 0) {
      x += (m.snack ? 0.16 : 0.22) * math.exp(-d / 2.2) * math.min(1, d / 0.7);
    } else {
      x -= 0.04 * math.exp(d / 1.5);
    }
  }
  if (training != null) {
    final t = training / 60;
    if (h > t && h < t + 1.2) {
      final gegessen = mahlzeiten.any(
        (m) => m.minute / 60 < t && t - m.minute / 60 < 3.2,
      );
      x -= gegessen ? 0.08 : 0.28;
    }
  }
  return x.clamp(0.05, 0.98).toDouble();
}

/// The coach line under the curve, computed from the meal times.
String energieSatz(List<MahlzeitSlot> mahlzeiten, {int? training, int? ende}) {
  if (mahlzeiten.isEmpty) {
    return 'Leg fest, wie oft du am Tag isst, dann siehst du hier deine '
        'Energie über den Tag.';
  }
  if (training != null) {
    MahlzeitSlot? davor;
    for (final m in mahlzeiten) {
      if (m.minute < training) davor = m;
    }
    final t = formatUhrzeit(training % 1440);
    if (davor == null || training - davor.minute > 195) {
      return 'Vor dem Training um $t ist zu lange nichts eingeplant, dann ist '
          'der Tank leer. Siehst du den Knick? Zieh eine Mahlzeit näher ran.';
    }
    if (training - davor.minute < 45) {
      return '${davor.uhrzeit} ist zu knapp vor dem Training, das liegt dir '
          'dann im Magen. Etwas früher passt besser.';
    }
    return '${davor.name} um ${davor.uhrzeit}: Du gehst mit voller Energie '
        'ins Training.';
  }
  final letzte = mahlzeiten.last;
  if (ende != null && ende - letzte.minute < 90) {
    return '${letzte.name} um ${letzte.uhrzeit} ist sehr spät, das kann '
        'deinen Schlaf stören.';
  }
  for (var i = 0; i + 1 < mahlzeiten.length; i++) {
    if (mahlzeiten[i + 1].minute - mahlzeiten[i].minute > 300) {
      return 'Zwischen ${mahlzeiten[i].uhrzeit} und '
          '${mahlzeiten[i + 1].uhrzeit} ist eine lange Lücke, da kommt der '
          'Hunger. Ein Snack dazwischen hilft.';
    }
  }
  return 'Deine Mahlzeiten sind gut über den Tag verteilt, so bleibt deine '
      'Energie stabil.';
}

/// Idea B: one plate for the whole day, filled per eaten meal in protein,
/// vegetables and energy (0..1). Without a photo a meal counts with what a
/// normal meal of its kind brings; a photo uses the coach's read.
({double eiweiss, double gemuese, double energie}) tagesTeller(
  List<MahlzeitSlot> mahlzeiten,
  Map<String, MahlzeitEintrag> eintraege,
) {
  if (mahlzeiten.isEmpty) return (eiweiss: 0, gemuese: 0, energie: 0);
  var summe = 0.0, ei = 0.0, ge = 0.0, en = 0.0;
  for (final m in mahlzeiten) {
    final w = m.snack ? 0.4 : 1.0;
    summe += w;
    final e = eintraege[m.id];
    if (e == null || !e.gegessen) continue;
    final h = e.teller;
    ei += w * (h == null ? (m.snack ? 0.5 : 0.9) : h.eiweiss / 3);
    ge += w * (h == null ? (m.snack ? 0.3 : 0.7) : h.gemuese / 3);
    en += w * (h == null ? 1.0 : h.groesse / 3);
  }
  return (
    eiweiss: (ei / summe).clamp(0, 1).toDouble(),
    gemuese: (ge / summe).clamp(0, 1).toDouble(),
    energie: (en / summe).clamp(0, 1).toDouble(),
  );
}

String tellerWort(double x) => x >= 0.95
    ? 'voll'
    : x >= 0.65
    ? 'fast voll'
    : x >= 0.35
    ? 'halb'
    : x > 0
    ? 'wenig'
    : 'leer';

/// What the coach says under the plate.
String tellerSatz(
  ({double eiweiss, double gemuese, double energie}) t, {
  required int gegessen,
  required int geplant,
}) {
  if (geplant == 0) {
    return 'Leg fest, wie oft du isst, dann füllt sich hier dein Teller.';
  }
  if (gegessen == 0) {
    return 'Noch leer. Tipp nach dem Essen auf den Kreis, dann füllt sich '
        'dein Teller.';
  }
  final werte = {
    'Eiweiß': t.eiweiss,
    'Gemüse': t.gemuese,
    'Energie': t.energie,
  };
  final wenig = werte.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  if (gegessen >= geplant) {
    return werte.values.every((v) => v >= 0.65)
        ? 'Rundum gut gegessen heute.'
        : '$wenig war heute am wenigsten dabei. Morgen einfach bei einer '
              'Mahlzeit eine Handvoll mehr davon.';
  }
  return 'Bisher am wenigsten: $wenig. ${switch (wenig) {
    'Gemüse' => 'Bei der nächsten Mahlzeit eine Handvoll Gemüse dazu.',
    'Eiweiß' => 'Bei der nächsten Mahlzeit ordentlich Eiweiß, dann passt es.',
    _ => 'Iss die nächste Mahlzeit ganz, nicht nur nebenbei.',
  }}';
}

/// One line of the shopping list.
class EinkaufPosten {
  EinkaufPosten({
    required this.name,
    required this.einheit,
    required this.gruppe,
    this.menge,
  });

  final String name;
  final String einheit;
  final String gruppe;
  double? menge;
  final fuer = <String>[];

  String get key => '${name.toLowerCase()}|$einheit';

  String get mengeText {
    final m = menge;
    if (m == null || m == 0) return '';
    String z(double v) => v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1).replaceAll('.', ',');
    if ((einheit == 'g' || einheit == 'ml') && m >= 1000) {
      return '${z(m / 1000)} ${einheit == 'g' ? 'kg' : 'l'}';
    }
    return einheit.isEmpty ? z(m) : '${z(m)} $einheit';
  }
}

/// The ingredients of all dishes of the week, added up per ingredient and
/// sorted by group, then the user's own items.
List<EinkaufPosten> einkaufsliste(ErnaehrungDaten d) {
  final posten = <String, EinkaufPosten>{};
  for (final e in d.einkauf.auswahl.entries) {
    final g = d.gericht(e.key);
    if (g == null || e.value <= 0) continue;
    for (final z in g.zutaten) {
      final p = posten.putIfAbsent(
        '${z.name.toLowerCase()}|${z.einheit}',
        () => EinkaufPosten(
          name: z.name,
          einheit: z.einheit,
          gruppe: z.gruppe,
          menge: z.menge == null ? null : 0,
        ),
      );
      if (z.menge != null) p.menge = (p.menge ?? 0) + z.menge! * e.value;
      if (!p.fuer.contains(g.name)) p.fuer.add(g.name);
    }
  }
  final liste = posten.values.toList()
    ..sort((a, b) {
      final g = Zutat.gruppen
          .indexOf(a.gruppe)
          .compareTo(Zutat.gruppen.indexOf(b.gruppe));
      return g != 0 ? g : a.name.compareTo(b.name);
    });
  return [
    ...liste,
    for (final x in d.einkauf.eigene)
      EinkaufPosten(name: x, einheit: '', gruppe: 'Eigenes'),
  ];
}

/// Idea E: every dish cooked and kept is a leaf.
int kochbuchBlaetter(ErnaehrungDaten d) =>
    d.gerichte.where((g) => g.imKochbuch).length;

/// How often the user has cooked anything from the cookbook.
int kochenGesamt(ErnaehrungDaten d) =>
    d.gerichte.fold(0, (s, g) => s + g.gekocht);

/// From this many leaves the user builds own variants.
const variantenAb = 7;

/// Unlocks locked dishes once the user has cooked enough.
ErnaehrungDaten freischalten(ErnaehrungDaten d) {
  final n = kochenGesamt(d);
  if (!d.gerichte.any((g) => g.freiAb != null && g.freiAb! <= n)) return d;
  return d.copyWith(
    gerichte: [
      for (final g in d.gerichte)
        g.freiAb != null && g.freiAb! <= n ? g.copyWith(freigeben: true) : g,
    ],
  );
}

/// Cooked once more, with a rating. "nicht meins" removes a coach dish.
ErnaehrungDaten gekocht(ErnaehrungDaten d, String id, String bewertung) {
  final g = d.gericht(id);
  if (g == null) return d;
  if (bewertung == 'nicht meins' && g.quelle != 'eigen') {
    return d.copyWith(gerichte: [...d.gerichte.where((x) => x.id != id)]);
  }
  return freischalten(
    d.mitGericht(g.copyWith(gekocht: g.gekocht + 1, bewertung: bewertung)),
  );
}

/// The direction of the onboarding goal: +1 build up, -1 lose, 0 keep.
int zielRichtung(String ziel) {
  final z = ziel.toLowerCase();
  if (RegExp(r'abnehm|fett|definier|schlank|abspeck|weniger wieg|cut')
      .hasMatch(z)) {
    return -1;
  }
  if (RegExp(r'muskel|aufbau|zunehm|masse|stärker|kraft|bulk').hasMatch(z)) {
    return 1;
  }
  return 0;
}

/// Idea 6: whether the weight needs a Gewichts-Check now: over the last
/// 3 weeks it did not move towards the goal, or moved too fast. At most
/// every 3 weeks.
({String lage, String text})? gewichtsLage(
  List<WeightEntry> weights,
  String ziel,
  ErnaehrungDaten d,
  DateTime heute,
) {
  if (d.gewicht.isNotEmpty) {
    final letzter = DateTime.parse(d.gewicht.last.tag);
    if (heute.difference(letzter).inDays < 21) return null;
  }
  final w = weeklyAverages(weights);
  if (w.length < 4) return null;
  final jetzt = w.last.kg;
  final diff = jetzt - w[w.length - 4].kg;
  final r = zielRichtung(ziel);
  if (r > 0 && diff < 0.3) {
    return (
      lage: 'steht',
      text: 'Dein Gewicht bewegt sich seit 3 Wochen kaum.',
    );
  }
  if (r < 0 && diff > -0.3) {
    return (
      lage: 'steht',
      text: 'Dein Gewicht bewegt sich seit 3 Wochen kaum.',
    );
  }
  if (r < 0 && diff < -0.03 * jetzt) {
    return (
      lage: 'zu schnell',
      text: 'Dein Gewicht geht gerade sehr schnell runter.',
    );
  }
  if (r > 0 && diff > 1.5) {
    return (
      lage: 'zu schnell',
      text: 'Dein Gewicht geht gerade sehr schnell hoch.',
    );
  }
  if (r == 0 && diff.abs() > 1.5) {
    return (
      lage: 'weg',
      text: 'Dein Gewicht hat sich in 3 Wochen um mehr als 1,5 kg verändert.',
    );
  }
  return null;
}

/// The answers the user can give first in the Gewichts-Check.
List<String> gewichtsGruende(String lage, int richtung) => lage == 'zu schnell'
    ? [
        'Esse gerade wenig',
        'Viel Stress',
        'Mehr Sport als sonst',
        'Keine Ahnung',
      ]
    : [
        'Am Wochenende mehr',
        'Abends Heißhunger',
        'Weniger trainiert',
        if (richtung > 0) 'Esse eher zu wenig' else 'Esse eher zu viel',
        'Keine Ahnung',
      ];

/// Without the coach: 200 kcal towards the goal.
int kcalVorschlagOhneCoach(int kcal, String lage, int richtung) {
  final r = lage == 'zu schnell' ? -richtung : (richtung == 0 ? -1 : richtung);
  return kcal + 200 * r;
}
