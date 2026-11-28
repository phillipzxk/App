import 'package:coach_app/home/day_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rundgang 2026-11-28, Seite 10: Dein Tag.
void main() {
  testWidgets(
    'Zeitstrahl zuerst, Kapsel als Zeile, Training ohne Zeit unter Jetzt',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DayPlanCard(
                today: DateTime(2026, 11, 28, 16, 0),
                termine: const [],
                training: 'Push',
                mahlzeiten: 3,
                kcalZiel: null,
                onAddTermin: (_) async {},
                onRemoveTermin: (_) async {},
                onSetMahlzeiten: (_) async {},
                mahlzeitZeiten: const [
                  (8 * 60, 'Frühstück'),
                  (22 * 60, 'Abendessen'),
                ],
                extra: const [
                  (
                    minute: 21 * 60,
                    art: 'Kapsel',
                    titel: 'Magnesium',
                    text: '300 mg',
                    erledigt: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Magnesium'), findsOneWidget);
      expect(find.text('heute'), findsOneWidget);
      double y(String s) => t.getTopLeft(find.text(s)).dy;
      // Push (no time) right under Jetzt, before Magnesium at 21:00.
      expect(y('Push'), lessThan(y('Magnesium')));
      expect(y('Magnesium'), lessThan(y('Abendessen')));
      // Setting up the day comes after the time line.
      expect(y('Abendessen'), lessThan(y('Termine und Mahlzeiten')));
    },
  );
}
