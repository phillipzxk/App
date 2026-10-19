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
import '../feed/muster.dart';
import 'bereichs_werte.dart';
import 'muster_widgets.dart';
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
    this.muster = const [],
    required this.onMusterAblehnen,
    required this.onOpenMuster,
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

  /// Visible patterns, newest first (see Umsetzung/Deine Muster.md).
  final List<Muster> muster;
  final void Function(Muster m) onMusterAblehnen;
  final VoidCallback onOpenMuster;
  final ValueChanged<Bereich> onOpenArea;
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
        padding: const EdgeInsets.only(bottom: 110),
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
          ),
          const GroupLabel('Deine Woche'),
          _WeekCard(
            streak: streak,
            days: lastSevenDays(checkIns, today),
            today: today,
          ),
          const GroupLabel('Deine Bereiche'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
            children: [
              for (final b in Bereich.values)
                _AreaTile(
                  bereich: b,
                  checkIns: checkIns,
                  today: today,
                  onTap: () => onOpenArea(b),
                ),
            ],
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

/// "Deine Woche" in one small card: days in a row with check-in, and the
/// focus of the week with one stroke per day.
class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.streak,
    required this.days,
    required this.today,
  });

  final int streak;
  final List<bool> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    Widget line(IconData icon, String title, Widget right) => Row(
      children: [
        SymbolBadge(icon, size: 26, onDark: true),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: CoachStyle.cardTitle.copyWith(fontSize: 14),
          ),
        ),
        right,
      ],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: CoachStyle.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoachStyle.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(
            Icons.local_fire_department_outlined,
            streak == 1 ? '1 Tag am Stück' : '$streak Tage am Stück',
            _Dots(days: days),
          ),
          const SizedBox(height: 12),
          line(
            Icons.track_changes,
            'Fokus der Woche',
            Text(
              aiPending,
              style: CoachStyle.body.copyWith(
                fontSize: 13,
                color: CoachStyle.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _WeekStrokes(today: today),
        ],
      ),
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
                color: CoachStyle.nightLineStrong,
                borderRadius: BorderRadius.circular(3),
                border: i == today.weekday - 1
                    ? Border.all(color: CoachStyle.goldBright, width: 1.5)
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
              color: on ? const Color(0xFFD4A85E) : CoachStyle.nightLineStrong,
            ),
          ),
      ],
    );
  }
}

/// Area at a glance: own symbol, today's AI rating (a dash until the AI is
/// connected) and the small progress bars.
class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.bereich,
    required this.checkIns,
    required this.today,
    required this.onTap,
  });

  final Bereich bereich;
  final List<CheckIn> checkIns;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: CoachStyle.tileGradient,
        boxShadow: CoachStyle.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide.none,
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
                        color: CoachStyle.goldInk,
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
                        style: CoachStyle.cardTitle.copyWith(
                          fontSize: 13,
                          color: CoachStyle.goldInk,
                        ),
                      ),
                    ),
                  ],
                ),
                TileWerte(bereich: bereich, checkIns: checkIns, today: today),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
