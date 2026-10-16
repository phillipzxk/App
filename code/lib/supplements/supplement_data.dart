/// One intake of the user's own supplement routine (see
/// Umsetzung/Supplement-Routine.md). The user decides what, how much and
/// when; the app only reminds and lets them tick it off.
class Supplement {
  const Supplement({required this.zeit, required this.name, this.menge = ''});

  /// "08:00".
  final String zeit;

  /// E.g. "Kreatin".
  final String name;

  /// In the user's words, e.g. "5 g"; may be empty.
  final String menge;

  /// Tells intakes apart when ticking them off.
  String get id => '$zeit|$name';

  Map<String, dynamic> toJson() => {'zeit': zeit, 'name': name, 'menge': menge};

  factory Supplement.fromJson(Map<String, dynamic> json) => Supplement(
    zeit: json['zeit'] as String,
    name: json['name'] as String,
    menge: json['menge'] as String? ?? '',
  );
}

final _zeitPattern = RegExp(r'^([01]?\d|2[0-3])(?:[:.]([0-5]\d))?$');

/// "8" → "08:00", "8.30" → "08:30", "21:30" stays; null if it is no time.
String? normZeit(String text) {
  final m = _zeitPattern.firstMatch(text.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!).toString().padLeft(2, '0');
  final min = (m.group(2) ?? '00').padLeft(2, '0');
  return '$h:$min';
}

/// Sorted by time of day.
List<Supplement> nachZeit(List<Supplement> all) =>
    List.of(all)..sort((a, b) => a.zeit.compareTo(b.zeit));

/// The next intake not ticked off yet: the first one from now on, or else
/// the earliest one still open.
Supplement? naechsteOffene(
  List<Supplement> all,
  Set<String> genommen,
  DateTime now,
) {
  final open = [
    for (final s in nachZeit(all))
      if (!genommen.contains(s.id)) s,
  ];
  if (open.isEmpty) return null;
  final jetzt =
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';
  for (final s in open) {
    if (s.zeit.compareTo(jetzt) >= 0) return s;
  }
  return open.first;
}
