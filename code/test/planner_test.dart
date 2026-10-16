import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/planner/planner_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(ziel: 'Frei sein', motivation: 'Stolz sein.');

Future<MemoryFeedStore> _openToday(WidgetTester tester) async {
  final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
  final feed = MemoryFeedStore();
  tallView(tester);
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(_profile),
      diary: diary,
      feed: feed,
      clock: fixedClock,
    ),
  );
  await tester.pumpAndSettle();
  return feed;
}

void main() {
  // fixedNow is Monday, 12 October 2026.
  group('parseTermin', () {
    test('time with "Uhr" and a weekday', () {
      final t = parseTermin('Zahnarzt Donnerstag 17 Uhr', fixedNow);
      expect(t.zeit, '17:00');
      expect(t.datum, DateTime(2026, 10, 15));
      expect(t.text, 'Zahnarzt Donnerstag 17 Uhr');
    });

    test('colon time, no day means today', () {
      final t = parseTermin('Meeting 9:30', fixedNow);
      expect(t.zeit, '09:30');
      expect(t.datum, DateTime(2026, 10, 12));
    });

    test('a date is not read as a time', () {
      final t = parseTermin('Klausur am 15.10. um 8 Uhr', fixedNow);
      expect(t.zeit, '08:00');
    });

    test('morgen and übermorgen', () {
      expect(
        parseTermin('morgen Arbeit', fixedNow).datum,
        DateTime(2026, 10, 13),
      );
      expect(
        parseTermin('übermorgen Arbeit', fixedNow).datum,
        DateTime(2026, 10, 14),
      );
      expect(parseTermin('Morgenlauf', fixedNow).datum, DateTime(2026, 10, 12));
    });

    test('today\'s weekday stays today', () {
      expect(parseTermin('Montag Uni', fixedNow).datum, DateTime(2026, 10, 12));
    });
  });

  test('termineAm sorts timed first, then in written order', () {
    final a = parseTermin('Ohne Zeit', fixedNow);
    final b = parseTermin(
      'Spät 20 Uhr',
      fixedNow.add(const Duration(seconds: 1)),
    );
    final c = parseTermin(
      'Früh 7 Uhr',
      fixedNow.add(const Duration(seconds: 2)),
    );
    final d = parseTermin('morgen 7 Uhr', fixedNow);
    expect(termineAm([a, b, c, d], fixedNow).map((t) => t.text), [
      'Früh 7 Uhr',
      'Spät 20 Uhr',
      'Ohne Zeit',
    ]);
  });

  testWidgets('appointments and meals go into the day plan', (tester) async {
    final feed = await _openToday(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('termin-feld')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('termin-eintragen')));
    await tester.pumpAndSettle();
    expect(find.text('Dein Tag'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('termin-feld')),
      'Arbeit 14 Uhr',
    );
    await tester.tap(find.byKey(const ValueKey('termin-eintragen')));
    await tester.pumpAndSettle();
    expect(feed.termine.single.zeit, '14:00');
    expect(find.text('Arbeit 14 Uhr'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('termin-feld')),
      'Mittwoch Zahnarzt 9:15',
    );
    await tester.tap(find.byKey(const ValueKey('termin-eintragen')));
    await tester.pumpAndSettle();
    expect(find.text('NÄCHSTE TERMINE'), findsOneWidget);
    expect(find.text('Mittwoch Zahnarzt 9:15'), findsOneWidget);

    final meals = find.byKey(const ValueKey('mahlzeiten'));
    await tester.ensureVisible(meals);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: meals, matching: find.text('Festlegen')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mahlzeiten-4')));
    await tester.pumpAndSettle();
    expect(feed.mahlzeiten, 4);
    expect(find.textContaining('4 Mahlzeiten'), findsWidgets);
  });
}
