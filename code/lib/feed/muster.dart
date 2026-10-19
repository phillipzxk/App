/// A connection between areas the coach saw clearly in the check-ins,
/// with one concrete counter-step (see vault Umsetzung/Deine Muster.md).
class Muster {
  const Muster({
    required this.datum,
    required this.text,
    required this.schritt,
    required this.von,
    required this.nach,
    this.abgelehnt = false,
  });

  /// Day the coach found it.
  final DateTime datum;
  final String text;

  /// The counter-step ("Dein Gegenschritt").
  final String schritt;

  /// Area labels, e.g. "Schlaf" -> "Ernährung".
  final String von;
  final String nach;

  /// The user tapped "Stimmt nicht": hidden, and the coach does not
  /// suggest it again.
  final bool abgelehnt;

  Muster ablehnen() => Muster(
    datum: datum,
    text: text,
    schritt: schritt,
    von: von,
    nach: nach,
    abgelehnt: true,
  );

  Map<String, Object> toJson() => {
    'datum': datum.toIso8601String(),
    'text': text,
    'schritt': schritt,
    'von': von,
    'nach': nach,
    'abgelehnt': abgelehnt,
  };

  factory Muster.fromJson(Map<String, dynamic> json) => Muster(
    datum: DateTime.parse(json['datum'] as String),
    text: json['text'] as String? ?? '',
    schritt: json['schritt'] as String? ?? '',
    von: json['von'] as String? ?? '',
    nach: json['nach'] as String? ?? '',
    abgelehnt: json['abgelehnt'] == true,
  );
}

/// Visible patterns, newest first.
List<Muster> sichtbareMuster(List<Muster> all) => [
  for (final m in all)
    if (!m.abgelehnt) m,
]..sort((a, b) => b.datum.compareTo(a.datum));

/// The coach only looks for patterns once there are this many check-ins.
const musterAbCheckIns = 5;
