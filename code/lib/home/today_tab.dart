import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../feed/feed_data.dart';
import '../future_me/future_me_card.dart';
import '../future_me/future_me_data.dart';
import '../planner/planner_data.dart';
import '../sleep/schlafzeiten.dart';
import '../supplements/supplement_data.dart';
import '../supplements/supplement_widgets.dart';
import 'day_plan.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../feed/muster.dart';
import 'coach_karte.dart';
import 'muster_widgets.dart';
import 'feed_widgets.dart';
import 'heute_animationen.dart';

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

/// Start page after the check-in: the coach's reply, the supplement
/// reminder, the progress photo, the day plan, the focus of the week, days
/// in a row, all four areas at a glance and the patterns.
class TodayTab extends StatelessWidget {
  const TodayTab({
    super.key,
    required this.name,
    required this.date,
    required this.today,
    required this.checkIns,
    required this.termine,
    required this.training,
    required this.mahlzeiten,
    required this.kcalZiel,
    required this.onAddTermin,
    required this.onRemoveTermin,
    required this.onSetMahlzeiten,
    required this.fotoEinstellungen,
    required this.wochenFotos,
    required this.onOpenZukunft,
    required this.supplements,
    required this.genommen,
    required this.onOpenSupplements,
    this.muster = const [],
    required this.onMusterAblehnen,
    required this.onOpenMuster,
    this.fokus,
    this.coachAnsicht = 'text',
    required this.onCoachAnsicht,
    required this.onStichpunkte,
    this.bettzeit,
    this.schlafStunden = 8,
    this.routineAb,
    this.onOpenSchlaf,
    required this.onOpenArea,
    this.onOpenAreaVon,
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
  final List<Termin> termine;
  final String training;
  final int? mahlzeiten;
  final int? kcalZiel;
  final Future<void> Function(String text) onAddTermin;
  final Future<void> Function(Termin termin) onRemoveTermin;
  final Future<void> Function(int anzahl) onSetMahlzeiten;
  final FotoEinstellungen? fotoEinstellungen;
  final List<WochenFoto> wochenFotos;
  final VoidCallback onOpenZukunft;
  final List<Supplement> supplements;
  final Set<String> genommen;
  final VoidCallback onOpenSupplements;

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
  final double schlafStunden;
  final String? routineAb;
  final VoidCallback? onOpenSchlaf;
  final ValueChanged<Bereich> onOpenArea;

  /// Opens an area page growing out of the big field at [von].
  final void Function(Bereich b, Rect von)? onOpenAreaVon;

  /// How far the sprout's roots reach (each "Heute geschafft" this week).
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
        return 'Foto · Woche ${lage.woche}';
      case FotoStatus.nachholen:
        return 'Foto nachholen · Woche ${lage.woche}';
      case FotoStatus.spaeter:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _todayCheckIn;
    final streak = checkInStreak(checkIns, today);
    return NightScope(
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PageHeader(
                  label: date,
                  title: name.isEmpty ? 'Heute' : 'Heute, $name',
                  brand: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 8),
                child: SprossBox(
                  streak: streak,
                  wurzeln: wurzeln,
                  jubelTick: jubelTick,
                ),
              ),
            ],
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
            const SizedBox(height: 14),
          ],
          BereichsFeld(
            checkIns: checkIns,
            today: today,
            onOpen: (b, von) =>
                onOpenAreaVon != null ? onOpenAreaVon!(b, von) : onOpenArea(b),
          ),
          const SizedBox(height: 14),
          ?fokus,
          const GroupLabel('Heute dran'),
          SupplementHinweis(
            supplements: supplements,
            genommen: genommen,
            now: today,
            onTap: onOpenSupplements,
          ),
          FutureMeCard(
            today: today,
            einstellungen: fotoEinstellungen,
            fotos: wochenFotos,
            onOpen: onOpenZukunft,
          ),
          DayPlanCard(
            today: today,
            termine: termine,
            training: training,
            mahlzeiten: mahlzeiten,
            kcalZiel: kcalZiel,
            onAddTermin: onAddTermin,
            onRemoveTermin: onRemoveTermin,
            onSetMahlzeiten: onSetMahlzeiten,
            onOpenTraining: () => onOpenArea(Bereich.training),
            foto: _fotoHeute,
            onOpenFoto: onOpenZukunft,
            bettzeit: bettzeit,
            schlafStunden: schlafStunden,
            routineAb: routineAb,
            onOpenSchlaf: onOpenSchlaf,
          ),
          const SizedBox(height: 14),
          // Only shown once the coach saw a clear pattern.
          if (muster.isNotEmpty) ...[
            const GroupLabel('Deine Muster'),
            MusterKarte(
              muster: muster.first,
              onAblehnen: () => onMusterAblehnen(muster.first),
              onAlle: onOpenMuster,
            ),
          ],
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
