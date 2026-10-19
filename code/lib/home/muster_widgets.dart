import 'package:flutter/material.dart';

import '../feed/muster.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'feed_widgets.dart';

/// Small chip "Schlaf → Ernährung".
class _BereichChip extends StatelessWidget {
  const _BereichChip(this.m);

  final Muster m;

  @override
  Widget build(BuildContext context) {
    if (m.von.isEmpty || m.nach.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CoachStyle.selectedFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF5A4630)),
      ),
      child: Text(
        '${m.von} → ${m.nach}',
        style: CoachStyle.body.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CoachStyle.goldLight,
        ),
      ),
    );
  }
}

/// The newest pattern on "Heute": gold edge, the pattern, the counter-step
/// on cream, "Stimmt nicht" and "Alle Muster".
class MusterKarte extends StatelessWidget {
  const MusterKarte({
    super.key,
    required this.muster,
    required this.onAblehnen,
    required this.onAlle,
  });

  final Muster muster;
  final VoidCallback onAblehnen;
  final VoidCallback onAlle;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('muster-karte'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CoachStyle.nightShadow,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2118), Color(0xFF1B1611)],
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SymbolBadge(Icons.insights, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DEIN MUSTER',
                    style: CoachStyle.goldLabel.copyWith(
                      color: CoachStyle.goldLight,
                    ),
                  ),
                ),
                _BereichChip(muster),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              muster.text,
              style: CoachStyle.body.copyWith(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF6EEDD),
              ),
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
              decoration: BoxDecoration(
                gradient: CoachStyle.tileGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEIN GEGENSCHRITT',
                    style: CoachStyle.goldLabel.copyWith(
                      fontSize: 10,
                      color: const Color(0xFF7A5A2C),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    muster.schritt,
                    style: CoachStyle.body.copyWith(
                      fontSize: 14,
                      color: CoachStyle.goldInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('muster-ablehnen'),
                  onPressed: onAblehnen,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoachStyle.inkSoft,
                    side: const BorderSide(color: CoachStyle.line),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Stimmt nicht'),
                ),
                TextButton(
                  key: const ValueKey('muster-alle'),
                  onPressed: onAlle,
                  child: const Text(
                    'Alle Muster ›',
                    style: TextStyle(
                      color: CoachStyle.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// All patterns so far, newest first.
class MusterSeite extends StatelessWidget {
  const MusterSeite({super.key, required this.muster, required this.heute});

  final List<Muster> muster;
  final DateTime heute;

  String _wann(DateTime d) {
    final t = DateTime(heute.year, heute.month, heute.day);
    final tage = t.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (tage <= 0) return 'heute';
    if (tage == 1) return 'gestern';
    if (tage < 14) return 'vor $tage Tagen';
    return 'vor ${tage ~/ 7} Wochen';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachStyle.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: CoachStyle.goldLight,
        elevation: 0,
      ),
      body: NightScope(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            const PageHeader(label: 'Coach', title: 'Deine Muster'),
            Text(
              'Zusammenhänge, die der Coach in deinen Check-ins klar '
              'gesehen hat. Das neueste steht oben.',
              style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
            ),
            const SizedBox(height: 14),
            for (final m in muster)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: CoachStyle.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: CoachStyle.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          _wann(m.datum),
                          style: CoachStyle.body.copyWith(
                            fontSize: 12,
                            color: CoachStyle.inkSoft,
                          ),
                        ),
                        const Spacer(),
                        _BereichChip(m),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.text,
                      style: CoachStyle.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF6EEDD),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Gegenschritt: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: CoachStyle.goldLight,
                            ),
                          ),
                          TextSpan(text: m.schritt),
                        ],
                      ),
                      style: CoachStyle.body.copyWith(
                        fontSize: 13.5,
                        color: CoachStyle.beigeLabel,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
