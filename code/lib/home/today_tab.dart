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

  /// "Foto · Woche 7" on the photo day, null on other days.
  String? get _fotoHeute {
    final e = fotoEinstellungen;
    if (e == null) return null;
    final lage = fotoLage(today, e, wochenFotos);
    switch (lage.status) {
      case FotoStatus.heute:
        return 'Fortschrittsfoto · Woche ${lage.woche}';
      case FotoStatus.nachholen:
        return 'Foto nachholen · Woche ${lage.woche}';
      case FotoStatus.spaeter:
        return null;
    }
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
    final foto = _fotoHeute;
    final m = _neuesMuster;
    final tag = shortDay(training);
    final b = bettzeit;
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HeuteChip(
                  key: const ValueKey('dein-tag'),
                  icon: Icons.wb_sunny_outlined,
                  text: tag == 'frei' ? 'Kein Training' : tag,
                  klein: b == null
                      ? 'Dein Tag'
                      : 'Bett ${formatUhrzeit(b.bett)}',
                  onTap: onOpenTag,
                ),
                if (foto != null)
                  HeuteChip(
                    key: const ValueKey('foto-chip'),
                    icon: Icons.photo_camera_outlined,
                    text: foto,
                    gold: true,
                    onTap: onOpenZukunft,
                  ),
              ],
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

/// Small round field on top of "Heute", e.g. the day or the photo day.
class HeuteChip extends StatelessWidget {
  const HeuteChip({
    super.key,
    required this.icon,
    required this.text,
    this.klein,
    this.gold = false,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final String? klein;
  final bool gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = gold ? const Color(0xFF1A140E) : CoachStyle.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: gold ? CoachStyle.goldGradient : null,
            color: gold ? null : CoachStyle.card,
            border: gold ? null : Border.all(color: CoachStyle.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: gold ? ink : CoachStyle.goldLight),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: CoachStyle.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              if (klein != null) ...[
                const SizedBox(width: 6),
                Text(
                  klein!,
                  style: CoachStyle.body.copyWith(
                    fontSize: 11.5,
                    color: CoachStyle.inkSoft,
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: gold ? ink : CoachStyle.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
