import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../feed/feed_data.dart';
import '../future_me/future_me_data.dart';
import '../sleep/schlafzeiten.dart';
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

/// Start page after the check-in, "Home-Feed als Wurzelwerk" (vault
/// Umsetzung/Home-Schichten.md, 2026-10-25). On top only the essentials:
/// the coach's reply, the focus of the week and a chip for the day; things
/// that are only due on some days (progress photo, a new pattern) show up
/// there on their day. Below the ground line the root system with the four
/// areas.
class TodayTab extends StatelessWidget {
  const TodayTab({
    super.key,
    required this.name,
    required this.date,
    required this.today,
    required this.checkIns,
    required this.training,
    required this.fotoEinstellungen,
    required this.wochenFotos,
    required this.onOpenZukunft,
    required this.onOpenTag,
    required this.heuteDran,
    this.muster = const [],
    required this.onMusterAblehnen,
    required this.onOpenMuster,
    this.fokus,
    this.coachAnsicht = 'text',
    required this.onCoachAnsicht,
    required this.onStichpunkte,
    this.bettzeit,
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
  final String training;
  final FotoEinstellungen? fotoEinstellungen;
  final List<WochenFoto> wochenFotos;
  final VoidCallback onOpenZukunft;

  /// Opens "Dein Tag" (appointments, meals, bedtime) as its own page.
  final VoidCallback onOpenTag;

  /// Supplements still to take today (shown in "Heute dran").
  /// The small sun arc "Heute dran"; tapping it opens Dein Tag.
  final Widget heuteDran;

  /// Visible patterns, newest first (see Umsetzung/Deine Muster.md).
  final List<Muster> muster;
  final void Function(Muster m) onMusterAblehnen;
  final VoidCallback onOpenMuster;

  /// "Fokus der Woche": the running week or the choice (built by the home
  /// page, which holds the state).
  final Widget? fokus;

  /// How the coach's reply is shown, see [CoachKarte.ansicht].
  final String coachAnsicht;
  final ValueChanged<String> onCoachAnsicht;
  final Future<void> Function(CheckIn c) onStichpunkte;
  final Bettzeit? bettzeit;

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

  /// A pattern found in the last two days counts as new and shows on top.
  Muster? get _neuesMuster {
    if (muster.isEmpty) return null;
    final m = muster.first;
    final t = DateTime(today.year, today.month, today.day);
    final d = DateTime(m.datum.year, m.datum.month, m.datum.day);
    return t.difference(d).inDays <= 2 ? m : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = _todayCheckIn;
    final streak = checkInStreak(checkIns, today);
    final m = _neuesMuster;
    return NightScope(
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          for (final w in [
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
              const SizedBox(height: 12),
            ],
            ?fokus,
            heuteDran,
            if (m != null) ...[
              const SizedBox(height: 14),
              const GroupLabel('Neues Muster'),
              MusterKarte(
                muster: m,
                onAblehnen: () => onMusterAblehnen(m),
                onAlle: onOpenMuster,
              ),
            ],
            const SizedBox(height: 8),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: w,
            ),
          // The soil runs edge to edge.
          Wurzelwerk(
            bereiche: bereiche,
            onOpen: onOpenBereich,
            streak: streak,
            wurzeln: wurzeln,
            jubelTick: jubelTick,
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
