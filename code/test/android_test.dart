import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/erinnerungen/erinnerung_dienst.dart';
import 'package:coach_app/health/health_android.dart';
import 'package:coach_app/health/health_daten.dart';
import 'package:coach_app/health/health_dienst.dart';
import 'package:coach_app/health/health_verbinden.dart';
import 'package:coach_app/kalender/kalender_dienst.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/plattform/plattform.dart';
import 'package:coach_app/schlaf/schritt_zaehler.dart';
import 'package:coach_app/schlaf/wecker_klingelt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

import 'helpers.dart';

/// Android version (vault Umsetzung/Android nachziehen.md). Widget tests
/// run as Android unless a test says otherwise.
class _Health implements HealthDienst {
  @override
  bool get moeglich => true;
  @override
  Future<bool> verbunden() async => false;
  @override
  Future<bool> verbinden() async => true;
  @override
  Future<HealthTag?> lesen(DateTime heute) async => null;
}

void main() {
  testWidgets('names on Android', (tester) async {
    expect(istAndroid, isTrue);
    expect(healthName, 'Health Connect');
    expect(HandyKalender().name, 'Handy-Kalender');
    expect(healthWurzeln, isNot(contains('Tageslicht')));
    expect(healthWurzeln, hasLength(6));
    expect(healthFuerPlattform(), isA<HealthConnect>());
    expect(kalenderFuerPlattform(), isA<HandyKalender>());
    expect(schrittZaehlerFuerPlattform(), isA<HandySchritte>());
  });

  testWidgets('names on the iPhone stay', (tester) async {
    expect(healthName, 'Apple Health');
    expect(HandyKalender().name, 'iPhone-Kalender');
    expect(healthWurzeln, contains('Tageslicht'));
    expect(healthFuerPlattform(), isA<HandyHealth>());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Health Connect page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HealthVerbindenSeite(dienst: _Health())),
    );
    expect(find.text('Mit Health Connect verbinden'), findsOneWidget);
    expect(find.text('Tageslicht'), findsNothing);
  });

  test('workouts get the same German names as on the iPhone', () {
    expect(trainingName(HealthWorkoutActivityType.RUNNING), 'Laufen');
    expect(
      trainingName(HealthWorkoutActivityType.STRENGTH_TRAINING),
      'Krafttraining',
    );
    expect(trainingName(HealthWorkoutActivityType.GOLF), 'Training');
  });

  test('date on the ringing alarm', () {
    expect(weckerDatum(DateTime(2026, 11, 22, 6, 30)), 'So, 22. November');
  });

  testWidgets('ringing alarm: 5 Min only when switched on', (tester) async {
    final antworten = <bool>[];
    Future<void> zeige(bool schlummern) => tester.pumpWidget(
      MaterialApp(
        home: WeckerKlingeltSeite(
          key: ValueKey(schlummern),
          name: 'Phillip',
          clock: () => DateTime(2026, 11, 22, 6, 30),
          schlummern: schlummern,
          onAntwort: antworten.add,
        ),
      ),
    );
    await zeige(true);
    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('Guten Morgen, Phillip'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wecker-schlummern')));
    await zeige(false);
    expect(find.byKey(const ValueKey('wecker-schlummern')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('wecker-aufstehen')));
    // A second tap does nothing.
    await tester.tap(find.byKey(const ValueKey('wecker-aufstehen')));
    expect(antworten, [false, true]);
  });

  testWidgets('the alarm rings over the app, Aufstehen opens the task', (
    tester,
  ) async {
    final dienst = StilleErinnerungen();
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(
          const UserProfile(name: 'Phillip', ziel: 'Frei sein'),
        ),
        diary: MemoryDiaryStore(),
        feed: MemoryFeedStore(),
        clock: () => DateTime(2026, 6, 7, 6, 30),
        erinnerungen: dienst,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wecker-klingelt')), findsNothing);
    dienst.klingeln(DateTime(2026, 6, 7, 6, 30));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('wecker-klingelt')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wecker-aufstehen')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('wecker-klingelt')), findsNothing);
    expect(dienst.aufgabeSeit, isNotNull);
    expect(find.byKey(const ValueKey('wecker-aufgabe-karte')), findsOneWidget);
  });

  test('the alarm ids stay out of the other reminders', () {
    expect(AndroidWecker.wecker, greaterThanOrEqualTo(9000));
    expect(AndroidWecker.nochmal, greaterThanOrEqualTo(9000));
    expect(AndroidWecker.nachklingeln, greaterThanOrEqualTo(9000));
    expect(AndroidWecker.payload, startsWith('wecker|'));
  });
}
