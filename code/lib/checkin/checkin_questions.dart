import 'package:flutter/material.dart';

/// One row of the daily check-in: a short label and the answers to tap
/// (one per row). [topic] is also the key the answer is saved under.
class CheckInRow {
  const CheckInRow(this.topic, this.options, {this.label = ''});

  final String topic;
  final List<String> options;

  /// Small heading above the answers inside a card with several rows.
  final String label;
}

/// One card of the check-in: one area of the home page with one or more
/// rows.
class CheckInCard {
  const CheckInCard({
    required this.name,
    required this.icon,
    required this.question,
    required this.rows,
  });

  final String name;
  final IconData icon;
  final String question;
  final List<CheckInRow> rows;
}

/// The five cards, one per area like on the home page (Phillip 2026-10-31,
/// vault Umsetzung/Täglicher Check-in.md): Körper with training, nutrition
/// and sleep as before, Produktivität & Fokus with energy (moved there on
/// 2026-10-28) and focus, Business & Beruf, Persönlichkeit and Mindset.
/// 8 taps in all.
const List<CheckInCard> checkInCards = [
  CheckInCard(
    name: 'Körper',
    icon: Icons.fitness_center,
    question: 'Training, Essen und Schlaf',
    rows: [
      CheckInRow('Training', [
        'Gut trainiert',
        'Lief zäh',
        'Pause, gut erholt',
        'Pause, eher unproduktiv',
      ], label: 'Training'),
      CheckInRow('Ernährung', [
        'Strukturiert gegessen',
        'Heißhunger gehabt',
        'Unregelmäßig gegessen',
        'Viel Fast Food',
      ], label: 'Ernährung'),
      CheckInRow('Schlaf', [
        'Gut geschlafen',
        'Schlecht eingeschlafen',
        'Nachts wach gewesen',
        'Zu kurz geschlafen',
      ], label: 'Schlaf'),
    ],
  ),
  CheckInCard(
    name: 'Produktivität & Fokus',
    icon: Icons.bolt,
    question: 'Energie und Fokus',
    rows: [
      CheckInRow('Energie', ['Hoch', 'Mittel', 'Niedrig'], label: 'Energie'),
      CheckInRow('Fokus', [
        'Die eine Sache geschafft',
        'Viel am Handy',
        'Aufgeschoben',
        'Bewusst frei',
      ], label: 'Fokus'),
    ],
  ),
  CheckInCard(
    name: 'Business & Beruf',
    icon: Icons.work_outline,
    question: 'Bist du vorangekommen?',
    rows: [
      CheckInRow('Business', [
        'Wichtigen Schritt gemacht',
        'Nur Kleinkram',
        'Etwas aufgeschoben',
        'Heute frei',
      ]),
    ],
  ),
  CheckInCard(
    name: 'Persönlichkeit',
    icon: Icons.person_outline,
    question: 'Hast du in dich investiert?',
    rows: [
      CheckInRow('Persönlichkeit', [
        'Pflege und gelernt',
        'Nur Pflege',
        'Nur gelernt',
        'Heute nichts davon',
      ]),
    ],
  ),
  CheckInCard(
    name: 'Mindset',
    icon: Icons.landscape,
    question: 'Hast du durchgezogen?',
    rows: [
      CheckInRow('Mindset', [
        'Alles durchgezogen',
        'Vor etwas gedrückt',
        'Kaum Motivation',
      ]),
    ],
  ),
];

/// All rows in order, for checks and saving.
final List<CheckInRow> checkInRows = [for (final c in checkInCards) ...c.rows];
