import '../checkin/checkin.dart';

/// How long the user slept in the night before [datum], in hours.
class SleepEntry {
  const SleepEntry(this.datum, this.stunden);

  final DateTime datum;
  final double stunden;

  Map<String, Object> toJson() => {
    'datum': datum.toIso8601String(),
    'stunden': stunden,
  };

  factory SleepEntry.fromJson(Map<String, dynamic> json) => SleepEntry(
    DateTime.parse(json['datum'] as String),
    (json['stunden'] as num).toDouble(),
  );
}

/// Hours for each of the last [count] days up to [today], oldest first;
/// null where nothing was entered. One bar per night in the chart
/// (decided with Phillip on 2026-10-12).
List<double?> lastNights(List<SleepEntry> entries, DateTime today, int count) {
  final byDay = {for (final e in entries) dayKey(e.datum): e.stunden};
  final day = DateTime(today.year, today.month, today.day);
  return [
    for (var i = count - 1; i >= 0; i--)
      byDay[dayKey(day.subtract(Duration(days: i)))],
  ];
}

/// Average of the entered nights, or null if there are none.
double? average(Iterable<double?> nights) {
  final values = nights.whereType<double>();
  return values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
}

/// Parses "7,5", "7.5" or "7:30"; null if not between 1 and 16 hours.
double? parseHours(String input) {
  final t = input.trim();
  double? value;
  final clock = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t);
  if (clock != null) {
    final minutes = int.parse(clock.group(2)!);
    if (minutes < 60) value = int.parse(clock.group(1)!) + minutes / 60;
  } else {
    value = double.tryParse(t.replaceAll(',', '.'));
  }
  if (value == null || value < 1 || value > 16) return null;
  return value;
}

/// Formats hours German style with one decimal, e.g. "7,5".
String formatHours(double h) => h.toStringAsFixed(1).replaceAll('.', ',');
