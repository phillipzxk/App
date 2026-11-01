import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/erinnerungen/erinnerung_plan.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/fokus.dart';
import 'package:coach_app/planner/planner_data.dart';
import 'package:coach_app/sleep/schlafzeiten.dart';
import 'package:coach_app/supplements/supplement_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 4 November 2026, 6:00.
  final jetzt = DateTime(2026, 11, 4, 6);
  const schlaf = Schlafzeiten(werktag: 7 * 60, wochenende: 9 * 60, stunden: 8);

  List<Erinnerung> heute(List<Erinnerung> l) => [
    for (final e in l)
      if (e.zeit.day == jetzt.day) e,
  ];

  test(
    'normal day: alarm, check-in, supplements, training, focus, evening',
    () {
      final plan = TrainingPlan([
        'Push 17:30\nBankdrücken 3 × 8 80 kg',
        'Push 17:30\nBankdrücken 3 × 8 80 kg',
        'Pull 18:00',
        '',
        '',
        '',
        '',
      ]);
      final l = planeErinnerungen(
        ErinnerungsLage(
          jetzt: jetzt,
          name: 'Phillip',
          schlafzeiten: schlaf,
          plan: plan,
          supplements: const [
            Supplement(zeit: '08:00', name: 'Kreatin'),
            Supplement(zeit: '08:00', name: 'Vitamin D'),
          ],
          termine: [parseTermin('Zahnarzt 14 Uhr', jetzt)],
          fokus: Wochenfokus(
            start: DateTime(2026, 11, 1),
            text: 'Handy nach 21 Uhr weg',
          ),
        ),
      );
      final t = heute(l);
      final arten = [for (final e in t) e.art];
      expect(arten, [
        ErinnerungArt.wecker,
        ErinnerungArt.checkin,
        ErinnerungArt.supplements,
        ErinnerungArt.termine,
        ErinnerungArt.training,
        ErinnerungArt.fokus,
        ErinnerungArt.abend,
      ]);
      expect(t[1].zeit, DateTime(2026, 11, 4, 7, 20));
      expect(t[1].text, contains('Phillip'));
      expect(t[2].text, 'Kreatin und Vitamin D sind noch offen.');
      expect(t[2].daten, '08:00|Kreatin;08:00|Vitamin D');
      expect(t[3].zeit, DateTime(2026, 11, 4, 13, 30));
      expect(t[4].zeit, DateTime(2026, 11, 4, 17));
      expect(t[4].titel, 'Pull 18:00');
      expect(t[5].text, 'Handy nach 21 Uhr weg. Tag 4 von 7. Heute geschafft?');
      // Bed 23:00 (7:00 tomorrow minus 8 h), reminder 30 min before.
      expect(t[6].zeit, DateTime(2026, 11, 4, 22, 30));
      expect(t[6].text, contains('Bettzeit 23:00'));
    },
  );

  test('only what is still open', () {
    final l = planeErinnerungen(
      ErinnerungsLage(
        jetzt: jetzt,
        name: 'Phillip',
        schlafzeiten: schlaf,
        checkinHeute: true,
        supplements: const [Supplement(zeit: '08:00', name: 'Kreatin')],
        genommenHeute: const {'08:00|Kreatin'},
        fokus: Wochenfokus(
          start: DateTime(2026, 11, 1),
          text: 'X',
          geschafft: {dayKey(jetzt)},
        ),
      ),
    );
    final arten = {for (final e in heute(l)) e.art};
    expect(arten.contains(ErinnerungArt.checkin), isFalse);
    expect(arten.contains(ErinnerungArt.supplements), isFalse);
    expect(arten.contains(ErinnerungArt.fokus), isFalse);
    // Tomorrow they are open again.
    final morgen = [
      for (final e in l)
        if (e.zeit.day == 5) e.art,
    ];
    expect(morgen, contains(ErinnerungArt.checkin));
    expect(morgen, contains(ErinnerungArt.supplements));
  });

  test('quiet after Gute Nacht until the alarm', () {
    final abends = DateTime(2026, 11, 4, 22, 40);
    final l = planeErinnerungen(
      ErinnerungsLage(
        jetzt: abends,
        name: 'P',
        schlafzeiten: schlaf,
        supplements: const [Supplement(zeit: '23:30', name: 'Magnesium')],
        ruheBis: DateTime(2026, 11, 5, 7),
      ),
    );
    expect(l.first.art, ErinnerungArt.wecker);
    expect(l.first.zeit, DateTime(2026, 11, 5, 7));
    // Nothing after bedtime either, also without Gute Nacht.
    final ohne = planeErinnerungen(
      ErinnerungsLage(
        jetzt: abends,
        name: 'P',
        schlafzeiten: schlaf,
        supplements: const [Supplement(zeit: '23:30', name: 'Magnesium')],
      ),
    );
    expect(ohne.first.art, ErinnerungArt.wecker);
  });

  test('at most 5 a day; appointments and alarm do not count', () {
    final supps = [
      for (final z in ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00'])
        Supplement(zeit: z, name: 'S$z'),
    ];
    final l = heute(
      planeErinnerungen(
        ErinnerungsLage(
          jetzt: jetzt,
          name: 'P',
          schlafzeiten: schlaf,
          supplements: supps,
          termine: [
            parseTermin('A 10 Uhr', jetzt),
            parseTermin('B 15 Uhr', jetzt),
          ],
        ),
      ),
    );
    expect(l.where((e) => e.zaehlt).length, lessThanOrEqualTo(proTag));
    final s = l.where((e) => e.art == ErinnerungArt.supplements).toList();
    expect(s, hasLength(1));
    expect(s.single.daten.split(';'), hasLength(6));
    expect(l.where((e) => e.art == ErinnerungArt.termine), hasLength(2));
    expect(l.where((e) => e.art == ErinnerungArt.wecker), hasLength(1));
  });

  test('switched off kinds are left out', () {
    final l = planeErinnerungen(
      ErinnerungsLage(
        jetzt: jetzt,
        name: 'P',
        schlafzeiten: schlaf,
        einstellungen: const ErinnerungEinstellungen(
          aus: {ErinnerungArt.wecker, ErinnerungArt.checkin},
        ),
      ),
    );
    expect(l.any((e) => e.art == ErinnerungArt.wecker), isFalse);
    expect(l.any((e) => e.art == ErinnerungArt.checkin), isFalse);
    expect(l.any((e) => e.art == ErinnerungArt.abend), isTrue);
  });

  test('Reality Check on day 8 of the focus', () {
    final l = heute(
      planeErinnerungen(
        ErinnerungsLage(
          jetzt: jetzt,
          name: 'P',
          schlafzeiten: schlaf,
          fokus: Wochenfokus(start: DateTime(2026, 10, 28), text: 'X'),
        ),
      ),
    );
    expect(l.any((e) => e.art == ErinnerungArt.reality), isTrue);
    expect(l.any((e) => e.art == ErinnerungArt.fokus), isFalse);
  });

  test('settings survive saving', () {
    const e = ErinnerungEinstellungen(aus: {ErinnerungArt.foto}, grenze: false);
    final z = ErinnerungEinstellungen.fromJson(e.toJson());
    expect(z.an(ErinnerungArt.foto), isFalse);
    expect(z.an(ErinnerungArt.wecker), isTrue);
    expect(z.grenze, isFalse);
  });
}
