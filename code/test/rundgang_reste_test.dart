import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(ziel: 'Frei sein', motivation: 'Stolz sein.');

Future<MemoryFeedStore> _open(WidgetTester tester) async {
  final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
  final feed = MemoryFeedStore();
  tallView(tester);
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(_profile),
      diary: diary,
      feed: feed,
      clock: fixedClock,
    ),
  );
  await tester.pumpAndSettle();
  return feed;
}

void main() {
  testWidgets('"Fragebogen neu" lives on Dein Warum, not on Heute', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Fragebogen neu starten'), findsNothing);
    await openTab(tester, 'Mindset');
    await openKachel(tester, 'm-warum');
    await scrollTo(tester, find.byKey(const ValueKey('fragebogen-neu')));
    expect(find.text('Fragebogen neu machen'), findsOneWidget);
  });

  testWidgets('plan: the week strip shows one day at a time', (tester) async {
    final feed = await _open(tester);
    await openTab(tester, 'Training', 't-heute');
    // Monday is today and shown first.
    expect(find.byKey(const ValueKey('plan-name-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-name-3')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('plan-wochentag-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-name-3')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('plan-name-3')),
      'Beine 18:00',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(feed.plan.tage[3], 'Beine 18:00');
  });
}
