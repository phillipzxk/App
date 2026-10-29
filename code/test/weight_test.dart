import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/weight/weight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('weekly averages group by Monday-to-Sunday weeks', () {
    final weeks = weeklyAverages([
      WeightEntry(DateTime(2026, 10, 5), 84), // Monday
      WeightEntry(DateTime(2026, 10, 11), 83), // Sunday, same week
      WeightEntry(DateTime(2026, 10, 12), 82), // next Monday
    ]);
    expect(weeks.length, 2);
    expect(weeks[0].monday, DateTime(2026, 10, 5));
    expect(weeks[0].kg, 83.5);
    expect(weeks[1].kg, 82);
  });

  test('parseKg accepts comma and rejects nonsense', () {
    expect(parseKg('82,4'), 82.4);
    expect(parseKg(' 82.4 '), 82.4);
    expect(parseKg('abc'), isNull);
    expect(parseKg('5'), isNull);
    expect(formatKg(82.4), '82,4');
  });

  testWidgets('weight can be entered and shows the weekly trend', (
    tester,
  ) async {
    final diary = MemoryDiaryStore()
      ..checkIns.add(checkInOn(fixedNow))
      ..weights.add(WeightEntry(DateTime(2026, 10, 6), 83));
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(const UserProfile(ziel: 'Frei sein')),
        diary: diary,
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'Ernährung', 'e-gewicht');
    await scrollTo(tester, find.text('Gewicht eintragen'));
    expect(find.text('83,0 kg'), findsOneWidget);

    await tester.ensureVisible(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '82,4');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(diary.weights.last.kg, 82.4);
    expect(find.text('82,4 kg'), findsOneWidget);
    expect(find.text('−0,6 kg zur Vorwoche'), findsOneWidget);
  });

  testWidgets('implausible weight shows an error', (tester) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(const UserProfile(ziel: 'Frei sein')),
        diary: diary,
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'Ernährung', 'e-gewicht');
    await scrollTo(tester, find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '5');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.textContaining('zwischen 30 und 300'), findsOneWidget);
    expect(diary.weights, isEmpty);
  });
}
