import '../abo/abo_heute.dart';

import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../checkin/checkin_flow.dart';
import '../health/health_heute.dart';
import '../health/health_logik.dart';
import '../konto/konto_ui.dart' show bewegungAn;
import '../ui/coach_widgets.dart';
import '../ui/umbau.dart';
import '../feed/muster.dart';
import 'coach_karte.dart';
import 'heute_felder.dart';
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
    this.blatt = false,
    this.fundamentKey,
  });

  /// Today's focus is done: the sprout carries one more leaf.
  final bool blatt;

  /// Lets the home page find the Fundament tile (the light flies there).
  final Key? fundamentKey;

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

  /// "Donnerstag, 12. November" as "DO, 12. NOVEMBER".
  String get _kurzDatum {
    final i = date.indexOf(',');
    if (i < 2) return date.toUpperCase();
    return '${date.substring(0, 2)}${date.substring(i)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = _todayCheckIn;
    final streak = checkInStreak(checkIns, today);
    final m = muster;
    final felder = HeuteFelder(
      warum: c == null ? '' : warum.trim(),
      warumSatz: c == null ? '' : (warumSatz ?? '').trim(),
      muster: m,
      musterNeu: musterNeu,
      onOpenMuster: onOpenMuster,
      health: c == null ? const [] : healthFelder,
      onHealthKnopf: onHealthKnopf,
    );
    // The Umbau (vault Umsetzung/Umbau.md, 2026-11-12): calm glass tiles
    // without frames, all on one screen, one light gold tile as eye-catcher.
    return NightScope(
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 120),
        children: [
          Einflug(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _kurzDatum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Umbau.label.copyWith(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      color: Umbau.hell,
                    ),
                  ),
                ),
                if (aboTag != null) AboZaehler(tag: aboTag!),
                if (aboTag != null && onKonto != null)
                  const SizedBox(width: 10),
                if (onKonto != null)
                  KontoKnopfKlein(
                    initiale: name.isEmpty ? '' : name[0].toUpperCase(),
                    onTap: onKonto!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Einflug(
            platz: 1,
            child: Text.rich(
              TextSpan(
                text: name.isEmpty ? 'Heute' : 'Heute, ',
                children: [
                  if (name.isNotEmpty)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GoldMaske(child: Text(name, style: _titel)),
                    ),
                ],
              ),
              style: _titel,
            ),
          ),
          if (c != null) ...[
            const SizedBox(height: 16),
            Einflug(
              platz: 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _Still(
                    an: coachStill,
                    child: CoachKarte(
                      text: c.kiAntwort.isNotEmpty ? c.kiAntwort : noReplyYet,
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
            ),
            if (aboTag == 6) ...[
              const SizedBox(height: 12),
              const MorgenKarte(),
            ],
            if (coachStill && onAbo != null) ...[
              const SizedBox(height: 12),
              CoachEinschaltenFeld(onTap: onAbo!),
            ],
          ],
          const SizedBox(height: 22),
          GlasKachel(
            key: const ValueKey('dein-tag'),
            hell: true,
            platz: 3,
            onTap: onOpenTag,
            child: heuteDran,
          ),
          if (!felder.leer) ...[const SizedBox(height: 12), felder],
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GlasKachel(
                    key: fokusKey ?? const ValueKey('krone-fokus'),
                    platz: 4,
                    onTap: onOpenFokus,
                    child: fokusFeld,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlasKachel(
                    platz: 5,
                    child: _TageFeld(
                      streak: streak,
                      jubelTick: jubelTick,
                      blatt: blatt,
                      foto: fotoFeld,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // The roots live on their own page (2026-11-08).
          FundamentVorschau(
            key: fundamentKey,
            bereiche: bereiche,
            onTap: onFundament,
          ),
        ],
      ),
    );
  }

  static const _titel = TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.15,
    letterSpacing: -.6,
    color: Umbau.text,
  );
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
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x1FFFECD2),
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
                  fontSize: 12,
                  color: Umbau.gold,
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
        color: const Color(0x00000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x17FFF5E6), Color(0x17FFF5E6)],
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

/// Days in a row with the gold sprout, below a hairline the photo.
class _TageFeld extends StatelessWidget {
  const _TageFeld({
    required this.streak,
    required this.jubelTick,
    required this.blatt,
    required this.foto,
  });

  final int streak;
  final int jubelTick;
  final bool blatt;
  final Widget foto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('spross'),
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              streak == 1 ? 'TAG AM STÜCK' : 'TAGE AM STÜCK',
              style: Umbau.label,
            ),
            const SizedBox(height: 6),
            // Bumps on every cheer.
            Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(jubelTick),
                tween: Tween(begin: jubelTick > 0 ? 1.3 : 1, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(
                  scale: v,
                  alignment: Alignment.centerLeft,
                  child: child,
                ),
                child: ZaehlZahl(
                  wert: streak.toDouble(),
                  style: Umbau.zahl,
                  textKey: const ValueKey('spross-tage'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Umbau.linie),
            const SizedBox(height: 9),
            foto,
          ],
        ),
        Positioned(
          right: -6,
          top: -4,
          width: 46,
          height: 60,
          child: IgnorePointer(child: _Spross(blatt: blatt)),
        ),
      ],
    );
  }
}

/// The small gold sprout: the stem draws itself, two leaves spring out,
/// a third one grows once today's focus is done.
class _Spross extends StatelessWidget {
  const _Spross({required this.blatt});
  final bool blatt;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: bewegungAn ? 0 : 1, end: 1),
    duration: const Duration(milliseconds: 2400),
    builder: (context, v, _) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: blatt ? 1 : 0),
      duration: Duration(milliseconds: bewegungAn ? 700 : 0),
      curve: Curves.easeOutBack,
      builder: (context, n, _) => CustomPaint(painter: _SprossMaler(v, n)),
    ),
  );
}

class _SprossMaler extends CustomPainter {
  _SprossMaler(this.v, this.neu);
  final double v, neu;

  static const _farbe = Color(0xFFF0D79E);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 46, size.height / 60);
    double teil(double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);
    final stiel = Path()
      ..moveTo(23, 60)
      ..cubicTo(23, 44, 21, 34, 23, 18);
    final m = stiel.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * Curves.easeOut.transform(teil(.25, .75))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = _farbe,
    );
    void blatt(Path p, Offset fuss, double g) {
      if (g <= 0) return;
      canvas
        ..save()
        ..translate(fuss.dx, fuss.dy)
        ..scale(g)
        ..translate(-fuss.dx, -fuss.dy)
        ..drawPath(p, Paint()..color = _farbe)
        ..restore();
    }

    blatt(
      Path()
        ..moveTo(23, 40)
        ..cubicTo(34, 40, 40, 32, 40, 24)
        ..cubicTo(30, 24, 23, 30, 23, 40)
        ..close(),
      const Offset(23, 40),
      Curves.easeOutBack.transform(teil(.55, .85)),
    );
    blatt(
      Path()
        ..moveTo(22, 30)
        ..cubicTo(12, 30, 6, 23, 6, 15)
        ..cubicTo(15, 15, 22, 21, 22, 30)
        ..close(),
      const Offset(22, 30),
      Curves.easeOutBack.transform(teil(.65, .95)),
    );
    blatt(
      Path()
        ..moveTo(23, 19)
        ..cubicTo(32, 17, 36, 9, 34, 2)
        ..cubicTo(26, 4, 22, 11, 23, 19)
        ..close(),
      const Offset(23, 19),
      v < 1 ? 0 : neu,
    );
  }

  @override
  bool shouldRepaint(_SprossMaler old) => old.v != v || old.neu != neu;
}
