import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../feed/muster.dart';
import 'coach_karte.dart';
import 'muster_widgets.dart';
import 'feed_widgets.dart';
import 'wurzelwerk.dart';

/// Days in a row with a check-in, counted back from [today]. A day without
/// a check-in yet today does not break the row until it is over.
int checkInStreak(List<CheckIn> checkIns, DateTime today) {
  final days = {for (final c in checkIns) dayKey(c.datum)};
  var day = DateTime(today.year, today.month, today.day);
  if (!days.contains(dayKey(day))) {
    day = day.subtract(const Duration(days: 1));
  }
  var n = 0;
  while (days.contains(dayKey(day))) {
    n++;
    day = day.subtract(const Duration(days: 1));
  }
  return n;
}

/// For each of the last 7 days (oldest first, today last): checked in?
List<bool> lastSevenDays(List<CheckIn> checkIns, DateTime today) {
  final days = {for (final c in checkIns) dayKey(c.datum)};
  final d = DateTime(today.year, today.month, today.day);
  return [
    for (var i = 6; i >= 0; i--)
      days.contains(dayKey(d.subtract(Duration(days: i)))),
  ];
}

/// Start page after the check-in (vault Umsetzung/Home-Schichten.md,
/// decided with Phillip 2026-10-25): on top clear fields, the coach big,
/// below it Fokus and Heute dran side by side and a slim field with the
/// days in a row. Below the ground line a big root system that puts the
/// four areas in focus.
class TodayTab extends StatelessWidget {
  const TodayTab({
    super.key,
    required this.name,
    required this.date,
    required this.today,
    required this.checkIns,
    required this.heuteDran,
    required this.fokusFeld,
    this.fokusKey,
    required this.onOpenTag,
    required this.onOpenFokus,
    this.coachAnsicht = 'text',
    required this.onCoachAnsicht,
    required this.onStichpunkte,
    this.neuesMuster,
    required this.onMusterAblehnen,
    required this.onOpenMuster,
    required this.bereiche,
    required this.onOpenBereich,
    this.wurzeln = 0,
    this.jubel,
    this.jubelTick = 0,
    this.scroll,
    required this.onRestartOnboarding,
  });

  final String name;
  final String date;
  final DateTime today;
  final List<CheckIn> checkIns;

  /// The small sun arc for the "Heute dran" field.
  final Widget heuteDran;

  /// Content of the Fokus field (the home page holds the focus state).
  final Widget fokusFeld;
  final Key? fokusKey;

  /// Taps on the fields, with the field's centre on screen.
  final void Function(Offset mitte) onOpenTag;
  final void Function(Offset mitte) onOpenFokus;

  /// How the coach's reply is shown, see [CoachKarte.ansicht].
  final String coachAnsicht;
  final ValueChanged<String> onCoachAnsicht;
  final Future<void> Function(CheckIn c) onStichpunkte;

  /// A pattern found in the last two days, shown on its day.
  final Muster? neuesMuster;
  final void Function(Muster m) onMusterAblehnen;
  final VoidCallback onOpenMuster;

  /// The four areas on the roots and what happens on a tap.
  final List<WurzelBereich> bereiche;
  final Future<void> Function(Bereich b, Offset mitte) onOpenBereich;

  /// How deep the roots reach (each "Heute geschafft" this week).
  final int wurzeln;

  /// Cheer from the coach and its trigger, see [CoachKarte.jubel].
  final String? jubel;
  final int jubelTick;

  /// Lets the home page scroll up to the cheer.
  final ScrollController? scroll;
  final VoidCallback onRestartOnboarding;

  CheckIn? get _todayCheckIn {
    final key = dayKey(today);
    for (final c in checkIns) {
      if (dayKey(c.datum) == key) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = _todayCheckIn;
    final streak = checkInStreak(checkIns, today);
    final m = neuesMuster;
    return NightScope(
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  label: date,
                  title: name.isEmpty ? 'Heute' : 'Heute, $name',
                  brand: true,
                ),
                if (c != null) ...[
                  CoachKarte(
                    text: c.kiAntwort.isNotEmpty ? c.kiAntwort : noReplyYet,
                    umschaltbar: c.kiAntwort.isNotEmpty,
                    stichpunkte: c.stichpunkte,
                    ansicht: coachAnsicht,
                    onAnsicht: onCoachAnsicht,
                    onStichpunkte: () => onStichpunkte(c),
                    jubel: jubel,
                    jubelTick: jubelTick,
                  ),
                  const SizedBox(height: 10),
                ],
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: HeuteFeld(
                          key: fokusKey ?? const ValueKey('krone-fokus'),
                          onTap: onOpenFokus,
                          child: fokusFeld,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HeuteFeld(
                          key: const ValueKey('dein-tag'),
                          onTap: onOpenTag,
                          child: heuteDran,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _TageFeld(
                  streak: streak,
                  woche: lastSevenDays(checkIns, today),
                  jubelTick: jubelTick,
                ),
                if (m != null) ...[
                  const SizedBox(height: 14),
                  const GroupLabel('Neues Muster'),
                  MusterKarte(
                    muster: m,
                    onAblehnen: () => onMusterAblehnen(m),
                    onAlle: onOpenMuster,
                  ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),
          // The soil runs edge to edge.
          Wurzelwerk(
            bereiche: bereiche,
            onOpen: onOpenBereich,
            streak: streak,
            wurzeln: wurzeln,
            jubelTick: jubelTick,
            gross: true,
          ),
          TextButton(
            onPressed: onRestartOnboarding,
            child: const Text(
              'Fragebogen neu starten',
              style: TextStyle(color: CoachStyle.nightMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A gold-edged dark field on Heute; tapping gives its centre on screen.
class HeuteFeld extends StatelessWidget {
  const HeuteFeld({super.key, required this.child, required this.onTap});

  final Widget child;
  final void Function(Offset mitte) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CoachStyle.nightShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF261C12), Color(0xFF140F0A)],
            ),
            borderRadius: BorderRadius.circular(19),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: () {
              final box = context.findRenderObject() as RenderBox?;
              onTap(
                box == null
                    ? Offset.zero
                    : box.localToGlobal(box.size.center(Offset.zero)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim field: sprout, days in a row and the last 7 days as dots.
class _TageFeld extends StatelessWidget {
  const _TageFeld({
    required this.streak,
    required this.woche,
    required this.jubelTick,
  });

  final int streak;
  final List<bool> woche;
  final int jubelTick;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('spross'),
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF261C12), Color(0xFF140F0A)],
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            ShaderMask(
              shaderCallback: (r) => CoachStyle.goldGradient.createShader(r),
              child: const Icon(Icons.spa, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // Bumps on every cheer.
            TweenAnimationBuilder<double>(
              key: ValueKey(jubelTick),
              tween: Tween(begin: jubelTick > 0 ? 1.3 : 1, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: ShaderMask(
                shaderCallback: (r) => CoachStyle.goldGradient.createShader(r),
                child: Text(
                  '$streak',
                  key: const ValueKey('spross-tage'),
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              streak == 1 ? 'TAG AM STÜCK' : 'TAGE AM STÜCK',
              style: CoachStyle.goldLabel.copyWith(
                fontFamily: 'Sora',
                fontSize: 9,
                letterSpacing: 1.4,
                color: CoachStyle.gold,
              ),
            ),
            const Spacer(),
            for (final x in woche)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: x ? CoachStyle.goldGradient : null,
                  color: x ? null : const Color(0xFF3A3127),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
