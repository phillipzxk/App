import 'package:coach_app/home/fundament_seite.dart';
import 'package:coach_app/home/wurzelwerk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Fundament after the walkthrough of 2026-11-26 (vault Umsetzung/Rundgang
// 2026-11-26.md).
void main() {
  testWidgets('a number in the gold tile scrolls to its capsule without '
      'opening it', (tester) async {
    final geoeffnet = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FundamentSeite(
            bereiche: const [
              WurzelBereich(
                id: 'koerper',
                name: 'Körper',
                icon: Icons.add,
                wert: 6,
                teile: ['Training', 'Essen', 'Schlaf'],
              ),
              WurzelBereich(
                id: 'produktiv',
                name: 'Fokus & Arbeit',
                icon: Icons.add,
                wert: 6,
              ),
              WurzelBereich(
                id: 'persoenlich',
                name: 'Ausstrahlung',
                icon: Icons.add,
                wert: 5,
              ),
              WurzelBereich(
                id: 'mindset',
                name: 'Mindset',
                icon: Icons.add,
                wert: 7,
                infos: [('Durchgezogen', '0 Mal'), ('x', 'y')],
              ),
            ],
            onOpen: (id, _) async => geoeffnet.add(id),
            lebensziele: const GoldStein(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Training · Essen · Schlaf'), findsOneWidget);
    // Only the first info, so the line fits.
    expect(find.text('Durchgezogen 0 Mal'), findsOneWidget);
    final kapsel = find.byKey(const ValueKey('wurzel-mindset'));
    final vorher = tester.getCenter(kapsel).dy;
    await tester.tap(find.byKey(const ValueKey('schnitt-mindset')));
    await tester.pumpAndSettle();
    expect(tester.getCenter(kapsel).dy, lessThan(vorher));
    expect(geoeffnet, isEmpty);
  });
}
