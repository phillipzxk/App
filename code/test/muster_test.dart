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

class _MusterCoach implements FeedCoach {
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
  ) async {
    calls++;
    return Muster(
      datum: fixedNow,
      text: 'Nach kurzen Nächten hast du Heißhunger.',
      schritt: 'Eiweiß zum Frühstück.',
      von: 'Schlaf',
      nach: 'Ernährung',
    );
  }

  @override
  Future<FokusAuswahl?> fokusVorschlaege(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> muster, {
    Wochenfokus? letzter,
    TrainingWoche? training,
  }) async => null;

  @override
  Future<List<String>?> stichpunkte(String text) async => null;

  @override
  Future<String?> durchgezogen(
    UserProfile profile,
    CheckIn today, {
    String? fokus,
    bool fokusGeschafft = false,
    List<Durchgezogen> bisher = const [],
  }) async => null;
}

Future<(MemoryFeedStore, _MusterCoach)> _open(
  WidgetTester tester, {
  required int tage,
}) async {
  final diary = MemoryDiaryStore();
  for (var i = tage - 1; i >= 0; i--) {
    diary.checkIns.add(
      checkInOn(DateTime(fixedNow.year, fixedNow.month, fixedNow.day - i)),
    );
  }
  final feed = MemoryFeedStore();
  final coach = _MusterCoach();
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
  return (feed, coach);
}

void main() {
  testWidgets('no pattern card before 5 check-ins', (tester) async {
    final (feed, coach) = await _open(tester, tage: 4);
    expect(coach.calls, 0);
    expect(find.byKey(const ValueKey('muster-karte')), findsNothing);
    expect(feed.muster, isEmpty);
  });

  testWidgets('pattern shows small on Heute, list opens, "Stimmt nicht" '
      'on the Mindset page hides it', (tester) async {
    final (feed, coach) = await _open(tester, tage: 5);
    expect(coach.calls, 1);
    final feld = find.byKey(const ValueKey('muster-feld'));
    await scrollTo(tester, feld);
    expect(find.text('NEUES MUSTER'), findsOneWidget);
    expect(find.byKey(const ValueKey('muster-karte')), findsNothing);

    await tester.tap(feld);
    await tester.pumpAndSettle();
    expect(find.text('Deine Muster'), findsWidgets);
    expect(
      find.textContaining('Eiweiß zum Frühstück.', findRichText: true),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openTab(tester, 'Mindset', 'm-muster');
    await scrollTo(tester, find.byKey(const ValueKey('muster-ablehnen')));
    await tester.tap(find.byKey(const ValueKey('muster-ablehnen')));
    await tester.pumpAndSettle();
    expect(feed.muster.single.abgelehnt, isTrue);
    await openTab(tester, 'Heute');
    expect(find.byKey(const ValueKey('muster-feld')), findsNothing);
    // Checked once today already: no second search.
    expect(coach.calls, 1);
  });
}
