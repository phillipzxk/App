import 'package:coach_app/bereiche/aufbau_logik.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final heute = DateTime(2026, 11, 13); // a Friday

  test('streak counts days in a row and keeps the record', () {
    expect(serieTage(const [], heute), (jetzt: 0, rekord: 0));
    expect(serieTage(const ['2026-11-11', '2026-11-12', '2026-11-13'], heute), (
      jetzt: 3,
      rekord: 3,
    ));
    // Today still open: the run from yesterday holds.
    expect(serieTage(const ['2026-11-11', '2026-11-12'], heute).jetzt, 2);
    // A whole missed day breaks it, the record stays.
    expect(
      serieTage(const [
        '2026-11-01',
        '2026-11-02',
        '2026-11-03',
        '2026-11-04',
        '2026-11-13',
      ], heute),
      (jetzt: 1, rekord: 4),
    );
    expect(serieTage(const ['2026-11-10'], heute), (jetzt: 0, rekord: 1));
  });

  test('week streak counts Mondays in a row', () {
    expect(
      serieWochen(const ['2026-10-26', '2026-11-02', '2026-11-09'], heute),
      (jetzt: 3, rekord: 3),
    );
    expect(serieWochen(const ['2026-10-26', '2026-11-02'], heute).jetzt, 2);
    expect(serieWochen(const ['2026-10-19'], heute).jetzt, 0);
  });

  test('next mark and short day', () {
    expect(naechsteMarke(0), 3);
    expect(naechsteMarke(3), 7);
    expect(naechsteMarke(13), 14);
    expect(naechsteMarke(30), 60);
    expect(tagKurz(heute), 'Fr');
  });
}
