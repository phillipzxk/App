import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../konto/konto_ui.dart' show bewegungAn;
import '../ui/coach_style.dart';
import 'glas.dart';

/// Which living picture sits on top of a Körper page (draft "Körper,
/// lebendig", Phillip "ja sehr gut so den Stil beibehalten" 2026-11-07).
enum SzeneArt { training, ernaehrung, schlaf }

/// The data a scene shows.
class SzeneDaten {
  const SzeneDaten({
    this.zeile = '',
    this.mahlzeiten = const [],
    this.jetzt = .5,
    this.mond = .7,
  });

  /// Small line in the scene, e.g. "Heute Push · 5 Übungen".
  final String zeile;

  /// Ernährung: each meal as (position 0..1 over the day, eaten).
  final List<(double, bool)> mahlzeiten;

  /// Ernährung: where "now" is on the day, 0..1.
  final double jetzt;

  /// Schlaf: how full the moon is, 0..1 (the Schlafwert).
  final double mond;
}

/// A living picture instead of the plain ring on top of a Körper page:
/// plates fly onto a barbell, a sun walks along the energy curve, or the
/// moon fills over a night sky. Title, line and the part's value lie on
/// top of it; the value counts up.
class KoerperSzene extends StatefulWidget {
  const KoerperSzene({
    super.key,
    required this.art,
    required this.titel,
    required this.sub,
    required this.wert,
    required this.daten,
    this.onTap,
    this.rahmenKey,
    this.gross = false,
    this.obenFrei = 12,
    this.ueber,
  });

  /// Small line above the title (the area, e.g. "Körper").
  final String? ueber;

  /// Big: fills the whole top of the page, no frame, fades into the page.
  final bool gross;

  /// Room above the title (status bar and back link in big mode).
  final double obenFrei;

  /// Marks the scene, so the Verlauf can grow out of it.
  final GlobalKey? rahmenKey;

  final SzeneArt art;
  final String titel, sub;
  final int? wert;
  final SzeneDaten daten;
  final VoidCallback? onTap;

  @override
  State<KoerperSzene> createState() => _KoerperSzeneState();
}

class _KoerperSzeneState extends State<KoerperSzene>
    with TickerProviderStateMixin {
  /// Plays once when the scene appears.
  late final AnimationController _auf = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  /// Slow endless motion: twinkling stars, a wave on the curve.
  late final AnimationController _leben = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (bewegungAn) _leben.repeat();
  }

  @override
  void didUpdateWidget(KoerperSzene old) {
    super.didUpdateWidget(old);
    if (old.art != widget.art) _auf.forward(from: 0);
  }

  @override
  void dispose() {
    _auf.dispose();
    _leben.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nacht = widget.art == SzeneArt.schlaf;
    final mitte = widget.gross ? .6 : .7;
    return GestureDetector(
      key: const ValueKey('bereich-ring'),
      onTap: widget.onTap,
      child: ClipRRect(
        key: widget.rahmenKey,
        borderRadius: BorderRadius.circular(widget.gross ? 0 : Glas.radius),
        child: Container(
          height: widget.gross ? null : 142,
          decoration: widget.gross
              ? null
              : BoxDecoration(
                  border: Border.all(color: nacht ? Glas.nightEdge : Glas.edge),
                  borderRadius: BorderRadius.circular(Glas.radius),
                ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_auf, _leben]),
                  builder: (context, _) => CustomPaint(
                    painter: switch (widget.art) {
                      SzeneArt.training => _HantelMaler(_auf.value, mitte),
                      SzeneArt.ernaehrung => _KurveMaler(
                        _auf.value,
                        _leben.value,
                        widget.daten,
                        mitte,
                      ),
                      SzeneArt.schlaf => _NachtMaler(
                        _auf.value,
                        _leben.value,
                        widget.daten.mond,
                        mitte,
                      ),
                    },
                  ),
                ),
              ),
              if (widget.gross)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 90,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x000D0A07), CoachStyle.night],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                top: widget.obenFrei,
                right: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.ueber != null)
                      Text(
                        widget.ueber!,
                        style: Glas.tLabel.copyWith(
                          fontSize: 11,
                          letterSpacing: 1.6,
                          color: CoachStyle.goldLight,
                        ),
                      ),
                    Text(
                      widget.titel,
                      style: CoachStyle.title.copyWith(
                        fontSize: widget.gross ? 30 : 26,
                        color: Glas.text,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Text(
                      widget.sub,
                      key: ValueKey('sub-${widget.art.name}'),
                      maxLines: 2,
                      style: Glas.tSoft.copyWith(
                        fontSize: 12,
                        color: CoachStyle.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: widget.gross ? widget.obenFrei - 4 : 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      key: ValueKey('wert-${widget.art.name}'),
                      tween: Tween(begin: 0, end: (widget.wert ?? 0) * 1.0),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => GoldSchrift(
                        widget.wert == null ? '–' : '${v.round()}',
                        style: Glas.tBig.copyWith(
                          fontSize: widget.gross ? 44 : 34,
                        ),
                      ),
                    ),
                    Text('von 10', style: Glas.tSoft.copyWith(fontSize: 10.5)),
                  ],
                ),
              ),
              if (widget.daten.zeile.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: widget.gross ? 54 : 8,
                  child: Text(
                    widget.daten.zeile,
                    textAlign: TextAlign.center,
                    style: Glas.tSoft.copyWith(
                      fontSize: 11,
                      color: nacht ? const Color(0xFFB9C0EE) : Glas.soft,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

double _teil(double v, double von, double bis) =>
    ((v - von) / (bis - von)).clamp(0.0, 1.0);

/// Training: a bar, then the plates fly on from above one after the
/// other and bounce, with a warm light behind.
class _HantelMaler extends CustomPainter {
  _HantelMaler(this.v, this.mitte);
  final double v, mitte;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, .3),
          radius: .9,
          colors: [Color(0xFF3A2B19), Color(0xFF0D0A07)],
        ).createShader(Offset.zero & s),
    );
    final mx = w / 2 + 10, y = h * mitte;
    final bar = w * .52;
    // Shadow and bar.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(mx, y + 26),
        width: bar * 1.05,
        height: 10,
      ),
      Paint()..color = const Color(0x80000000),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(mx, y), width: bar, height: 5),
        const Radius.circular(3),
      ),
      Paint()..color = Glas.soft,
    );
    const platten = [24.0, 20.0, 15.0];
    for (var seite = -1; seite <= 1; seite += 2) {
      for (var i = 0; i < 3; i++) {
        final start = .1 + i * .14 + (seite > 0 ? .06 : 0);
        final t = Curves.elasticOut.transform(_teil(v, start, start + .45));
        if (t <= 0) continue;
        final x = mx + seite * (bar / 2 - 16 - i * 9);
        final r = platten[i];
        final dy = (1 - t) * -90;
        final rect = Rect.fromCenter(
          center: Offset(x, y + dy),
          width: 7,
          height: r * 2,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5DFAE), Color(0xFF9B7536)],
            ).createShader(rect),
        );
      }
    }
    // A short glow once all plates sit.
    final glanz = _teil(v, .75, 1);
    if (glanz > 0 && glanz < 1) {
      c.drawCircle(
        Offset(mx, y),
        bar * .5,
        Paint()
          ..color = Color.fromRGBO(
            224,
            191,
            126,
            .18 * math.sin(glanz * math.pi),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
  }

  @override
  bool shouldRepaint(_HantelMaler old) => old.v != v;
}

/// Ernährung: the energy curve of the day draws itself, the meals drop on
/// as points, a sun walks along to "now".
class _KurveMaler extends CustomPainter {
  _KurveMaler(this.v, this.l, this.d, this.mitte);
  final double v, l, mitte;
  final SzeneDaten d;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E2113), Color(0xFF0D0A07)],
        ).createShader(Offset.zero & s),
    );
    double y(double x) {
      final t = x / w;
      return h * mitte -
          h * .1 * math.sin(t * math.pi * 2.2 + .3) -
          h * .03 * math.sin(t * math.pi * 6 + l * math.pi * 2);
    }

    final pfad = Path()..moveTo(8, y(8));
    for (var x = 8.0; x <= w - 8; x += 3) {
      pfad.lineTo(x, y(x));
    }
    final teil = Curves.easeInOut.transform(_teil(v, 0, .7));
    final metrik = pfad.computeMetrics().first;
    final sichtbar = metrik.extractPath(0, metrik.length * teil);
    c.drawPath(
      sichtbar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0x33E0BF7E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    c.drawPath(
      sichtbar,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF8A6A33), Color(0xFFF5DFAE), Color(0xFF8A6A33)],
        ).createShader(Offset.zero & s),
    );
    // Meals drop onto the curve.
    for (var i = 0; i < d.mahlzeiten.length; i++) {
      final (p, gegessen) = d.mahlzeiten[i];
      final t = Curves.easeOutBack.transform(
        _teil(v, .3 + i * .1, .6 + i * .1),
      );
      if (t <= 0) continue;
      final x = 8 + (w - 16) * p;
      final pos = Offset(x, y(x) - (1 - t) * 30);
      final paint = Paint()..color = Color.fromRGBO(224, 191, 126, t);
      if (gegessen) {
        c.drawCircle(pos, 5.5, paint);
      } else {
        c.drawCircle(
          pos,
          5.5,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }
    // The sun walks along the curve to now.
    final sonne = Curves.easeOutCubic.transform(_teil(v, .35, 1));
    if (sonne > 0) {
      final x = 8 + (w - 16) * d.jetzt.clamp(0, 1) * sonne;
      final pos = Offset(x, y(x));
      c.drawCircle(
        pos,
        16,
        Paint()
          ..color = const Color(0x55E0BF7E)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      c.drawCircle(pos, 8, Paint()..color = const Color(0xFFF5DFAE));
    }
  }

  @override
  bool shouldRepaint(_KurveMaler old) => old.v != v || old.l != l;
}

/// Schlaf: night sky with twinkling stars, a moon that fills up to the
/// sleep score, dark hills.
class _NachtMaler extends CustomPainter {
  _NachtMaler(this.v, this.l, this.mond, this.mitte);
  final double v, l, mond, mitte;

  static final _sterne = [
    for (var i = 0; i < 46; i++)
      (
        math.Random(i * 7 + 3).nextDouble(),
        math.Random(i * 13 + 1).nextDouble() * .75,
        .4 + math.Random(i * 5 + 2).nextDouble() * 1.1,
        math.Random(i * 3 + 9).nextDouble(),
      ),
  ];

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1424), Color(0xFF1A1520), Color(0xFF0D0A07)],
          stops: [0, .7, 1],
        ).createShader(Offset.zero & s),
    );
    final ein = _teil(v, 0, .5);
    for (final (x, y, r, p) in _sterne) {
      final a = ein * (.35 + .65 * (.5 + .5 * math.sin((l + p) * math.pi * 2)));
      c.drawCircle(
        Offset(x * w, y * h),
        r,
        Paint()..color = Color.fromRGBO(245, 230, 196, a),
      );
    }
    // The moon, its shadow slides away up to the sleep score.
    final m = Offset(w * .6, h * (mitte - .08));
    const r = 21.0;
    c.drawCircle(
      m,
      r * 1.9,
      Paint()
        ..color = const Color(0x22E0BF7E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    final voll = Curves.easeOutCubic.transform(_teil(v, .1, 1)) * mond;
    c.saveLayer(Rect.fromCircle(center: m, radius: r + 2), Paint());
    c.drawCircle(
      m,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF4DC), Color(0xFFE0BF7E)],
        ).createShader(Rect.fromCircle(center: m, radius: r)),
    );
    c.drawCircle(
      m.translate(-r * .4 + r * 2.4 * voll, -r * .15),
      r,
      Paint()..blendMode = BlendMode.dstOut,
    );
    c.restore();
    // Hills.
    final huegel = Path()
      ..moveTo(0, h * .9)
      ..quadraticBezierTo(w * .25, h * .76, w * .5, h * .86)
      ..quadraticBezierTo(w * .78, h * .95, w, h * .82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(huegel, Paint()..color = const Color(0xFF0B0907));
  }

  @override
  bool shouldRepaint(_NachtMaler old) =>
      old.v != v || old.l != l || old.mond != mond;
}
