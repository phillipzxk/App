import '../abo/abo_heute.dart';

import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../health/health_heute.dart';
import '../health/health_logik.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../feed/muster.dart';
import 'coach_karte.dart';
import 'muster_widgets.dart';
import 'warum_karte.dart';
import 'feed_widgets.dart';
import 'fundament_seite.dart';
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
/// days in a row. Since 2026-11-08 the root system has its own page
/// (Fundament, vault Umsetzung/Heute und Fundament.md); Heute ends with a
/// small card that leads there.
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
    this.warum = '',
    this.warumSatz,
    this.muster,
    this.musterNeu = false,
    required this.fotoFeld,
    required this.onOpenMuster,
    required this.bereiche,
    required this.onFundament,
    this.jubel,
    this.jubelTick = 0,
    this.scroll,
    required this.onRestartOnboarding,
    this.onKonto,
    this.samen = const [],
    this.onSamenFertig,
    this.healthFelder = const [],
    this.onHealthKnopf,
    this.aboTag,
    this.coachStill = false,
    this.onAbo,
  });

  /// Free week counter, grey coach without Abo (vault Umsetzung/Abo.md).
  final int? aboTag;
  final bool coachStill;
  final VoidCallback? onAbo;

  /// Opens "Konto und Sicherung" from the small button top right.
  final VoidCallback? onKonto;

  /// Measured values that fall into the coach card once today, and the
  /// fields under it (vault Umsetzung/Apple Health.md).
  final List<String> samen;
  final VoidCallback? onSamenFertig;
  final List<HealthFeld> healthFelder;
  final ValueChanged<HealthFeld>? onHealthKnopf;

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

  /// The user's own "Warum" and, on a weak day, the coach's sentence that
  /// shows it under the coach card (see [WarumKarte]).
  final String warum;
  final String? warumSatz;

  /// The newest pattern as a small field ([musterNeu]: found in the last
  /// two days); tapping opens all patterns.
  final Muster? muster;
  final bool musterNeu;
  final VoidCallback onOpenMuster;

  /// The small progress photo field next to the days in a row.
  final Widget fotoFeld;

  /// The areas for the small Fundament card at the end; tapping it opens
  /// the Fundament page.
  final List<WurzelBereich> bereiche;
  final VoidCallback onFundament;

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
    final m = muster;
    return NightScope(
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.only(bottom: 110),
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
                  trailing: onKonto == null && aboTag == null
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (aboTag != null) AboZaehler(tag: aboTag!),
                            if (aboTag != null && onKonto != null)
                              const SizedBox(width: 8),
                            if (onKonto != null)
                              KontoKnopfKlein(
                                initiale: name.isEmpty
                                    ? ''
                                    : name[0].toUpperCase(),
                                onTap: onKonto!,
                              ),
                          ],
                        ),
                ),
                if (c != null) ...[
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _Still(
                        an: coachStill,
                        child: CoachKarte(
                          text: c.kiAntwort.isNotEmpty
                              ? c.kiAntwort
                              : noReplyYet,
                          umschaltbar: c.kiAntwort.isNotEmpty,
                          stichpunkte: c.stichpunkte,
                          ansicht: coachAnsicht,
                          onAnsicht: onCoachAnsicht,
                          onStichpunkte: () => onStichpunkte(c),
                          jubel: jubel,
                          jubelTick: jubelTick,
                        ),
                      ),
                      if (samen.isNotEmpty)
                        Positioned.fill(
                          child: SamenRegen(
                            key: const ValueKey('samen-regen'),
                            samen: samen,
                            onFertig: onSamenFertig,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (aboTag == 6) ...[
                    const MorgenKarte(),
                    const SizedBox(height: 10),
                  ],
                  if (coachStill && onAbo != null) ...[
                    CoachEinschaltenFeld(onTap: onAbo!),
                    const SizedBox(height: 10),
                  ],
                  if (healthFelder.isNotEmpty && onHealthKnopf != null) ...[
                    HealthFelderListe(
                      felder: healthFelder,
                      onKnopf: onHealthKnopf!,
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (warum.trim().isNotEmpty &&
                      (warumSatz ?? '').trim().isNotEmpty) ...[
                    WarumKarte(warum: warum.trim(), satz: warumSatz!.trim()),
                    const SizedBox(height: 10),
                  ],
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
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _TageFeld(
                          streak: streak,
                          woche: lastSevenDays(checkIns, today),
                          jubelTick: jubelTick,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: fotoFeld),
                    ],
                  ),
                ),
                if (m != null) ...[
                  const SizedBox(height: 10),
                  MusterFeld(muster: m, neu: musterNeu, onTap: onOpenMuster),
                ],
                const SizedBox(height: 10),
                // The roots live on their own page now (2026-11-08).
                FundamentVorschau(bereiche: bereiche, onTap: onFundament),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round glass button with the first letter of the name, top right on
/// Heute: opens "Konto und Sicherung".
/// Without Abo the coach card is quiet and grey (vault Umsetzung/Abo.md).
class _Still extends StatelessWidget {
  const _Still({required this.an, required this.child});
  final bool an;
  final Widget child;

  @override
  Widget build(BuildContext context) => an
      ? Opacity(
          key: const ValueKey('coach-still'),
          opacity: .55,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              .33, .59, .11, 0, 0, //
              .33, .59, .11, 0, 0, //
              .33, .59, .11, 0, 0, //
              0, 0, 0, 1, 0,
            ]),
            child: child,
          ),
        )
      : child;
}

class KontoKnopfKlein extends StatelessWidget {
  const KontoKnopfKlein({
    super.key,
    required this.initiale,
    required this.onTap,
  });

  final String initiale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Konto und Sicherung',
    excludeSemantics: true,
    child: GestureDetector(
      key: const ValueKey('konto-oeffnen'),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x26FFE8BE), Color(0x0AE0BF7E)],
          ),
          border: Border.all(color: const Color(0x99E0BF7E)),
        ),
        child: initiale.isEmpty
            ? const Icon(
                Icons.person_outline,
                size: 18,
                color: Color(0xFFE6C98F),
              )
            : Text(
                initiale,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFFE6C98F),
                ),
              ),
      ),
    ),
  );
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              child: const Icon(Icons.spa, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bumps on every cheer.
                  TweenAnimationBuilder<double>(
                    key: ValueKey(jubelTick),
                    tween: Tween(begin: jubelTick > 0 ? 1.3 : 1, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: ShaderMask(
                      shaderCallback: (r) =>
                          CoachStyle.goldGradient.createShader(r),
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
                  const SizedBox(height: 3),
                  Text(
                    streak == 1 ? 'TAG AM STÜCK' : 'TAGE AM STÜCK',
                    maxLines: 2,
                    style: CoachStyle.goldLabel.copyWith(
                      fontFamily: 'Sora',
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: CoachStyle.gold,
                    ),
                  ),
                ],
              ),
            ),
            for (final x in woche)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(left: 3),
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
