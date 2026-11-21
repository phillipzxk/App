import 'package:coach_app/abo/abo_seite.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/mindset/langfristig.dart';
import 'package:coach_app/mindset/mindset_data.dart';
import 'package:coach_app/onboarding/onboarding_questions.dart';
import 'package:coach_app/onboarding/start_saetze.dart';
import 'package:coach_app/training/training_data.dart';
import 'package:coach_app/training/training_logik.dart';
import 'package:coach_app/training/trainings_modus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The five Rundgang proposals, built 2026-11-21.
void main() {
  test('questions 2 and 3 have a coach line', () {
    expect(onboardingQuestions[1].coach, contains('dein Warum'));
    expect(onboardingQuestions[2].coach, contains('ansetze'));
  });

  test('start sentences follow the tapped answers', () {
    const p = UserProfile(
      koerper: 'Heißhunger, vor allem abends',
      produktiv: 'Ich verliere mich am Handy',
      persoenlich: keineProbleme,
      level: 'Fängt oft an, bleibt aber nicht dran',
    );
    final s = startSaetze(p);
    expect([for (final x in s) x.name], radBereiche);
    expect(s[0].satz, contains('Heißhunger'));
    expect(s[1].satz, contains('ohne Handy'));
    expect(s[2].satz, contains('Läuft schon gut'));
    expect(s[3].satz, contains('durchziehst'));
    // Nothing tapped: a general sentence, never empty.
    expect(
      startSaetze(const UserProfile()).every((x) => x.satz.isNotEmpty),
      isTrue,
    );
  });

  testWidgets('life goals show as stones', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ZielSteine(
            ziele: [
              Lebensziel(text: 'Mit 40 in Topform', bereich: 'Körper'),
              Lebensziel(text: 'Eigene Firma'),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Mit 40 in Topform'), findsOneWidget);
    expect(find.text('Eigene Firma'), findsOneWidget);
  });

  testWidgets('feel question only after the last set, and Satz zurück', (
    t,
  ) async {
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final s = HeuteSession(
      datum: DateTime(2026, 11, 21),
      name: 'Push',
      plan: const [
        PlanUebung(name: 'Bankdrücken', saetze: 2, wert: 80),
        PlanUebung(name: 'Rudern', saetze: 2, wert: 60),
      ],
      logs: const [
        UebungLog(
          name: 'Bankdrücken',
          art: UebungArt.gewicht,
          saetze: [SatzLog(wert: 80, menge: 8), SatzLog(wert: 80, menge: 8)],
        ),
        UebungLog(
          name: 'Rudern',
          art: UebungArt.gewicht,
          saetze: [SatzLog(wert: 60, menge: 8), SatzLog(wert: 60, menge: 8)],
        ),
      ],
      onSpeichern: (_) async {},
    );
    await t.pumpWidget(MaterialApp(home: TrainingsModus(session: s)));
    await t.pump();

    // Set 1 of 2: rest, but no question yet.
    await t.tap(find.text('Satz geschafft'));
    await t.pump();
    expect(find.text('Wie war Bankdrücken?'), findsNothing);
    expect(find.byKey(const ValueKey('modus-satz-zurueck')), findsOneWidget);

    // Satz zurück: the set is open again and we are back on it.
    await t.tap(find.byKey(const ValueKey('modus-satz-zurueck')));
    await t.pump();
    expect(s.logs[0].saetze[0].fertig, isFalse);
    expect(find.text('Satz geschafft'), findsOneWidget);

    // Both sets: now the question comes.
    await t.tap(find.text('Satz geschafft'));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('modus-pause-weg')));
    await t.pump();
    await t.tap(find.text('Satz geschafft'));
    await t.pump();
    expect(find.text('Wie war Bankdrücken?'), findsOneWidget);
    s.pauseStopp();
    s.dispose();
  });

  test('payment text names Google Play on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(bezahltUeber(), 'Google Play');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(bezahltUeber(), 'Apple');
    debugDefaultTargetPlatformOverride = null;
  });
}
