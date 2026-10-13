import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/checkin/checkin_evaluator.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class FixedReply implements CheckInEvaluator {
  const FixedReply(this.text);

  final String text;

  @override
  Future<String?> reply(UserProfile p, CheckIn t, List<CheckIn> r) async =>
      text;
}

Future<void> openApp(
  WidgetTester tester,
  MemoryDiaryStore diary, {
  CheckInEvaluator evaluator = const NoCheckInEvaluator(),
}) async {
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(const UserProfile(ziel: 'Frei sein')),
      diary: diary,
      feed: MemoryFeedStore(),
      checkInEvaluator: evaluator,
      clock: fixedClock,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> answerAll(WidgetTester tester) async {
  for (var i = 1; i <= 4; i++) {
    await tester.enterText(find.byType(TextField), 'Antwort $i');
    await tester.pump();
    await tester.tap(find.text(i < 4 ? 'Weiter' : 'Absenden'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('check-in opens by itself and saves four answers', (
    tester,
  ) async {
    final diary = MemoryDiaryStore();
    await openApp(tester, diary);
    expect(find.textContaining('FRAGE 1 VON 4 · TRAINING'), findsOneWidget);
    expect(
      find.textContaining('falls du heute nicht trainiert'),
      findsOneWidget,
    );
    expect(find.byTooltip('Zurück'), findsNothing);

    await answerAll(tester);
    final c = diary.checkIns.single;
    expect(dayKey(c.datum), '2026-10-12');
    expect(
      [c.training, c.ernaehrung, c.schlaf, c.mindset],
      ['Antwort 1', 'Antwort 2', 'Antwort 3', 'Antwort 4'],
    );
    expect(
      find.textContaining('Sobald dein Coach freigeschaltet'),
      findsOneWidget,
    );

    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(find.text('MONTAG, 12. OKTOBER'), findsOneWidget);
    expect(find.text('DEIN COACH · HEUTE'), findsOneWidget);
    expect(find.text('Check-in starten'), findsNothing);
  });

  testWidgets('AI reply is shown and appears in the Main Feed', (tester) async {
    final diary = MemoryDiaryStore();
    await openApp(tester, diary, evaluator: const FixedReply('Guter Tag.'));
    await answerAll(tester);
    expect(find.text('Guter Tag.'), findsOneWidget);
    expect(diary.checkIns.single.kiAntwort, 'Guter Tag.');

    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(find.text('Guter Tag.'), findsOneWidget);
  });

  testWidgets('after today\'s check-in the app opens the Main Feed', (
    tester,
  ) async {
    final diary = MemoryDiaryStore()
      ..checkIns.add(checkInOn(fixedNow, reply: 'Weiter so.'));
    await openApp(tester, diary);
    expect(find.text('MONTAG, 12. OKTOBER'), findsOneWidget);
    expect(find.text('Weiter so.'), findsOneWidget);
  });

  testWidgets('yesterday\'s check-in does not count for today', (tester) async {
    final diary = MemoryDiaryStore()
      ..checkIns.add(checkInOn(DateTime(2026, 10, 11)));
    await openApp(tester, diary);
    expect(find.textContaining('FRAGE 1 VON 4'), findsOneWidget);
  });

  testWidgets('back keeps earlier answers', (tester) async {
    await openApp(tester, MemoryDiaryStore());
    await tester.enterText(find.byType(TextField), 'Gut trainiert');
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Gut trainiert'), findsOneWidget);
  });
}
