import 'dart:convert';
import 'dart:typed_data';

import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/future_me/foto_aufnahme.dart';
import 'package:coach_app/future_me/future_me_data.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(ziel: 'Frei sein', motivation: 'Stolz sein.');

// 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

FotoEinstellungen _e(int tag) =>
    FotoEinstellungen(fototag: tag, posen: const ['Vorne'], werte: const []);

WochenFoto _foto(DateTime tag, {DateTime? gemacht}) => WochenFoto(
  fototag: tag,
  gemacht: gemacht ?? tag,
  bilder: const {'Vorne': 'x'},
  werte: const {},
);

void main() {
  // fixedNow is Monday, 12 October 2026.
  group('fotoLage', () {
    test('photo day today', () {
      final l = fotoLage(fixedNow, _e(DateTime.monday), const []);
      expect(l.status, FotoStatus.heute);
      expect(l.woche, 1);
    });

    test('missed yesterday can be caught up today', () {
      final l = fotoLage(fixedNow, _e(DateTime.sunday), const []);
      expect(l.status, FotoStatus.nachholen);
      expect(l.tag, DateTime(2026, 10, 11));
    });

    test('taken yesterday: next one in a week', () {
      final fotos = [
        _foto(DateTime(2026, 10, 4)),
        _foto(DateTime(2026, 10, 11)),
      ];
      final l = fotoLage(fixedNow, _e(DateTime.sunday), fotos);
      expect(l.status, FotoStatus.spaeter);
      expect(l.tag, DateTime(2026, 10, 18));
      expect(l.woche, 3);
    });

    test('other day: next photo day', () {
      final l = fotoLage(fixedNow, _e(DateTime.wednesday), const []);
      expect(l.status, FotoStatus.spaeter);
      expect(l.tag, DateTime(2026, 10, 14));
    });
  });

  test('all weeks show a missed week as a gap', () {
    final fotos = [
      _foto(DateTime(2026, 9, 20)),
      _foto(DateTime(2026, 10, 4), gemacht: DateTime(2026, 10, 5)),
    ];
    final wochen = alleWochen(fixedNow, fotos);
    // 11 October can still be caught up today, so it is no gap yet.
    expect(wochen.map((w) => w.woche), [1, 2, 3]);
    expect(wochen[1].foto, isNull);
    expect(wochen[2].foto!.nachgeholt, isTrue);
  });

  testWidgets('set up, take the photo and see it on the page', (tester) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    final feed = MemoryFeedStore();
    fotoAufnahme = () async => Uint8List.fromList(_png);
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(_profile),
        diary: diary,
        feed: feed,
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const ValueKey('zukunft-karte')));
    await tester.tap(find.byKey(const ValueKey('zukunft-karte')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Einrichten'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fototag-1')));
    await tester.enterText(
      find.byKey(const ValueKey('wert-0')),
      'Klimmzüge am Stück',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(feed.fotoEinstellungen!.fototag, DateTime.monday);

    await tester.tap(find.byKey(const ValueKey('seite-foto')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('aufnehmen-Vorne')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('wert-eintrag-Klimmzüge am Stück')),
      '6',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(feed.wochenFotos.single.werte, {'Klimmzüge am Stück': '6'});
    expect(find.byKey(const ValueKey('seite-foto')), findsNothing);
    expect(find.byKey(const ValueKey('vergleich-regler')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Deine Werte'), 200);
    expect(find.text('Deine Werte'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nächstes Foto'), findsOneWidget);
  });

  test('kit code check and kit poses', () {
    expect(kitCodeGueltig('FRAME-7K2Q9'), isTrue);
    expect(kitCodeGueltig('abc'), isFalse);
    expect(posenMitKit(['Vorne', 'Bizeps']), [
      'Vorne',
      'Seite',
      'Hinten',
      'Bizeps',
    ]);
  });

  Future<MemoryFeedStore> openApp(WidgetTester tester) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    final feed = MemoryFeedStore()..fotoEinstellungen = _e(fixedNow.weekday);
    fotoAufnahme = () async => Uint8List.fromList(_png);
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(_profile),
        diary: diary,
        feed: feed,
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    return feed;
  }

  testWidgets('photo day: fixed photo slot in Dein Tag', (tester) async {
    await openApp(tester);
    await scrollTo(tester, find.byKey(const ValueKey('tag-foto')));
    expect(find.byKey(const ValueKey('tag-foto')), findsOneWidget);
    expect(find.text('Foto · Woche 1'), findsOneWidget);
  });

  testWidgets('without kit the photo screen shows the kit line', (
    tester,
  ) async {
    await openApp(tester);
    await scrollTo(tester, find.byKey(const ValueKey('zukunft-karte')));
    await tester.tap(find.byKey(const ValueKey('zukunft-karte')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('seite-foto')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kit-zeile')), findsOneWidget);
  });

  testWidgets('kit code unlocks the kit and preselects three poses', (
    tester,
  ) async {
    final feed = await openApp(tester);
    await scrollTo(tester, find.byKey(const ValueKey('zukunft-karte')));
    await tester.tap(find.byKey(const ValueKey('zukunft-karte')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('kit-code')),
      200,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('kit-code')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kit-code')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('kit-code-feld')),
      'FRAME-7K2Q9',
    );
    await tester.tap(find.byKey(const ValueKey('kit-code-ok')));
    await tester.pumpAndSettle();

    expect(feed.kitAktiv, isTrue);
    expect(feed.fotoEinstellungen!.posen, kitPosen);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('seite-foto')),
      -200,
    );
    await tester.tap(find.byKey(const ValueKey('seite-foto')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kit-zeile')), findsNothing);
    expect(find.byKey(const ValueKey('aufnehmen-Hinten')), findsOneWidget);
  });
}
