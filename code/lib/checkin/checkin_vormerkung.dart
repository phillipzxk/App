import '../persoenlich/persoenlich_data.dart';
import '../persoenlich/persoenlich_logik.dart';
import '../schlaf/schlaf_data.dart';
import 'checkin.dart';

/// Answers the check-in can already pick from what the user entered
/// during the day (Rundgang 2026-11-28, Seite 9): the app does not ask
/// again what it already knows. The user can still change each one.

/// Schlaf from this morning's "Wie bist du aufgewacht?".
String? schlafVormerkung(Morgen? m) {
  if (m == null) return null;
  if (m.tags.contains('Öfter wach') || m.tags.contains('Einmal wach')) {
    return 'Nachts wach gewesen';
  }
  if (m.tags.contains('Lange wach gelegen')) return 'Schlecht eingeschlafen';
  if (m.stunden > 0 && m.stunden < 6.5) return 'Zu kurz geschlafen';
  if (m.himmel >= 50) return 'Gut geschlafen';
  return null;
}

/// Ausstrahlung from the ticked care steps and learning minutes, today or
/// else yesterday (the check-in may open early in the morning). Null when
/// nothing was entered, so "Heute nichts davon" is never guessed.
String? ausstrahlungVormerkung(PersoenlichDaten d, DateTime heute) {
  for (final tag in [
    dayKey(heute),
    dayKey(DateTime(heute.year, heute.month, heute.day - 1)),
  ]) {
    final pflege = pflegeVoll(d, tag);
    final lern = (d.lernMinuten[tag] ?? 0) >= 10;
    if (pflege && lern) return 'Pflege und gelernt';
    if (pflege) return 'Nur Pflege';
    if (lern) return 'Nur gelernt';
  }
  return null;
}
