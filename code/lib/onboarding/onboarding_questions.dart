import '../data/user_profile.dart';

/// One onboarding question, answered in the user's own words.
class OnboardingQuestion {
  const OnboardingQuestion({
    required this.topic,
    required this.question,
    required this.read,
    required this.apply,
  });

  /// Short label, e.g. "Ziel".
  final String topic;
  final String question;

  /// Reads this question's answer from the profile.
  final String Function(UserProfile profile) read;

  /// Writes the answer into the profile.
  final UserProfile Function(UserProfile profile, String answer) apply;
}

/// The six questions decided with Phillip on 2026-10-11, same for everyone,
/// in this order (see Umsetzung/Onboarding-Fragebogen.md).
final List<OnboardingQuestion> onboardingQuestions = [
  OnboardingQuestion(
    topic: 'Ziel',
    question:
        'Wie stellst du dir dein Leben vor, wenn du endlich glücklich bist und '
        'im Inneren Erfolg spürst? Was machst du dann anders als heute?',
    read: (p) => p.ziel,
    apply: (p, a) => p.copyWith(ziel: a),
  ),
  OnboardingQuestion(
    topic: 'Motivation',
    question:
        'Was ist der wahre Grund, warum du dich und dein Leben jetzt verändern '
        'willst?',
    read: (p) => p.motivation,
    apply: (p, a) => p.copyWith(motivation: a),
  ),
  OnboardingQuestion(
    topic: 'Level',
    question:
        'Wie würde jemand, der dich gut kennt, deine Essgewohnheiten, deinen '
        'Sport, deine Energie, dein Verhalten und mögliche positive '
        'Veränderungen in letzter Zeit beschreiben?',
    read: (p) => p.level,
    apply: (p, a) => p.copyWith(level: a),
  ),
  OnboardingQuestion(
    topic: 'Training',
    question:
        'Wo bist du dir bei deinem Training und deiner körperlichen Verfassung '
        'gerade unsicher, oder was ist dir noch unklar?',
    read: (p) => p.training,
    apply: (p, a) => p.copyWith(training: a),
  ),
  OnboardingQuestion(
    topic: 'Ernährung',
    question:
        'Wie fühlst du dich gerade mit deiner Ernährung, und wo bist du dir '
        'unsicher, ob sie dir wirklich guttut?',
    read: (p) => p.ernaehrung,
    apply: (p, a) => p.copyWith(ernaehrung: a),
  ),
  OnboardingQuestion(
    topic: 'Schlaf & Energie',
    question:
        'Wie erholt fühlst du dich morgens wirklich, und wann im Alltag merkst '
        'du, dass dir Energie fehlt?',
    read: (p) => p.schlafEnergie,
    apply: (p, a) => p.copyWith(schlafEnergie: a),
  ),
];
