import '../checkin/checkin.dart' show dayKey;

/// Numbers for the motivating parts of the new page structure (vault
/// Umsetzung/Schlaf und Mindset Aufbau, confirmed 2026-11-13): streaks
/// and the next small goal. Everything is counted from real entries.

/// How many days in a row up to today are in [tage] (day keys), and the
/// longest run ever. A run still counts while today is open, so it only
/// breaks after a whole missed day.
({int jetzt, int rekord}) serieTage(Iterable<String> tage, DateTime heute) {
  final da = tage.toSet();
  if (da.isEmpty) return (jetzt: 0, rekord: 0);
  DateTime tag(int zurueck) =>
      DateTime(heute.year, heute.month, heute.day - zurueck);
  var start = da.contains(dayKey(tag(0))) ? 0 : 1;
  var jetzt = 0;
  while (da.contains(dayKey(tag(start + jetzt)))) {
    jetzt++;
  }
  final sortiert = [for (final t in da) DateTime.parse(t)]..sort();
  var rekord = 1, lauf = 1;
  for (var i = 1; i < sortiert.length; i++) {
    final a = sortiert[i - 1], b = sortiert[i];
    final naechster = DateTime(a.year, a.month, a.day + 1);
    lauf = dayKey(naechster) == dayKey(b) ? lauf + 1 : 1;
    if (lauf > rekord) rekord = lauf;
  }
  return (jetzt: jetzt, rekord: rekord < jetzt ? jetzt : rekord);
}

/// The same for whole weeks: [wochen] holds the Monday (day key) of every
/// week that counts.
({int jetzt, int rekord}) serieWochen(Iterable<String> wochen, DateTime heute) {
  final da = wochen.toSet();
  if (da.isEmpty) return (jetzt: 0, rekord: 0);
  final mo = DateTime(heute.year, heute.month, heute.day - (heute.weekday - 1));
  DateTime woche(int zurueck) =>
      DateTime(mo.year, mo.month, mo.day - 7 * zurueck);
  final start = da.contains(dayKey(woche(0))) ? 0 : 1;
  var jetzt = 0;
  while (da.contains(dayKey(woche(start + jetzt)))) {
    jetzt++;
  }
  final sortiert = [for (final t in da) DateTime.parse(t)]..sort();
  var rekord = 1, lauf = 1;
  for (var i = 1; i < sortiert.length; i++) {
    final a = sortiert[i - 1], b = sortiert[i];
    final naechste = DateTime(a.year, a.month, a.day + 7);
    lauf = dayKey(naechste) == dayKey(b) ? lauf + 1 : 1;
    if (lauf > rekord) rekord = lauf;
  }
  return (jetzt: jetzt, rekord: rekord < jetzt ? jetzt : rekord);
}

/// The next mark a streak of [n] grows towards: 3, 7, 14, 30, then every
/// further 30.
int naechsteMarke(int n) {
  for (final m in const [3, 7, 14, 30]) {
    if (n < m) return m;
  }
  return (n ~/ 30 + 1) * 30;
}

/// "Mo".."So" for a date.
String tagKurz(DateTime d) =>
    const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][d.weekday - 1];
