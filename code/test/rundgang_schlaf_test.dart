import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/schlaf/schlaf_data.dart';
import 'package:coach_app/sleep/schlafzeiten.dart';
import 'package:coach_app/sleep/sleep.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

// Schlaf & Routine after the walkthrough of 2026-11-28 (vault
// Umsetzung/Rundgang 2026-11-26.md, Seite 5).
void main() {
  testWidgets('Schlaf: after the morning the day as rows, the answer in the '
      'picture, lower part only on Morgen', (tester) async {
    final feed = MemoryFeedStore()
      ..schlafzeiten = const Schlafzeiten(werktag: 390, stunden: 8)
      ..routine = [RoutineStep('21:30', 'Handy weg')]
      ..schlaf = const SchlafDaten(
        morgen: [
          Morgen(
            tag: '2026-10-12',
            himmel: 80,
            stunden: 7.5,
            wert: 78,
            teile: {
              'laenge': 90,
              'erholung': 80,
              'durchschlafen': 60,
              'rhythmus': 75,
            },
          ),
        ],
      );
    final diary = MemoryDiaryStore()
      ..checkIns.add(checkInOn(fixedNow))
      ..sleep.add(SleepEntry(DateTime(2026, 10, 12, 7), 7.5));
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
    await openBereich(tester, 'schlaf');
    await tester.tap(find.byKey(const ValueKey('seite-Morgen')));
    await tester.pumpAndSettle();

    // 18:00: no light tip any more, the evening routine is due.
    expect(find.byKey(const ValueKey('jetzt-zeilen')), findsOneWidget);
    expect(find.text('Licht am Morgen'), findsNothing);
    expect(find.text('Aufgewacht · frisch'), findsOneWidget);
    expect(find.text('Um 21:30 startet deine Abendroutine'), findsOneWidget);
    expect(find.text('mit 7 Stunden oder mehr'), findsOneWidget);

    for (final s in ['Nacht', 'Abend']) {
      await tester.tap(find.byKey(ValueKey('seite-$s')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('serie')), findsNothing);
      expect(find.byKey(const ValueKey('geschafft')), findsNothing);
    }
  });
}
