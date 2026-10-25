import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/planner/planner_data.dart';
import 'package:coach_app/sleep/schlafzeiten.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  // Monday evening; tomorrow is a Tuesday, Friday's tomorrow is Saturday.
  final montag = DateTime(2026, 10, 12, 18);
  final freitag = DateTime(2026, 10, 16, 18);
  const z = Schlafzeiten(
    werktag: 6 * 60 + 30,
    wochenende: 8 * 60 + 30,
    stunden: 7,
  );

  test('bedtime is tomorrow\'s wake-up time minus the hours of sleep', () {
    final b = bettzeitFuer(z, montag, const [])!;
    expect(formatUhrzeit(b.aufstehen), '6:30');
    expect(formatUhrzeit(b.bett), '23:30');
    expect(formatUhrzeit(bettzeitFuer(z, freitag, const [])!.bett), '1:30');
  });

  test('weekend falls back to the weekday time', () {
    const nurWerktag = Schlafzeiten(werktag: 6 * 60, stunden: 8);
    expect(
      formatUhrzeit(bettzeitFuer(nurWerktag, freitag, const [])!.bett),
      '22:00',
    );
    expect(bettzeitFuer(const Schlafzeiten(), montag, const []), isNull);
  });

  test('an early appointment tomorrow moves the wake-up time forward', () {
    final dienstag = DateTime(2026, 10, 13);
    final uni = Termin(
      datum: dienstag,
      zeit: '07:00',
      text: 'Uni 7 Uhr',
      erstellt: montag,
    );
    final b = bettzeitFuer(z, montag, [uni])!;
    expect(formatUhrzeit(b.aufstehen), '6:00');
    expect(formatUhrzeit(b.bett), '23:00');
    expect(b.termin, uni);
    // Late enough: no change.
    final spaet = Termin(
      datum: dienstag,
      zeit: '09:00',
      text: 'x',
      erstellt: montag,
    );
    expect(bettzeitFuer(z, montag, [spaet])!.termin, isNull);
  });

  test('parses times', () {
    expect(parseUhrzeit('6:30'), 390);
    expect(parseUhrzeit('06.30'), 390);
    expect(parseUhrzeit('7'), 420);
    expect(parseUhrzeit('25:00'), isNull);
    expect(parseUhrzeit('abc'), isNull);
  });

  testWidgets(
    'Heute asks for the wake-up time, Schlaf sets it, plan shows bedtime',
    (tester) async {
      final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
      final feed = MemoryFeedStore();
      await tester.pumpWidget(
        CoachApp(
          store: MemoryProfileStore(const UserProfile(ziel: 'Frei sein')),
          diary: diary,
          feed: feed,
          clock: fixedClock,
        ),
      );
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const ValueKey('dein-tag')));
      await tester.tap(find.byKey(const ValueKey('dein-tag')));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('tag-bettzeit'));
      await scrollTo(tester, row);
      expect(find.text('Trag ein, wann du aufstehst ›'), findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();

      final werktag = find.byKey(const ValueKey('aufstehen-werktag'));
      await scrollTo(tester, werktag);
      await tester.tap(werktag);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('uhrzeit-feld')),
        '6:30',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(feed.schlafzeiten.werktag, 390);
      expect(
        find.textContaining('Heute ins Bett: 22:30.', findRichText: true),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const ValueKey('tag-bettzeit')));
      expect(find.text('22:30'), findsOneWidget);
      expect(
        find.textContaining('Morgen um 6:30 raus, 8 Std. Schlaf.'),
        findsOneWidget,
      );
    },
  );
}
