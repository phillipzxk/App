import 'package:flutter/material.dart';

import '../ui/coach_style.dart';

/// "Dein Warum" on Heute (vault Umsetzung/Dein Warum.md, decided with
/// Phillip 2026-10-24, draft approved 2026-10-25): only on days the coach
/// sees a weak phase. On top the user's own words from onboarding
/// question 2, below one coach sentence that ties them to today. The card
/// glides in under the coach card.
class WarumKarte extends StatefulWidget {
  const WarumKarte({super.key, required this.warum, required this.satz});

  /// The user's own words ("Warum hast du dich gerade jetzt entschieden").
  final String warum;

  /// The coach's sentence for today.
  final String satz;

  @override
  State<WarumKarte> createState() => _WarumKarteState();
}

class _WarumKarteState extends State<WarumKarte>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rein = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _rein.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kurve = CurvedAnimation(parent: _rein, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: kurve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(kurve),
        child: _karte(),
      ),
    );
  }

  Widget _karte() {
    return Container(
      key: const ValueKey('warum-karte'),
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CoachStyle.nightShadow,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.topLeft,
            radius: 1.4,
            colors: [Color(0xFF3A2A16), Color(0xFF1A130C), Color(0xFF120D09)],
            stops: [0, 0.55, 1],
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 15,
                  color: CoachStyle.goldBright,
                ),
                const SizedBox(width: 7),
                Text(
                  'DEIN WARUM',
                  style: CoachStyle.goldLabel.copyWith(
                    color: CoachStyle.goldBright,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '„${widget.warum}“',
              style: CoachStyle.question.copyWith(
                fontSize: 17,
                height: 1.45,
                color: CoachStyle.cream,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x88C9A25C), Color(0x00C9A25C)],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/coach.jpg',
                    width: 22,
                    height: 22,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    widget.satz,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 14,
                      height: 1.5,
                      color: CoachStyle.ink,
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
