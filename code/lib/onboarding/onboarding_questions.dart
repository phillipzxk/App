import '../data/user_profile.dart';

/// One onboarding question: answers to tap (several allowed) plus a short
/// field for the user's own words.
class OnboardingQuestion {
  const OnboardingQuestion({
    required this.topic,
    required this.question,
    required this.options,
    required this.fieldLabel,
    this.fieldHint = 'Ein Satz reicht …',
    this.fieldRequired = false,
    required this.apply,
  });

  /// Short label, e.g. "Ziel".
  final String topic;
  final String question;

  /// Answers to tap; the user may pick several.
  final List<String> options;

  /// Label of the field under the answers.
  final String fieldLabel;
  final String fieldHint;

  /// Whether the field must be filled (only the goal). Otherwise one tapped
  /// answer or some text is enough.
  final bool fieldRequired;

  /// Writes the combined answer into the profile.
  final UserProfile Function(UserProfile profile, String answer) apply;

  bool canContinue(Set<String> picked, String text) => fieldRequired
      ? text.trim().isNotEmpty
      : picked.isNotEmpty || text.trim().isNotEmpty;

  /// The answer as one text for the profile and the coach: the tapped
  /// answers, then the field with its label.
  String compose(Set<String> picked, String text) {
    final chosen = [
      for (final o in options)
        if (picked.contains(o)) o,
    ];
    return [
      if (chosen.isNotEmpty) chosen.join('; '),
      if (text.trim().isNotEmpty) '$fieldLabel: ${text.trim()}',
    ].join('\n');
  }
}

const keineProbleme = 'Gerade keine größeren Probleme';

/// The six questions decided with Phillip on 2026-10-18, same for everyone,
/// in this order (see Umsetzung/Onboarding-Fragebogen.md).
final List<OnboardingQuestion> onboardingQuestions = [
  OnboardingQuestion(
    topic: 'Ziel',
    question: 'Was ist dein Ziel, und was willst du dafür vor allem verändern?',
    options: const [
      'Fitter und stärker werden',
      'Mehr Energie im Alltag',
      'Mental stärker werden und Dinge durchziehen',
      'Mich wohler in meiner Haut fühlen',
    ],
    fieldLabel: 'Dein Ziel in einem Satz',
    fieldHint: 'z. B. Bis zum Sommer 8 kg leichter und wieder Spaß am Sport',
    fieldRequired: true,
    apply: (p, a) => p.copyWith(ziel: a),
  ),
  OnboardingQuestion(
    topic: 'Motivation',
    question: 'Warum hast du dich gerade jetzt entschieden, das anzugehen?',
    options: const [
      'Ich bin unzufrieden damit, wie es gerade ist',
      'Ich will lange gesund und fit bleiben',
      'Ich will ein Vorbild sein, z. B. für Familie oder Freunde',
      'Ich will endlich mein Potenzial ausschöpfen',
    ],
    fieldLabel: 'Was ist dein wahrer Grund?',
    apply: (p, a) => p.copyWith(motivation: a),
  ),
  OnboardingQuestion(
    topic: 'Stand',
    question: 'Wie würde dich jemand beschreiben, der dich gut kennt?',
    options: const [
      'Trainiert regelmäßig, kommt aber nicht weiter',
      'Fängt oft an, bleibt aber nicht dran',
      'Macht gerade kaum Sport',
      'Hat in letzter Zeit schon einiges verändert',
    ],
    fieldLabel: 'Und was würde diese Person als deine Stärke nennen?',
    apply: (p, a) => p.copyWith(level: a),
  ),
  OnboardingQuestion(
    topic: 'Training',
    question: 'Welche Probleme hast du gerade bei Training und Sport?',
    options: const [
      'Mein Plan passt nicht richtig zu mir',
      'Ich mache keine Fortschritte mehr',
      'Ich weiß nicht, wie viel Pause ich brauche',
      'Ich bleibe nicht dran',
      keineProbleme,
    ],
    fieldLabel: 'Und was fällt dir dabei leicht?',
    apply: (p, a) => p.copyWith(training: a),
  ),
  OnboardingQuestion(
    topic: 'Ernährung',
    question: 'Welche Probleme hast du gerade mit deiner Ernährung?',
    options: const [
      'Heißhunger, vor allem abends',
      'Keine Struktur, ich esse unregelmäßig',
      'Ich weiß nicht, was mir wirklich guttut',
      'Oft unterwegs oder Fast Food',
      keineProbleme,
    ],
    fieldLabel:
        'Was weißt du schon, oder was hast du an deiner Ernährung bereits '
        'angepasst?',
    apply: (p, a) => p.copyWith(ernaehrung: a),
  ),
  OnboardingQuestion(
    topic: 'Schlaf & Energie',
    question: 'Welche Probleme hast du gerade mit Schlaf und Energie?',
    options: const [
      'Ich schlafe schlecht ein',
      'Ich wache nachts oft auf',
      'Ich bin morgens nicht erholt',
      'Ich habe tagsüber Energietiefs',
      keineProbleme,
    ],
    fieldLabel: 'Und wann fühlst du dich richtig fit?',
    apply: (p, a) => p.copyWith(schlafEnergie: a),
  ),
];
