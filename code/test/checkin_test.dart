import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/checkin/checkin_evaluator.dart';
import 'package:coach_app/checkin/checkin_questions.dart';
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

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
  await tester.pump();
}

/// Taps the first answer in every row and sends.
Future<void> answerAll(WidgetTester tester, {String note = ''}) async {
  for (final row in checkInRows) {
    await tapText(tester, row.options.first);
  }
  if (note.isNotEmpty) {
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), note);
    await tester.pump();
  }
  await tester.tap(find.text('Absenden'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('check-in opens by itself and saves one tap per area', (
    tester,
  ) async {
    final diary = MemoryDiaryStore();
    await openApp(tester, diary);
    expect(find.text('Wie war dein Tag?'), findsOneWidget);

    await answerAll(tester, note: 'Chef war krank');
    final c = diary.checkIns.single;
    expect(dayKey(c.datum), '2026-10-12');
    expect(
      [c.training, c.ernaehrung, c.schlaf, c.energie, c.mindset, c.notiz],
      [
        'Gut trainiert',
        'Strukturiert gegessen',
        'Gut geschlafen',
        'Hoch',
        'Alles durchgezogen',
        'Chef war krank',
      ],
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
    expect(find.text('Wie war dein Tag?'), findsOneWidget);
  });

  testWidgets('send only works once every row is tapped', (tester) async {
    final diary = MemoryDiaryStore();
    await openApp(tester, diary);
    for (final row in checkInRows.take(4)) {
      await tapText(tester, row.options.last);
    }
    await tester.tap(find.text('Absenden'));
    await tester.pumpAndSettle();
    expect(diary.checkIns, isEmpty);

    await tapText(tester, 'Kaum Motivation');
    await tester.tap(find.text('Absenden'));
    await tester.pumpAndSettle();
    expect(diary.checkIns.single.mindset, 'Kaum Motivation');
    expect(diary.checkIns.single.energie, 'Niedrig');
  });
}
