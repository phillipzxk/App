import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/onboarding/onboarding_evaluator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class FixedEvaluator implements OnboardingEvaluator {
  const FixedEvaluator(this.text);

  final String text;

  @override
  Future<String?> summarize(UserProfile answers) async => text;
}

Future<void> answerAll(WidgetTester tester) async {
  for (var i = 1; i <= 6; i++) {
    await tester.enterText(find.byType(TextField), 'Antwort $i');
    await tester.pump();
    await tester.tap(find.text(i < 6 ? 'Weiter' : 'Fertig'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('six answers are stored in the right fields', (tester) async {
    final store = MemoryProfileStore();
    await tester.pumpWidget(
      CoachApp(store: store, diary: MemoryDiaryStore(), clock: fixedClock),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('FRAGE 1 VON 6 · ZIEL'), findsOneWidget);
    await answerAll(tester);

    final p = store.profile;
    expect(
      [
        p.ziel,
        p.motivation,
        p.level,
        p.training,
        p.ernaehrung,
        p.schlafEnergie,
      ],
      [
        'Antwort 1',
        'Antwort 2',
        'Antwort 3',
        'Antwort 4',
        'Antwort 5',
        'Antwort 6',
      ],
    );
    expect(p.zusammenfassung, isEmpty);
    expect(find.text('So sehe ich dich gerade'), findsOneWidget);
    expect(find.textContaining('Auswertung kommt bald'), findsOneWidget);

    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 1 VON 4 · TRAINING'), findsOneWidget);
  });

  testWidgets('summary from the evaluator is shown and saved', (tester) async {
    final store = MemoryProfileStore();
    await tester.pumpWidget(
      CoachApp(
        store: store,
        diary: MemoryDiaryStore(),
        evaluator: const FixedEvaluator('Du bist dran.'),
      ),
    );
    await tester.pumpAndSettle();
    await answerAll(tester);

    expect(find.text('Du bist dran.'), findsOneWidget);
    expect(store.profile.zusammenfassung, 'Du bist dran.');
  });

  testWidgets('empty answer cannot continue', (tester) async {
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(),
        diary: MemoryDiaryStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 1 VON 6'), findsOneWidget);
  });

  testWidgets('back keeps the earlier answer', (tester) async {
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(),
        diary: MemoryDiaryStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mein Ziel');
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 2 VON 6 · MOTIVATION'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 1 VON 6'), findsOneWidget);
    expect(find.text('Mein Ziel'), findsOneWidget);
  });

  testWidgets('onboarded users go straight to the check-in', (tester) async {
    final store = MemoryProfileStore(const UserProfile(ziel: 'Frei sein'));
    await tester.pumpWidget(
      CoachApp(store: store, diary: MemoryDiaryStore(), clock: fixedClock),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 1 VON 4'), findsOneWidget);
  });
}
