import '../checkin/checkin.dart';
import '../schlaf/schlaf_data.dart';
import '../schlaf/schlaf_logik.dart';
import 'health_daten.dart';
import 'health_dienst.dart';

/// "1 h 10"
String _dauer(int minuten) => formatDauer(minuten / 60);

/// What the coach gets to know from Apple Health, one line each.
List<String> healthZeilen(HealthTag? h) {
  if (h == null) return const [];
  final n = h.nacht;
  return [
    if (n != null)
      'Gemessen letzte Nacht: ${formatDauer(n.stunden)} geschlafen '
          '(${_uhr(n.start)} bis ${_uhr(n.ende)}), '
          '${n.wachMal == 0 ? 'durchgeschlafen' : '${n.wachMal} Mal wach'}'
          '${n.mitPhasen ? ', Tiefschlaf ${_dauer(n.tiefMinuten)}, REM ${_dauer(n.remMinuten)}' : ''}.',
    if (h.ruhepuls != null)
      'Ruhepuls ${h.ruhepuls}${h.ruhepulsSchnitt == null ? '' : ' (eigener Schnitt ${h.ruhepulsSchnitt})'}.',
    if (h.hrv != null)
      'Herzfrequenzvariabilität ${h.hrv} ms${h.hrvSchnitt == null ? '' : ' (eigener Schnitt ${h.hrvSchnitt} ms)'}.',
    if (h.schritte != null) 'Schritte heute bisher: ${h.schritte}.',
    if (h.tageslicht != null) 'Tageslicht heute: ${h.tageslicht} Min.',
    for (final t in h.trainings) 'Von der Uhr: ${t.text}',
    if (h.gewicht != null) 'Gewicht von der Waage: ${_kg(h.gewicht!)} kg.',
  ];
}

/// The same in one text for the check-in.
String messwerteText(HealthTag? h) => healthZeilen(h).join(' ');

String _uhr(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

String _kg(double kg) => kg.toStringAsFixed(1).replaceAll('.', ',');

/// The seeds that fall into the coach card: at most 4 short values, the
/// ones that tell the most first.
List<String> healthSamen(HealthTag? h) {
  if (h == null) return const [];
  final out = <String>[
    if (h.nacht case final n?) '${formatDauer(n.stunden)} Schlaf',
    if ((h.ruhepuls, h.ruhepulsSchnitt) case (final p?, final s?)
        when (p - s).abs() >= 3)
      'Ruhepuls ${p > s ? '+' : '−'}${(p - s).abs()}',
    if ((h.hrv, h.hrvSchnitt) case (final v?, final s?) when s > 0)
      v < s * .85
          ? 'HRV niedrig'
          : v > s * 1.1
          ? 'HRV hoch'
          : 'HRV normal',
    if (h.nacht case final n? when n.wachMal > 0) '${n.wachMal}× wach',
    for (final t in h.trainings) t.art,
  ];
  return out.take(4).toList();
}

/// One field under the coach card on Heute.
class HealthFeld {
  const HealthFeld(this.id, this.text, this.rechts, {this.knopf = false});

  final String id;
  final String text;
  final String rechts;

  /// "Übernehmen" is a button.
  final bool knopf;
}

/// Sunlight goal per day in minutes (as the Sonnenlicht card).
const tageslichtZiel = 5;

/// What is new today: a watch workout to take over, the weight from the
/// scale, minutes in daylight. Only fields with something measured.
List<HealthFeld> healthFelder(SchlafDaten d, String heute) {
  final h = d.healthAm(heute);
  if (h == null) return const [];
  return [
    for (final t in h.trainings)
      if (!d.uebernommen.contains(t.id))
        HealthFeld(
          'training:${t.id}',
          'Von deiner Uhr: ${t.text}',
          'Übernehmen',
          knopf: true,
        ),
    if (h.gewicht != null && h.gewichtZeit != null)
      if (dayKey(h.gewichtZeit!) == heute)
        HealthFeld(
          'gewicht',
          'Von deiner Waage: ${_kg(h.gewicht!)} kg',
          'im Verlauf',
        ),
    if (h.tageslicht case final m? when m > 0)
      HealthFeld(
        'tageslicht',
        'Tageslicht heute: $m Min.',
        m >= tageslichtZiel
            ? 'Ziel erreicht'
            : 'noch ${tageslichtZiel - m} Min.',
      ),
  ];
}

/// Reads today from Apple Health and keeps it with the sleep data. Returns
/// the new data, or null when nothing new came.
Future<SchlafDaten?> healthHolen(
  HealthDienst dienst,
  SchlafDaten d,
  DateTime jetzt,
) async {
  if (!dienst.moeglich) return null;
  final h = await dienst.lesen(jetzt);
  if (h == null) return null;
  return d.mitHealth(h);
}
