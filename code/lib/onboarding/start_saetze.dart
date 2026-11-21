import 'package:flutter/material.dart';

import '../data/user_profile.dart';
import 'onboarding_questions.dart' show keineProbleme;

/// One area on "So sehe ich dich gerade": what we start with.
typedef StartSatz = ({String name, IconData icon, String satz});

/// The first tapped answer that has a sentence decides; otherwise a
/// general one.
String _erster(String antwort, Map<String, String> saetze, String sonst) {
  if (antwort.contains(keineProbleme)) {
    return 'Läuft schon gut. Wir halten es so und bauen darauf auf.';
  }
  for (final e in saetze.entries) {
    if (antwort.contains(e.key)) return e.value;
  }
  return sonst;
}

/// The four areas, each with one sentence what we start with, from the
/// answers in the questionnaire (Rundgang proposal 6, Phillip 2026-11-21).
List<StartSatz> startSaetze(UserProfile p) => [
  (
    name: 'Körper',
    icon: Icons.fitness_center,
    satz: _erster(p.koerper, const {
      'Ich schlafe schlecht ein': 'Wir starten mit einer festen Bettzeit.',
      'Ich bin morgens nicht erholt':
          'Wir starten mit deinem Morgen: gleiche Aufstehzeit und Licht.',
      'Heißhunger': 'Wir starten mit festen Mahlzeiten gegen den Heißhunger.',
      'Ich esse unregelmäßig': 'Wir starten mit festen Zeiten fürs Essen.',
      'Ich mache keine Fortschritte':
          'Wir starten damit, jedes Training einzutragen und gezielt zu '
          'steigern.',
      'Ich bleibe beim Training nicht dran':
          'Wir starten mit wenigen, festen Trainingstagen.',
    }, 'Wir starten damit, deinen Alltag kennenzulernen.'),
  ),
  (
    name: 'Fokus & Arbeit',
    icon: Icons.bolt,
    satz: _erster('${p.produktiv}\n${p.business}', const {
      'Ich verliere mich am Handy':
          'Wir starten mit einem Block am Tag ohne Handy.',
      'Ich schiebe Wichtiges auf':
          'Wir starten mit einer Sache pro Tag, die wirklich zählt.',
      'Energietiefs': 'Wir starten damit, deine Tiefs zu finden.',
      'Mir fehlt eine feste Struktur':
          'Wir starten mit einem einfachen Plan für deinen Tag.',
      'Ich weiß nicht, wo ich anfangen soll':
          'Wir starten mit deinem ersten Hebel der Woche.',
      'Ich habe Ideen, setze aber nichts um':
          'Wir starten damit, eine Idee pro Woche wirklich umzusetzen.',
      'Ich komme im Job oder Studium nicht weiter':
          'Wir starten mit einem klaren nächsten Schritt im Job.',
      'Ich verdiene weniger': 'Wir starten mit deinem ersten Hebel der Woche.',
    }, 'Wir starten mit einer Sache pro Tag, die wirklich zählt.'),
  ),
  (
    name: 'Ausstrahlung',
    icon: Icons.person_outline,
    satz: _erster(p.persoenlich, const {
      'Ich fühle mich mit meinem Aussehen nicht wohl':
          'Wir starten mit kleinen Schritten, damit du dich wohler fühlst.',
      'Mir fehlt eine Pflege-Routine':
          'Wir starten mit einer kurzen Pflege-Routine am Morgen.',
      'Ich trete unsicher auf':
          'Wir starten mit einer kleinen Übung für dein Auftreten.',
      'Ich lerne viel, setze aber wenig um':
          'Wir starten mit einem Skill, den du wirklich anwendest.',
    }, 'Wir starten mit einer kurzen Pflege-Routine am Morgen.'),
  ),
  (
    name: 'Mindset',
    icon: Icons.landscape,
    satz: _erster(p.level, const {
      'Trainiert regelmäßig, kommt aber nicht weiter':
          'Wir starten damit, ehrlich hinzuschauen, woran es hängt.',
      'Fängt oft an, bleibt aber nicht dran':
          'Wir starten mit einer Sache am Tag, die du durchziehst.',
      'Macht gerade kaum Sport': 'Wir starten klein, damit du dranbleibst.',
      'Hat in letzter Zeit schon einiges verändert':
          'Wir starten damit, das Erreichte zu halten.',
    }, 'Wir starten mit einer Sache am Tag, die du durchziehst.'),
  ),
];
