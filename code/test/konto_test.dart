import 'dart:convert';

import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/konto/konto_daten.dart';
import 'package:coach_app/konto/konto_dienst.dart';
import 'package:coach_app/konto/konto_einstellungen.dart';
import 'package:coach_app/konto/sicherung.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _profile = UserProfile(
  name: 'Phillip',
  ziel: 'Fitter und stärker werden\nDein Ziel in einem Satz: Mehr durchziehen',
  motivation: 'Stolz sein.',
);

Future<(MemoryKontoStore, Map<String, List<int>>)> _open(
  WidgetTester tester, {
  UserProfile profile = _profile,
  Map<String, List<int>>? server,
}) async {
  final dateien = server ?? <String, List<int>>{};
  final store = MemoryKontoStore();
  tallView(tester);
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(profile),
      diary: MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow)),
      feed: MemoryFeedStore(),
      clock: fixedClock,
      kontoDienst: VorschauKontoDienst(dateien: dateien),
      kontoStore: store,
    ),
  );
  await tester.pumpAndSettle();
  return (store, dateien);
}

Future<void> _mitCode(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('konto-email')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('konto-mail')),
    'phillip@beispiel.de',
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('konto-code-senden')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('konto-code')), '481207');
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('goal sentence comes from the field of question 1', () {
    expect(_profile.zielSatz, 'Mehr durchziehen');
    expect(
      const UserProfile(ziel: 'Fitter und stärker werden; Mehr Fokus').zielSatz,
      'Fitter und stärker werden',
    );
  });

  testWidgets('after the questionnaire: account with e-mail code, then '
      '"Gesichert" with name and goal, then the app', (tester) async {
    SharedPreferences.setMockInitialValues({'trainingsplan': '"Push"'});
    final (store, server) = await _open(tester);
    expect(find.text('Bau dein Fundament\nfürs Leben.'), findsOneWidget);

    await _mitCode(tester);
    expect(find.text('Phillip, dein\nFundament steht.'), findsOneWidget);
    expect(find.text('„Mehr durchziehen“'), findsOneWidget);
    expect(store.konto?.email, 'phillip@beispiel.de');
    // Backed up straight away.
    expect(
      server.keys,
      containsAll(['vorschau/daten.json', 'vorschau/fotos.json']),
    );
    final daten =
        jsonDecode(utf8.decode(server['vorschau/daten.json']!)) as Map;
    expect(daten['trainingsplan'], '"Push"');
    expect(store.stand.zuletzt, isNotNull);

    await tester.tap(find.byKey(const ValueKey('konto-weiter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('konto-oeffnen')), findsOneWidget);
  });

  testWidgets('a wrong code length is not accepted', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('konto-email')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('konto-mail')),
      'keine-mail',
    );
    await tester.pump();
    final knopf = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(const ValueKey('konto-code-senden')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(knopf.properties.enabled, isFalse);
  });

  testWidgets('settings: state, photo switch, sign out', (tester) async {
    final (store, server) = await _open(tester);
    await _mitCode(tester);
    await tester.tap(find.byKey(const ValueKey('konto-weiter')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('konto-oeffnen')));
    await tester.pumpAndSettle();
    expect(find.text('Konto und Sicherung'), findsOneWidget);
    expect(find.text('Alles gesichert'), findsOneWidget);
    expect(find.text('phillip@beispiel.de'), findsOneWidget);

    // Photos off: the next backup leaves them out.
    await tester.tap(find.byKey(const ValueKey('schalter-fotos')));
    await tester.pumpAndSettle();
    expect(store.stand.fotosSichern, isFalse);
    server.clear();
    await tester.tap(find.byKey(const ValueKey('jetzt-sichern')));
    await tester.pumpAndSettle();
    expect(server.keys, ['vorschau/daten.json']);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('abmelden')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(KontoEinstellungen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('abmelden')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dialog-ja')));
    await tester.pumpAndSettle();
    expect(store.konto, isNull);
    expect(find.text('Bau dein Fundament\nfürs Leben.'), findsOneWidget);
  });

  testWidgets('new phone: "Ich habe schon ein Konto" brings the backup back', (
    tester,
  ) async {
    final server = {
      'vorschau/daten.json': utf8.encode(
        jsonEncode({'trainingsplan': '"Beine"', 'checkins': jsonEncode([])}),
      ),
    };
    // Profile keys come back too: profile store reads SharedPreferences in
    // the real app; here we check the restored data itself.
    await _open(tester, profile: const UserProfile(), server: server);
    await tester.tap(find.byKey(const ValueKey('schon-konto')));
    await tester.pumpAndSettle();
    expect(find.text('Willkommen zurück.'), findsOneWidget);
    await _mitCode(tester);
    expect(find.text('ZURÜCKGEHOLT'), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getString('trainingsplan'), '"Beine"');
  });

  test('export holds all data but not the session', () async {
    SharedPreferences.setMockInitialValues({
      'konto': '{"access":"geheim"}',
      'checkins': '[]',
    });
    final store = MemoryKontoStore()
      ..konto = const Konto(id: 'x', email: 'a@b.de', art: Anmeldeart.google);
    final s = Sicherung(dienst: VorschauKontoDienst(), store: store);
    final text = await s.export();
    expect(text, contains('"checkins"'));
    expect(text, contains('Google'));
    expect(text, isNot(contains('geheim')));
  });

  test('sizes and times read well', () {
    expect(formatGroesse(214 * 1024 * 1024), '214 MB');
    expect(formatGroesse(1536 * 1024), '1,5 MB');
    expect(formatGroesse(2000), '2 KB');
    final j = DateTime(2026, 11, 1, 12);
    expect(
      formatZuletzt(j.subtract(const Duration(minutes: 2)), j),
      'vor 2 Min.',
    );
    expect(formatZuletzt(null, j), 'noch nie');
  });
}
