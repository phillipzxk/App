import 'package:coach_app/data/profile_store.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryProfileStore implements ProfileStore {
  MemoryProfileStore([this.profile = const UserProfile()]);

  UserProfile profile;

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;

  @override
  Future<void> clear() async => profile = const UserProfile();
}

void main() {
  testWidgets('onboarding stores all answers and opens home', (tester) async {
    final store = MemoryProfileStore();
    await tester.pumpWidget(CoachApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Schön, dass du da bist!'), findsOneWidget);
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();

    expect(find.text('Frage 1 von 4'), findsOneWidget);
    await tester.tap(find.text('Muskeln aufbauen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 bis 2 Mal pro Woche'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zu wenig Zeit'));
    await tester.pumpAndSettle();

    expect(find.text('Frage 4 von 4'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Fitter werden');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(store.profile.ziel, 'muskelaufbau');
    expect(store.profile.level, 'gelegentlich');
    expect(store.profile.ausgangssituation, 'zeit');
    expect(store.profile.onboardingNotiz, 'Fitter werden');

    await tester.tap(find.text('Zum ersten Check-in'));
    await tester.pumpAndSettle();
    expect(
      find.text('Hier kommt bald dein täglicher Check-in.'),
      findsOneWidget,
    );
    expect(find.text('Muskeln aufbauen'), findsOneWidget);
  });

  testWidgets('back button returns to the previous question', (tester) async {
    await tester.pumpWidget(CoachApp(store: MemoryProfileStore()));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mehr Energie im Alltag'));
    await tester.pumpAndSettle();
    expect(find.text('Frage 2 von 4'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Frage 1 von 4'), findsOneWidget);
  });

  testWidgets('skipping the free text leaves the note empty', (tester) async {
    final store = MemoryProfileStore();
    await tester.pumpWidget(CoachApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insgesamt fitter werden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaum oder gar nicht'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ich bleibe nicht dran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();

    expect(store.profile.isOnboarded, isTrue);
    expect(store.profile.onboardingNotiz, isEmpty);
  });

  testWidgets('onboarded users skip the questionnaire', (tester) async {
    final store = MemoryProfileStore(
      const UserProfile(ziel: 'routinen', level: 'regelmaessig'),
    );
    await tester.pumpWidget(CoachApp(store: store));
    await tester.pumpAndSettle();
    expect(
      find.text('Hier kommt bald dein täglicher Check-in.'),
      findsOneWidget,
    );
  });
}
