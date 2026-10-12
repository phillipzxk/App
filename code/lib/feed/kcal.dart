/// Data for the kcal target, entered once in the Ernährung page.
enum Geschlecht { mann, frau }

/// How active the user is in everyday life, with the usual PAL factor.
enum Aktivitaet {
  kaum('Kaum Bewegung', 'z. B. Bürojob, wenig zu Fuß', 1.2),
  leicht(
    'Leicht aktiv',
    'viel auf den Beinen oder 1–3x Sport pro Woche',
    1.375,
  ),
  aktiv('Aktiv', '3–5x Sport pro Woche', 1.55),
  sehrAktiv('Sehr aktiv', 'fast täglich Sport oder körperliche Arbeit', 1.725);

  const Aktivitaet(this.label, this.beschreibung, this.faktor);

  final String label;
  final String beschreibung;
  final double faktor;
}

class KcalProfil {
  const KcalProfil({
    required this.groesseCm,
    required this.alter,
    required this.geschlecht,
    required this.aktivitaet,
  });

  final int groesseCm;
  final int alter;
  final Geschlecht geschlecht;
  final Aktivitaet aktivitaet;

  Map<String, dynamic> toJson() => {
    'groesse_cm': groesseCm,
    'alter': alter,
    'geschlecht': geschlecht.name,
    'aktivitaet': aktivitaet.name,
  };

  factory KcalProfil.fromJson(Map<String, dynamic> json) => KcalProfil(
    groesseCm: json['groesse_cm'] as int,
    alter: json['alter'] as int,
    geschlecht: Geschlecht.values.byName(json['geschlecht'] as String),
    aktivitaet: Aktivitaet.values.byName(json['aktivitaet'] as String),
  );
}

/// Daily energy need for the current weight: Mifflin-St Jeor times the
/// activity factor, rounded to 50 kcal. The AI adjusts this to the user's
/// goal from the onboarding once it is connected; until then it is the
/// amount that keeps the weight.
int kcalZiel(KcalProfil p, double kg) {
  final grundumsatz =
      10 * kg +
      6.25 * p.groesseCm -
      5 * p.alter +
      (p.geschlecht == Geschlecht.mann ? 5 : -161);
  return ((grundumsatz * p.aktivitaet.faktor) / 50).round() * 50;
}

/// E.g. 2450 -> "2.450".
String formatKcal(int kcal) {
  final s = kcal.toString();
  return s.length > 3
      ? '${s.substring(0, s.length - 3)}.${s.substring(s.length - 3)}'
      : s;
}

/// Parses a whole number in [min, max], else null.
int? parseInt(String text, int min, int max) {
  final n = int.tryParse(text.trim());
  return n != null && n >= min && n <= max ? n : null;
}
