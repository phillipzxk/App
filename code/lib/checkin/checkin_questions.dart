/// One row of the daily check-in: an area and the answers to tap (one per
/// row).
class CheckInRow {
  const CheckInRow(this.topic, this.options);

  final String topic;
  final List<String> options;
}

/// The five rows on the one check-in screen, decided with Phillip on
/// 2026-10-18 (see Umsetzung/Täglicher Check-in.md). Order: training,
/// nutrition, sleep, energy, mindset.
const List<CheckInRow> checkInRows = [
  CheckInRow('Training', [
    'Gut trainiert',
    'Lief zäh',
    'Pause, gut erholt',
    'Pause, eher unproduktiv',
  ]),
  CheckInRow('Ernährung', [
    'Strukturiert gegessen',
    'Heißhunger gehabt',
    'Unregelmäßig gegessen',
    'Viel Fast Food',
  ]),
  CheckInRow('Schlaf', [
    'Gut geschlafen',
    'Schlecht eingeschlafen',
    'Nachts wach gewesen',
    'Zu kurz geschlafen',
  ]),
  CheckInRow('Energie', ['Hoch', 'Mittel', 'Niedrig']),
  CheckInRow('Mindset', [
    'Alles durchgezogen',
    'Vor etwas gedrückt',
    'Kaum Motivation',
  ]),
];
