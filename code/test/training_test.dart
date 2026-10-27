import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/training/training_data.dart';
import 'package:coach_app/training/training_logik.dart';
import 'package:flutter_test/flutter_test.dart';

UebungLog _log(String name, double kg, List<double> reps, {String? gefuehl}) =>
    UebungLog(
      name: name,
      art: UebungArt.gewicht,
      saetze: [for (final r in reps) SatzLog(wert: kg, menge: r, fertig: true)],
      gefuehl: gefuehl,
    );

TrainingEinheit _einheit(DateTime d, List<UebungLog> u) => TrainingEinheit(
  datum: d,
  name: 'Push',
  status: EinheitStatus.fertig,
  uebungen: u,
);

void main() {
  final heute = DateTime(2026, 10, 12); // a Monday

  test('plan lines are read into exercises', () {
    final b = PlanUebung.lesen('Bankdrücken 5x5 mit 80 kg');
    expect(b.name, 'Bankdrücken');
    expect(b.saetze, 5);
    expect(b.wdhVon, 5);
    expect(b.wert, 80);
    expect(b.art, UebungArt.gewicht);

    final r = PlanUebung.lesen('Rudern 3x8-10 60 kg');
    expect(r.modus, WdhModus.bereich);
    expect(r.wdhBis, 10);

    final l = PlanUebung.lesen('Laufen 5 km');
    expect(l.art, UebungArt.strecke);
    expect(l.wert, 5);

    final p = PlanUebung.lesen('Plank 3x45s');
    expect(p.art, UebungArt.zeit);
    expect(p.wdhVon, 45);

    expect(PlanUebung.lesen('Klimmzüge 4x8').art, UebungArt.koerpergewicht);
  });

  test('target goes up after a finished session, not after a heavy one', () {
    const u = PlanUebung(
      name: 'Bankdrücken',
      saetze: 3,
      modus: WdhModus.bereich,
      wdhVon: 8,
      wdhBis: 10,
      wert: 80,
    );
    final vorher = DateTime(2026, 10, 9);
    // All sets at the top of the range: +2.5 kg, back to 8.
    var d = TrainingDaten(
      einheiten: [
        _einheit(vorher, [
          _log('Bankdrücken', 80, [10, 10, 10]),
        ]),
      ],
    );
    var z = zielFuer(u, d, heute);
    expect(z.saetze.first.wert, 82.5);
    expect(z.saetze.first.menge, 8);
    expect(z.letztes!.wert, 80);

    // Not yet at the top: +1 repetition.
    d = TrainingDaten(
      einheiten: [
        _einheit(vorher, [
          _log('Bankdrücken', 80, [9, 8, 8]),
        ]),
      ],
    );
    z = zielFuer(u, d, heute);
    expect(z.saetze.first.wert, 80);
    expect(z.saetze.first.menge, 9);

    // Felt heavy: no increase.
    d = TrainingDaten(
      einheiten: [
        _einheit(vorher, [
          _log('Bankdrücken', 80, [10, 10, 10], gefuehl: 'schwer'),
        ]),
      ],
    );
    z = zielFuer(u, d, heute);
    expect(z.saetze.first.wert, 80);
    expect(z.saetze.first.menge, 10);

    // The user's own suggestion wins.
    d = TrainingDaten(
      einheiten: [
        _einheit(vorher, [
          _log('Bankdrücken', 80, [10, 10, 10]),
        ]),
      ],
      vorschlaege: const {'bankdrücken': SatzWert(85, 6)},
    );
    z = zielFuer(u, d, heute);
    expect(z.saetze.first.wert, 85);
    expect(z.saetze.first.menge, 6);

    // The coach's adjustment for today: fewer sets.
    z = zielFuer(
      u,
      const TrainingDaten(),
      heute,
      anpassung: const Anpassung(
        uebung: 'Bankdrücken',
        saetze: 2,
        grund: 'Kurz geschlafen',
      ),
    );
    expect(z.saetze.length, 2);
    expect(z.angepasst, 'Kurz geschlafen');
  });

  test('a new record only counts after the first session', () {
    final erste = _einheit(DateTime(2026, 10, 5), [
      _log('Bankdrücken', 80, [8]),
    ]);
    var d = const TrainingDaten();
    expect(neueRekorde(d, erste), isEmpty);
    d = d.mitEinheit(erste);
    final zweite = _einheit(heute, [
      _log('Bankdrücken', 82.5, [8]),
    ]);
    expect(neueRekorde(d, zweite).keys, ['Bankdrücken']);
    final gleich = _einheit(heute, [
      _log('Bankdrücken', 80, [8]),
    ]);
    expect(neueRekorde(d, gleich), isEmpty);
  });

  test('stuck for 3 weeks triggers the Stagnations-Check once', () {
    final d = TrainingDaten(
      einheiten: [
        for (final tag in [21, 14, 7, 1])
          _einheit(DateTime(2026, 10, 12 - tag), [
            _log('Seitheben', 10, [12]),
          ]),
      ],
    );
    expect(stagniert(d, 'Seitheben', heute), isTrue);
    expect(stagnationFaellig(d, ['Seitheben'], heute), 'Seitheben');
    final gefragt = d.copyWith(
      stagnation: const [
        StagnationsCheck(uebung: 'Seitheben', tag: '2026-10-05'),
      ],
    );
    expect(stagnationFaellig(gefragt, ['Seitheben'], heute), isNull);

    final besser = d.mitEinheit(
      _einheit(DateTime(2026, 10, 10), [
        _log('Seitheben', 12, [12]),
      ]),
    );
    expect(stagniert(besser, 'Seitheben', heute), isFalse);
  });

  test('a skipped session moves to the next free day of the week', () {
    final tage = ['Push', 'Ruhe', 'Pull', 'Ruhe', 'Beine', 'Ruhe', 'Ruhe'];
    const d = TrainingDaten();
    final ziel = verschiebeZiel(tage, d, heute, 'Keine Zeit');
    expect(ziel, DateTime(2026, 10, 13));
    expect(verschiebeZiel(tage, d, heute, 'Krank'), isNull);
    expect(verschiebeText('Push', 'Krank', null), contains('geh zum Arzt'));

    final geschoben = d.mitEinheit(
      TrainingEinheit(
        datum: heute,
        name: 'Push',
        status: EinheitStatus.uebersprungen,
        grund: 'Keine Zeit',
        verschobenAuf: ziel,
      ),
    );
    final woche = wochenPlan(TrainingPlan(tage), geschoben, heute);
    expect(woche.tage[0], '');
    expect(woche.tage[1], 'Push');
    // The next free day is now Thursday.
    expect(
      verschiebeZiel(tage, geschoben, heute, 'Termin'),
      DateTime(2026, 10, 15),
    );
  });

  test('the check-in pre-selects training after a logged session', () {
    expect(checkInVormerkung(const TrainingDaten(), heute), isNull);
    final gut = TrainingDaten(
      einheiten: [
        _einheit(heute, [
          _log('A', 50, [8], gefuehl: 'passt'),
        ]),
      ],
    );
    expect(checkInVormerkung(gut, heute), 'Gut trainiert');
    final zaeh = TrainingDaten(
      einheiten: [
        _einheit(heute, [
          _log('A', 50, [8], gefuehl: 'schwer'),
          _log('B', 50, [8], gefuehl: 'schwer'),
          _log('C', 50, [8], gefuehl: 'passt'),
        ]),
      ],
    );
    expect(checkInVormerkung(zaeh, heute), 'Lief zäh');
  });

  test('training data survives saving and loading', () {
    final d = TrainingDaten(
      sportarten: const ['Krafttraining', 'Laufen'],
      einheiten: [
        _einheit(heute, [
          _log('Bankdrücken', 80, [8, 8], gefuehl: 'leicht'),
        ]),
      ],
      vorschlaege: const {'bankdrücken': SatzWert(85, 6)},
    );
    final back = TrainingDaten.fromJson(d.toJson());
    expect(back.sportarten, ['Krafttraining', 'Laufen']);
    expect(back.einheitAm(heute)!.uebungen.first.bester!.wert, 80);
    expect(back.einheitAm(heute)!.uebungen.first.gefuehl, 'leicht');
    expect(back.vorschlaege['bankdrücken']!.menge, 6);

    final plan = TrainingPlan.aus(
      ['Push', '', '', '', '', '', ''],
      [
        [PlanUebung.lesen('Bankdrücken 3x8-10 80 kg')],
        for (var i = 0; i < 6; i++) const <PlanUebung>[],
      ],
    );
    final p2 = TrainingPlan.fromJson(plan.toJson());
    expect(p2.uebungenAm(0).single.wdhBis, 10);
    // Old plans (just text) still load.
    final alt = TrainingPlan.fromJson([
      'Push\nBankdrücken 5x5 80 kg',
      ...List.filled(6, ''),
    ]);
    expect(alt.uebungenAm(0).single.saetze, 5);
  });

  test('HeuteSession carries a changed value to later open sets', () async {
    TrainingEinheit? gespeichert;
    final s = HeuteSession(
      datum: heute,
      name: 'Push',
      plan: const [PlanUebung(name: 'Bankdrücken', wert: 80)],
      logs: const [
        UebungLog(
          name: 'Bankdrücken',
          art: UebungArt.gewicht,
          saetze: [
            SatzLog(wert: 80, menge: 8),
            SatzLog(wert: 80, menge: 8),
            SatzLog(wert: 80, menge: 8),
          ],
        ),
      ],
      onSpeichern: (e) async => gespeichert = e,
    );
    s.abhaken(0, 0);
    s.setWert(0, 1, 82.5);
    expect([for (final x in s.logs[0].saetze) x.wert], [80, 82.5, 82.5]);
    expect(s.logs[0].saetze[0].fertig, isTrue);
    expect(gespeichert, isNotNull);
    s.dispose();
  });
}
