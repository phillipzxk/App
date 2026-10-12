/// One weight entry in kilograms.
class WeightEntry {
  const WeightEntry(this.datum, this.kg);

  final DateTime datum;
  final double kg;

  Map<String, Object> toJson() => {'datum': datum.toIso8601String(), 'kg': kg};

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    DateTime.parse(json['datum'] as String),
    (json['kg'] as num).toDouble(),
  );
}

/// Average weight of one calendar week (Monday to Sunday).
class WeekAverage {
  const WeekAverage(this.monday, this.kg);

  final DateTime monday;
  final double kg;
}

/// Groups entries by week and averages them, oldest week first.
///
/// The chart shows these averages instead of single days, so normal daily
/// swings don't discourage anyone (decided with Phillip on 2026-10-12).
List<WeekAverage> weeklyAverages(List<WeightEntry> entries) {
  final weeks = <DateTime, List<double>>{};
  for (final e in entries) {
    final day = DateTime(e.datum.year, e.datum.month, e.datum.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    weeks.putIfAbsent(monday, () => []).add(e.kg);
  }
  final mondays = weeks.keys.toList()..sort();
  return [
    for (final m in mondays)
      WeekAverage(m, weeks[m]!.reduce((a, b) => a + b) / weeks[m]!.length),
  ];
}

/// Parses user input like "82,4" or "82.4"; null if not a plausible weight.
double? parseKg(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  if (value == null || value < 30 || value > 300) return null;
  return value;
}

/// Formats kilograms German style with one decimal, e.g. "82,4".
String formatKg(double kg) => kg.toStringAsFixed(1).replaceAll('.', ',');
