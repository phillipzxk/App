import 'package:coach_app/feed/muster.dart';
import 'package:coach_app/home/sonnenbogen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Heute after the walkthrough of 2026-11-26 (vault Umsetzung/Rundgang
// 2026-11-26.md).
void main() {
  Widget bogen(List<BogenPunkt> punkte) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 340,
        child: HeuteBogen(
          punkte: punkte,
          start: 6 * 60,
          ende: 23 * 60,
          jetzt: 13 * 60.0,
          held: true,
        ),
      ),
    ),
  );

  testWidgets('Heute dran: dashed signs while getting up, training or bed '
      'are missing', (tester) async {
    await tester.pumpWidget(bogen(const []));
    expect(find.byKey(const ValueKey('heute-zeichen')), findsOneWidget);
    expect(find.text('Noch offen: Aufstehen, Training, Bett'), findsOneWidget);

    await tester.pumpWidget(
      bogen(const [
        BogenPunkt(id: 'a', minute: 7 * 60, art: 'Aufstehen', titel: 'Auf'),
        BogenPunkt(id: 's', minute: 22 * 60, art: 'Schlaf', titel: 'Bett'),
      ]),
    );
    expect(find.text('Noch offen: Training'), findsOneWidget);

    await tester.pumpWidget(
      bogen(const [
        BogenPunkt(id: 'a', minute: 7 * 60, art: 'Aufstehen', titel: 'Auf'),
        BogenPunkt(id: 't', minute: 17 * 60, art: 'Training', titel: 'Push'),
        BogenPunkt(id: 's', minute: 22 * 60, art: 'Schlaf', titel: 'Bett'),
      ]),
    );
    expect(find.byKey(const ValueKey('heute-zeichen')), findsNothing);
  });

  test('a pattern shows its short sentence on Heute, older ones the full '
      'one', () {
    final m = Muster(
      datum: DateTime(2026, 11, 26),
      text: 'An 4 von 4 guten Nächten hast du strukturiert gegessen.',
      kurz: 'Nach guten Nächten isst du strukturiert.',
      schritt: 'Plane das Mittagessen am Vorabend.',
      von: 'Schlaf',
      nach: 'Ernährung',
    );
    expect(m.heuteText, 'Nach guten Nächten isst du strukturiert.');
    final zurueck = Muster.fromJson(m.toJson());
    expect(zurueck.kurz, m.kurz);
    final alt = Muster.fromJson({
      'datum': '2026-11-20T00:00:00.000',
      'text': 'Langer alter Satz.',
      'schritt': 'x',
      'von': '',
      'nach': '',
    });
    expect(alt.heuteText, 'Langer alter Satz.');
  });
}
