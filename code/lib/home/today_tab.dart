import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'baum_krone.dart';
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

/// Start page after the check-in, Heute as one big tree (vault
/// Umsetzung/Home-Schichten.md, 2026-10-25): the crown is four round
/// fields (Coach, Heute dran, Fokus, Tage am Stück), extras hang on it as a
/// golden fruit on their day, and below the ground line the roots carry the
/// four areas.
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
    required this.onOpenCoach,
    required this.onOpenTag,
    required this.onOpenFokus,
    this.fruechte = const [],
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

  /// The small round sun arc for the "Heute dran" field.
  final Widget heuteDran;

  /// Content of the Fokus field (the home page holds the focus state).
  final Widget fokusFeld;
  final Key? fokusKey;

  /// Taps on the crown fields, with the field's centre on screen.
  final void Function(Offset mitte) onOpenCoach;
  final void Function(Offset mitte) onOpenTag;
  final void Function(Offset mitte) onOpenFokus;

  /// Extras due today (a new pattern, the Reality Check).
  final List<Frucht> fruechte;

  /// The four areas on the roots and what happens on a tap.
  final List<WurzelBereich> bereiche;
  final Future<void> Function(Bereich b, Offset mitte) onOpenBereich;

  /// How deep the roots reach (each "Heute geschafft" this week).
  final int wurzeln;

  /// Cheer from the coach and its trigger.
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

  /// The first sentence of the coach's reply, for the small round field.
  static String ersterSatz(String text) {
    final t = text.trim().replaceAll('\n', ' ');
    final m = RegExp(r'^.{12,}?[.!?](\s|$)').firstMatch(t);
    return (m?.group(0) ?? t).trim();
  }

  Widget _coachFeld() {
    final c = _todayCheckIn;
    final j = jubel;
    final text = j != null
        ? j.split('\n').first
        : c == null
        ? 'Mach deinen Check-in, dann sag ich dir was.'
        : ersterSatz(c.kiAntwort.isNotEmpty ? c.kiAntwort : noReplyYet);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoachAvatar(size: 40, lacht: j != null),
        const SizedBox(height: 6),
        Text(
          'DEIN COACH',
          style: CoachStyle.goldLabel.copyWith(
            fontFamily: 'Sora',
            fontSize: 8.5,
            letterSpacing: 1.6,
            color: CoachStyle.gold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          key: j != null ? const ValueKey('coach-jubel') : null,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: CoachStyle.body.copyWith(
            fontSize: 12,
            height: 1.3,
            fontWeight: j != null ? FontWeight.w700 : FontWeight.w500,
            color: j != null
                ? const Color(0xFFF5DFAE)
                : const Color(0xFFF1E7D2),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'mehr ›',
          style: TextStyle(fontSize: 10, color: CoachStyle.gold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = checkInStreak(checkIns, today);
    return NightScope(
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PageHeader(
              label: date,
              title: name.isEmpty ? 'Heute' : 'Heute, $name',
              brand: true,
            ),
          ),
          BaumKrone(
            coach: _coachFeld(),
            tag: heuteDran,
            fokus: fokusFeld,
            fokusKey: fokusKey,
            streak: streak,
            onCoach: onOpenCoach,
            onTag: onOpenTag,
            onFokus: onOpenFokus,
            fruechte: fruechte,
            jubelTick: jubelTick,
            jubelt: jubel != null,
          ),
          // The soil runs edge to edge, the trunk goes on into it.
          LayoutBuilder(
            builder: (context, c) => Wurzelwerk(
              bereiche: bereiche,
              onOpen: onOpenBereich,
              streak: streak,
              wurzeln: wurzeln,
              jubelTick: jubelTick,
              hoehe: 540,
              stamm: stammBreite * c.maxWidth / 390,
            ),
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
