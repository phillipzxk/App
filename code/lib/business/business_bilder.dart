import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../ui/coach_style.dart';
import 'business_data.dart';

/// A sprout that grows one leaf per bold ask done (Mutige Anfrage).
class Spross extends StatelessWidget {
  const Spross({super.key, required this.n, this.size = 90});
  final int n;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * .9,
    height: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: n.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => CustomPaint(painter: _SprossMaler(t)),
    ),
  );
}

class _SprossMaler extends CustomPainter {
  _SprossMaler(this.n);
  final double n;

  @override
  void paint(Canvas c, Size s) {
    final x = s.width / 2;
    final blaetter = math.min(n, 8.0);
    final top = s.height * (.85 - .1 * math.min(blaetter, 7));
    final stiel = Path()
      ..moveTo(x, s.height)
      ..cubicTo(x - 2, s.height * .7, x + 2, s.height * .45, x, top);
    c.drawPath(
      stiel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = CoachStyle.goldLight,
    );
    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF5DFAE), Color(0xFFB8894A)],
      ).createShader(Offset.zero & s);
    for (var k = 0; k < blaetter.ceil(); k++) {
      final g = (blaetter - k).clamp(0, 1).toDouble();
      final y = s.height * (.8 - .1 * k);
      final r = k.isEven ? -1.0 : 1.0;
      final l = s.width * .3 * g;
      final p = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + r * l * .6, y - l * .55, x + r * l, y - l * .2)
        ..quadraticBezierTo(x + r * l * .5, y + l * .25, x, y)
        ..close();
      c.drawPath(p, fill);
    }
  }

  @override
  bool shouldRepaint(_SprossMaler o) => o.n != n;
}

/// The Business-Baum: a trunk, each milestone a branch with a leaf; the
/// next one a glowing bud.
class BusinessBaum extends StatelessWidget {
  const BusinessBaum({
    super.key,
    required this.meilensteine,
    this.gross = false,
  });
  final List<Punkt> meilensteine;
  final bool gross;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: gross ? 260 : 120,
    width: double.infinity,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) =>
          CustomPaint(painter: _BaumMaler(meilensteine, t, gross)),
    ),
  );
}

class _BaumMaler extends CustomPainter {
  _BaumMaler(this.ms, this.t, this.gross);
  final List<Punkt> ms;
  final double t;
  final bool gross;

  @override
  void paint(Canvas c, Size s) {
    final x = gross ? s.width / 2 : s.width * .62;
    final unten = s.height - 6;
    final n = math.max(ms.length, 3);
    final oben = s.height * .08;
    c.drawLine(
      Offset(x - 40, unten),
      Offset(x + 40, unten),
      Paint()
        ..color = const Color(0x40FFEECD)
        ..strokeWidth = 1,
    );
    final stamm = Path()
      ..moveTo(x, unten)
      ..cubicTo(x - 2, unten * .8, x + 3, unten * .5, x, oben);
    c.save();
    c.clipRect(
      Rect.fromLTWH(0, unten - (unten - oben) * t - 10, s.width, s.height),
    );
    c.drawPath(
      stamm,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = gross ? 5 : 3.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFC9A25C),
    );
    c.restore();
    final naechster = ms.indexWhere((m) => !m.an);
    final weite = gross ? s.width * .26 : s.width * .3;
    for (var k = 0; k < ms.length; k++) {
      final y0 = unten - (unten - oben) * (k + .6) / (n + .2);
      if (t < (k + 1) / (ms.length + 1)) break;
      final r = k.isEven ? -1.0 : 1.0;
      final ende = Offset(x + r * weite, y0 - 22);
      final ast = Path()
        ..moveTo(x, y0)
        ..quadraticBezierTo(x + r * weite / 2, y0 - 16, ende.dx, ende.dy);
      final an = ms[k].an;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = gross ? 2.4 : 2
        ..strokeCap = StrokeCap.round
        ..color = an ? CoachStyle.goldLight : const Color(0x40FFEECD);
      c.drawPath(ast, p);
      if (an) {
        c.save();
        c.translate(ende.dx, ende.dy);
        c.rotate(r < 0 ? .5 : -.5);
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 20, height: 13),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFF5DFAE), Color(0xFFB8894A)],
            ).createShader(const Rect.fromLTWH(-10, -6, 20, 13)),
        );
        c.restore();
      } else if (k == naechster) {
        c.drawCircle(
          ende,
          11,
          Paint()
            ..color = const Color(0x55F5DFAE)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        c.drawCircle(
          ende,
          7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFFF5DFAE),
        );
        c.drawCircle(ende, 3, Paint()..color = const Color(0xFFF5DFAE));
      } else {
        c.drawCircle(ende, 3, Paint()..color = const Color(0x40FFEECD));
      }
      if (gross) {
        final tp = TextPainter(
          text: TextSpan(
            text: ms[k].text,
            style: Glas.tLabel.copyWith(
              fontSize: 12,
              color: an
                  ? Glas.text
                  : k == naechster
                  ? const Color(0xFFF5DFAE)
                  : Glas.soft,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: s.width / 2 - weite - 16);
        tp.paint(
          c,
          Offset(
            r < 0 ? ende.dx - 12 - tp.width : ende.dx + 12,
            ende.dy - tp.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BaumMaler o) => o.t != t || o.ms != ms;
}

/// A thin gold bar 0..1.
class GoldBalken extends StatelessWidget {
  const GoldBalken({super.key, required this.anteil, this.hoehe = 8});
  final double anteil;
  final double hoehe;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: Container(
      height: hoehe,
      color: const Color(0x1AFFECC8),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: anteil.clamp(0, 1)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => FractionallySizedBox(
          widthFactor: t,
          child: Container(
            decoration: const BoxDecoration(gradient: CoachStyle.goldGradient),
          ),
        ),
      ),
    ),
  );
}

/// Seven rungs, the reached ones gold, the next one outlined.
class SkillLeiter extends StatelessWidget {
  const SkillLeiter({super.key, required this.skill});
  final Skill skill;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var k = skill.stufen.length - 1; k >= 0; k--)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: k < skill.erreicht ? CoachStyle.goldGradient : null,
              color: k < skill.erreicht ? null : const Color(0x0DFFECC8),
              border: Border.all(
                color: k == skill.erreicht
                    ? CoachStyle.goldLight
                    : k < skill.erreicht
                    ? Colors.transparent
                    : const Color(0x22FFEECD),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${k + 1}',
                    style: Glas.tLabel.copyWith(
                      color: k < skill.erreicht
                          ? CoachStyle.goldInk
                          : Glas.label,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    skill.stufen[k].titel,
                    style: Glas.tText.copyWith(
                      fontSize: 14,
                      color: k < skill.erreicht
                          ? CoachStyle.goldInk
                          : k == skill.erreicht
                          ? Glas.text
                          : Glas.soft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

/// Seven short strokes, the first [n] gold.
class Striche extends StatelessWidget {
  const Striche({super.key, required this.n, this.von = 7});
  final int n;
  final int von;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < von; i++)
        Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: i < n ? CoachStyle.goldGradient : null,
              color: i < n ? null : const Color(0x1FFFECC8),
            ),
          ),
        ),
    ],
  );
}

/// The big gold tick over the whole screen when a goal is reached.
void grossesHaken(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry e;
  e = OverlayEntry(builder: (_) => _GrossesHaken(onFertig: () => e.remove()));
  overlay.insert(e);
}

class _GrossesHaken extends StatefulWidget {
  const _GrossesHaken({required this.onFertig});
  final VoidCallback onFertig;

  @override
  State<_GrossesHaken> createState() => _GrossesHakenState();
}

class _GrossesHakenState extends State<_GrossesHaken>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onFertig);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final rein = Curves.easeOutBack.transform((t / .35).clamp(0, 1));
        final raus = t < .75 ? 1.0 : 1 - (t - .75) / .25;
        return Opacity(
          opacity: raus.clamp(0, 1),
          child: Container(
            color: Color.fromRGBO(10, 8, 6, .55 * raus.clamp(0, 1)),
            alignment: Alignment.center,
            child: Transform.scale(
              scale: .4 + .6 * rein,
              child: Container(
                key: const ValueKey('grosses-haken'),
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CoachStyle.goldGradient,
                  boxShadow: CoachStyle.goldGlow,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 130,
                  color: CoachStyle.goldInk,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
