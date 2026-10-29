import 'package:coach_app/business/business_coach.dart';
import 'package:coach_app/business/business_data.dart';
import 'package:coach_app/business/business_logik.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/persoenlich/persoenlich_coach.dart';
import 'package:coach_app/persoenlich/persoenlich_data.dart';
import 'package:coach_app/persoenlich/persoenlich_logik.dart';
import 'package:coach_app/produktiv/produktiv_logik.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(
  name: 'Phillip',
  ziel: 'Frei sein',
  motivation: 'Ich will stolz auf mich sein.',
);

class _Coach extends NoFeedCoach implements BusinessCoach, PersoenlichCoach {
  final arten = <String>[];

  @override
  Future<Map?> business(
    UserProfile profile,
    String art,
    Map<String, Object> mehr,
  ) async {
    arten.add(art);
    return switch (art) {
      'hebel' => {
        'hebel': '3 alte Kunden fragen',
        'punkte': ['Lena', 'Marco', 'Frau Peters'],
        'tipps': [
          {'titel': 'Frag wen, nicht ob.', 'text': 'Bringt mehr Namen.'},
        ],
      },
      'skill' => {
        'stufen': [
          for (var i = 1; i <= 7; i++)
            {'titel': 'Stufe $i', 'text': 'Aufgabe $i'},
        ],
      },
      _ => null,
    };
  }

  @override
  Future<Map?> persoenlich(
    UserProfile profile,
    String art,
    Map<String, Object> mehr,
  ) async {
    arten.add(art);
    return switch (art) {
      'kurs' => {
        'lektionen': [for (var i = 1; i <= 12; i++) 'Lektion $i'],
      },
      'lektion' => {
        'text': 'Mach nach dem wichtigen Satz eine Pause.',
        'frage': 'Wann setzt du die Pause?',
        'antworten': ['Vorher', 'Nachher', 'Nie'],
        'richtig': 1,
      },
      _ => null,
    };
  }
}

Future<(MemoryFeedStore, _Coach)> _start(WidgetTester tester) async {
  final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
  final feed = MemoryFeedStore();
  final coach = _Coach();
  tallView(tester);
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(_profile),
      diary: diary,
      feed: feed,
      feedCoach: coach,
      clock: () => fixedNow,
    ),
  );
  await tester.pumpAndSettle();
  return (feed, coach);
}

Future<void> _tippe(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await scrollTo(tester, f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('logic', () {
    test('euro and numbers in German', () {
      expect(euro(2140), '2.140 €');
      expect(euro(860), '860 €');
      expect(zahl('1.200'), 1200);
      expect(zahl('12,5'), 12.5);
      expect(zahl('149 €'), 149);
    });

    test('business value from lever and turnover goal', () {
      final heute = DateTime(2026, 10, 15);
      expect(businessWert(const BusinessDaten(), heute), isNull);
      final d = BusinessDaten(
        hebel: const [
          Hebel(
            woche: '2026-10-12',
            text: 'x',
            punkte: [
              Punkt('a', erledigt: '2026-10-13'),
              Punkt('b'),
            ],
          ),
        ],
        ziele: const {'2026-10': 3100},
        eingaenge: const [Eingang(tag: '2026-10-10', betrag: 1500)],
      );
      // Lever half done, turnover on track: 1 + 9 * .75.
      expect(businessWert(d, heute), 8);
      expect(
        BusinessDaten.fromJson(d.toJson()).toJson().toString(),
        d.toJson().toString(),
      );
    });

    test('next branch counts this month against "3.000 € im Monat"', () {
      final d = BusinessDaten(
        meilensteine: const [
          Punkt('Erster Kunde', erledigt: '2026-09-01'),
          Punkt('3.000 € im Monat'),
        ],
        eingaenge: const [Eingang(tag: '2026-10-02', betrag: 1500)],
      );
      expect(naechsterAst(d), 1);
      expect(astAnteil('3.000 € im Monat', d, DateTime(2026, 10, 12)), .5);
    });

    test('care routine in a row and the value of the day', () {
      final heute = DateTime(2026, 10, 12);
      const alle = ['m0', 'm1', 'm2', 'a0', 'a1'];
      final d = const PersoenlichDaten().copyWith(
        pflege: {
          '2026-10-10': alle,
          '2026-10-11': alle,
          '2026-10-12': ['m0'],
        },
      );
      expect(pflegeAmStueck(d, heute), 2);
      expect(persoenlichWert(d, '2026-10-11'), 10);
      expect(morgensOffen(d, '2026-10-12'), 'Feuchtigkeitscreme');
      expect(
        PersoenlichDaten.fromJson(d.toJson()).toJson().toString(),
        d.toJson().toString(),
      );
    });
  });

  group('page', () {
    testWidgets('five roots and the life goals at the bottom', (tester) async {
      await _start(tester);
      for (final id in [
        'koerper',
        'produktiv',
        'business',
        'persoenlich',
        'mindset',
      ]) {
        await scrollTo(tester, find.byKey(ValueKey('wurzel-$id')));
        expect(find.byKey(ValueKey('wurzel-$id')), findsOneWidget);
      }
      await _tippe(tester, 'lebensziele');
      expect(find.text('Deine Lebensziele'), findsWidgets);
      expect(find.byKey(const ValueKey('ziel-feld')), findsOneWidget);
    });

    testWidgets('Produktivität: the one thing today is set and done', (
      tester,
    ) async {
      final (feed, _) = await _start(tester);
      await openBereich(tester, 'produktiv');
      expect(find.byKey(const ValueKey('produktiv-seite')), findsOneWidget);
      await openKachel(tester, 'p-fokus');
      await tester.enterText(
        find.byKey(const ValueKey('fokus-feld')),
        'Angebot fertig',
      );
      await _tippe(tester, 'fokus-setzen');
      await _tippe(tester, 'fokus-erledigt');
      final f = feed.produktiv.fokusAm(dayKey(fixedNow))!;
      expect(f.text, 'Angebot fertig');
      expect(f.erledigt, isTrue);
      expect(produktivWert(feed.produktiv, dayKey(fixedNow)), isNotNull);
    });

    testWidgets('Business: coach lever, ticks and the turnover goal', (
      tester,
    ) async {
      final (feed, coach) = await _start(tester);
      await openBereich(tester, 'business');
      expect(find.byKey(const ValueKey('business-seite')), findsOneWidget);
      await openKachel(tester, 'b-hebel');
      await _tippe(tester, 'hebel-vorschlag');
      expect(coach.arten, contains('hebel'));
      expect(find.text('3 alte Kunden fragen'), findsWidgets);
      expect(find.text('Frag wen, nicht ob.'), findsOneWidget);
      await _tippe(tester, 'hebel-punkt-0');
      expect(feed.business.hebel.single.erledigt, 1);

      await tester.tap(find.byKey(const ValueKey('feld-zurueck')));
      await tester.pumpAndSettle();
      await openKachel(tester, 'b-umsatz');
      await tester.enterText(find.byKey(const ValueKey('ziel-feld')), '3.000');
      await _tippe(tester, 'ziel-setzen');
      expect(feed.business.ziele['2026-10'], 3000);
      await tester.enterText(find.byKey(const ValueKey('umsatz-feld')), '3100');
      await tester.tap(find.byKey(const ValueKey('umsatz-dazu')));
      await tester.pump(const Duration(milliseconds: 500));
      // Goal reached: the big gold tick over the screen.
      expect(find.byKey(const ValueKey('grosses-haken')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('grosses-haken')), findsNothing);
      expect(umsatzIm(feed.business, '2026-10'), 3100);
    });

    testWidgets('Business: bold asks grow, skill ladder from the coach', (
      tester,
    ) async {
      final (feed, _) = await _start(tester);
      await openBereich(tester, 'business');
      await openKachel(tester, 'b-anfrage');
      await tester.enterText(
        find.byKey(const ValueKey('anfrage-feld')),
        'Preis erhöhen',
      );
      await _tippe(tester, 'anfrage-dazu');
      await _tippe(tester, 'anfrage-0');
      expect(feed.business.anfragen.single.an, isTrue);
      expect(find.text('1 geschafft'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('feld-zurueck')));
      await tester.pumpAndSettle();
      await openKachel(tester, 'b-skill');
      await tester.enterText(
        find.byKey(const ValueKey('skill-feld')),
        'Verkaufen',
      );
      await _tippe(tester, 'skill-start');
      expect(feed.business.skill!.stufen, hasLength(7));
      await _tippe(tester, 'skill-weiter');
      expect(feed.business.skill!.erreicht, 1);
    });

    testWidgets('Persönlichkeit: care ticks and the course opens lesson 2 '
        'after the right answer', (tester) async {
      final (feed, coach) = await _start(tester);
      await openBereich(tester, 'persoenlich');
      expect(find.byKey(const ValueKey('persoenlich-seite')), findsOneWidget);
      await openKachel(tester, 'pe-pflege');
      await _tippe(tester, 'pflege-m0');
      expect(feed.persoenlich.pflegeAm(dayKey(fixedNow)), ['m0']);

      await tester.tap(find.byKey(const ValueKey('feld-zurueck')));
      await tester.pumpAndSettle();
      await openKachel(tester, 'pe-kurs');
      await tester.enterText(
        find.byKey(const ValueKey('kurs-feld')),
        'Rhetorik',
      );
      await _tippe(tester, 'kurs-start');
      expect(coach.arten, containsAll(['kurs', 'lektion']));
      expect(feed.persoenlich.kurs!.lektionen, hasLength(12));
      expect(find.text('Wann setzt du die Pause?'), findsOneWidget);
      // Wrong answer keeps the lesson closed.
      await _tippe(tester, 'lektion-antwort-0');
      expect(feed.persoenlich.kurs!.erreicht, 0);
      await _tippe(tester, 'lektion-antwort-1');
      expect(feed.persoenlich.kurs!.erreicht, 1);
    });

    testWidgets('Persönlichkeit: small things and the library', (tester) async {
      final (feed, _) = await _start(tester);
      await openBereich(tester, 'persoenlich');
      await openKachel(tester, 'pe-kleine');
      await _tippe(tester, 'klein-0');
      expect(feed.persoenlich.kleine.first.zuletzt, dayKey(fixedNow));

      await tester.tap(find.byKey(const ValueKey('feld-zurueck')));
      await tester.pumpAndSettle();
      await openKachel(tester, 'pe-buecher');
      await tester.enterText(
        find.byKey(const ValueKey('buch-feld')),
        'Deep Work',
      );
      await _tippe(tester, 'buch-dazu');
      await _tippe(tester, 'buch-fertig-0');
      expect(feed.persoenlich.buecher.single.fertig, isTrue);
    });
  });
}
