import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';

/// Area scores from the coach (see vault Umsetzung/Bereichs-Werte.md):
/// 1..10 per check-in, 10 = läuft super, energy counts to sleep.

/// Gives the area pages the check-ins without passing them through every
/// constructor.
class WerteScope extends InheritedWidget {
  const WerteScope({
    super.key,
    required this.checkIns,
    required this.today,
    required super.child,
  });

  final List<CheckIn> checkIns;
  final DateTime today;

  static WerteScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WerteScope>();

  @override
  bool updateShouldNotify(WerteScope old) =>
      old.checkIns != checkIns || old.today != today;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The scores of the last [days] days, oldest first, null for days
/// without a rated check-in.
List<int?> werteVerlauf(
  List<CheckIn> checkIns,
  Bereich bereich,
  DateTime today,
  int days,
) {
  final byDay = {for (final c in checkIns) dayKey(c.datum): c};
  final end = _day(today);
  return [
    for (var i = days - 1; i >= 0; i--)
      byDay[dayKey(DateTime(end.year, end.month, end.day - i))]?.werte[bereich
          .name],
  ];
}

/// The value of Produktivität, Business or Persönlichkeit for a day
/// (Phillip 2026-10-31): the coach's rating of the check-in answer and the
/// value from what was done on the page, averaged when both exist.
int? mitCheckIn(int? aktion, List<CheckIn> checkIns, String key, DateTime tag) {
  final k = dayKey(tag);
  int? c;
  for (final x in checkIns) {
    if (dayKey(x.datum) == k) c = x.werte[key];
  }
  if (aktion == null) return c;
  if (c == null) return aktion;
  return ((aktion + c) / 2).round();
}

/// The latest rated check-in for [bereich], or null.
CheckIn? letzteBewertung(List<CheckIn> checkIns, Bereich bereich) {
  CheckIn? best;
  for (final c in checkIns) {
    if (c.werte[bereich.name] == null) continue;
    if (best == null || c.datum.isAfter(best.datum)) best = c;
  }
  return best;
}

/// Today's score, the change to the day before and seven small bars.
/// Used inside the cream area tile on "Heute".
class TileWerte extends StatelessWidget {
  const TileWerte({
    super.key,
    required this.bereich,
    required this.checkIns,
    required this.today,
  });

  final Bereich bereich;
  final List<CheckIn> checkIns;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final week = werteVerlauf(checkIns, bereich, today, 7);
    final heute = week.last;
    final gestern = week[5];
    final diff = heute != null && gestern != null ? heute - gestern : null;
    final (pfeil, farbe) = switch (diff) {
      null => ('', CoachStyle.creamInkSoft),
      0 => ('–', CoachStyle.creamInkSoft),
      > 0 => ('▲ $diff', const Color(0xFF7A5A2C)),
      _ => ('▼ ${-diff}', const Color(0xFF8A4A32)),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text.rich(
              key: ValueKey('wert-${bereich.name}'),
              TextSpan(
                children: [
                  TextSpan(
                    text: heute?.toString() ?? '–',
                    style: CoachStyle.title.copyWith(
                      fontSize: 26,
                      height: 1,
                      color: CoachStyle.goldInk,
                    ),
                  ),
                  if (heute != null)
                    TextSpan(
                      text: ' /10',
                      style: CoachStyle.body.copyWith(
                        fontSize: 12,
                        color: CoachStyle.creamInkSoft,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              pfeil,
              style: CoachStyle.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: farbe,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Container(
                    height: week[i] == null ? 3 : 4 + week[i]! * 2.0,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i == 6 && week[i] != null
                          ? null
                          : const Color(0x381A140E),
                      gradient: i == 6 && week[i] != null
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF8A6330), Color(0xFF5A4128)],
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Dein Verlauf · 30 Tage" on an area page: today's score, the 30-day
/// average (dashed), a line over 30 days and the coach's reason.
class AreaChart extends StatelessWidget {
  const AreaChart({super.key, required this.bereich});

  final Bereich bereich;

  @override
  Widget build(BuildContext context) {
    final scope = WerteScope.of(context);
    final checkIns = scope?.checkIns ?? const <CheckIn>[];
    final today = scope?.today ?? DateTime.now();
    final verlauf = werteVerlauf(checkIns, bereich, today, 30);
    final da = [for (final v in verlauf) ?v];
    final avg = da.isEmpty ? null : da.reduce((a, b) => a + b) / da.length;
    final letzte = letzteBewertung(checkIns, bereich);
    final heute = verlauf.last;
    final grund = letzte?.gruende[bereich.name] ?? '';

    return Container(
      key: ValueKey('verlauf-${bereich.name}'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CoachStyle.nightShadow,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2118), Color(0xFF1B1611)],
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DEIN VERLAUF · 30 TAGE',
              style: CoachStyle.goldLabel.copyWith(color: CoachStyle.goldLight),
            ),
            const SizedBox(height: 10),
            if (da.isEmpty)
              Text(
                'Nach deinem ersten Check-in bewertet der Coach jeden Tag '
                'diesen Bereich von 1 bis 10.',
                style: CoachStyle.body.copyWith(color: CoachStyle.creamSoft),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: heute?.toString() ?? '–',
                          style: CoachStyle.title.copyWith(
                            fontSize: 32,
                            height: 1,
                            color: const Color(0xFFF5DFAE),
                          ),
                        ),
                        TextSpan(
                          text: heute == null ? ' heute' : ' /10 heute',
                          style: CoachStyle.body.copyWith(
                            fontSize: 13,
                            color: CoachStyle.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Ø 30 Tage '),
                          TextSpan(
                            text: avg!.toStringAsFixed(1).replaceAll('.', ','),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: CoachStyle.beige,
                            ),
                          ),
                        ],
                      ),
                      style: CoachStyle.body.copyWith(
                        fontSize: 12.5,
                        color: CoachStyle.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: CustomPaint(
                  painter: _LinePainter(verlauf, avg),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('vor 30 Tagen', style: _axis),
                  const Spacer(),
                  Text('heute', style: _axis),
                ],
              ),
              if (grund.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(height: 1, color: CoachStyle.line),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CoachAvatar(size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WARUM GERADE HIER',
                            style: CoachStyle.goldLabel.copyWith(
                              fontSize: 10,
                              color: CoachStyle.gold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            grund,
                            key: ValueKey('grund-${bereich.name}'),
                            style: CoachStyle.body.copyWith(
                              fontSize: 14,
                              color: CoachStyle.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static final _axis = CoachStyle.body.copyWith(
    fontSize: 11,
    color: CoachStyle.nightMuted,
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.werte, this.avg);

  final List<int?> werte;
  final double? avg;

  @override
  void paint(Canvas canvas, Size size) {
    final n = werte.length;
    double x(int i) => i * size.width / (n - 1);
    double y(num v) => size.height - 6 - (v - 1) / 9 * (size.height - 12);

    if (avg != null) {
      final dash = Paint()
        ..color = CoachStyle.beigeLabel.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      final ay = y(avg!);
      for (var px = 0.0; px < size.width; px += 7) {
        canvas.drawLine(Offset(px, ay), Offset(px + 3, ay), dash);
      }
    }

    // Line through the rated days; gaps are bridged.
    final pts = [
      for (var i = 0; i < n; i++)
        if (werte[i] != null) Offset(x(i), y(werte[i]!)),
    ];
    if (pts.isEmpty) return;
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x59D4A85E), Color(0x00D4A85E)],
        ).createShader(rect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF9A6D35), Color(0xFFF5DFAE)],
        ).createShader(rect),
    );
    for (final p in pts.length == 1 ? pts : [pts.last]) {
      canvas.drawCircle(p, 5, Paint()..color = const Color(0xFFF5DFAE));
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = CoachStyle.goldInk,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.werte != werte || old.avg != avg;
}
