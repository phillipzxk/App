import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/schlaf/abend.dart';
import 'package:coach_app/schlaf/schlaf_data.dart';
import 'package:coach_app/schlaf/schlaf_logik.dart';
import 'package:coach_app/sleep/schlafzeiten.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(
  name: 'Phillip',
  ziel: 'Muskeln aufbauen',
  motivation: 'Stolz sein.',
);

void main() {
  group('logic', () {
    test('sleep score: good night high, short broken night low', () {
      final gut = schlafwert(
        stunden: 8,
        brauch: 8,
        himmel: 90,
        tags: const ['Gut eingeschlafen'],
        abweichung: 0,
      );
      final schlecht = schlafwert(
        stunden: 5,
        brauch: 8,
        himmel: 15,
        tags: const ['Öfter wach', 'Lange wach gelegen'],
        abweichung: 90,
      );
      expect(gut.wert, greaterThan(80));
      expect(schlecht.wert, lessThan(50));
      expect(gut.wert, inInclusiveRange(1, 100));
      expect(gut.teile.keys, containsAll(teilNamen.keys));
    });

    test('energy forecast: high in the morning part, low after lunch', () {
      final e = energieTag(aufstehen: 390, bett: 22 * 60 + 30, wert: 80);
      expect(e.hoch.$1, greaterThan(390));
      expect(e.hoch.$1, lessThan(390 + 8 * 60));
      expect(e.tief, greaterThan(e.hoch.$1));
      expect(e.werte.first.$1, 390);
    });

    test('sunrise is later in December than in June', () {
      expect(
        sonnenaufgang(DateTime(2026, 12, 20)),
        greaterThan(sonnenaufgang(DateTime(2026, 6, 20))),
      );
      expect(nochDunkel(DateTime(2026, 12, 20), 6 * 60), isTrue);
      expect(nochDunkel(DateTime(2026, 6, 20), 7 * 60), isFalse);
    });

    test('next alarm: tomorrow in the evening, today at night', () {
      expect(
        naechsterWecker(DateTime(2026, 10, 12, 22), 390),
        DateTime(2026, 10, 13, 6, 30),
      );
      expect(
        naechsterWecker(DateTime(2026, 10, 13, 1), 390),
        DateTime(2026, 10, 13, 6, 30),
      );
    });

    test(
      'day without the coach: sorted, light first, ends with Gute Nacht',
      () {
        final p = ablaufOhneCoach(
          aufstehen: 390,
          bett: 22 * 60 + 30,
          hoch: (570, 750),
          tief: 840,
          training: 17 * 60 + 30,
          trainingName: 'Push',
          mahlzeiten: const [(420, 'Frühstück')],
        );
        for (var i = 1; i < p.length; i++) {
          expect(p[i].minute, greaterThanOrEqualTo(p[i - 1].minute));
        }
        expect(p[1].was, '5 Min Sonnenlicht');
        expect(p.last.was, 'Gute Nacht');
        expect(p.any((x) => x.was == 'Training: Push'), isTrue);
      },
    );

    test('journal is complete only with all 6 fields', () {
      expect(
        const Journal(
          tag: 't',
          dankbar: ['a', 'b', 'c'],
          besser: ['d', 'e', ''],
        ).fertig,
        isFalse,
      );
      expect(
        const Journal(
          tag: 't',
          dankbar: ['a', 'b', 'c'],
          besser: ['d', 'e', 'f'],
        ).fertig,
        isTrue,
      );
    });

    test('everything survives saving', () {
      final d = SchlafDaten(
        morgen: const [
          Morgen(
            tag: '2026-10-12',
            himmel: 70,
            tags: ['Einmal wach'],
            stunden: 7.25,
            wert: 74,
            teile: {'laenge': 80},
            satz: 'Gut.',
          ),
        ],
        journal: [
          Journal(
            tag: '2026-10-11',
            dankbar: const ['a', 'b', 'c'],
            besser: const ['d', 'e', 'f'],
            guteNacht: DateTime(2026, 10, 11, 22, 40),
          ),
        ],
        energie: const [EnergieMeldung(tag: '2026-10-12', wie: 'Besser')],
        wecker: const Wecker(aufgabe: 'schritte', klang: 'Regen'),
        lampe: true,
        muster: const [SchlafMuster(text: 'Licht hilft', gut: true)],
        besteZeit: (typ: 'Eher Morgenmensch', text: 'Hoch 9 bis 12'),
        ablauf: const Tagesablauf(
          tag: '2026-10-12',
          punkte: [AblaufPunkt(minute: 390, was: 'Aufstehen')],
          uebernommen: true,
        ),
        ruheBis: DateTime(2026, 10, 13, 6, 30),
      );
      final z = SchlafDaten.fromJson(d.toJson());
      expect(z.morgen.single.wert, 74);
      expect(z.journal.single.guteNacht, DateTime(2026, 10, 11, 22, 40));
      expect(z.energieAm('2026-10-12'), 'Besser');
      expect(z.wecker.aufgabe, 'schritte');
      expect(z.lampe, isTrue);
      expect(z.besteZeit!.typ, 'Eher Morgenmensch');
      expect(z.ablauf!.uebernommen, isTrue);
      expect(z.ruheBis, DateTime(2026, 10, 13, 6, 30));
    });
  });

  group('page', () {
    Future<(MemoryDiaryStore, MemoryFeedStore)> start(
      WidgetTester tester, {
      DateTime? jetzt,
      SchlafDaten? daten,
      bool seite = true,
    }) async {
      final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
      final feed = MemoryFeedStore()
        ..schlafzeiten = const Schlafzeiten(werktag: 390, stunden: 8);
      if (daten != null) feed.schlaf = daten;
      tallView(tester);
      final t = jetzt ?? fixedNow;
      await tester.pumpWidget(
        CoachApp(
          store: MemoryProfileStore(_profile),
          diary: diary,
          feed: feed,
          clock: () => t,
        ),
      );
      await tester.pumpAndSettle();
      if (seite) await openTab(tester, 'Schlaf');
      return (diary, feed);
    }

    // Tiles on the new Körper page that open these parts directly.
    const direkt = {
      'wie-geschlafen': 's-himmel',
      'kachel-journal': 's-journal',
      'kachel-wecker': 's-wecker',
      'kachel-tag': 's-tag',
      'muster-oeffnen': 's-muster',
    };
    Future<void> tippe(WidgetTester tester, String key) async {
      final kachel = direkt[key];
      final aufSeite = find
          .byKey(const ValueKey('bereich-zurueck'))
          .evaluate()
          .isNotEmpty;
      if (kachel != null && aufSeite) {
        await openKachel(tester, kachel);
        return;
      }
      if (key == 'energie-Besser' &&
          find.byKey(ValueKey(key)).evaluate().isEmpty) {
        await openKachel(tester, 'p-energie');
      }
      final f = find.byKey(ValueKey(key));
      await scrollTo(tester, f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('morning entry gives the sleep score and saves the hours', (
      tester,
    ) async {
      final (diary, feed) = await start(
        tester,
        jetzt: DateTime(2026, 10, 12, 7, 15),
      );
      await tippe(tester, 'wie-geschlafen');
      expect(find.byKey(const ValueKey('himmel-regler')), findsOneWidget);
      await tippe(tester, 'nacht-Einmal wach');
      await tippe(tester, 'aufwachen-fertig');

      final m = feed.schlaf.morgenAm('2026-10-12')!;
      expect(m.tags, ['Einmal wach']);
      expect(m.wert, inInclusiveRange(1, 100));
      expect(m.satz, isNotNull);
      expect(find.byKey(const ValueKey('schlafwert')), findsOneWidget);
      expect(find.byKey(const ValueKey('sonnenlicht')), findsOneWidget);
      expect(diary.sleep.single.stunden, m.stunden);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await openKachel(tester, 's-wert');
      expect(find.byKey(const ValueKey('schlafwert-seite')), findsOneWidget);
      expect(find.byKey(const ValueKey('wie-geschlafen')), findsNothing);
    });

    testWidgets('energy feedback is remembered', (tester) async {
      final (_, feed) = await start(tester);
      // Energie lives in Produktivität & Fokus since 2026-10-29.
      await openTab(tester, 'Heute');
      await openBereich(tester, 'produktiv');
      await openKachel(tester, 'p-energie');
      expect(find.byKey(const ValueKey('energie-vorhersage')), findsOneWidget);
      await tippe(tester, 'energie-Besser');
      expect(feed.schlaf.energieAm('2026-10-12'), 'Besser');
      expect(
        find.text('Gemerkt. Daraus lernt der Coach deine eigene Kurve.'),
        findsOneWidget,
      );
    });

    testWidgets('journal: Gute Nacht only with all 6, then rest until the '
        'alarm', (tester) async {
      final (_, feed) = await start(
        tester,
        jetzt: DateTime(2026, 10, 12, 21, 40),
      );
      await tippe(tester, 'kachel-journal');
      for (var i = 0; i < 3; i++) {
        await tester.enterText(find.byKey(ValueKey('dankbar-$i')), 'Dank $i');
      }
      await tester.enterText(find.byKey(const ValueKey('besser-0')), 'B 0');
      await tester.pump();
      expect(
        find.text('Erst alle 6 Felder, dann geht Gute Nacht.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('gute-nacht')));
      await tester.pumpAndSettle();
      expect(find.text('RUNTERFAHREN'), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('besser-1')), 'B 1');
      await tester.enterText(find.byKey(const ValueKey('besser-2')), 'B 2');
      await tester.pump();
      await tippe(tester, 'gute-nacht');

      expect(feed.schlaf.journalAm('2026-10-12')!.fertig, isTrue);
      expect(find.text('RUNTERFAHREN'), findsOneWidget);
      // Default steps without a routine: three, then "Schlafen".
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('runter-weiter')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Schlafen'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('runter-weiter')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(feed.schlaf.ruheBis, DateTime(2026, 10, 13, 6, 30));
      expect(find.byKey(const ValueKey('ruhe')), findsOneWidget);
      expect(find.text('Gute Nacht, Phillip.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ruhe-aus')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(feed.schlaf.ruheBis, isNull);
      expect(find.byKey(const ValueKey('ruhe')), findsNothing);
    });

    testWidgets('alarm settings are saved, the test alarm ends with the task', (
      tester,
    ) async {
      final (_, feed) = await start(tester);
      await tippe(tester, 'kachel-wecker');
      expect(find.byKey(const ValueKey('wecker-morgen')), findsOneWidget);
      await tippe(tester, 'aufgabe-schritte');
      await tippe(tester, 'klang-Regen');
      await tippe(tester, 'wecker-schlummern-an');
      expect(feed.schlaf.wecker.aufgabe, 'schritte');
      expect(feed.schlaf.wecker.klang, 'Regen');
      expect(feed.schlaf.wecker.schlummern, isFalse);

      await tippe(tester, 'wecker-testen');
      expect(find.byKey(const ValueKey('wecker-schlummern')), findsNothing);
      for (var i = 0; i < 30; i++) {
        await tester.tap(find.byKey(const ValueKey('wecker-aufgabe')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('himmel-regler')), findsOneWidget);
    });

    testWidgets('coach day: take over and undo', (tester) async {
      final (_, feed) = await start(tester);
      await tippe(tester, 'kachel-tag');
      expect(find.text('Dein Tag vom Coach'), findsOneWidget);
      expect(find.text('Gute Nacht'), findsOneWidget);
      await tippe(tester, 'ablauf-uebernehmen');
      expect(feed.schlaf.ablauf!.uebernommen, isTrue);
      await tippe(tester, 'ablauf-rueckgaengig');
      expect(feed.schlaf.ablauf!.uebernommen, isFalse);
    });

    testWidgets('patterns: placeholder before 14 mornings, Stimmt nicht '
        'hides one', (tester) async {
      final (_, feed) = await start(
        tester,
        daten: SchlafDaten(
          musterTag: '2026-10-12',
          muster: const [
            SchlafMuster(text: 'Licht am Morgen hilft dir.', gut: true),
            SchlafMuster(text: 'Spätes Training stört.', gut: false),
          ],
          besteZeit: (typ: 'Eher Morgenmensch', text: 'Hoch 9 bis 12 Uhr.'),
        ),
      );
      await tippe(tester, 'muster-oeffnen');
      expect(find.byKey(const ValueKey('beste-zeit')), findsOneWidget);
      await tester.tap(find.text('Stimmt nicht').first);
      await tester.pumpAndSettle();
      expect(feed.schlaf.muster.first.abgelehnt, isTrue);
      expect(find.text('Licht am Morgen hilft dir.'), findsNothing);
    });

    testWidgets('yesterday\'s "besser" come back in Dein Tag', (tester) async {
      await start(
        tester,
        seite: false,
        daten: SchlafDaten(
          journal: [
            Journal(
              tag: dayKey(fixedNow.subtract(const Duration(days: 1))),
              dankbar: const ['a', 'b', 'c'],
              besser: const ['Früher Handy weg', 'Mehr trinken', 'Spazieren'],
              guteNacht: DateTime(2026, 10, 11, 22, 40),
            ),
          ],
        ),
      );
      await scrollTo(tester, find.byKey(const ValueKey('dein-tag')));
      await tester.tap(find.byKey(const ValueKey('dein-tag')));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const ValueKey('besser-heute')));
      expect(find.text('Früher Handy weg'), findsOneWidget);
    });
  });
}
