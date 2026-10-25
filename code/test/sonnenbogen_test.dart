import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/planner/planner_data.dart';
import 'package:coach_app/sleep/schlafzeiten.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('Dein Tag opens with the sun arc and counts down to the next '
      'point; a line marks now in the list', (tester) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    final feed = MemoryFeedStore()
      ..schlafzeiten = const Schlafzeiten(werktag: 6 * 60 + 30)
      ..termine.add(
        Termin(
          datum: fixedNow,
          zeit: '19:30',
          text: 'Kino',
          erstellt: fixedNow,
        ),
      );
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

    expect(find.byKey(const ValueKey('sonnenbogen')), findsOneWidget);
    final karte = find.byKey(const ValueKey('tag-naechstes'));
    expect(
      find.descendant(of: karte, matching: find.text('bis Kino · 19:30')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: karte,
        matching: find.textContaining('1:30', findRichText: true),
      ),
      findsOneWidget,
    );

    await scrollTo(tester, find.byKey(const ValueKey('tag-jetzt')));
    expect(find.text('JETZT 18:00'), findsOneWidget);
    // Getting up is over and comes before the line, Kino after it.
    final auf = tester.getTopLeft(find.byKey(const ValueKey('tag-aufstehen')));
    final jetzt = tester.getTopLeft(find.byKey(const ValueKey('tag-jetzt')));
    final kino = tester.getTopLeft(find.text('Kino').last);
    expect(auf.dy < jetzt.dy && jetzt.dy < kino.dy, isTrue);
  });
}
