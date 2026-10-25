import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/durchgezogen.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/fokus.dart';
import 'package:coach_app/feed/muster.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _PunkteCoach implements FeedCoach {
  @override
  Future<String?> warumSatz(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) async => null;

  int calls = 0;

  @override
  Future<String?> answer(
    UserProfile profile,
    Bereich bereich,
    String text, {
    String context = '',
  }) async => null;

  @override
  Future<Muster?> findeMuster(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> bisher,
  ) async => null;

  @override
  Future<FokusAuswahl?> fokusVorschlaege(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> muster, {
    Wochenfokus? letzter,
    TrainingWoche? training,
  }) async => null;

  @override
  Future<List<String>?> stichpunkte(String text) async {
    calls++;
    return ['Schlaf ist der Hebel', 'Heute 22:00 Handy weg'];
  }

  @override
  Future<String?> durchgezogen(
    UserProfile profile,
    CheckIn today, {
    String? fokus,
    bool fokusGeschafft = false,
    List<Durchgezogen> bisher = const [],
  }) async => null;
}

const _antwort =
    'Phillip, dein Schlaf ist heute der Hebel. Leg das Handy um 22:00 weg.';

void main() {
  testWidgets('coach reply as points, folded and unfolded again', (
    tester,
  ) async {
    final diary = MemoryDiaryStore()
      ..checkIns.add(checkInOn(fixedNow, reply: _antwort));
    final feed = MemoryFeedStore();
    final coach = _PunkteCoach();
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(const UserProfile(ziel: 'Frei sein')),
        diary: diary,
        feed: feed,
        feedCoach: coach,
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_antwort), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('coach-als-punkte')));
    await tester.pumpAndSettle();
    expect(find.text('Heute 22:00 Handy weg'), findsOneWidget);
    expect(find.text(_antwort), findsNothing);
    expect(diary.checkIns.single.stichpunkte, hasLength(2));
    expect(feed.coachAnsicht, 'punkte');

    await tester.tap(find.byKey(const ValueKey('coach-klappen')));
    await tester.pumpAndSettle();
    expect(find.text('Heute 22:00 Handy weg'), findsNothing);
    expect(find.text('Aufklappen'), findsOneWidget);
    expect(feed.coachAnsicht, 'zu:punkte');

    await tester.tap(find.byKey(const ValueKey('coach-aufklappen')));
    await tester.pumpAndSettle();
    expect(find.text('Heute 22:00 Handy weg'), findsOneWidget);

    // Back to text and to points again: no second request.
    await tester.tap(find.byKey(const ValueKey('coach-als-text')));
    await tester.pumpAndSettle();
    expect(find.text(_antwort), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('coach-als-punkte')));
    await tester.pumpAndSettle();
    expect(coach.calls, 1);
  });

  test('a new reply drops the old points', () {
    final c = checkInOn(fixedNow, reply: 'a').withStichpunkte(['x', 'y']);
    expect(CheckIn.fromJson(c.toJson()).stichpunkte, ['x', 'y']);
    expect(c.withReply('b').stichpunkte, isEmpty);
  });
}
