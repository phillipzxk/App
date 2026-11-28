import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/checkin/checkin_flow.dart';
import 'package:coach_app/checkin/checkin_vormerkung.dart';
import 'package:coach_app/ernaehrung/ernaehrung_logik.dart';
import 'package:coach_app/persoenlich/persoenlich_data.dart';
import 'package:coach_app/schlaf/schlaf_data.dart';
import 'package:coach_app/schnell/schnell_eintrag.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rundgang 2026-11-28, Seite 9: Schnell-Eintrag und Check-in.
void main() {
  test('Schlaf wird aus dem Morgen vorgemerkt', () {
    Morgen m({List<String> tags = const [], double h = 7.5, int himmel = 80}) =>
        Morgen(
          tag: '2026-11-28',
          himmel: himmel,
          tags: tags,
          stunden: h,
          wert: 70,
        );
    expect(schlafVormerkung(null), isNull);
    expect(schlafVormerkung(m()), 'Gut geschlafen');
    expect(schlafVormerkung(m(h: 5.5)), 'Zu kurz geschlafen');
    expect(schlafVormerkung(m(tags: ['Öfter wach'])), 'Nachts wach gewesen');
    expect(
      schlafVormerkung(m(tags: ['Lange wach gelegen'])),
      'Schlecht eingeschlafen',
    );
    expect(schlafVormerkung(m(himmel: 30)), isNull);
  });

  test('Ausstrahlung nur vorgemerkt, wenn etwas eingetragen ist', () {
    final heute = DateTime(2026, 11, 28);
    expect(ausstrahlungVormerkung(const PersoenlichDaten(), heute), isNull);
    expect(
      ausstrahlungVormerkung(
        const PersoenlichDaten(lernMinuten: {'2026-11-28': 12}),
        heute,
      ),
      'Nur gelernt',
    );
    expect(
      ausstrahlungVormerkung(
        const PersoenlichDaten(lernMinuten: {'2026-11-27': 10}),
        heute,
      ),
      'Nur gelernt',
    );
  });

  test('Werte nach dem Check-in: Körper ist der Schnitt, mit gestern', () {
    CheckIn c(DateTime d, Map<String, int> w) => CheckIn(
      datum: d,
      training: 'Gut trainiert',
      ernaehrung: 'Strukturiert gegessen',
      schlaf: 'Gut geschlafen',
      mindset: 'Alles durchgezogen',
      werte: w,
    );
    final w = bereichWerte(
      c(DateTime(2026, 11, 28), {
        'training': 8,
        'ernaehrung': 6,
        'schlaf': 7,
        'produktiv': 5,
        'persoenlich': 4,
        'mindset': 9,
      }),
      c(DateTime(2026, 11, 27), {
        'training': 7,
        'ernaehrung': 6,
        'schlaf': 5,
        'produktiv': 5,
        'mindset': 7,
      }),
    );
    expect(
      [for (final x in w) x.name],
      ['Körper', 'Fokus', 'Ausstrahlung', 'Mindset'],
    );
    expect(w[0].wert, 7);
    expect(w[0].diff, 1);
    expect(w[1].diff, 0);
    expect(w[2].diff, isNull);
    expect(w[3].diff, 2);
  });

  test('Satz des Coaches zählt die Karten, die wirklich da sind', () {
    expect(zahlAngleichen('Hab ich, vier Sachen.', 2), 'Hab ich, zwei Sachen.');
    expect(zahlAngleichen('Vier Sachen erfasst.', 1), 'Eine Sache erfasst.');
    expect(zahlAngleichen('Drei Einträge drin.', 1), 'Einen Eintrag drin.');
    expect(zahlAngleichen('Alles drin.', 3), 'Alles drin.');
  });

  test('Keine Gegenfrage zu einer Mahlzeit, die gerade genannt wurde', () {
    const slots = [
      MahlzeitSlot(
        id: 'fruehstueck',
        name: 'Frühstück',
        minute: 480,
        snack: false,
        tipp: '',
      ),
      MahlzeitSlot(
        id: 'mittag',
        name: 'Mittag',
        minute: 780,
        snack: false,
        tipp: '',
      ),
    ];
    // The coach left out the meal word; the title says "Mittag".
    final f = gegenfragen(
      jetzt: 16 * 60,
      mahlzeiten: slots,
      gegessen: {'fruehstueck'},
      eintraege: const [
        SchnellEintrag(art: 'mahlzeit', titel: 'Mittag: Hähnchen mit Reis'),
      ],
    );
    expect(f, isEmpty);
  });
}
