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

Future<MemoryDiaryStore> openFeed(
  WidgetTester tester, {
  CheckInEvaluator evaluator = const NoCheckInEvaluator(),
}) async {
  final diary = MemoryDiaryStore();
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(const UserProfile(ziel: 'Frei sein')),
      diary: diary,
      checkInEvaluator: evaluator,
      clock: fixedClock,
    ),
  );
  await tester.pumpAndSettle();
  return diary;
}

Future<void> answerAll(WidgetTester tester) async {
  await tester.tap(find.text('Check-in starten'));
  await tester.pumpAndSettle();
  for (var i = 1; i <= 4; i++) {
    await tester.enterText(find.byType(TextField), 'Antwort $i');
    await tester.pump();
    await tester.tap(find.text(i < 4 ? 'Weiter' : 'Absenden'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('feed shows the date and an open check-in', (tester) async {
    await openFeed(tester);
    expect(find.text('Montag, 12. Oktober'), findsOneWidget);
    expect(find.text('Check-in starten'), findsOneWidget);
  });

  testWidgets('check-in saves four answers for today', (tester) async {
    final diary = await openFeed(tester);
    await tester.tap(find.text('Check-in starten'));
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 1 VON 4 · TRAINING'), findsOneWidget);
    expect(
      find.textContaining('falls du heute nicht trainiert'),
      findsOneWidget,
    );

    for (var i = 1; i <= 4; i++) {
      await tester.enterText(find.byType(TextField), 'Antwort $i');
      await tester.pump();
      await tester.tap(find.text(i < 4 ? 'Weiter' : 'Absenden'));
      await tester.pumpAndSettle();
    }

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
    expect(find.text('Erledigt für heute ✓'), findsOneWidget);
    expect(find.text('Antwort ansehen'), findsOneWidget);
  });

  testWidgets('AI reply is shown and can be opened again', (tester) async {
    final diary = await openFeed(
      tester,
      evaluator: const FixedReply('Guter Tag.'),
    );
    await answerAll(tester);
    expect(find.text('Guter Tag.'), findsOneWidget);
    expect(diary.checkIns.single.kiAntwort, 'Guter Tag.');

    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Antwort ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Guter Tag.'), findsOneWidget);
  });

  testWidgets('closing on the first question saves nothing', (tester) async {
    final diary = await openFeed(tester);
    await tester.tap(find.text('Check-in starten'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(diary.checkIns, isEmpty);
    expect(find.text('Check-in starten'), findsOneWidget);
  });
}
