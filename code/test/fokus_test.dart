import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/fokus.dart';
import 'package:coach_app/feed/muster.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _FokusCoach implements FeedCoach {
  int calls = 0;
  Wochenfokus? letzter;

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
  }) async {
    calls++;
    this.letzter = letzter;
    return FokusAuswahl(
      vorschlaege: [
        if (letzter != null)
          FokusVorschlag(
            text: letzter.text,
            warum: 'Dranbleiben.',
            behalten: true,
          ),
        const FokusVorschlag(text: 'Handy ab 23 Uhr raus', warum: 'Schlaf.'),
        const FokusVorschlag(
          text: 'Eiweiß zum Frühstück',
          warum: 'Heißhunger.',
        ),
        if (letzter == null)
          const FokusVorschlag(
            text: 'Erst die gedrückte Sache',
            warum: 'Mindset.',
          ),
      ],
      rueckblick: letzter == null ? null : 'Am Wochenende hat es gewackelt.',
      geschafft: letzter?.anzahlGeschafft,
    );
  }

  @override
  Future<List<String>?> stichpunkte(String text) async => null;
}

Future<(MemoryFeedStore, _FokusCoach)> _open(
  WidgetTester tester, {
  Wochenfokus? fokus,
}) async {
  final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
  final feed = MemoryFeedStore()..fokus = fokus;
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
    final wahl = find.byKey(const ValueKey('fokus-wahl'));
    await scrollTo(tester, wahl);
    expect(find.text('FOKUS DER WOCHE · WÄHL EINEN'), findsOneWidget);
    expect(find.byKey(const ValueKey('fokus-rueckblick')), findsNothing);

    await tester.tap(find.text('Eiweiß zum Frühstück'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('fokus-start')));
    await tester.tap(find.byKey(const ValueKey('fokus-start')));
    await tester.pumpAndSettle();

    expect(feed.fokus!.text, 'Eiweiß zum Frühstück');
    expect(feed.fokusAuswahl, isNull);
    await scrollTo(tester, find.byKey(const ValueKey('fokus-karte')));
    expect(find.text('Tag 1 von 7'), findsOneWidget);
    expect(find.text('0 von 1 Tag geschafft'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fokus-heute')));
    await tester.pumpAndSettle();
    expect(feed.fokus!.heuteGeschafft(fixedNow), isTrue);
    expect(find.text('✓ Heute geschafft'), findsOneWidget);
    expect(find.text('1 von 1 Tag geschafft'), findsOneWidget);

    // Tapping again takes it back.
    await tester.tap(find.byKey(const ValueKey('fokus-heute')));
    await tester.pumpAndSettle();
    expect(feed.fokus!.heuteGeschafft(fixedNow), isFalse);
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
    await scrollTo(tester, find.byKey(const ValueKey('fokus-karte')));
    expect(find.text('Tag 4 von 7'), findsOneWidget);
    expect(find.text('2 von 4 Tagen geschafft'), findsOneWidget);
    expect(find.byKey(const ValueKey('streak-karte')), findsOneWidget);
  });

  testWidgets('after 7 days: look back, keep the old focus as a new week', (
    tester,
  ) async {
    final alt = Wochenfokus(
      start: _tageZurueck(7),
      text: 'Handy ab 23 Uhr raus',
      geschafft: {for (var i = 3; i <= 7; i++) dayKey(_tageZurueck(i))},
    );
    final (feed, coach) = await _open(tester, fokus: alt);
    expect(coach.calls, 1);
    expect(coach.letzter!.anzahlGeschafft, 5);
    await scrollTo(tester, find.byKey(const ValueKey('fokus-wahl')));
    expect(find.text('NEUER FOKUS · WÄHL EINEN'), findsOneWidget);
    expect(
      find.textContaining('Letzte Woche 5 von 7.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('BEHALTEN'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fokus-option-0')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('fokus-start')));
    await tester.tap(find.byKey(const ValueKey('fokus-start')));
    await tester.pumpAndSettle();
    expect(feed.fokus!.text, 'Handy ab 23 Uhr raus');
    expect(feed.fokus!.start, _tageZurueck(0));
    expect(feed.fokus!.anzahlGeschafft, 0);
  });
}
