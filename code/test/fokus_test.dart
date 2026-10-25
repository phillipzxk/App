import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/durchgezogen.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/fokus.dart';
import 'package:coach_app/feed/muster.dart';
import 'package:coach_app/home/reality_check.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _FokusCoach implements FeedCoach {
  int calls = 0;
  Wochenfokus? letzter;
  TrainingWoche? training;

  @override
  Future<String?> answer(
    UserProfile profile,
    Bereich bereich,
    String text, {
    String context = '',
  }) async => null;

  @override
  Future<Muster?> findeMuster(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> bisher,
  ) async => null;

  @override
  Future<FokusAuswahl?> fokusVorschlaege(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> muster, {
    Wochenfokus? letzter,
    TrainingWoche? training,
  }) async {
    calls++;
    this.letzter = letzter;
    this.training = training;
    if (letzter != null) {
      return FokusAuswahl(
        vorschlaege: [
          const FokusVorschlag(
            text: 'Unter der Woche um 23 Uhr ins Bett',
            warum: 'Wenn der Schlaf sitzt, löst sich der Heißhunger mit.',
          ),
          FokusVorschlag(
            text: letzter.text,
            warum: 'Dranbleiben.',
            behalten: true,
          ),
          const FokusVorschlag(
            text: 'Eiweiß zum Frühstück',
            warum: 'Heißhunger.',
          ),
        ],
        geschafft: letzter.anzahlGeschafft,
        fokusText: letzter.text,
        start: letzter.start,
        bremse: 'Kurze Nächte am Dienstag und Mittwoch.',
        training: training,
      );
    }
    return FokusAuswahl(
      vorschlaege: [
        const FokusVorschlag(text: 'Handy ab 23 Uhr raus', warum: 'Schlaf.'),
        const FokusVorschlag(
          text: 'Eiweiß zum Frühstück',
          warum: 'Heißhunger.',
        ),
        const FokusVorschlag(
          text: 'Erst die gedrückte Sache',
          warum: 'Mindset.',
        ),
      ],
    );
  }

  @override
  Future<List<String>?> stichpunkte(String text) async => null;

  @override
  Future<String?> durchgezogen(
    UserProfile profile,
    CheckIn today, {
    String? fokus,
    bool fokusGeschafft = false,
    List<Durchgezogen> bisher = const [],
  }) async => null;
}

Future<(MemoryFeedStore, _FokusCoach)> _open(
  WidgetTester tester, {
  Wochenfokus? fokus,
  List<CheckIn> checkIns = const [],
  TrainingPlan? plan,
}) async {
  final diary = MemoryDiaryStore()
    ..checkIns.addAll(checkIns)
    ..checkIns.add(checkInOn(fixedNow));
  final feed = MemoryFeedStore()..fokus = fokus;
  if (plan != null) feed.plan = plan;
  final coach = _FokusCoach();
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(const UserProfile(ziel: 'Frei sein')),
      diary: diary,
      feed: feed,
      feedCoach: coach,
      clock: fixedClock,
    ),
  );
  await tester.pumpAndSettle();
  return (feed, coach);
}

DateTime _tageZurueck(int n) =>
    DateTime(fixedNow.year, fixedNow.month, fixedNow.day - n);

void main() {
  group('Wochenfokus', () {
    final f = Wochenfokus(start: DateTime(2026, 10, 10), text: 'x');

    test('counts 7 days from the start day', () {
      expect(f.tag(DateTime(2026, 10, 10, 23)), 1);
      expect(f.tag(DateTime(2026, 10, 16)), 7);
      expect(f.vorbei(DateTime(2026, 10, 16, 23)), isFalse);
      expect(f.vorbei(DateTime(2026, 10, 17)), isTrue);
    });

    test('ticking today on and off again', () {
      final heute = DateTime(2026, 10, 12, 18);
      final an = f.umschalten(heute);
      expect(an.heuteGeschafft(heute), isTrue);
      expect(an.striche, [false, false, true, false, false, false, false]);
      expect(an.anzahlGeschafft, 1);
      expect(an.umschalten(heute).anzahlGeschafft, 0);
    });

    test('Reality Check counts planned and done training days', () {
      // 2026-10-12 is a Monday; Mo, Mi and Sa planned, Fr says rest.
      final w = Wochenfokus(start: DateTime(2026, 10, 12), text: 'x');
      final plan = TrainingPlan([
        'Push',
        '',
        'Laufen',
        '',
        'Ruhetag',
        'Beine',
        '',
      ]);
      final t = TrainingWoche.aus(w, plan, [
        checkInOn(DateTime(2026, 10, 12), training: 'Gut trainiert'),
        checkInOn(DateTime(2026, 10, 13), training: 'Lief zäh'),
        checkInOn(DateTime(2026, 10, 14), training: 'Pause, gut erholt'),
        // Outside the week.
        checkInOn(DateTime(2026, 10, 19), training: 'Gut trainiert'),
      ]);
      expect(t.geplant, 3);
      expect(t.gemacht, 2);
    });

    test('Reality Check survives a json round trip', () {
      final a = FokusAuswahl(
        vorschlaege: const [FokusVorschlag(text: 'a')],
        geschafft: 4,
        fokusText: 'x',
        start: DateTime(2026, 10, 12),
        bremse: 'b',
        training: const TrainingWoche(geplant: 4, gemacht: 3),
      );
      final b = FokusAuswahl.fromJson(a.toJson());
      expect(b.istRealityCheck, isTrue);
      expect(b.fokusText, 'x');
      expect(b.start, DateTime(2026, 10, 12));
      expect(b.bremse, 'b');
      expect(b.training!.gemacht, 3);
    });

    test('week span label', () {
      expect(wochenSpanne(DateTime(2026, 10, 20)), 'Woche 20. bis 26. Okt');
      expect(wochenSpanne(DateTime(2026, 9, 28)), 'Woche 28. Sep bis 4. Okt');
    });

    test('survives a json round trip', () {
      final a = f.umschalten(DateTime(2026, 10, 11));
      final b = Wochenfokus.fromJson(a.toJson());
      expect(b.text, 'x');
      expect(b.geschafft, a.geschafft);
      expect(b.start, a.start);
    });
  });

  testWidgets('first time: pick one of three, start, tick today off', (
    tester,
  ) async {
    final (feed, coach) = await _open(tester);
    expect(coach.calls, 1);
    expect(coach.letzter, isNull);
    expect(find.text('3 Vorschläge ›'), findsOneWidget);
    await openKrone(tester, 'krone-fokus');
    expect(find.byKey(const ValueKey('fokus-wahl')), findsOneWidget);
    expect(find.text('FOKUS DER WOCHE · WÄHL EINEN'), findsOneWidget);
    expect(find.byKey(const ValueKey('fokus-rueckblick')), findsNothing);

    await tester.tap(find.text('Eiweiß zum Frühstück'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('fokus-start')));
    await tester.tap(find.byKey(const ValueKey('fokus-start')));
    await tester.pumpAndSettle();

    expect(feed.fokus!.text, 'Eiweiß zum Frühstück');
    expect(feed.fokusAuswahl, isNull);
    // Starting closes the page; the crown field shows the running week.
    expect(find.byKey(const ValueKey('fokus-wahl')), findsNothing);
    expect(find.text('FOKUS · TAG 1/7'), findsOneWidget);

    await openKrone(tester, 'krone-fokus');
    expect(find.text('Tag 1 von 7'), findsOneWidget);
    expect(find.text('0 von 1 Tag geschafft'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // "Heute geschafft" right in the crown field.
    await tester.tap(find.byKey(const ValueKey('fokus-heute')));
    await tester.pumpAndSettle();
    expect(feed.fokus!.heuteGeschafft(fixedNow), isTrue);
    // The coach cheers in its crown field.
    expect(find.byKey(const ValueKey('coach-jubel')), findsOneWidget);
    expect(
      find.textContaining('Fokus heute geschafft', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('✓ Geschafft'), findsOneWidget);

    // On the page it counts too; tapping there again takes it back.
    await openKrone(tester, 'krone-fokus');
    expect(find.text('1 von 1 Tag geschafft'), findsOneWidget);
    expect(find.text('✓ Heute geschafft'), findsOneWidget);
    await tester.tap(find.text('✓ Heute geschafft'));
    await tester.pumpAndSettle();
    expect(feed.fokus!.heuteGeschafft(fixedNow), isFalse);
    expect(find.text('0 von 1 Tag geschafft'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('coach-jubel')), findsNothing);
    expect(find.text('Heute geschafft'), findsOneWidget);
    expect(coach.calls, 1);
  });

  testWidgets('running week shows its day and asks the coach nothing', (
    tester,
  ) async {
    final (_, coach) = await _open(
      tester,
      fokus: Wochenfokus(
        start: _tageZurueck(3),
        text: 'Handy ab 23 Uhr raus',
        geschafft: {dayKey(_tageZurueck(3)), dayKey(_tageZurueck(1))},
      ),
    );
    expect(coach.calls, 0);
    expect(find.text('FOKUS · TAG 4/7'), findsOneWidget);
    expect(find.byKey(const ValueKey('spross-tage')), findsOneWidget);
    await openKrone(tester, 'krone-fokus');
    expect(find.text('Tag 4 von 7'), findsOneWidget);
    expect(find.text('2 von 4 Tagen geschafft'), findsOneWidget);
  });

  testWidgets('after 7 days: Reality Check page, keep the old focus', (
    tester,
  ) async {
    final alt = Wochenfokus(
      start: _tageZurueck(7),
      text: 'Handy ab 23 Uhr raus',
      geschafft: {for (var i = 3; i <= 7; i++) dayKey(_tageZurueck(i))},
    );
    final s = alt.start;
    final (feed, coach) = await _open(
      tester,
      fokus: alt,
      // Plan for 3 of the 7 days, trained on 2 of them.
      plan: TrainingPlan([
        for (var wd = 1; wd <= 7; wd++)
          [
                s.weekday,
                (s.weekday % 7) + 1,
                ((s.weekday + 1) % 7) + 1,
              ].contains(wd)
              ? 'Push'
              : '',
      ]),
      checkIns: [
        checkInOn(s, training: 'Gut trainiert'),
        checkInOn(DateTime(s.year, s.month, s.day + 1), training: 'Lief zäh'),
        checkInOn(
          DateTime(s.year, s.month, s.day + 2),
          training: 'Pause, eher unproduktiv',
        ),
      ],
    );
    expect(coach.calls, 1);
    expect(coach.letzter!.anzahlGeschafft, 5);
    expect(coach.training!.geplant, 3);
    expect(coach.training!.gemacht, 2);

    // Heute shows only the small field, not the choice.
    expect(find.byKey(const ValueKey('fokus-wahl')), findsNothing);
    // The Reality Check hangs on the tree as a golden fruit.
    expect(find.text('Erst dein\nReality Check'), findsOneWidget);
    await openKrone(tester, 'reality-feld');

    expect(find.text('Reality Check'), findsOneWidget);
    expect(find.text('Fokus: Handy ab 23 Uhr raus'), findsOneWidget);
    expect(find.text('5 von 7'), findsOneWidget);
    expect(find.text('2 von 3'), findsOneWidget);
    expect(find.text('Kurze Nächte am Dienstag und Mittwoch.'), findsOneWidget);
    expect(find.text('Unter der Woche um 23 Uhr ins Bett.'), findsOneWidget);
    expect(find.text('Die eine Veränderung von oben'), findsOneWidget);
    expect(find.text('BEHALTEN'), findsOneWidget);
    expect(find.byKey(const ValueKey('fokus-rueckblick')), findsNothing);

    await scrollTo(tester, find.byKey(const ValueKey('fokus-start')));
    await tester.tap(find.byKey(const ValueKey('fokus-option-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fokus-start')));
    await tester.pumpAndSettle();
    expect(find.text('Reality Check'), findsNothing);
    expect(feed.fokus!.text, 'Handy ab 23 Uhr raus');
    expect(feed.fokus!.start, _tageZurueck(0));
    expect(feed.fokus!.anzahlGeschafft, 0);
    expect(feed.fokusAuswahl, isNull);
    expect(find.text('FOKUS · TAG 1/7'), findsOneWidget);
    expect(find.byKey(const ValueKey('reality-feld')), findsNothing);
  });

  testWidgets('the one change can be started as the new focus', (tester) async {
    final alt = Wochenfokus(start: _tageZurueck(8), text: 'Alt');
    final (feed, _) = await _open(tester, fokus: alt);
    await openKrone(tester, 'reality-feld');
    // No plan: training shows only the days.
    expect(find.text('Training (kein Plan eingetragen)'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('fokus-start')));
    await tester.tap(find.byKey(const ValueKey('fokus-option-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fokus-start')));
    await tester.pumpAndSettle();
    expect(feed.fokus!.text, 'Unter der Woche um 23 Uhr ins Bett');
  });
}
