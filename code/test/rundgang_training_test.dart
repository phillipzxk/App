import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/training/training_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// Training after the walkthrough of 2026-11-28 (vault Umsetzung/Rundgang
// 2026-11-26.md, Seite 3).
void main() {
  testWidgets('Training: exercises in "Jetzt dran", at most four, and the '
      'lower part only on Heute', (tester) async {
    final feed = MemoryFeedStore()
      ..plan = TrainingPlan(
        ['Push', '', '', '', '', '', ''],
        uebungen: [
          [
            for (final n in [
              'Bankdrücken',
              'Schrägbank',
              'Schulterdrücken',
              'Dips',
              'Seitheben',
              'Trizeps',
            ])
              PlanUebung(name: n, wert: 40),
          ],
          for (var i = 0; i < 6; i++) const <PlanUebung>[],
        ],
      );
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(const UserProfile(ziel: 'Stark werden')),
        diary: diary,
        feed: feed,
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await openBereich(tester, 'training');

    expect(find.byKey(const ValueKey('jetzt-zeilen')), findsOneWidget);
    expect(find.text('Bankdrücken'), findsOneWidget);
    expect(find.text('Dips'), findsOneWidget);
    expect(find.text('40 kg × 8'), findsNWidgets(4));
    expect(find.text('Seitheben'), findsNothing);
    expect(find.text('+ 2 weitere Übungen'), findsOneWidget);
    expect(find.byKey(const ValueKey('mehr')), findsNothing);
    expect(find.byKey(const ValueKey('geschafft')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('seite-Woche')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('geschafft')), findsNothing);
    expect(find.byKey(const ValueKey('mehr')), findsNothing);
    expect(find.textContaining('Stagnation'), findsNothing);
  });
}
