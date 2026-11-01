import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../schlaf/schlaf_logik.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import 'health_daten.dart';

/// "Deine Nacht als Wurzel" (vault Umsetzung/Apple Health.md, Entwurf 2):
/// the ground line is the night from falling asleep (left) to waking up
/// (right). The gold root grows as deep as the sleep was: REM near the
/// top, core in the middle, deep sleep at the bottom. Where the user was
/// awake, a small sprout shoots above the ground.
class NachtWurzel extends StatefulWidget {
  const NachtWurzel({super.key, required this.nacht, this.hoehe = 200});

  final HealthNacht nacht;
  final double hoehe;

  @override
  State<NachtWurzel> createState() => _NachtWurzelState();
}

class _NachtWurzelState extends State<NachtWurzel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('nacht-wurzel'),
    height: widget.hoehe,
    child: AnimatedBuilder(
      animation: _a,
      builder: (context, _) => CustomPaint(
        painter: NachtMaler(widget.nacht, Curves.easeInOut.transform(_a.value)),
        size: Size.infinite,
      ),
    ),
  );
}

/// How deep each phase goes, as a share of the soil height.
double _tiefe(PhaseArt a, bool mitPhasen) => !mitPhasen
    ? .5
    : switch (a) {
        PhaseArt.wach => 0,
        PhaseArt.rem => .22,
        PhaseArt.kern => .52,
        PhaseArt.tief => .9,
      };

class NachtMaler extends CustomPainter {
  NachtMaler(this.nacht, this.t);

  final HealthNacht nacht;

  /// 0..1 how far the root has grown.
  final double t;

  static const _oben = 30.0;
  static const _rechts = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final boden = _oben;
    final unten = size.height - 6;
    final breite = size.width - _rechts;
    final start = nacht.start;
    final dauer = math.max(1, nacht.ende.difference(start).inMinutes);
    double x(DateTime d) =>
        4 + (breite - 8) * d.difference(start).inMinutes / dauer;
    double y(PhaseArt a) =>
        boden + 8 + (unten - boden - 8) * _tiefe(a, nacht.mitPhasen);

    // Soil.
    canvas.drawRect(
      Rect.fromLTRB(0, boden, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, boden),
          Offset(0, size.height),
          const [Color(0x332A1F15), Color(0xCC1A130C)],
        ),
    );
    canvas.drawLine(
      Offset(0, boden),
      Offset(size.width, boden),
      Paint()
        ..color = const Color(0x8CD9C7A7)
        ..strokeWidth = 1,
    );
    _text(canvas, _uhr(nacht.start), Offset(4, 6), CoachStyle.beigeLabel);
    _text(
      canvas,
      _uhr(nacht.ende),
      Offset(breite - 4, 6),
      CoachStyle.beigeLabel,
      rechts: true,
    );
    if (nacht.mitPhasen) {
      for (final (a, name, farbe) in const [
        (PhaseArt.rem, 'REM', Color(0xFF8F7AC8)),
        (PhaseArt.kern, 'Kern', Color(0xFF7D93D6)),
        (PhaseArt.tief, 'Tief', Color(0xFF9FB2FF)),
      ]) {
        _text(
          canvas,
          name,
          Offset(size.width - 2, y(a) - 6),
          farbe,
          rechts: true,
          klein: true,
        );
      }
    }

    // The root: through the middle of each sleep phase.
    final punkte = <Offset>[Offset(x(start), boden)];
    for (final p in nacht.phasen) {
      final mitte = p.von.add(Duration(minutes: p.minuten ~/ 2));
      punkte.add(
        Offset(x(mitte), p.art == PhaseArt.wach ? boden + 4 : y(p.art)),
      );
    }
    punkte.add(Offset(x(nacht.ende), boden));
    final pfad = Path()..moveTo(punkte.first.dx, punkte.first.dy);
    for (var i = 1; i < punkte.length; i++) {
      final a = punkte[i - 1], b = punkte[i];
      final mx = (a.dx + b.dx) / 2;
      pfad.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final teil = Path();
    for (final m in pfad.computeMetrics()) {
      teil.addPath(m.extractPath(0, m.length * t), Offset.zero);
    }
    final gold = ui.Gradient.linear(Offset(0, boden), Offset(0, unten), const [
      Color(0xFFF3D79A),
      Color(0xFFB9862F),
    ]);
    canvas.drawPath(
      teil,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x40F3D79A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      teil,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = gold,
    );

    // Sprouts where the user was awake, once the root got there.
    final bis = start.add(Duration(minutes: (dauer * t).round()));
    for (final p in nacht.phasen) {
      if (p.art != PhaseArt.wach || p.von.isAfter(bis)) continue;
      final sx = x(p.von.add(Duration(minutes: p.minuten ~/ 2)));
      final s = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF3D79A);
      canvas.drawPath(
        Path()
          ..moveTo(sx, boden)
          ..quadraticBezierTo(sx - 1, boden - 10, sx - 7, boden - 14)
          ..moveTo(sx, boden)
          ..quadraticBezierTo(sx + 1, boden - 12, sx + 8, boden - 15),
        s,
      );
      // No word where it would cover the times at both ends.
      if (sx < 44 || sx > breite - 44) continue;
      _text(
        canvas,
        'wach',
        Offset(sx, boden - 28),
        CoachStyle.goldLight,
        mitte: true,
        klein: true,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset o,
    Color farbe, {
    bool rechts = false,
    bool mitte = false,
    bool klein = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Figtree',
          fontSize: klein ? 9.5 : 10.5,
          color: farbe,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = rechts
        ? o.dx - tp.width
        : mitte
        ? o.dx - tp.width / 2
        : o.dx;
    tp.paint(canvas, Offset(dx, o.dy));
  }

  @override
  bool shouldRepaint(NachtMaler old) => old.t != t || old.nacht != nacht;
}

String _uhr(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

/// The card on the Schlaf & Energie page: last night as measured.
class NachtKarte extends StatelessWidget {
  const NachtKarte({super.key, required this.nacht});

  final HealthNacht nacht;

  @override
  Widget build(BuildContext context) => TKarte(
    key: const ValueKey('nacht-karte'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: TLabel('Deine Nacht als Wurzel')),
            Icon(Icons.favorite, size: 14, color: Color(0xFFFF2D55)),
            SizedBox(width: 4),
            Text('Apple Health', style: tSoft),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${formatDauer(nacht.stunden)} geschlafen, '
          '${nacht.wachMal == 0 ? 'durchgeschlafen' : '${nacht.wachMal} Mal kurz wach'}.',
          style: tText,
        ),
        const SizedBox(height: 8),
        NachtWurzel(nacht: nacht),
        const SizedBox(height: 6),
        Text(
          nacht.mitPhasen
              ? 'Je tiefer die Wurzel, desto tiefer hast du geschlafen.'
              : 'Ohne Uhr misst das iPhone nur, wann du geschlafen hast, '
                    'nicht wie tief.',
          style: tSoft,
        ),
      ],
    ),
  );
}
