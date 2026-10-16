import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../feed/feed_data.dart';
import '../future_me/future_me_card.dart';
import '../future_me/future_me_data.dart';
import '../planner/planner_data.dart';
import '../supplements/supplement_data.dart';
import '../supplements/supplement_widgets.dart';
import 'day_plan.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'feed_widgets.dart';

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

const _icons = {
  Bereich.training: Icons.fitness_center,
  Bereich.ernaehrung: Icons.eco,
  Bereich.schlaf: Icons.bedtime,
  Bereich.mindset: Icons.spa,
};

/// Start page after the check-in: the coach's reply, the supplement
/// reminder, "Dein zukünftiges Ich", the focus of the week, the day plan, days in a row, all four areas at a glance and the patterns.
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
    required this.onOpenArea,
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
  final ValueChanged<Bereich> onOpenArea;
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
    return ListView(
      children: [
        PageHeader(
          label: date,
          title: name.isEmpty ? 'Heute' : 'Heute, $name',
          brand: true,
        ),
        if (c != null) ...[
          CoachCard(
            label: 'Dein Coach · heute',
            text: c.kiAntwort.isNotEmpty ? c.kiAntwort : noReplyYet,
          ),
          const SizedBox(height: 14),
        ],
        const GroupLabel('Heute dran'),
        if (supplements.isNotEmpty)
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
        ),
        const GroupLabel('Deine Woche'),
        FeedCard(
          title: 'Fokus der Woche',
          icon: Icons.track_changes,
          children: [
            const HintText(
              'Ein Fokus für die ganze Woche, abgeleitet aus deinen '
              'Check-ins. $aiPending',
            ),
            const SizedBox(height: 12),
            _WeekStrokes(today: today),
            const SizedBox(height: 6),
            const HintText(
              'Jeder Tag, an dem du deinen Fokus schaffst, füllt einen Strich.',
            ),
          ],
        ),
        FeedCard(
          title: streak == 1 ? '1 Tag am Stück' : '$streak Tage am Stück',
          icon: Icons.local_fire_department_outlined,
          trailing: _Dots(days: lastSevenDays(checkIns, today)),
          children: const [HintText('jeden Tag eingecheckt')],
        ),
        const GroupLabel('Deine Bereiche'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: [
            for (final b in Bereich.values)
              _AreaTile(bereich: b, onTap: () => onOpenArea(b)),
          ],
        ),
        const SizedBox(height: 14),
        const FeedCard(
          title: 'Deine Muster',
          icon: Icons.insights,
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

/// Seven strokes for Monday to Sunday; today's is outlined in gold.
class _WeekStrokes extends StatelessWidget {
  const _WeekStrokes({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: CoachStyle.bar,
                borderRadius: BorderRadius.circular(3),
                border: i == today.weekday - 1
                    ? Border.all(color: CoachStyle.gold, width: 1.5)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// One dot per day of the last week, gold when checked in.
class _Dots extends StatelessWidget {
  const _Dots({required this.days});

  final List<bool> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final on in days)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? CoachStyle.gold : CoachStyle.bar,
            ),
          ),
      ],
    );
  }
}

/// Area at a glance: own symbol, today's AI rating (a dash until the AI is
/// connected) and the small progress bars.
class _AreaTile extends StatelessWidget {
  const _AreaTile({required this.bereich, required this.onTap});

  final Bereich bereich;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: CoachStyle.cardBright,
        boxShadow: CoachStyle.cardShadowStrong,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: CoachStyle.edgeStrong),
        ),
        child: InkWell(
          key: ValueKey('bereich-${bereich.name}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: CoachStyle.dark,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icons[bereich],
                        size: 14,
                        color: CoachStyle.goldLight,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        bereich.label,
                        overflow: TextOverflow.ellipsis,
                        style: CoachStyle.cardTitle.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      '–',
                      style: CoachStyle.cardTitle.copyWith(
                        color: CoachStyle.inkSoft,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final h in const [10.0, 14.0, 8.0, 12.0])
                      Expanded(
                        child: Container(
                          height: h,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: CoachStyle.bar.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Verlauf folgt',
                  style: CoachStyle.label.copyWith(
                    letterSpacing: 0,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
