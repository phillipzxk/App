import 'package:flutter/material.dart';

import '../data/user_profile.dart';
import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import 'bereichs_werte.dart';
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
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        const PageHeader(label: 'Bereich', title: 'Mindset', icon: Icons.spa),
        const AreaChart(bereich: Bereich.mindset),
        const FeedCard(
          title: 'Durchgezogen · diese Woche',
          icon: Icons.check_circle_outline,
          children: [
            HintText('Was du diese Woche durchgezogen hast. $aiPending'),
          ],
        ),
        if (profile.motivation.isNotEmpty) ...[
          const GroupLabel('Deine Basis'),
          FeedCard(
            title: 'Dein Warum',
            icon: Icons.favorite_border,
            gold: true,
            trailing: const Tag('in schwachen Phasen'),
            children: [
              Text(
                '„${profile.motivation}“',
                style: CoachStyle.question.copyWith(fontSize: 18),
              ),
            ],
          ),
        ],
        const GroupLabel('Frag deinen Coach'),
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
