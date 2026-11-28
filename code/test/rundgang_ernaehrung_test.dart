import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// Ernährung after the walkthrough of 2026-11-28 (vault Umsetzung/Rundgang
// 2026-11-26.md, Seite 4).
void main() {
  testWidgets('Ernährung: the meal due now leads "Jetzt dran", all meals '
      'as rows, missed ones to fill in, lower part only on Heute', (
    tester,
  ) async {
    final feed = MemoryFeedStore()..mahlzeiten = 3;
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
    await openBereich(tester, 'ernaehrung');

    expect(find.byKey(const ValueKey('jetzt-zeilen')), findsOneWidget);
    expect(find.text('Ohne Kalorienzählen.'), findsOneWidget);
    expect(find.textContaining('Gezählt wird nichts'), findsNothing);
    expect(find.textContaining('· nachtragen'), findsWidgets);
    expect(find.text('mit allen Mahlzeiten'), findsOneWidget);
    // Only Foto and Heißhunger stay under "Mehr"; Trinken is in the glass.
    await zeigeKachel(tester, 'e-foto');
    expect(find.byKey(const ValueKey('mehr-e-foto')), findsOneWidget);
    expect(find.byKey(const ValueKey('mehr-e-trinken')), findsNothing);

    for (final s in ['Küche', 'Ziel']) {
      await tester.tap(find.byKey(ValueKey('seite-$s')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('serie')), findsNothing);
      expect(find.byKey(const ValueKey('mehr')), findsNothing);
    }
  });
}
