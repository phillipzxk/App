/// One area of the daily check-in with its guiding question.
class CheckInQuestion {
  const CheckInQuestion(this.topic, this.question);

  final String topic;

  /// Guiding question decided with Phillip on 2026-10-12. Once the AI is
  /// connected it rephrases this question for each user every day.
  final String question;
}

/// The four areas, asked every day in this order
/// (see Umsetzung/Täglicher Check-in.md).
const List<CheckInQuestion> checkInQuestions = [
  CheckInQuestion(
    'Training',
    'Wie war dein Training heute, was lief gut und was nicht? Und falls du '
        'heute nicht trainiert hast: Hast du dich wirklich erholt oder eher '
        'unproduktiv gefühlt?',
  ),
  CheckInQuestion(
    'Ernährung',
    'Hast du heute strukturiert und ohne Verlangen gegessen? Oder was lief '
        'bei deiner Ernährung heute nicht so gut?',
  ),
  CheckInQuestion(
    'Schlaf',
    'Hattest du Probleme beim Ein- oder Durchschlafen? Und wenn ja, was '
        'glaubst du, war der Auslöser?',
  ),
  CheckInQuestion(
    'Mindset',
    'Gab es heute etwas, wovor du dich aus fehlender Motivation gedrückt '
        'hast?',
  ),
];
