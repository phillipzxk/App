import 'package:flutter/material.dart';

import '../data/user_profile.dart';
import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import 'feed_widgets.dart';

/// Mindset page: progress, Durchgezogen, Dein Warum and the field
/// "Wovor drückst du dich gerade?".
class MindsetTab extends StatelessWidget {
  const MindsetTab({
    super.key,
    required this.profile,
    required this.fragen,
    required this.onAsk,
  });

  final UserProfile profile;
  final List<CoachFrage> fragen;
  final Future<void> Function(String text) onAsk;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const PageHeader(label: 'Bereich', title: 'Mindset'),
        const AreaChart(),
        const FeedCard(
          title: 'Durchgezogen · diese Woche',
          icon: Icons.check_circle_outline,
          children: [
            HintText(
              'Hier sammelt der Coach aus deinen Mindset-Antworten im '
              'Check-in, was du diese Woche durchgezogen hast. $aiPending',
            ),
          ],
        ),
        if (profile.motivation.isNotEmpty)
          FeedCard(
            title: 'Dein Warum',
            icon: Icons.favorite_border,
            trailing: const Tag('in schwachen Phasen'),
            children: [
              Text(
                '„${profile.motivation}“',
                style: CoachStyle.question.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const HintText(
                'Deine eigene Antwort aus dem Onboarding. Sobald die KI '
                'angeschlossen ist, erscheint sie nur, wenn du gerade eine '
                'schwache Phase hast.',
              ),
            ],
          ),
        AskCoachCard(
          title: 'Wovor drückst du dich gerade?',
          hint: 'Schreib es auf, und wir finden den ersten kleinen Schritt.',
          today: fragen,
          onSend: onAsk,
        ),
      ],
    );
  }
}
