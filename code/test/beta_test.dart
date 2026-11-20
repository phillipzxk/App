import 'package:coach_app/beta/beta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Feedback geben: Text abschicken zeigt Danke', (tester) async {
    String? gesendet;
    await tester.pumpWidget(
      MaterialApp(
        home: FeedbackSeite(
          senden: (t) async {
            gesendet = t;
            return true;
          },
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('feedback-feld')),
      'Check-in zu lang',
    );
    await tester.tap(find.byKey(const ValueKey('feedback-senden')));
    await tester.pumpAndSettle();
    expect(gesendet, 'Check-in zu lang');
    expect(find.byKey(const ValueKey('feedback-danke')), findsOneWidget);
  });

  testWidgets('Feedback: Fehler bleibt auf der Seite', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: FeedbackSeite(senden: (_) async => false)),
    );
    await tester.enterText(find.byKey(const ValueKey('feedback-feld')), 'x');
    await tester.tap(find.byKey(const ValueKey('feedback-senden')));
    await tester.pumpAndSettle();
    expect(find.textContaining('nicht geklappt'), findsOneWidget);
  });

  testWidgets('Neue Version: goldene Karte erscheint und geht weg', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BetaUpdateHinweis(
          pruefen: () async => (build: 5, apk: 'https://x/groundset.apk'),
          child: const Scaffold(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Neue Version da'), findsOneWidget);
    await tester.tap(find.byTooltip('Später'));
    await tester.pumpAndSettle();
    expect(find.text('Neue Version da'), findsNothing);
  });

  test('neueVersion vergleicht mit der eigenen Build-Nummer', () async {
    final c = MockClient(
      (_) async => http.Response('{"build": 3, "apk": "a.apk"}', 200),
    );
    final v = await neueVersion(client: c);
    // In tests BETA_BUILD is 0, so build 3 is newer.
    expect(v?.build, 3);
    expect(v?.apk, 'a.apk');
    final alt = MockClient((_) async => http.Response('{"build": 0}', 200));
    expect(await neueVersion(client: alt), isNull);
  });
}
