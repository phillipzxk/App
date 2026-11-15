import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/feed/fokus.dart';
import 'package:coach_app/home/sonnenbogen.dart';
import 'package:coach_app/startwidget/widget_daten.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kernSatz takes the first sentence, the second one if it fits', () {
    expect(kernSatz(''), '');
    expect(
      kernSatz('Gutes Training. Heute früh ins Bett. Und noch viel mehr Text.'),
      'Gutes Training. Heute früh ins Bett.',
    );
    final lang = 'A' * 200;
    expect(kernSatz('$lang.').length, 110);
  });

  CheckIn ci(DateTime d, [int wert = 6]) => CheckIn(
    datum: d,
    training: 'Gut trainiert',
    ernaehrung: '',
    schlaf: '',
    mindset: '',
    kiAntwort: 'Phillip, heute kein Extra-Satz. Dafür um 22:40 ins Bett.',
    werte: {'training': wert, 'schlaf': wert},
  );

  test('widget data: points, streak, week circles and praise', () {
    final jetzt = DateTime(2026, 11, 14, 9, 41); // a Saturday
    final fokus = Wochenfokus(
      start: DateTime(2026, 11, 11),
      text: 'Vor 23 Uhr im Bett',
      geschafft: const {'2026-11-11', '2026-11-12'},
    );
    final d = widgetDaten(
      jetzt: jetzt,
      name: 'Phillip',
      punkte: const [
        BogenPunkt(id: 'bett', minute: 1360, art: 'Schlaf', titel: 'Bettzeit'),
        BogenPunkt(id: 'a', minute: 420, art: 'Aufstehen', titel: 'Aufstehen'),
        BogenPunkt(
          id: 'training',
          minute: 1050,
          art: 'Training',
          titel: 'Push',
        ),
        BogenPunkt(
          id: 'supp-1',
          minute: 480,
          art: 'Supplement',
          titel: 'Kreatin',
          erledigt: true,
        ),
      ],
      checkIns: [
        for (final t in [9, 10, 11, 12, 13, 14]) ci(DateTime(2026, 11, t)),
      ],
      fokus: fokus,
      ziel: 'Mehr Muskeln',
      grund: 'Nicht mehr stehen bleiben',
      lob: (titel: 'Kreatin', bis: DateTime(2026, 11, 14, 10, 30)),
    );
    expect(d['tag'], '2026-11-14');
    final punkte = d['punkte']! as List;
    expect(
      [for (final p in punkte) (p as Map)['titel']],
      ['Kreatin', 'Push', 'Bettzeit'],
    );
    expect((punkte[1] as Map)['ziel'], 'training');
    expect(
      (punkte[1] as Map)['t'],
      DateTime(2026, 11, 14, 17, 30).millisecondsSinceEpoch ~/ 1000,
    );
    expect(d['checkin'], true);
    expect(d['serie'], 6);
    expect(d['rekord'], 6);
    expect(d['wurzeln'], 2);
    expect((d['lob']! as Map)['titel'], 'Kreatin');
    expect((d['fokus']! as Map)['start'], '2026-11-11');
    expect(
      d['coach'],
      'Phillip, heute kein Extra-Satz. Dafür um 22:40 ins Bett.',
    );
    // Mon 9 and Tue 10: check-in, no focus yet. Wed 11, Thu 12: focus
    // ticked. Fri 13 and Sat 14: check-in but focus not ticked.
    expect(d['woche'], [true, true, true, true, false, false, false]);
    expect(d['letzteWoche'], 0);
  });

  test('praise that is over and a focus that is over are not sent', () {
    final d = widgetDaten(
      jetzt: DateTime(2026, 11, 14, 12),
      name: '',
      punkte: const [],
      checkIns: const [],
      fokus: Wochenfokus(start: DateTime(2026, 11, 1), text: 'Alt'),
      ziel: '',
      grund: '',
      lob: (titel: 'Push', bis: DateTime(2026, 11, 14, 11)),
    );
    expect(d['fokus'], isNull);
    expect(d['lob'], isNull);
    expect(d['serie'], 0);
    expect(d['abend'], isNull);
  });

  test('evening comparison only when today beats the last two weeks', () {
    final jetzt = DateTime(2026, 11, 14, 20);
    expect(abendVergleich([ci(jetzt, 8)], jetzt), isNull);
    expect(
      abendVergleich([
        ci(DateTime(2026, 10, 31), 5),
        ci(DateTime(2026, 11, 7), 6),
        ci(jetzt, 8),
      ], jetzt),
      'Dein bester Samstag der letzten 3 Wochen.',
    );
    expect(
      abendVergleich([
        ci(DateTime(2026, 10, 31), 5),
        ci(DateTime(2026, 11, 7), 9),
        ci(jetzt, 8),
      ], jetzt),
      isNull,
    );
  });
}
