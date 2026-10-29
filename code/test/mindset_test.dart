import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/mindset/mindset_coach.dart';
import 'package:coach_app/mindset/mindset_data.dart';
import 'package:coach_app/mindset/mindset_logik.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(
  name: 'Phillip',
  ziel: 'Frei sein',
  motivation: 'Ich will stolz auf mich sein.',
);

class _Coach extends NoFeedCoach implements MindsetCoach {
  String? eigenerGesehen;

  @override
  Future<({String schritt, String satz, bool passt})?> schritt(
    UserProfile profile,
    String titel,
    String? eigener,
    String kontext,
  ) async {
    eigenerGesehen = eigener;
    return (
      schritt: eigener ?? 'Ordner öffnen',
      satz: 'Passt. Nur 2 Minuten.',
      passt: eigener != null,
    );
  }

  @override
  Future<List<String>?> danach(
    UserProfile profile,
    String titel,
    String kontext,
  ) async => ['2 Minuten $titel', '10 Minuten raus', 'Abendessen 19:00'];

  @override
  Future<String?> ausredenPlan(
    UserProfile profile,
    String ausrede,
    String kontext,
  ) async => 'Die schweren Sachen vor 12 Uhr.';

  @override
  Future<({List<Sorge> sorgen, String? satz})?> sorgen(
    UserProfile profile,
    String text,
    String kontext,
  ) async => (
    sorgen: const [
      Sorge(
        tag: '',
        text: 'Vater ist krank',
        aendern: 'Heute Abend anrufen',
        nicht: 'Wie schnell er gesund wird',
      ),
    ],
    satz: 'Kümmere dich nur um die linke Seite.',
  );

  @override
  Future<String?> leitsatz(
    UserProfile profile,
    List<Abendantwort> antworten,
  ) async => 'Ich bin der, auf den man sich verlassen kann.';

  @override
  Future<String?> brief(
    UserProfile profile,
    Brief brief,
    String kontext,
  ) async => 'Du trainierst jetzt dreimal die Woche.';
}

Future<MemoryFeedStore> _start(
  WidgetTester tester, {
  MindsetDaten? daten,
  FeedCoach? coach,
  DateTime? jetzt,
}) async {
  final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
  final feed = MemoryFeedStore();
  if (daten != null) feed.mindset = daten;
  tallView(tester);
  final t = jetzt ?? fixedNow;
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(_profile),
      diary: diary,
      feed: feed,
      feedCoach: coach ?? _Coach(),
      clock: () => t,
    ),
  );
  await tester.pumpAndSettle();
  await openTab(tester, 'Mindset');
  return feed;
}

Future<void> _tippe(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await scrollTo(tester, f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('logic', () {
    test('Selbstständig level rises every 3 own steps', () {
      Stein s(int i, bool eigen) => Stein(
        id: '$i',
        titel: 't',
        schritt: 's',
        seit: '2026-10-01',
        eigener: eigen,
      );
      expect(selbststaendig(const MindsetDaten()).stufe, 1);
      final d = MindsetDaten(
        steine: [for (var i = 0; i < 4; i++) s(i, true), s(9, false)],
      );
      final r = selbststaendig(d);
      expect(r.stufe, 2);
      expect(r.eigene, 4);
      expect(r.bisNaechste, 2);
    });

    test('excuses are counted with their usual time', () {
      final d = MindsetDaten(
        ausreden: [
          Ausrede(zeit: DateTime(2026, 10, 13, 19), text: 'Bin zu müde'),
          Ausrede(zeit: DateTime(2026, 10, 15, 20), text: 'Bin zu müde'),
          Ausrede(zeit: DateTime(2026, 10, 20, 19), text: 'Bin zu müde'),
          Ausrede(zeit: DateTime(2026, 10, 16, 9), text: 'Keine Zeit'),
        ],
      );
      final l = ausredenListe(d);
      expect(l.first.text, 'Bin zu müde');
      expect(l.first.n, 3);
      expect(l.first.wann, 'meist Di · abends');
    });

    test('a letter opens after 6 months', () {
      expect(sechsMonate(DateTime(2026, 10, 28)), DateTime(2027, 4, 28));
      expect(sechsMonate(DateTime(2026, 8, 31)), DateTime(2027, 2, 28));
      const b = Brief(
        geschrieben: '2026-10-28',
        oeffnet: '2027-04-28',
        text: 'x',
      );
      expect(b.offen(DateTime(2027, 4, 27)), isFalse);
      expect(b.offen(DateTime(2027, 4, 28)), isTrue);
      expect(b.tageBis(DateTime(2026, 10, 28)), 182);
    });

    test('data survives the round trip through JSON', () {
      final d = MindsetDaten(
        steine: const [
          Stein(
            id: 'a',
            titel: 'Steuer',
            schritt: 'Ordner',
            seit: '2026-10-01',
          ),
        ],
        ausredenPlan: (ausrede: 'Keine Zeit', plan: 'p', uebernommen: true),
        werte: const [
          Wert(name: 'Ruhig', noten: {'2026-10-12': 4}),
        ],
        ruhe: [DateTime(2026, 10, 12, 18)],
        raeder: const [
          Lebensrad(tag: '2026-10-01', werte: {'Körper': 6}),
        ],
        leitsatz: 'L',
      );
      final z = MindsetDaten.fromJson(d.toJson());
      expect(z.steine.single.titel, 'Steuer');
      expect(z.ausredenPlan!.uebernommen, isTrue);
      expect(z.werte.single.noten['2026-10-12'], 4);
      expect(z.ruhe.single, DateTime(2026, 10, 12, 18));
      expect(z.raeder.single.werte['Körper'], 6);
      expect(z.leitsatz, 'L');
    });
  });

  group('page', () {
    testWidgets('four pages and all tiles are there', (tester) async {
      await _start(tester);
      expect(find.byKey(const ValueKey('mindset-seite')), findsOneWidget);
      for (final k in [
        'm-berg',
        'm-wort',
        'm-ruhe',
        'm-durch',
        'm-stufe',
        'm-aus',
        'm-muster',
        'm-werte',
        'm-sorgen',
        'm-abend',
        'm-rad',
        'm-brief',
        'm-ziele',
        'm-warum',
      ]) {
        await zeigeKachel(tester, k);
        expect(find.byKey(ValueKey('kachel-$k')), findsOneWidget);
      }
    });

    testWidgets('own first step counts, 2 minutes start the Danach-Plan, '
        'stone rolls away', (tester) async {
      final coach = _Coach();
      final feed = await _start(tester, coach: coach);
      await openKachel(tester, 'm-berg');
      await _tippe(tester, 'berg-neu');
      await tester.enterText(
        find.byKey(const ValueKey('stein-titel')),
        'Steuererklärung',
      );
      await tester.enterText(
        find.byKey(const ValueKey('stein-schritt')),
        'Ordner Steuer öffnen',
      );
      await _tippe(tester, 'stein-legen');
      expect(coach.eigenerGesehen, 'Ordner Steuer öffnen');
      final s = feed.mindset.steine.single;
      expect(s.eigener, isTrue);
      expect(s.schritt, 'Ordner Steuer öffnen');
      expect(find.text('Passt. Nur 2 Minuten.'), findsOneWidget);

      await _tippe(tester, 'stein-los');
      expect(find.byKey(const ValueKey('stein-timer')), findsOneWidget);
      expect(find.byKey(const ValueKey('danach-plan')), findsOneWidget);
      expect(feed.mindset.steine.single.danach.last, 'Abendessen 19:00');
      expect(feed.mindset.steine.single.starts, 1);
      await tester.pump(const Duration(seconds: 121));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stein-weiter')), findsOneWidget);
      await _tippe(tester, 'stein-erledigt');
      expect(feed.mindset.steine.single.erledigt, dayKey(fixedNow));
      expect(feed.mindset.offeneSteine, isEmpty);
    });

    testWidgets('leaving a stone lying saves the excuse, from 3 the coach '
        'makes a plan', (tester) async {
      final feed = await _start(
        tester,
        daten: MindsetDaten(
          steine: const [
            Stein(
              id: 'a',
              titel: 'Arzt',
              schritt: 'Nummer',
              seit: '2026-10-01',
            ),
          ],
          ausreden: [
            Ausrede(zeit: DateTime(2026, 10, 6, 19), text: 'Bin zu müde'),
            Ausrede(zeit: DateTime(2026, 10, 8, 19), text: 'Bin zu müde'),
          ],
        ),
      );
      await openKachel(tester, 'm-berg');
      await _tippe(tester, 'stein-liegen');
      await _tippe(tester, 'ausrede-Bin zu müde');
      expect(feed.mindset.ausreden, hasLength(3));
      expect(feed.mindset.offeneSteine, hasLength(1));

      await tester.tap(find.byKey(const ValueKey('feld-zurueck')));
      await tester.pumpAndSettle();
      await openKachel(tester, 'm-aus');
      expect(find.byKey(const ValueKey('ausreden-plan')), findsOneWidget);
      await _tippe(tester, 'plan-uebernehmen');
      expect(feed.mindset.ausredenPlan!.uebernommen, isTrue);
    });

    testWidgets('promises: at most 3 a day, ticked off in the evening', (
      tester,
    ) async {
      final feed = await _start(tester);
      await openKachel(tester, 'm-wort');
      for (final t in ['Steuer 2 Minuten', 'Training', 'Handy weg']) {
        await tester.enterText(find.byKey(const ValueKey('vorsatz-feld')), t);
        await _tippe(tester, 'vorsatz-dazu');
      }
      expect(feed.mindset.vorsaetze, hasLength(3));
      expect(find.byKey(const ValueKey('vorsatz-feld')), findsNothing);
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const ValueKey('vorsatz-1')),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(feed.mindset.vorsaetze[1].gehalten, isTrue);
      expect(wortWoche(feed.mindset, fixedNow).gehalten, 1);
    });

    testWidgets('Ruhe-Knopf locks for 3 minutes and counts', (tester) async {
      final feed = await _start(tester);
      await openKachel(tester, 'm-ruhe');
      await _tippe(tester, 'ruhe-start');
      expect(find.byKey(const ValueKey('ruhe-zeit')), findsOneWidget);
      expect(find.byKey(const ValueKey('ruhe-fertig')), findsNothing);
      await tester.pump(const Duration(seconds: 181));
      await tester.pumpAndSettle();
      expect(feed.mindset.ruhe, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('ruhe-fertig')));
      await tester.pumpAndSettle();
      expect(find.text('1 Mal Ruhe genommen'), findsOneWidget);
    });

    testWidgets('values are rated, habits ticked, the practice saved', (
      tester,
    ) async {
      final feed = await _start(tester);
      await openKachel(tester, 'm-werte');
      await tester.enterText(
        find.byKey(const ValueKey('wert-name')),
        'Ruhig bleiben',
      );
      await _tippe(tester, 'wert-dazu');
      await _tippe(tester, 'wert-0-4');
      expect(feed.mindset.werte.single.noten[wocheVon(fixedNow)], 4);
      await tester.enterText(
        find.byKey(const ValueKey('gewohnheit-name')),
        'Lesen',
      );
      await _tippe(tester, 'gewohnheit-dazu');
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const ValueKey('gewohnheit-0')),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(feed.mindset.gewohnheiten.single.tage, [dayKey(fixedNow)]);
      await tester.enterText(
        find.byKey(const ValueKey('praxis-feld')),
        'Stille am Morgen',
      );
      await tester.pumpAndSettle();
      expect(feed.mindset.praxis, 'Stille am Morgen');
    });

    testWidgets('worries are sorted, the changeable part becomes a stone', (
      tester,
    ) async {
      final feed = await _start(tester);
      await openKachel(tester, 'm-sorgen');
      await tester.enterText(
        find.byKey(const ValueKey('sorgen-feld')),
        'Mein Vater ist krank.',
      );
      await _tippe(tester, 'sorgen-abgeben');
      expect(find.text('Heute Abend anrufen'), findsOneWidget);
      expect(feed.mindset.sorgen.single.nicht, 'Wie schnell er gesund wird');
      await _tippe(tester, 'sorge-stein-0');
      expect(feed.mindset.offeneSteine.single.titel, 'Heute Abend anrufen');
    });

    testWidgets('evening answer forms the Leitsatz', (tester) async {
      final feed = await _start(tester);
      await openKachel(tester, 'm-abend');
      expect(find.text('„${abendFragen.first}“'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('abend-feld')),
        'Dass man sich auf mich verlassen kann.',
      );
      await _tippe(tester, 'abend-gute-nacht');
      expect(feed.mindset.abend.single.frage, abendFragen.first);
      expect(
        feed.mindset.leitsatz,
        'Ich bin der, auf den man sich verlassen kann.',
      );
      expect(find.byKey(const ValueKey('abend-feld')), findsNothing);
    });

    testWidgets('Lebensrad: fill now, next one in 3 months', (tester) async {
      final feed = await _start(tester);
      await openKachel(tester, 'm-rad');
      await _tippe(tester, 'rad-speichern');
      expect(feed.mindset.raeder.single.werte['Business'], 5);
      expect(find.text('Das nächste kommt in 91 Tagen.'), findsOneWidget);
    });

    testWidgets('letter is sealed for 6 months, then opens with the coach', (
      tester,
    ) async {
      final feed = await _start(tester);
      await openKachel(tester, 'm-brief');
      await tester.enterText(
        find.byKey(const ValueKey('brief-feld')),
        'Lieber ich, bleib dran.',
      );
      await _tippe(tester, 'brief-versiegeln');
      final b = feed.mindset.briefe.single;
      expect(b.oeffnet, dayKey(sechsMonate(fixedNow)));
      expect(find.byKey(const ValueKey('brief-tage')), findsOneWidget);
    });

    testWidgets('an opened letter shows the coach next to it', (tester) async {
      final feed = await _start(
        tester,
        daten: const MindsetDaten(
          briefe: [
            Brief(
              geschrieben: '2026-04-01',
              oeffnet: '2026-10-01',
              text: 'Lieber ich, bleib dran.',
            ),
          ],
        ),
      );
      await openKachel(tester, 'm-brief');
      expect(find.text('Lieber ich, bleib dran.'), findsOneWidget);
      expect(
        find.text('Du trainierst jetzt dreimal die Woche.'),
        findsOneWidget,
      );
      expect(feed.mindset.briefe.single.satz, isNotNull);
    });

    testWidgets('life goals with an area', (tester) async {
      final feed = await _start(tester);
      await openKachel(tester, 'm-ziele');
      await tester.enterText(
        find.byKey(const ValueKey('ziel-feld')),
        'Mit 40 in Topform',
      );
      await _tippe(tester, 'ziel-bereich-Körper');
      await _tippe(tester, 'ziel-dazu');
      expect(feed.mindset.ziele.single.bereich, 'Körper');
      await _tippe(tester, 'ziel-weg-0');
      expect(feed.mindset.ziele, isEmpty);
    });

    testWidgets('without the coach the stone gets a simple first step', (
      tester,
    ) async {
      final feed = await _start(tester, coach: const NoFeedCoach());
      await openKachel(tester, 'm-berg');
      await _tippe(tester, 'berg-neu');
      await tester.enterText(
        find.byKey(const ValueKey('stein-titel')),
        'Bewerbung',
      );
      await _tippe(tester, 'stein-legen');
      final s = feed.mindset.steine.single;
      expect(s.eigener, isFalse);
      expect(s.schritt, isNotEmpty);
      await _tippe(tester, 'stein-los');
      expect(feed.mindset.steine.single.danach, hasLength(3));
    });
  });
}
