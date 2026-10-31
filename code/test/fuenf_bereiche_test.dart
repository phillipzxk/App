import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/home/bereichs_werte.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Werte der neuen Bereiche (2026-10-31)', () {
    final tag = DateTime(2026, 10, 31);
    final checkIn = CheckIn(
      datum: tag,
      training: 'Gut trainiert',
      ernaehrung: 'Heißhunger gehabt',
      schlaf: 'Gut geschlafen',
      mindset: 'Alles durchgezogen',
      werte: const {'business': 6},
    );

    test('nur Check-in: der Wert vom Coach', () {
      expect(mitCheckIn(null, [checkIn], 'business', tag), 6);
    });

    test('nur Seite: der Wert aus dem, was man gemacht hat', () {
      expect(mitCheckIn(9, const [], 'business', tag), 9);
    });

    test('beides: der Mittelwert', () {
      expect(mitCheckIn(9, [checkIn], 'business', tag), 8);
    });

    test('anderer Tag zählt nicht', () {
      expect(
        mitCheckIn(null, [checkIn], 'business', DateTime(2026, 10, 30)),
        isNull,
      );
    });
  });

  group('Dein Warum', () {
    test('eigene Worte statt Feldname', () {
      const p = UserProfile(
        motivation:
            'Ich will endlich mein Potenzial ausschöpfen\n'
            'Was ist dein wahrer Grund?: Ich will es mir beweisen',
      );
      expect(p.warum, 'Ich will es mir beweisen');
    });

    test('ohne eigene Worte die angetippten Antworten', () {
      const p = UserProfile(
        motivation:
            'Ich bin unzufrieden damit, wie es gerade ist; '
            'Ich will lange gesund und fit bleiben',
      );
      expect(
        p.warum,
        'Ich bin unzufrieden damit, wie es gerade ist. '
        'Ich will lange gesund und fit bleiben',
      );
    });
  });
}
