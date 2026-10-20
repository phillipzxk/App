import '../planner/planner_data.dart';

/// "Deine Schlafzeiten" (see vault Umsetzung/Tages-Planer.md, 2026-10-20):
/// wake-up time set once for Mon-Fri and Sat/Sun, and the hours of sleep
/// the user needs. Bedtime = tomorrow's wake-up time minus those hours.
class Schlafzeiten {
  const Schlafzeiten({this.werktag, this.wochenende, this.stunden = 8});

  /// Minutes after midnight, null until set.
  final int? werktag;

  /// Minutes after midnight; falls back to [werktag] when not set.
  final int? wochenende;

  /// Hours of sleep per night.
  final double stunden;

  bool get gesetzt => werktag != null || wochenende != null;

  /// Normal wake-up time on [day], or null.
  int? aufstehenAm(DateTime day) => day.weekday >= DateTime.saturday
      ? wochenende ?? werktag
      : werktag ?? wochenende;

  Schlafzeiten copyWith({int? werktag, int? wochenende, double? stunden}) =>
      Schlafzeiten(
        werktag: werktag ?? this.werktag,
        wochenende: wochenende ?? this.wochenende,
        stunden: stunden ?? this.stunden,
      );

  Map<String, Object?> toJson() => {
    'werktag': werktag,
    'wochenende': wochenende,
    'stunden': stunden,
  };

  factory Schlafzeiten.fromJson(Map<String, dynamic> json) => Schlafzeiten(
    werktag: (json['werktag'] as num?)?.toInt(),
    wochenende: (json['wochenende'] as num?)?.toInt(),
    stunden: (json['stunden'] as num?)?.toDouble() ?? 8,
  );
}

/// Tonight's bedtime and tomorrow's wake-up time.
class Bettzeit {
  const Bettzeit({required this.bett, required this.aufstehen, this.termin});

  /// Minutes after midnight (0..1439).
  final int bett;
  final int aufstehen;

  /// The early appointment that moved the wake-up time, if any.
  final Termin? termin;
}

/// How long before an early appointment the user gets up.
const vorlaufMinuten = 60;

/// Tonight's bedtime, or null while no wake-up time is set. An appointment
/// tomorrow that starts less than an hour after the normal wake-up time
/// moves it to one hour before the appointment.
Bettzeit? bettzeitFuer(Schlafzeiten z, DateTime today, List<Termin> termine) {
  final morgen = DateTime(today.year, today.month, today.day + 1);
  var aufstehen = z.aufstehenAm(morgen);
  if (aufstehen == null) return null;
  Termin? frueh;
  for (final t in termineAm(termine, morgen)) {
    final m = parseUhrzeit(t.zeit ?? '');
    if (m == null) continue;
    if (m - vorlaufMinuten < aufstehen!) {
      aufstehen = (m - vorlaufMinuten).clamp(0, 1439);
      frueh = t;
    }
    break; // sorted by time: the first one is the earliest
  }
  final bett = ((aufstehen! - (z.stunden * 60).round()) % 1440 + 1440) % 1440;
  return Bettzeit(bett: bett, aufstehen: aufstehen, termin: frueh);
}

/// "6:30", "06:30", "6.30", "6" -> minutes after midnight; null if invalid.
int? parseUhrzeit(String input) {
  final m = RegExp(r'^(\d{1,2})(?:[:.](\d{2}))?$').firstMatch(input.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2) ?? '0');
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

/// Minutes after midnight -> "6:30", "22:30".
String formatUhrzeit(int minuten) =>
    '${minuten ~/ 60}:${(minuten % 60).toString().padLeft(2, '0')}';

/// Hours German style without needless decimals: "8", "7,5".
String formatStunden(double h) => h == h.roundToDouble()
    ? h.toStringAsFixed(0)
    : h.toStringAsFixed(1).replaceAll('.', ',');
