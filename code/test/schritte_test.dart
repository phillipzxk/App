import 'dart:async';

import 'package:coach_app/schlaf/schlaf_data.dart';
import 'package:coach_app/schlaf/schritt_weg.dart';
import 'package:coach_app/schlaf/schritt_zaehler.dart';
import 'package:coach_app/schlaf/wecker_aufgabe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Zaehler implements SchrittZaehler {
  final c = StreamController<int>();

  @override
  bool get moeglich => true;

  @override
  Stream<int> zaehlen() => c.stream;
}

void main() {
  var t = DateTime(2026, 11, 5, 6, 30);
  DateTime uhr() => t;

  test('Sätze für den Wach-Bildschirm und den Coach', () {
    expect(
      schritteSatz(30, const Duration(seconds: 41)),
      '30 Schritte in 41 Sekunden',
    );
    expect(
      schritteSatz(50, const Duration(seconds: 75)),
      '50 Schritte in 1:15 Minuten',
    );
    expect(
      morgenSatz(30, const Duration(seconds: 41), 2),
      'Heute Morgen: 30 Schritte in 41 Sekunden, 2 Minuten nach dem Wecker.',
    );
  });

  test('Anzahl wird gespeichert, sonst 30', () {
    expect(Wecker.fromJson(const {}).schritte, 30);
    final w = const Wecker().copyWith(schritte: 50);
    expect(Wecker.fromJson(w.toJson()).schritte, 50);
  });

  testWidgets('ohne Zähler: tippen bis zum Ziel', (tester) async {
    int? fertig;
    await tester.pumpWidget(
      MaterialApp(
        home: SchrittWeg(ziel: 3, clock: uhr, onFertig: (n, _) => fertig = n),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('schritte-frage')), findsNothing);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('schritte-tipp')));
      await tester.pump();
    }
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(fertig, 3);
  });

  testWidgets('erstes Mal: fragen, dann zählt das iPhone', (tester) async {
    final z = _Zaehler();
    final wahl = MemorySchrittWahl();
    Duration? dauer;
    t = DateTime(2026, 11, 5, 6, 30);
    await tester.pumpWidget(
      MaterialApp(
        home: SchrittWeg(
          ziel: 30,
          zaehler: z,
          wahl: wahl,
          clock: uhr,
          onFertig: (_, d) => dauer = d,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('schritte-frage')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schritte-erlauben')));
    await tester.pump();
    expect(wahl.wert, isTrue);
    z.c.add(12);
    await tester.pump();
    expect(find.text('12'), findsOneWidget);
    t = t.add(const Duration(seconds: 41));
    z.c.add(31);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    expect(dauer, const Duration(seconds: 41));
  });

  testWidgets('Zählen klappt nicht: weiter mit Tippen', (tester) async {
    final z = _Zaehler();
    await tester.pumpWidget(
      MaterialApp(
        home: SchrittWeg(
          ziel: 20,
          zaehler: z,
          wahl: MemorySchrittWahl(true),
          clock: uhr,
          onFertig: (_, _) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    z.c.addError('nein');
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('schritte-tipp')), findsOneWidget);
    expect(find.textContaining('Zählen klappt gerade nicht'), findsOneWidget);
  });

  testWidgets('Wecker-Aufgabe: Schritte, dann „Du bist wach“ mit Zeile', (
    tester,
  ) async {
    String? morgen;
    t = DateTime(2026, 11, 5, 6, 32);
    await tester.pumpWidget(
      MaterialApp(
        home: WeckerAufgabe(
          name: 'Phillip',
          aufgabe: 'schritte',
          schritte: 20,
          geklingelt: DateTime(2026, 11, 5, 6, 30),
          clock: uhr,
          onMorgen: (m) => morgen = m,
          onFertig: () {},
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.tap(find.byKey(const ValueKey('schritte-tipp')));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    expect(find.byKey(const ValueKey('wecker-wach')), findsOneWidget);
    expect(find.text('20 Schritte in 0 Sekunden'), findsOneWidget);
    expect(morgen, contains('2 Minuten nach dem Wecker'));
  });
}
