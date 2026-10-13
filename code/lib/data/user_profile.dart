/// Profile of the user, filled by the onboarding.
///
/// Holds the first name (asked once before the questions; the coach
/// addresses the user with it, see Umsetzung/Coach-Stil.md), the answers to
/// the six onboarding questions in the user's own words (see Umsetzung/Onboarding-Fragebogen.md) and the short AI summary
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
    this.zusammenfassung = '',
  });

  final String name;
  final String ziel;
  final String motivation;
  final String level;
  final String training;
  final String ernaehrung;
  final String schlafEnergie;
  final String zusammenfassung;

  /// The profile is only saved after the last question, so a stored goal
  /// means the onboarding is complete.
  bool get isOnboarded => ziel.isNotEmpty;

  UserProfile copyWith({
    String? name,
    String? ziel,
    String? motivation,
    String? level,
    String? training,
    String? ernaehrung,
    String? schlafEnergie,
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
      zusammenfassung: zusammenfassung ?? this.zusammenfassung,
    );
  }
}
