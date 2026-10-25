import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _WarumCoach extends NoFeedCoach {
  _WarumCoach(this.satz);

  final String? satz;
  int calls = 0;

  @override
  Future<String?> warumSatz(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) async {
    calls++;
    return satz;
  }
}

const _warum = 'Ich will wieder mit meinem Sohn Fußball spielen.';

Future<(MemoryFeedStore, _WarumCoach)> _open(
  WidgetTester tester, {
  String? satz,
  String motivation = _warum,
  MemoryFeedStore? feed,
}) async {
  final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
  final store = feed ?? MemoryFeedStore();
  final coach = _WarumCoach(satz);
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(
        UserProfile(ziel: 'Frei sein', motivation: motivation),
      ),
      diary: diary,
      feed: store,
      feedCoach: coach,
      clock: fixedClock,
    ),
  );
  await tester.pumpAndSettle();
  return (store, coach);
}

void main() {
  testWidgets('weak day: card with own words and coach sentence', (
    tester,
  ) async {
    final (feed, coach) = await _open(
      tester,
      satz: 'Für genau solche Wochen ist es da.',
    );
    expect(coach.calls, 1);
    expect(find.byKey(const ValueKey('warum-karte')), findsOneWidget);
    expect(find.text('„$_warum“'), findsOneWidget);
    expect(find.text('Für genau solche Wochen ist es da.'), findsOneWidget);
    expect(feed.warumHeute?.satz, 'Für genau solche Wochen ist es da.');
  });

  testWidgets('normal day: no card, coach asked only once a day', (
    tester,
  ) async {
    final (feed, coach) = await _open(tester);
    expect(coach.calls, 1);
    expect(find.byKey(const ValueKey('warum-karte')), findsNothing);
    expect(feed.warumHeute?.tag, isNotNull);

    final (_, again) = await _open(tester, feed: feed);
    expect(again.calls, 0);
  });

  testWidgets('no Warum given: coach is not asked', (tester) async {
    final (_, coach) = await _open(tester, motivation: '', satz: 'x');
    expect(coach.calls, 0);
    expect(find.byKey(const ValueKey('warum-karte')), findsNothing);
  });
}
