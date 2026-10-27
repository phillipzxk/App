import 'dart:convert';

import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/ernaehrung/ernaehrung_coach.dart';
import 'package:coach_app/ernaehrung/ernaehrung_data.dart';
import 'package:coach_app/ernaehrung/ernaehrung_logik.dart';
import 'package:coach_app/ernaehrung/kochbuch.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/feed/kcal.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/weight/weight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(
  ziel: 'Muskeln aufbauen',
  motivation: 'Stolz sein.',
);

class _EssenCoach extends NoFeedCoach implements ErnaehrungCoach {
  String? grund;

  @override
  Future<String?> zusammenhang(
    UserProfile profile,
    List<CheckIn> recent,
    String heisshunger,
    String schlaf,
  ) async => null;

  @override
  Future<String?> heisshunger(
    UserProfile profile,
    String grund,
    String uhrzeit,
    String kontext,
  ) async {
    this.grund = grund;
    return 'Trink erst ein Glas Wasser.';
  }

  @override
  Future<TellerHinweis?> teller(
    UserProfile profile,
    String mahlzeit,
    String bild,
  ) async => const TellerHinweis(
    eiweiss: 3,
    gemuese: 1,
    groesse: 2,
    tipp: 'Nächstes Mal eine Handvoll Gemüse dazu.',
  );

  @override
  Future<({List<String> zutaten, Gericht? gericht})?> kuehlschrank(
    UserProfile profile,
    String kontext, {
    String? bild,
    List<String>? zutaten,
  }) async => (
    zutaten: zutaten ?? ['Eier', 'Spinat', 'Feta'],
    gericht: const Gericht(
      id: 'k1',
      name: 'Spinat-Omelett',
      quelle: 'kuehlschrank',
      warum: 'Schnell und viel Eiweiß.',
      schritte: ['Eier verquirlen.', 'Mit Spinat braten.'],
    ),
  );

  @override
  Future<List<Gericht>?> rettung(
    UserProfile profile,
    String muster,
    String vorhanden,
    int anzahl,
  ) async => null;

  @override
  Future<({String sicht, String? vorschlag, int? kcalNeu})?> gewicht(
    UserProfile profile,
    String verlauf,
    int kcal,
    String grund,
    String kontext,
  ) async => (
    sicht: 'Du isst etwas zu wenig für Aufbau.',
    vorschlag: 'Ein Snack mehr am Tag.',
    kcalNeu: kcal + 200,
  );
}

void main() {
  test('meals sit around training: before and after', () {
    final m = planeMahlzeiten(
      anzahl: 4,
      start: 7 * 60,
      ende: 23 * 60,
      training: 17 * 60 + 30,
    );
    expect([for (final s in m) s.id], ['fruehstueck', 'mittag', 'vor', 'nach']);
    expect(m.first.minute, 7 * 60 + 30);
    expect(m[2].minute, 16 * 60);
    expect(m[3].minute, 19 * 60);
  });

  test('without training the last meal is in the evening, moves stay', () {
    final m = planeMahlzeiten(
      anzahl: 3,
      start: 7 * 60,
      ende: 23 * 60,
      verschoben: {'abend': 19 * 60},
    );
    expect(m.map((s) => s.id), containsAll(['fruehstueck', 'abend']));
    expect(m.last.minute, 19 * 60);
    expect(planeMahlzeiten(anzahl: 0, start: 420, ende: 1380), isEmpty);
  });

  test('energy line names a meal too close to training', () {
    const vor = MahlzeitSlot(
      id: 'vor',
      name: 'Vor dem Training',
      minute: 17 * 60,
      snack: true,
      tipp: '',
    );
    const f = MahlzeitSlot(
      id: 'fruehstueck',
      name: 'Frühstück',
      minute: 7 * 60 + 30,
      snack: false,
      tipp: '',
    );
    expect(
      energieSatz(const [f, vor], training: 17 * 60 + 30, ende: 23 * 60),
      contains('zu knapp vor dem Training'),
    );
  });

  test('the plate fills with eaten meals, photo reads count', () {
    final m = planeMahlzeiten(anzahl: 2, start: 420, ende: 1380);
    expect(tagesTeller(m, const {}).eiweiss, 0);
    final halb = tagesTeller(m, {
      m.first.id: const MahlzeitEintrag(gegessen: true),
    });
    expect(halb.eiweiss, closeTo(0.45, 0.01));
    final foto = tagesTeller(m, {
      m.first.id: const MahlzeitEintrag(
        gegessen: true,
        teller: TellerHinweis(eiweiss: 3, gemuese: 0, groesse: 3),
      ),
    });
    expect(foto.eiweiss, closeTo(0.5, 0.01));
    expect(foto.gemuese, 0);
    expect(
      tellerSatz(foto, gegessen: 1, geplant: 2),
      contains('Bisher am wenigsten: Gemüse'),
    );
  });

  test('shopping list adds up ingredients across dishes', () {
    const a = Gericht(
      id: 'a',
      name: 'Bowl',
      quelle: 'coach',
      zutaten: [
        Zutat(name: 'Skyr', menge: 200, einheit: 'g', gruppe: 'Kühlregal'),
      ],
    );
    const b = Gericht(
      id: 'b',
      name: 'Shake',
      quelle: 'coach',
      zutaten: [
        Zutat(name: 'skyr', menge: 300, einheit: 'g', gruppe: 'Kühlregal'),
        Zutat(name: 'Banane', menge: 1, einheit: 'Stück', gruppe: 'Obst'),
      ],
    );
    const d = ErnaehrungDaten(
      gerichte: [a, b],
      einkauf: Einkauf(auswahl: {'a': 2, 'b': 1}, eigene: ['Kaffee']),
    );
    final l = einkaufsliste(d);
    expect(l.map((p) => p.name), ['Banane', 'Skyr', 'Kaffee']);
    expect(l[1].mengeText, '700 g');
    expect(l[1].fuer, ['Bowl', 'Shake']);
    expect(l.last.gruppe, 'Eigenes');
  });

  test('cooking grows leaves and unlocks dishes, nicht meins removes', () {
    var d = const ErnaehrungDaten(
      gerichte: [
        Gericht(id: 'a', name: 'A', quelle: 'coach'),
        Gericht(id: 'b', name: 'B', quelle: 'coach', freiAb: 2),
        Gericht(id: 'c', name: 'C', quelle: 'eigen'),
      ],
    );
    expect(kochbuchBlaetter(d), 0);
    d = gekocht(d, 'a', 'lecker');
    expect(kochbuchBlaetter(d), 1);
    expect(d.gericht('b')!.freiAb, 2);
    d = gekocht(d, 'a', 'okay');
    expect(d.gericht('b')!.freiAb, isNull);
    expect(d.gericht('a')!.gekocht, 2);
    d = gekocht(d, 'b', 'nicht meins');
    expect(d.gericht('b'), isNull);
    d = gekocht(d, 'c', 'nicht meins');
    expect(d.gericht('c'), isNotNull);
  });

  test('weight check comes when the weight stands against the goal', () {
    final heute = DateTime(2026, 10, 26);
    final w = [
      for (var i = 0; i < 5; i++)
        WeightEntry(DateTime(2026, 9, 28).add(Duration(days: 7 * i)), 80),
    ];
    expect(zielRichtung('Muskeln aufbauen'), 1);
    expect(zielRichtung('5 kg abnehmen'), -1);
    final l = gewichtsLage(
      w,
      'Muskeln aufbauen',
      const ErnaehrungDaten(),
      heute,
    );
    expect(l?.lage, 'steht');
    // Not again within 3 weeks.
    final d = ErnaehrungDaten(
      gewicht: [GewichtsCheck(tag: '2026-10-20', lage: 'steht', kcalAlt: 2500)],
    );
    expect(gewichtsLage(w, 'Muskeln aufbauen', d, heute), isNull);
    expect(gewichtsGruende('steht', 1), contains('Esse eher zu wenig'));
    expect(kcalVorschlagOhneCoach(2500, 'steht', 1), 2700);
  });

  test('ingredient lines are read with amount and shop section', () {
    final z = zutatLesen('150 g Hähnchenbrust');
    expect(z.name, 'Hähnchenbrust');
    expect(z.menge, 150);
    expect(z.einheit, 'g');
    expect(z.gruppe, 'Eiweiß');
    final e = zutatLesen('Eier 3 stk');
    expect(e.einheit, 'Stück');
    expect(e.gruppe, 'Kühlregal');
  });

  test('data survives JSON, old photos are dropped', () {
    final d = const ErnaehrungDaten(kcalAnpassung: 200)
        .mitEintrag(
          '2026-10-01',
          'mittag',
          const MahlzeitEintrag(gegessen: true, gefuehl: 'satt', bild: 'abc'),
        )
        .mitZeit('2026-10-12', 'abend', 1140)
        .mitGericht(
          const Gericht(
            id: 'x',
            name: 'X',
            quelle: 'eigen',
            zutaten: [Zutat(name: 'Reis', menge: 80, einheit: 'g')],
          ),
        );
    final back = ErnaehrungDaten.fromJson(
      jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>,
    );
    expect(back.kcalAnpassung, 200);
    expect(back.tag('2026-10-01')['mittag']!.gefuehl, 'satt');
    expect(back.verschoben['2026-10-12']!['abend'], 1140);
    expect(back.gericht('x')!.zutaten.single.menge, 80);
    final sauber = back.aufgeraeumt(DateTime(2026, 10, 12));
    expect(sauber.tag('2026-10-01')['mittag']!.bild, isNull);
    expect(sauber.tag('2026-10-01')['mittag']!.gegessen, isTrue);
  });

  group('page', () {
    late _EssenCoach coach;

    Future<MemoryFeedStore> start(
      WidgetTester tester, {
      int? mahlzeiten,
      ErnaehrungDaten? daten,
    }) async {
      coach = _EssenCoach();
      final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
      final feed = MemoryFeedStore()..mahlzeiten = mahlzeiten;
      if (daten != null) feed.ernaehrung = daten;
      tallView(tester);
      await tester.pumpWidget(
        CoachApp(
          store: MemoryProfileStore(_profile),
          diary: diary,
          feed: feed,
          feedCoach: coach,
          clock: fixedClock,
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'Ernährung');
      return feed;
    }

    testWidgets('set meals, tick one with a feeling', (tester) async {
      final feed = await start(tester);
      await tester.tap(find.byKey(const ValueKey('mahlzeiten-festlegen')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('anzahl-3')));
      await tester.pumpAndSettle();
      expect(feed.mahlzeiten, 3);

      final ticken = find.byKey(const ValueKey('gegessen-fruehstueck'));
      await scrollTo(tester, ticken);
      await tester.tap(ticken);
      await tester.pumpAndSettle();
      final satt = find.byKey(const ValueKey('gefuehl-fruehstueck-satt'));
      await scrollTo(tester, satt);
      await tester.tap(satt);
      await tester.pumpAndSettle();
      final e = feed.ernaehrung.tag(dayKey(fixedNow))['fruehstueck']!;
      expect(e.gegessen, isTrue);
      expect(e.gefuehl, 'satt');
    });

    testWidgets('plate photo gives coach hints in words', (tester) async {
      fotoAufnahme = () async => base64Encode([1, 2, 3]);
      final feed = await start(tester, mahlzeiten: 2);
      final foto = find.byKey(const ValueKey('foto-fruehstueck'));
      await scrollTo(tester, foto);
      await tester.tap(foto);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('teller-aufnehmen')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('teller-hinweise')), findsOneWidget);
      expect(
        find.text('Nächstes Mal eine Handvoll Gemüse dazu.'),
        findsOneWidget,
      );
      final e = feed.ernaehrung.tag(dayKey(fixedNow))['fruehstueck']!;
      expect(e.gegessen, isTrue);
      expect(e.teller!.eiweiss, 3);
    });

    testWidgets('craving: reason, step, helped', (tester) async {
      final feed = await start(tester);
      final knopf = find.byKey(const ValueKey('heisshunger-knopf'));
      await scrollTo(tester, knopf);
      await tester.tap(knopf);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hh-grund-Stress')));
      await tester.pumpAndSettle();
      expect(coach.grund, 'Stress');
      expect(find.text('Trink erst ein Glas Wasser.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hh-geholfen')));
      await tester.pumpAndSettle();
      final h = feed.ernaehrung.heisshunger.single;
      expect(h.grund, 'Stress');
      expect(h.geholfen, isTrue);
    });

    testWidgets('fridge photo builds a dish that goes into the cookbook', (
      tester,
    ) async {
      fotoAufnahme = () async => base64Encode([1]);
      final feed = await start(tester);
      final kachel = find.byKey(const ValueKey('kachel-kuehlschrank'));
      await scrollTo(tester, kachel);
      await tester.tap(kachel);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('kuehl-aufnehmen')));
      await tester.pumpAndSettle();
      expect(find.text('Spinat-Omelett'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('kuehl-zutat-Feta')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('kuehl-zutat-Feta')), findsNothing);
      final gekocht = find.byKey(const ValueKey('kuehl-gekocht'));
      await scrollTo(tester, gekocht);
      await tester.tap(gekocht);
      await tester.pumpAndSettle();
      final g = feed.ernaehrung.gericht('k1')!;
      expect(g.gekocht, 1);
      expect(g.imKochbuch, isTrue);
    });

    testWidgets('cookbook offers rescue dishes, shopping list adds them', (
      tester,
    ) async {
      final feed = await start(tester);
      final kachel = find.byKey(const ValueKey('kachel-kochbuch'));
      await scrollTo(tester, kachel);
      await tester.tap(kachel);
      await tester.pumpAndSettle();
      // Without the coach, the built-in rescue dishes are there.
      expect(feed.ernaehrung.gerichte, isNotEmpty);
      final id = feed.ernaehrung.gerichte.first.id;
      final r = find.byKey(ValueKey('rettung-$id'));
      await scrollTo(tester, r);
      await tester.tap(r);
      await tester.pumpAndSettle();
      final liste = find.byKey(const ValueKey('auf-liste'));
      await scrollTo(tester, liste);
      await tester.tap(liste);
      await tester.pumpAndSettle();
      expect(feed.ernaehrung.einkauf.auswahl[id], 1);
    });
  });

  testWidgets('weight check changes the kcal target and can be undone', (
    tester,
  ) async {
    final coach = _EssenCoach();
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    for (var i = 0; i < 5; i++) {
      diary.weights.add(
        WeightEntry(fixedNow.subtract(Duration(days: 28 - 7 * i)), 80),
      );
    }
    final feed = MemoryFeedStore()
      ..kcal = const KcalProfil(
        groesseCm: 180,
        alter: 30,
        geschlecht: Geschlecht.mann,
        aktivitaet: Aktivitaet.aktiv,
      );
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(_profile),
        diary: diary,
        feed: feed,
        feedCoach: coach,
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'Ernährung');
    final link = find.byKey(const ValueKey('gewicht-check-link'));
    await scrollTo(tester, link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('gewicht-grund-Esse eher zu wenig')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Du isst etwas zu wenig'), findsOneWidget);
    final ueber = find.byKey(const ValueKey('gewicht-uebernehmen'));
    await scrollTo(tester, ueber);
    await tester.tap(ueber);
    await tester.pumpAndSettle();
    expect(feed.ernaehrung.kcalAnpassung, 200);
    expect(feed.ernaehrung.gewicht.single.status, 'uebernommen');
    await tester.tap(find.byKey(const ValueKey('gewicht-zurueck')));
    await tester.pumpAndSettle();
    expect(feed.ernaehrung.kcalAnpassung, 0);
  });
}
