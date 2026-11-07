import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import 'glas.dart';

/// Small living pictures inside the Körper tiles (draft "Körper,
/// lebendig", idea 4). Each plays once when the tile appears.

/// Plays [bau] from 0 to 1 once.
class _Einmal extends StatelessWidget {
  const _Einmal({required this.ms, required this.bau});
  final int ms;
  final Widget Function(double v) bau;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: ms),
    builder: (context, v, _) => bau(v),
  );
}

double _teil(double v, double von, double bis) =>
    ((v - von) / (bis - von)).clamp(0.0, 1.0);

/// Today's exercises as small fields; done ones fill gold one after the
/// other.
class SatzReihe extends StatelessWidget {
  const SatzReihe({super.key, required this.fertig});

  /// One entry per exercise of today: done or not.
  final List<bool> fertig;

  @override
  Widget build(BuildContext context) {
    final n = math.min(fertig.length, 7);
    return _Einmal(
      ms: 700 + 120 * n,
      bau: (v) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Builder(
              builder: (_) {
                final t = Curves.easeOutBack.transform(
                  _teil(v, i * .1, i * .1 + .45),
                );
                final an = fertig[i];
                return Transform.scale(
                  scale: .4 + .6 * t,
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Container(
                      width: 26,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: an ? CoachStyle.goldGradient : null,
                        border: an
                            ? null
                            : Border.all(color: const Color(0x40D9C7A7)),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: Glas.tLabel.copyWith(
                          fontFamily: 'Sora',
                          fontSize: 11,
                          color: an ? CoachStyle.goldInk : Glas.soft,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// An empty barbell waiting for its plates (no plan yet).
class HantelBild extends StatelessWidget {
  const HantelBild({super.key, this.platten = 3});
  final int platten;

  @override
  Widget build(BuildContext context) => _Einmal(
    ms: 1300,
    bau: (v) => CustomPaint(
      size: const Size(150, 64),
      painter: _HantelKlein(v, platten),
    ),
  );
}

class _HantelKlein extends CustomPainter {
  _HantelKlein(this.v, this.n);
  final double v;
  final int n;

  @override
  void paint(Canvas c, Size s) {
    final y = s.height * .55;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, y - 2, s.width - 8, 4),
        const Radius.circular(2),
      ),
      Paint()..color = Glas.soft,
    );
    for (var seite = -1; seite <= 1; seite += 2) {
      for (var i = 0; i < n; i++) {
        final start = .1 + i * .15 + (seite > 0 ? .07 : 0);
        final t = Curves.elasticOut.transform(_teil(v, start, start + .5));
        if (t <= 0) continue;
        final x = s.width / 2 + seite * (s.width / 2 - 18 - i * 8);
        final r = 20.0 - i * 4;
        final rect = Rect.fromCenter(
          center: Offset(x, y - (1 - t) * 50),
          width: 6,
          height: r * 2,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5DFAE), Color(0xFF9B7536)],
            ).createShader(rect),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HantelKlein old) => old.v != v;
}

/// The last nights as bars that grow up; short nights are darker.
class NachtBalken extends StatelessWidget {
  const NachtBalken({super.key, required this.stunden});
  final List<double> stunden;

  @override
  Widget build(BuildContext context) => _Einmal(
    ms: 1300,
    bau: (v) => CustomPaint(
      size: const Size(150, 56),
      painter: _BalkenMaler(v, stunden),
    ),
  );
}

class _BalkenMaler extends CustomPainter {
  _BalkenMaler(this.v, this.h);
  final double v;
  final List<double> h;

  @override
  void paint(Canvas c, Size s) {
    if (h.isEmpty) return;
    const gap = 5.0;
    final bw = (s.width - gap * (h.length - 1)) / h.length;
    for (var i = 0; i < h.length; i++) {
      final t = Curves.easeOutBack.transform(_teil(v, i * .08, i * .08 + .5));
      final hoehe = (h[i] / 9).clamp(.1, 1.0) * s.height * t;
      final r = Rect.fromLTWH(i * (bw + gap), s.height - hoehe, bw, hoehe);
      final kurz = h[i] < 6.5;
      c.drawRRect(
        RRect.fromRectAndCorners(
          r,
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
          bottomLeft: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: kurz
                ? const [Color(0xFF7C6A55), Color(0xFF2A2017)]
                : const [Color(0xFFE9CC8E), Color(0xFF3A2C1D)],
          ).createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(_BalkenMaler old) => old.v != v;
}

/// Today's meals on a small energy curve that draws itself.
class MiniKurve extends StatelessWidget {
  const MiniKurve({super.key, required this.mahlzeiten, required this.jetzt});

  /// Each meal as (position 0..1 over the day, eaten).
  final List<(double, bool)> mahlzeiten;
  final double jetzt;

  @override
  Widget build(BuildContext context) => _Einmal(
    ms: 1500,
    bau: (v) => CustomPaint(
      size: const Size(170, 60),
      painter: _MiniKurveMaler(v, mahlzeiten, jetzt),
    ),
  );
}

class _MiniKurveMaler extends CustomPainter {
  _MiniKurveMaler(this.v, this.m, this.jetzt);
  final double v, jetzt;
  final List<(double, bool)> m;

  @override
  void paint(Canvas c, Size s) {
    double y(double x) =>
        s.height * .55 - s.height * .28 * math.sin(x / s.width * math.pi * 2.2);
    final pfad = Path()..moveTo(0, y(0));
    for (var x = 2.0; x <= s.width; x += 2) {
      pfad.lineTo(x, y(x));
    }
    final metrik = pfad.computeMetrics().first;
    c.drawPath(
      metrik.extractPath(0, metrik.length * _teil(v, 0, .6)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF8A6A33), Color(0xFFF5DFAE), Color(0xFF8A6A33)],
        ).createShader(Offset.zero & s),
    );
    for (var i = 0; i < m.length; i++) {
      final (p, gegessen) = m[i];
      final t = Curves.easeOutBack.transform(
        _teil(v, .3 + i * .1, .6 + i * .1),
      );
      if (t <= 0) continue;
      final x = p * s.width;
      final pos = Offset(x, y(x) - (1 - t) * 20);
      final paint = Paint()..color = Color.fromRGBO(224, 191, 126, t);
      if (gegessen) {
        c.drawCircle(pos, 4.5, paint);
      } else {
        c.drawCircle(
          pos,
          4.5,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
    final sonne = _teil(v, .5, 1);
    if (sonne > 0) {
      final x = jetzt.clamp(0.0, 1.0) * s.width * sonne;
      c.drawCircle(
        Offset(x, y(x)),
        9,
        Paint()
          ..color = const Color(0x55E0BF7E)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      c.drawCircle(
        Offset(x, y(x)),
        5,
        Paint()..color = const Color(0xFFF5DFAE),
      );
    }
  }

  @override
  bool shouldRepaint(_MiniKurveMaler old) => old.v != v;
}

/// Seven days as dots that pop in; done days are gold.
class WochenPunkte extends StatelessWidget {
  const WochenPunkte(this.tage, {super.key});
  final List<bool?> tage;

  @override
  Widget build(BuildContext context) => _Einmal(
    ms: 1200,
    bau: (v) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tage.length; i++)
          Transform.scale(
            scale: Curves.elasticOut.transform(
              _teil(v, i * .08, i * .08 + .55),
            ),
            child: Container(
              width: 13,
              height: 13,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: tage[i] == true ? CoachStyle.goldGradient : null,
                color: tage[i] == true ? null : const Color(0x1FFFECC8),
                border: tage[i] == false
                    ? Border.all(color: CoachStyle.goldLight, width: 1.2)
                    : null,
                boxShadow: tage[i] == true
                    ? const [BoxShadow(color: Color(0x66E0BF7E), blurRadius: 8)]
                    : null,
              ),
            ),
          ),
      ],
    ),
  );
}
