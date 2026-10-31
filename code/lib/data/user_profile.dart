/// Profile of the user, filled by the onboarding.
///
/// Holds the first name (asked once before the questions; the coach
/// addresses the user with it, see Umsetzung/Coach-Stil.md), the answers to
/// the seven onboarding questions in the user's own words (see Umsetzung/Onboarding-Fragebogen.md) and the short AI summary
/// "So sehe ich dich gerade", which stays empty until the AI is connected.
class UserProfile {
  const UserProfile({
    this.name = '',
    this.ziel = '',
    this.motivation = '',
    this.level = '',
    this.training = '',
    this.ernaehrung = '',
    this.schlafEnergie = '',
    this.koerper = '',
    this.produktiv = '',
    this.business = '',
    this.persoenlich = '',
    this.zusammenfassung = '',
  });

  final String name;
  final String ziel;
  final String motivation;
  final String level;
  final String training;
  final String ernaehrung;
  final String schlafEnergie;

  /// Answers to the area questions since 2026-10-31: Körper (sleep,
  /// nutrition and training in one), Produktivität & Fokus, Business & Beruf
  /// and Persönlichkeit. [training], [ernaehrung] and [schlafEnergie] are
  /// from the earlier six questions and stay empty for new users.
  final String koerper;
  final String produktiv;
  final String business;
  final String persoenlich;
  final String zusammenfassung;

  /// The profile is only saved after the last question, so a stored goal
  /// means the onboarding is complete.
  bool get isOnboarded => ziel.isNotEmpty;

  /// "Dein Warum" for the cards: the user's own words from the field if
  /// there are any, otherwise the tapped answers. Never the field's label.
  String get warum {
    final zeilen = [
      for (final z in motivation.split('\n'))
        if (z.trim().isNotEmpty) z.trim(),
    ];
    for (final z in zeilen) {
      final m = RegExp(r'^[^:]*\?:\s*(.+)$').firstMatch(z);
      if (m != null) return m.group(1)!.trim();
    }
    return zeilen.isEmpty ? '' : zeilen.first.split('; ').join('. ');
  }

  UserProfile copyWith({
    String? name,
    String? ziel,
    String? motivation,
    String? level,
    String? training,
    String? ernaehrung,
    String? schlafEnergie,
    String? koerper,
    String? produktiv,
    String? business,
    String? persoenlich,
    String? zusammenfassung,
  }) {
    return UserProfile(
      name: name ?? this.name,
      ziel: ziel ?? this.ziel,
      motivation: motivation ?? this.motivation,
      level: level ?? this.level,
      training: training ?? this.training,
      ernaehrung: ernaehrung ?? this.ernaehrung,
      schlafEnergie: schlafEnergie ?? this.schlafEnergie,
      koerper: koerper ?? this.koerper,
      produktiv: produktiv ?? this.produktiv,
      business: business ?? this.business,
      persoenlich: persoenlich ?? this.persoenlich,
      zusammenfassung: zusammenfassung ?? this.zusammenfassung,
    );
  }
}
