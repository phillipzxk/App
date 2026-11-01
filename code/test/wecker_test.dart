import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/ernaehrung/ernaehrung_coach.dart' as essen;
import 'package:coach_app/erinnerungen/erinnerung_dienst.dart';
import 'package:coach_app/erinnerungen/erinnerung_plan.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/planner/planner_data.dart';
import 'package:coach_app/schlaf/wecker_aufgabe.dart';
import 'package:coach_app/sleep/schlafzeiten.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('dark in winter: Licht an instead of the sky photo', () {
    expect(aufgabeHeute('foto', DateTime(2026, 12, 7, 6, 45)), 'licht');
    expect(aufgabeHeute('foto', DateTime(2026, 6, 7, 6, 45)), 'foto');
    expect(aufgabeHeute('schritte', DateTime(2026, 12, 7, 6, 45)), 'schritte');
  });

  test('an early appointment moves the alarm', () {
    final jetzt = DateTime(2026, 11, 4, 20);
    final l = planeErinnerungen(
      ErinnerungsLage(
        jetzt: jetzt,
        name: 'P',
        schlafzeiten: const Schlafzeiten(werktag: 7 * 60),
        termine: [parseTermin('Arzt morgen 7:30', jetzt)],
      ),
    );
    final w = l.firstWhere((e) => e.art == ErinnerungArt.wecker);
    expect(w.zeit, DateTime(2026, 11, 5, 6, 30));
  });

  testWidgets('Licht an: a dark photo does not count, a bright one does', (
    tester,
  ) async {
    essen.fotoAufnahme = () async => 'eA==';
    var hell = false;
    var fertig = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WeckerAufgabe(
          name: 'Phillip',
          aufgabe: 'foto',
          geklingelt: DateTime(2026, 12, 7, 6, 45),
          heute: 'Heute: Push 17:30.',
          clock: () => DateTime(2026, 12, 7, 6, 47),
          pruefen: (_) async => hell,
          onFertig: () => fertig = true,
        ),
      ),
    );
    expect(find.text('Licht an'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wecker-aufgabe-los')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wecker-aufgabe-fehler')), findsOneWidget);
    hell = true;
    await tester.tap(find.byKey(const ValueKey('wecker-aufgabe-los')));
    await tester.pumpAndSettle();
    expect(find.text('Du bist wach, Phillip.'), findsOneWidget);
    expect(find.textContaining('2 Minuten nach dem Wecker'), findsOneWidget);
    expect(find.textContaining('Heute: Push 17:30.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wecker-weiter')));
    expect(fertig, isTrue);
  });

  testWidgets('after Aufstehen the task comes before the check-in', (
    tester,
  ) async {
    final dienst = StilleErinnerungen()
      ..aufgabeSeit = DateTime(2026, 6, 7, 6, 45);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(
          const UserProfile(name: 'Phillip', ziel: 'Frei sein'),
        ),
        diary: MemoryDiaryStore(),
        feed: MemoryFeedStore(),
        clock: () => DateTime(2026, 6, 7, 6, 46),
        erinnerungen: dienst,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wecker-aufgabe-karte')), findsOneWidget);
    expect(find.text('Foto vom Himmel'), findsOneWidget);
    essen.fotoAufnahme = () async => 'eA==';
    await tester.tap(find.byKey(const ValueKey('wecker-aufgabe-los')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wecker-weiter')));
    await tester.pumpAndSettle();
    expect(dienst.aufgabeSeit, isNull);
    expect(find.byKey(const ValueKey('wecker-aufgabe-karte')), findsNothing);
  });
}
