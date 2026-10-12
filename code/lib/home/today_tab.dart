import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'feed_widgets.dart';

/// Start page after the check-in: the coach's reply, the focus of the
/// week, all four areas at a glance and the patterns across areas.
class TodayTab extends StatelessWidget {
  const TodayTab({
    super.key,
    required this.date,
    required this.checkIn,
    required this.onOpenArea,
    required this.onRestartOnboarding,
  });

  final String date;
  final CheckIn? checkIn;
  final ValueChanged<Bereich> onOpenArea;
  final VoidCallback onRestartOnboarding;

  @override
  Widget build(BuildContext context) {
    final c = checkIn;
    return ListView(
      children: [
        PageHeader(label: 'Heute', title: date),
        if (c != null)
          FeedCard(
            title: 'Dein Coach · heute',
            highlight: true,
            children: [
              CoachNote(
                text: c.kiAntwort.isNotEmpty ? c.kiAntwort : noReplyYet,
              ),
            ],
          ),
        const FeedCard(
          title: 'Fokus der Woche',
          children: [
            HintText(
              'Ein Fokus für die ganze Woche, abgeleitet aus deinen '
              'Check-ins. $aiPending',
            ),
          ],
        ),
        const Text('DEINE BEREICHE', style: CoachStyle.label),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            for (final b in Bereich.values)
              _AreaTile(bereich: b, onTap: () => onOpenArea(b)),
          ],
        ),
        const SizedBox(height: 14),
        const FeedCard(
          title: 'Deine Muster',
          children: [
            HintText(
              'Zusammenhänge zwischen deinen Bereichen, die der Coach über '
              'die Wochen erkennt. $aiPending',
            ),
          ],
        ),
        TextButton(
          onPressed: onRestartOnboarding,
          child: const Text(
            'Fragebogen neu starten',
            style: TextStyle(color: CoachStyle.inkSoft),
          ),
        ),
      ],
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({required this.bereich, required this.onTap});

  final Bereich bereich;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        key: ValueKey('bereich-${bereich.name}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bereich.label,
                style: CoachStyle.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Verlauf folgt',
                style: CoachStyle.label.copyWith(letterSpacing: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
