import '../data/user_profile.dart';

/// One answer button: what the user reads and what gets stored.
class AnswerOption {
  const AnswerOption(this.label, this.value);

  final String label;
  final String value;
}

/// A multiple-choice question of the onboarding.
class ChoiceQuestion {
  const ChoiceQuestion({
    required this.question,
    required this.subtitle,
    required this.options,
    required this.apply,
  });

  final String question;
  final String subtitle;
  final List<AnswerOption> options;

  /// Writes the chosen value into the profile.
  final UserProfile Function(UserProfile profile, String value) apply;
}

/// Texts and storage codes as defined in Umsetzung/Onboarding-Fragebogen.md.
final List<ChoiceQuestion> choiceQuestions = [
  ChoiceQuestion(
    question: 'Was ist dein wichtigstes Ziel?',
    subtitle: 'Wähle das, was dir gerade am meisten am Herzen liegt.',
    options: const [
      AnswerOption('Muskeln aufbauen', 'muskelaufbau'),
      AnswerOption('Mehr Energie im Alltag', 'energie'),
      AnswerOption('Bessere Routinen entwickeln', 'routinen'),
      AnswerOption('Insgesamt fitter werden', 'fitness'),
    ],
    apply: (p, v) => p.copyWith(ziel: v),
  ),
  ChoiceQuestion(
    question: 'Wie aktiv bist du im Moment?',
    subtitle: 'Sei ehrlich, hier gibt es kein Richtig oder Falsch.',
    options: const [
      AnswerOption('Kaum oder gar nicht', 'einsteiger'),
      AnswerOption('1 bis 2 Mal pro Woche', 'gelegentlich'),
      AnswerOption('3 bis 4 Mal pro Woche', 'regelmaessig'),
      AnswerOption('5 Mal oder öfter pro Woche', 'sehr_aktiv'),
    ],
    apply: (p, v) => p.copyWith(level: v),
  ),
  ChoiceQuestion(
    question: 'Was hält dich gerade am meisten zurück?',
    subtitle: 'Damit dein Coach weiß, wo er ansetzen kann.',
    options: const [
      AnswerOption('Zu wenig Zeit', 'zeit'),
      AnswerOption('Ich bleibe nicht dran', 'motivation'),
      AnswerOption('Ich weiß nicht genau, was richtig ist', 'wissen'),
      AnswerOption('Wenig Energie oder schlechter Schlaf', 'erholung'),
    ],
    apply: (p, v) => p.copyWith(ausgangssituation: v),
  ),
];

/// Choice questions plus the free-text question.
int get questionCount => choiceQuestions.length + 1;

/// Button text for a stored value, e.g. for showing the profile.
String labelFor(int questionIndex, String value) {
  for (final option in choiceQuestions[questionIndex].options) {
    if (option.value == value) return option.label;
  }
  return value;
}
