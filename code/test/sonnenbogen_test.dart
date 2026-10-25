import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_data.dart';
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

  test('a training time in the day name is read and kept out of the name', () {
    expect(trainingZeit('Push 17:30\nBankdrücken 5x5'), 17 * 60 + 30);
    expect(trainingZeit('Beine um 7 Uhr'), 7 * 60);
    expect(trainingZeit('Push\nLaufen 5 km'), isNull);
    expect(shortDay('Push 17:30\nBankdrücken'), 'Push');
    expect(shortDay('Push 17:30'), 'Push');
    expect(dayDetails('Push 17:30'), '');
    expect(dayName('Push 17:30\nBankdrücken'), 'Push 17:30');
    expect(dayName('Push 17:30'), 'Push 17:30');
  });

  testWidgets('Heute dran is the small sun arc with the next point and '
      'what comes after it', (tester) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    final feed = MemoryFeedStore()
      ..schlafzeiten = const Schlafzeiten(werktag: 6 * 60 + 30)
      ..plan = TrainingPlan([
        for (var i = 0; i < 7; i++) 'Push 19:00\nBankdrücken 5x5',
      ])
      ..termine.add(
        Termin(
          datum: fixedNow,
          zeit: '18:30',
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
    final zeile = find.byKey(const ValueKey('heute-naechstes'));
    await scrollTo(tester, zeile);
    // The round field in the crown: countdown and what comes next.
    expect(
      find.descendant(of: zeile, matching: find.text('0:30:00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: zeile, matching: find.text('bis Kino')),
      findsOneWidget,
    );
  });
}
