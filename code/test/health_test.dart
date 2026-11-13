import 'package:coach_app/health/health_daten.dart';
import 'package:coach_app/health/health_dienst.dart';
import 'package:coach_app/health/health_heute.dart';
import 'package:coach_app/home/heute_felder.dart';
import 'package:coach_app/health/health_logik.dart';
import 'package:coach_app/health/health_verbinden.dart';
import 'package:coach_app/health/nacht_wurzel.dart';
import 'package:coach_app/schlaf/schlaf_data.dart';
import 'package:coach_app/schlaf/schlaf_logik.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double ms(DateTime d) => d.millisecondsSinceEpoch.toDouble();

class _FakeHealth implements HealthDienst {
  _FakeHealth(this.ok);
  final bool ok;
  bool _verbunden = false;

  @override
  bool get moeglich => true;

  @override
  Future<bool> verbunden() async => _verbunden;

  @override
  Future<bool> verbinden() async => _verbunden = ok;

  @override
  Future<HealthTag?> lesen(DateTime heute) async =>
      _verbunden ? beispielTag(heute) : null;
}

void main() {
  final heute = DateTime(2026, 11, 2, 7, 30);
  DateTime t(int h, int m) =>
      DateTime(2026, 11, 2).add(Duration(hours: h, minutes: m));

  group('Vom iPhone', () {
    test('Uhr-Phasen gewinnen, Wach am Rand fällt weg', () {
      final tag = HealthTag.ausHandy(heute, {
        'schlaf': [
          // iPhone: plain "asleep" over the whole night.
          {'von': ms(t(-1, 0)), 'bis': ms(t(6, 30)), 'art': 'schlaf'},
          // Watch: awake before falling asleep, phases, awake at the end.
          {'von': ms(t(-1, 0)), 'bis': ms(t(-1, 15)), 'art': 'wach'},
          {'von': ms(t(-1, 15)), 'bis': ms(t(1, 0)), 'art': 'tief'},
          {'von': ms(t(1, 0)), 'bis': ms(t(1, 10)), 'art': 'wach'},
          {'von': ms(t(1, 10)), 'bis': ms(t(4, 0)), 'art': 'kern'},
          {'von': ms(t(3, 50)), 'bis': ms(t(6, 0)), 'art': 'rem'},
          {'von': ms(t(6, 0)), 'bis': ms(t(6, 30)), 'art': 'wach'},
        ],
        'ruhepuls': 58.4,
        'ruhepuls_schnitt': 52.1,
        'gewicht': {'kg': 81.43, 'zeit': ms(t(6, 50))},
        'trainings': [
          {'art': 'Laufen', 'start': ms(t(7, 0)), 'minuten': 32},
        ],
      });
      final n = tag.nacht!;
      expect(n.start, t(-1, 15));
      expect(n.ende, t(6, 0));
      expect(n.mitPhasen, isTrue);
      expect(n.wachMal, 1);
      // REM started 10 minutes into the core phase: no double counting.
      expect(n.stunden, closeTo((6 * 60 + 45 - 10) / 60, .01));
      expect(tag.ruhepuls, 58);
      expect(tag.gewicht, closeTo(81.43, .001));
      expect(tag.trainings.single.text, 'Laufen, 32 Min.');
    });

    test('nur iPhone: Schlaf ohne Phasen', () {
      final tag = HealthTag.ausHandy(heute, {
        'schlaf': [
          {'von': ms(t(-1, 0)), 'bis': ms(t(6, 0)), 'art': 'schlaf'},
        ],
      });
      expect(tag.nacht!.mitPhasen, isFalse);
      expect(tag.nacht!.stunden, 7);
    });

    test('leer ohne Werte', () {
      expect(HealthTag.ausHandy(heute, {}).leer, isTrue);
    });
  });

  group('Schlafwert', () {
    final h = beispielTag(heute);

    test('Messung macht Erholung und Durchschlafen genauer', () {
      final ohne = schlafwert(stunden: 7, brauch: 8, himmel: 70, tags: []);
      final mit = schlafwert(
        stunden: 7,
        brauch: 8,
        himmel: 70,
        tags: [],
        health: h,
      );
      // Pulse above and HRV below the own average pull recovery down.
      expect(mit.teile['erholung']!, lessThan(ohne.teile['erholung']!));
      expect(mit.teile['durchschlafen']!, lessThan(100));
    });

    test('eigene Angabe zählt zuerst', () {
      final s = schlafwert(
        stunden: 7,
        brauch: 8,
        himmel: 70,
        tags: ['Einmal wach'],
        health: h,
      );
      expect(s.teile['durchschlafen'], 80);
    });

    test('Teil-Texte mit Messung', () {
      final m = Morgen(tag: dayKeyOf(heute), himmel: 70, stunden: 7, wert: 70);
      expect(teilText('erholung', m, h), 'Puls 58 · HRV 41');
      expect(teilText('durchschlafen', m, h), '${h.nacht!.wachMal} × wach');
    });
  });

  group('Heute', () {
    test('Samen und Felder', () {
      final h = beispielTag(DateTime(2026, 11, 2, 10));
      expect(healthSamen(h), [
        '7 h 11 Schlaf',
        'Ruhepuls +6',
        'HRV niedrig',
        '3× wach',
      ]);
      var d = const SchlafDaten().mitHealth(h);
      var felder = healthFelder(d, h.tag);
      expect(felder.map((f) => f.rechts), [
        'Übernehmen',
        'im Verlauf',
        'Ziel erreicht',
      ]);
      d = d.copyWith(uebernommen: [h.trainings.single.id]);
      felder = healthFelder(d, h.tag);
      expect(felder.any((f) => f.knopf), isFalse);
    });

    test('Coach-Zeilen', () {
      final z = healthZeilen(beispielTag(DateTime(2026, 11, 2, 10)));
      expect(z.first, startsWith('Gemessen letzte Nacht: 7 h 11 geschlafen'));
      expect(z, contains('Ruhepuls 58 (eigener Schnitt 52).'));
      expect(z, contains('Von der Uhr: Laufen, 32 Min.'));
    });

    test('gespeichert und wieder geladen', () {
      final h = beispielTag(heute);
      final d = const SchlafDaten()
          .mitHealth(h)
          .copyWith(samenTag: h.tag, uebernommen: ['x']);
      final zurueck = SchlafDaten.fromJson(d.toJson());
      expect(
        zurueck.healthAm(h.tag)!.nacht!.phasen.length,
        h.nacht!.phasen.length,
      );
      expect(zurueck.samenTag, h.tag);
      expect(zurueck.uebernommen, ['x']);
    });

    test('höchstens 14 Tage', () {
      var d = const SchlafDaten();
      for (var i = 0; i < 20; i++) {
        d = d.mitHealth(beispielTag(DateTime(2026, 10, 1 + i, 8)));
      }
      expect(d.health.length, 14);
      expect(d.health.last.tag, '2026-10-20');
    });
  });

  testWidgets('Verbinden: Wurzeln leuchten, dann verbunden', (tester) async {
    var gemeldet = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HealthVerbindenSeite(
          dienst: _FakeHealth(true),
          onVerbunden: () => gemeldet = true,
        ),
      ),
    );
    expect(find.text('Mit Apple Health verbinden'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('health-verbinden')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Verbinden …'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Fertig'), findsOneWidget);
    expect(gemeldet, isTrue);
  });

  testWidgets('Verbinden klappt nicht', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HealthVerbindenSeite(dienst: _FakeHealth(false))),
    );
    await tester.tap(find.byKey(const ValueKey('health-verbinden')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Nochmal versuchen'), findsOneWidget);
  });

  testWidgets('Nacht als Wurzel und Felder', (tester) async {
    final h = beispielTag(DateTime(2026, 11, 2, 10));
    HealthFeld? getippt;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              NachtKarte(nacht: h.nacht!),
              Stack(
                children: [
                  const SizedBox(height: 120, width: 300),
                  Positioned.fill(child: SamenRegen(samen: healthSamen(h))),
                ],
              ),
              HeuteFelder(
                health: healthFelder(const SchlafDaten().mitHealth(h), h.tag),
                onHealthKnopf: (f) => getippt = f,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('nacht-wurzel')), findsOneWidget);
    await tester.tap(find.text('Übernehmen'));
    expect(getippt?.id, startsWith('training:'));
    await tester.pumpAndSettle();
  });
}

String dayKeyOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
