import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/onboarding/onboarding_evaluator.dart';
import 'package:coach_app/onboarding/onboarding_questions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class FixedEvaluator implements OnboardingEvaluator {
  const FixedEvaluator(this.text);

  final String text;

  @override
  Future<String?> summarize(UserProfile answers) async => text;
}

Future<void> enterName(WidgetTester tester, [String name = 'Max']) async {
  await tester.enterText(find.byType(TextField), name);
  await tester.pump();
  await tester.tap(find.text('Weiter'));
  await tester.pumpAndSettle();
}

/// Question 1: taps the first answer and writes the goal; questions 2-6:
/// only write a text (taps alone are tested separately).
Future<void> answerAll(WidgetTester tester) async {
  await enterName(tester);
  await tester.tap(find.text('Fitter und stärker werden'));
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
      CoachApp(
        store: store,
        diary: MemoryDiaryStore(),
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wie heißt du?'), findsOneWidget);
    await answerAll(tester);

    final p = store.profile;
    expect(p.name, 'Max');
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
        'Fitter und stärker werden\nDein Ziel in einem Satz: Antwort 1',
        'Was ist dein wahrer Grund?: Antwort 2',
        'Und was würde diese Person als deine Stärke nennen?: Antwort 3',
        'Und was fällt dir dabei leicht?: Antwort 4',
        'Was weißt du schon, oder was hast du an deiner Ernährung bereits '
            'angepasst?: Antwort 5',
        'Und wann fühlst du dich richtig fit?: Antwort 6',
      ],
    );
    expect(p.zusammenfassung, isEmpty);
    expect(find.text('So sehe ich dich gerade'), findsOneWidget);
    expect(find.textContaining('Auswertung kommt bald'), findsOneWidget);

    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();
    expect(find.text('Wie war dein Tag?'), findsOneWidget);
  });

  testWidgets('summary from the evaluator is shown and saved', (tester) async {
    final store = MemoryProfileStore();
    await tester.pumpWidget(
      CoachApp(
        store: store,
        diary: MemoryDiaryStore(),
        feed: MemoryFeedStore(),
        evaluator: const FixedEvaluator('Du bist dran.'),
      ),
    );
    await tester.pumpAndSettle();
    await answerAll(tester);

    expect(find.text('Du bist dran.'), findsOneWidget);
    expect(store.profile.zusammenfassung, 'Du bist dran.');
  });

  testWidgets('empty name cannot continue', (tester) async {
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(),
        diary: MemoryDiaryStore(),
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  ');
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Wie heißt du?'), findsOneWidget);
  });

  testWidgets('the goal is required, the other fields are not', (tester) async {
    final store = MemoryProfileStore();
    await tester.pumpWidget(
      CoachApp(
        store: store,
        diary: MemoryDiaryStore(),
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await enterName(tester);

    // Tapping alone is not enough on question 1.
    await tester.tap(find.text('Mehr Energie im Alltag'));
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 1 VON 6'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Fit bleiben');
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    // Questions 2-6: one tap is enough.
    for (var i = 2; i <= 6; i++) {
      final q = onboardingQuestions[i - 1];
      await tester.tap(find.text(q.options.first));
      await tester.pump();
      await tester.tap(find.text(i < 6 ? 'Weiter' : 'Fertig'));
      await tester.pumpAndSettle();
    }
    expect(
      store.profile.ziel,
      'Mehr Energie im Alltag\nDein Ziel in einem Satz: Fit bleiben',
    );
    expect(store.profile.schlafEnergie, 'Ich schlafe schlecht ein');
  });

  testWidgets('empty answer cannot continue', (tester) async {
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(),
        diary: MemoryDiaryStore(),
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await enterName(tester);
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
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await enterName(tester);
    await tester.enterText(find.byType(TextField), 'Mein Ziel');
    await tester.pump();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 2 VON 6 · MOTIVATION'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.textContaining('FRAGE 1 VON 6'), findsOneWidget);
    expect(find.text('Mein Ziel'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Wie heißt du?'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
  });

  testWidgets('onboarded users go straight to the check-in', (tester) async {
    final store = MemoryProfileStore(const UserProfile(ziel: 'Frei sein'));
    await tester.pumpWidget(
      CoachApp(
        store: store,
        diary: MemoryDiaryStore(),
        feed: MemoryFeedStore(),
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wie war dein Tag?'), findsOneWidget);
  });
}
