import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// Fokus & Arbeit after the walkthrough of 2026-11-28 (vault
// Umsetzung/Rundgang 2026-11-26.md, Seite 6).
void main() {
  testWidgets('Fokus: lower part only on Heute', (tester) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(const UserProfile(ziel: 'Stark werden')),
        diary: diary,
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await openBereich(tester, 'produktiv');
    expect(find.byKey(const ValueKey('serie')), findsOneWidget);
    expect(find.text('mit der einen Sache geschafft'), findsOneWidget);
    for (final s in ['Ziele', 'Handy', 'Rhythmus', 'Routinen']) {
      await tester.tap(find.byKey(ValueKey('seite-$s')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('serie')), findsNothing);
      expect(find.byKey(const ValueKey('geschafft')), findsNothing);
    }
  });
}
