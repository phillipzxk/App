/// Profile of the user, filled by the onboarding.
///
/// Mirrors the onboarding fields of the "Nutzer" table in the vault
/// (Datenstruktur/Nutzer.md). Values are the fixed storage codes, not the
/// button texts (see Umsetzung/Onboarding-Fragebogen.md).
class UserProfile {
  const UserProfile({
    this.ziel = '',
    this.level = '',
    this.ausgangssituation = '',
    this.onboardingNotiz = '',
  });

  final String ziel;
  final String level;
  final String ausgangssituation;
  final String onboardingNotiz;

  /// A user counts as onboarded once a goal is stored.
  bool get isOnboarded => ziel.isNotEmpty;

  UserProfile copyWith({
    String? ziel,
    String? level,
    String? ausgangssituation,
    String? onboardingNotiz,
  }) {
    return UserProfile(
      ziel: ziel ?? this.ziel,
      level: level ?? this.level,
      ausgangssituation: ausgangssituation ?? this.ausgangssituation,
      onboardingNotiz: onboardingNotiz ?? this.onboardingNotiz,
    );
  }
}
