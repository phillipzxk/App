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

  test('widget data: points of today without getting up, sorted', () {
    final jetzt = DateTime(2026, 11, 14, 9, 41);
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
      checkinHeute: true,
      fokus: Wochenfokus(
        start: DateTime(2026, 11, 11),
        text: 'Vor 23 Uhr im Bett',
        geschafft: const {'2026-11-11', '2026-11-12'},
      ),
      coachAntwort: 'Phillip, heute kein Extra-Satz. Dafür um 22:40 ins Bett.',
      schnitt: 7,
      trend: 0.5,
      serie: 4,
    );
    expect(d['tag'], '2026-11-14');
    final punkte = d['punkte']! as List;
    expect(
      [for (final p in punkte) (p as Map)['titel']],
      ['Kreatin', 'Push', 'Bettzeit'],
    );
    expect((punkte[0] as Map)['erledigt'], true);
    expect((punkte[1] as Map)['ziel'], 'training');
    expect(
      (punkte[1] as Map)['t'],
      DateTime(2026, 11, 14, 17, 30).millisecondsSinceEpoch ~/ 1000,
    );
    expect(d['trainingZeit'], '17:30');
    expect(d['bett'], '22:40');
    expect((d['fokus']! as Map)['start'], '2026-11-11');
    expect(
      d['coach'],
      'Phillip, heute kein Extra-Satz. Dafür um 22:40 ins Bett.',
    );
  });

  test('a focus that is over is not sent', () {
    final d = widgetDaten(
      jetzt: DateTime(2026, 11, 14),
      name: '',
      punkte: const [],
      checkinHeute: false,
      fokus: Wochenfokus(start: DateTime(2026, 11, 1), text: 'Alt'),
      coachAntwort: '',
      schnitt: null,
      trend: null,
      serie: 0,
    );
    expect(d['fokus'], isNull);
    expect(d['bett'], isNull);
  });
}
