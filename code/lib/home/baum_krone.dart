import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';

/// Heute as one big tree (decided with Phillip 2026-10-25, vault
/// Umsetzung/Home-Schichten.md): the crown is made of four round fields,
/// Coach, Heute dran, Fokus and Tage am Stück. A bark trunk carries them,
/// branches grow into each field and sap light runs up into them. Extras
/// that are only due on some days hang on the tree as a golden fruit.
/// The roots with the four areas are drawn below by [Wurzelwerk].

/// A golden fruit on the tree, e.g. a new pattern.
class Frucht {
  const Frucht({required this.id, required this.label, required this.onTap});

  /// Used for the key `frucht-<id>` (or the given key below).
  final String id;
  final String label;
  final void Function(Offset mitte) onTap;
}

/// Design size; the crown scales to the width.
const _w = 390.0, _h = 420.0;

class _Feld {
  const _Feld(this.x, this.y, this.r, this.ph);
  final double x, y, r, ph;
  Offset get o => Offset(x, y);
}

const _coach = _Feld(195, 96, 86, 0);
const _tag = _Feld(90, 238, 72, 1.7);
const _fokus = _Feld(300, 238, 72, 3.1);
const _tage = _Feld(195, 332, 46, 4.4);
const _fruchtOrte = [Offset(46, 104), Offset(344, 104)];

/// Trunk width at the ground, also used by the roots below.
const stammBreite = 34.0;

class _Q {
  const _Q(this.o, this.w);
  final Offset o;
  final double w;
}

List<_Q> _kurve(
  Offset a,
  Offset c1,
  Offset c2,
  Offset b,
  double w0,
  double w1, {
  int n = 40,
}) {
  return [
    for (var i = 0; i <= n; i++)
      () {
        final t = i / n, u = 1 - t;
        return _Q(
          a * (u * u * u) +
              c1 * (3 * u * u * t) +
              c2 * (3 * u * t * t) +
              b * (t * t * t),
          w0 + (w1 - w0) * t,
        );
      }(),
  ];
}

/// All branches, trunk first. Fixed, so they are built once.
final _stamm = _kurve(
  const Offset(195, _h),
  const Offset(186, 360),
  const Offset(206, 250),
  const Offset(195, 150),
  stammBreite,
  15,
);
final _aeste = <List<_Q>>[
  // Into Heute dran and Fokus.
  _kurve(
    const Offset(192, 352),
    const Offset(160, 330),
    const Offset(120, 300),
    _tag.o,
    15,
    7,
  ),
  _kurve(
    const Offset(198, 342),
    const Offset(232, 322),
    const Offset(272, 296),
    _fokus.o,
    14,
    7,
  ),
  // Up to where the fruits hang.
  _kurve(
    const Offset(193, 262),
    const Offset(150, 230),
    const Offset(110, 150),
    _fruchtOrte[0],
    9,
    2.4,
  ),
  _kurve(
    const Offset(197, 255),
    const Offset(240, 226),
    const Offset(282, 150),
    _fruchtOrte[1],
    9,
    2.4,
  ),
];
final _zweige = <List<_Q>>[
  _kurve(
    const Offset(132, 300),
    const Offset(90, 316),
    const Offset(40, 318),
    const Offset(14, 300),
    5,
    1.2,
  ),
  _kurve(
    const Offset(258, 300),
    const Offset(300, 318),
    const Offset(352, 320),
    const Offset(378, 302),
    5,
    1.2,
  ),
  _kurve(
    const Offset(128, 176),
    const Offset(112, 140),
    const Offset(118, 60),
    const Offset(96, 22),
    4,
    1,
  ),
  _kurve(
    const Offset(262, 172),
    const Offset(280, 136),
    const Offset(272, 60),
    const Offset(296, 22),
    4,
    1,
  ),
  _kurve(
    const Offset(60, 116),
    const Offset(38, 150),
    const Offset(20, 170),
    const Offset(8, 200),
    2.6,
    .8,
  ),
  _kurve(
    const Offset(330, 116),
    const Offset(352, 150),
    const Offset(372, 172),
    const Offset(384, 202),
    2.6,
    .8,
  ),
];

void _strich(
  Canvas c,
  List<_Q> pts,
  double bis,
  double Function(_Q) breite,
  Paint p,
) {
  final n = (pts.length * bis).ceil().clamp(0, pts.length);
  for (var i = 1; i < n; i++) {
    p.strokeWidth = breite(pts[i]);
    c.drawLine(pts[i - 1].o, pts[i].o, p);
  }
}

class _BaumMaler extends CustomPainter {
  _BaumMaler(this.s) : super(repaint: s._puls);
  final _BaumKroneState s;

  @override
  void paint(Canvas canvas, Size size) {
    final t = s._sek;
    final auf = s._aufWert;
    final stammAuf = (auf / .45).clamp(0.0, 1.0);
    final astAuf = ((auf - .25) / .45).clamp(0.0, 1.0);
    final zweigAuf = ((auf - .45) / .4).clamp(0.0, 1.0);

    // Soft light behind the crown.
    canvas.drawCircle(
      const Offset(195, 190),
      230,
      Paint()
        ..shader =
            const RadialGradient(colors: [Color(0x2EF0C878), Color(0x00F0C878)])
                .createShader(
                  Rect.fromCircle(center: const Offset(195, 190), radius: 230),
                ),
    );

    final rund = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    void holz(List<_Q> pts, double bis) {
      _strich(
        canvas,
        pts,
        bis,
        (q) => q.w + 2.4,
        rund..color = const Color(0xFF1A120B),
      );
      _strich(
        canvas,
        pts,
        bis,
        (q) => q.w,
        rund..color = const Color(0xFF7E5A36),
      );
      // Light from the left on the bark.
      _strich(
        canvas,
        [for (final q in pts) _Q(q.o.translate(-q.w * .22, 0), q.w)],
        bis,
        (q) => math.max(.7, q.w * .22),
        rund..color = const Color(0x55EBC994),
      );
    }

    for (final z in _zweige) {
      holz(z, zweigAuf);
    }
    for (final a in _aeste) {
      holz(a, astAuf);
    }
    holz(_stamm, stammAuf);

    // Bark lines along the trunk.
    if (stammAuf > 0) {
      final rinde = Paint()
        ..color = const Color(0x8C3A2817)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      for (var k = -2; k <= 2; k++) {
        final p = Path();
        final n = (_stamm.length * stammAuf).floor();
        for (var i = 0; i < n; i++) {
          final q = _stamm[i];
          final x = q.o.dx + k * q.w * .17 + math.sin(i * .9 + k * 2) * 1.2;
          i == 0 ? p.moveTo(x, q.o.dy) : p.lineTo(x, q.o.dy);
        }
        canvas.drawPath(p, rinde);
      }
    }

    // Sap: light runs up the trunk and out into each field.
    final j = s._jubel.value;
    if (s._lebendig && auf >= 1) {
      final wege = [
        [..._stamm.sublist(0, 30), ..._aeste[0]],
        [..._stamm.sublist(0, 33), ..._aeste[1]],
        _stamm,
        [..._stamm.sublist(0, 25), ..._aeste[2]],
        [..._stamm.sublist(0, 26), ..._aeste[3]],
      ];
      for (var i = 0; i < wege.length; i++) {
        final w = wege[i];
        final ph = ((t / 3.4) + i * .21) % 1;
        final c = (ph * w.length * 1.3).floor();
        final a = math.max(0, c - 10), b = math.min(w.length, c);
        if (b - a > 1) {
          _strich(
            canvas,
            w.sublist(a, b),
            1,
            (q) => q.w * .5 + 1,
            Paint()
              ..color = const Color(0x8CF5D796)
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
          );
        }
      }
    }
    // On a cheer the whole tree lights up from the ground.
    if (j > 0 && j < 1) {
      final f = math.sin(j * math.pi);
      for (final w in [_stamm, ..._aeste, ..._zweige]) {
        _strich(
          canvas,
          w,
          math.min(1, j * 1.8),
          (q) => q.w * .6 + 1,
          Paint()
            ..color = Color.fromRGBO(245, 217, 154, .8 * f)
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // Motes of light drifting up through the crown.
    if (s._lebendig) {
      final m = Paint();
      for (var i = 0; i < 22; i++) {
        final r = math.Random(30 + i);
        final x0 = r.nextDouble() * _w, v = 8 + r.nextDouble() * 14;
        final y = _h - ((t * v + r.nextDouble() * _h) % _h);
        final a = .55 * math.sin(math.pi * y / _h);
        m.color = Color.fromRGBO(240, 207, 138, a);
        canvas.drawCircle(
          Offset(x0 + math.sin(t * .8 + i) * 6, y),
          .6 + r.nextDouble() * 1.3,
          m,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BaumMaler old) => false;
}

/// Sparks over everything, on a cheer.
class _FunkenMaler extends CustomPainter {
  _FunkenMaler(this.s) : super(repaint: s._jubel);
  final _BaumKroneState s;

  @override
  void paint(Canvas canvas, Size size) {
    final f = s._jubel.value;
    if (f <= 0 || f >= 1) return;
    final p = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    for (final (k, wo) in [_fokus.o, _tage.o, _coach.o].indexed) {
      final r = math.Random(7 + k);
      final g = ((f - k * .12) / .8).clamp(0.0, 1.0);
      if (g <= 0 || g >= 1) continue;
      final e = Curves.easeOutCubic.transform(g);
      for (var i = 0; i < 46; i++) {
        final a = r.nextDouble() * math.pi * 2, v = 50 + r.nextDouble() * 120;
        final pos =
            wo +
            Offset(math.cos(a) * v * e, math.sin(a) * v * e - 24 * e) +
            Offset(0, 50 * g * g);
        p.color = Color.fromRGBO(245, 215, 150, (1 - g) * .95);
        canvas.drawCircle(pos, (1 + r.nextDouble() * 2.2) * (1 - g * .6), p);
      }
    }
  }

  @override
  bool shouldRepaint(_FunkenMaler old) => false;
}

/// One round field: dark glass, a gold light running round its rim.
class _ScheibeMaler extends CustomPainter {
  _ScheibeMaler(this.s, this.f, this.glanz) : super(repaint: s._puls);
  final _BaumKroneState s;
  final _Feld f;

  /// Extra glow 0..1 (a cheer, a tap).
  final double Function() glanz;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = f.r;
    final t = s._sek;
    final g = glanz();
    final atem = s._lebendig ? .5 + .5 * math.sin(t * 1.3 + f.ph) : .6;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r + 22,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(240, 200, 120, .16 + .1 * atem + .35 * g),
            const Color(0x00F0C878),
          ],
          stops: [r / (r + 22), 1],
        ).createShader(Rect.fromCircle(center: c, radius: r + 22)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.5),
          radius: 1,
          colors: [Color(0xFF3D2F20), Color(0xFF1B140D), Color(0xFF0F0B07)],
          stops: [0, .6, 1],
        ).createShader(rect),
    );
    // Glass sheen at the top.
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-r * .15, -r * .62),
        width: r * 1.5,
        height: r * .8,
      ),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x1FFFF3D6), Color(0x00FFF3D6)],
            ).createShader(
              Rect.fromCenter(
                center: c.translate(0, -r * .62),
                width: r * 1.5,
                height: r * .8,
              ),
            ),
    );
    canvas.restore();
    canvas.drawCircle(
      c,
      r - 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0x24F0C878),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0x80C9A25C),
    );
    // The light that runs round the rim.
    final dreh = s._lebendig ? t * .55 + f.ph : -math.pi / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 + 1.6 * g
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: GradientRotation(dreh),
          colors: const [
            Color(0x00F5D796),
            Color(0xFFFFE9B5),
            Color(0xFFC9A25C),
            Color(0x00C9A25C),
            Color(0x00C9A25C),
          ],
          stops: const [0, .08, .22, .4, 1],
        ).createShader(rect),
    );
    if (g > 0) {
      canvas.drawCircle(
        c,
        r + 4 + 10 * g,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Color.fromRGBO(245, 215, 150, .6 * (1 - g)),
      );
    }
  }

  @override
  bool shouldRepaint(_ScheibeMaler old) => false;
}

/// A golden fruit hanging from a branch.
class _FruchtMaler extends CustomPainter {
  _FruchtMaler(this.s) : super(repaint: s._puls);
  final _BaumKroneState s;

  @override
  void paint(Canvas canvas, Size size) {
    final t = s._sek;
    final c = Offset(size.width / 2, 22);
    final k = s._lebendig ? (t % 1.8) / 1.8 : 0.0;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      c.translate(0, -12),
      Paint()
        ..color = const Color(0xFF7E5A36)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      c,
      15 + k * 12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Color.fromRGBO(240, 200, 120, .7 * (1 - k)),
    );
    canvas.drawCircle(
      c,
      22,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x66F0C878), Color(0x00F0C878)],
        ).createShader(Rect.fromCircle(center: c, radius: 22)),
    );
    final rect = Rect.fromCircle(center: c, radius: 13);
    canvas.drawCircle(
      c,
      13,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.45),
          colors: [Color(0xFFFFF1C9), Color(0xFFE2B865), Color(0xFF8F6528)],
          stops: [0, .45, 1],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c.translate(-4, -5),
      3,
      Paint()..color = const Color(0xCCFFFBEF),
    );
  }

  @override
  bool shouldRepaint(_FruchtMaler old) => false;
}

class BaumKrone extends StatefulWidget {
  const BaumKrone({
    super.key,
    required this.coach,
    required this.tag,
    required this.fokus,
    required this.streak,
    required this.onCoach,
    required this.onTag,
    required this.onFokus,
    this.fokusKey,
    this.fruechte = const [],
    this.jubelTick = 0,
    this.jubelt = false,
  });

  /// Contents of the three big fields (the home page builds them).
  final Widget coach;
  final Widget tag;
  final Widget fokus;
  final int streak;

  /// Taps on a field get its centre on screen, to open from there.
  final void Function(Offset mitte) onCoach;
  final void Function(Offset mitte) onTag;
  final void Function(Offset mitte) onFokus;
  final Key? fokusKey;
  final List<Frucht> fruechte;
  final int jubelTick;

  /// True while the coach cheers: the coach field glows.
  final bool jubelt;

  @override
  State<BaumKrone> createState() => _BaumKroneState();
}

class _BaumKroneState extends State<BaumKrone> with TickerProviderStateMixin {
  // Ambient motion runs forever, so it is off in widget tests.
  late final bool _lebendig = !WidgetsBinding.instance.runtimeType
      .toString()
      .contains('Test');
  late final _puls = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  late final _auf = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final _jubel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final _tipp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  int _getippt = -1;

  double get _sek => _puls.value * 60;
  double get _aufWert => _lebendig ? _auf.value : 1;

  @override
  void initState() {
    super.initState();
    if (_lebendig) {
      _puls.repeat();
      _auf.forward();
    }
  }

  @override
  void didUpdateWidget(BaumKrone old) {
    super.didUpdateWidget(old);
    if (widget.jubelTick > old.jubelTick) _jubel.forward(from: 0);
  }

  @override
  void dispose() {
    _puls.dispose();
    _auf.dispose();
    _jubel.dispose();
    _tipp.dispose();
    super.dispose();
  }

  Future<void> _tippen(
    int i,
    BuildContext ctx,
    void Function(Offset) cb,
  ) async {
    final box = ctx.findRenderObject() as RenderBox?;
    final mitte = box == null
        ? Offset.zero
        : box.localToGlobal(box.size.center(Offset.zero));
    setState(() => _getippt = i);
    await _tipp.forward(from: 0);
    if (!mounted) return;
    cb(mitte);
    _tipp.value = 0;
    setState(() => _getippt = -1);
  }

  /// 0..1 how far field [i] has bloomed in the opening animation.
  double _bluete(int i) {
    final v = ((_aufWert - .5 - i * .1) / .3).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(v);
  }

  Widget _scheibe(
    int i,
    _Feld f,
    Widget child, {
    Key? key,
    void Function(Offset)? onTap,
    double Function()? glanz,
    String? label,
  }) {
    final innen = Padding(
      padding: EdgeInsets.all(f.r * .16),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(width: f.r * 1.36, child: child),
        ),
      ),
    );
    return Positioned(
      left: f.x - f.r,
      top: f.y - f.r,
      width: f.r * 2,
      height: f.r * 2,
      child: AnimatedBuilder(
        animation: Listenable.merge([_puls, _auf, _tipp]),
        builder: (context, child) {
          final b = _bluete(i);
          final schweben = _lebendig ? math.sin(_sek * .9 + f.ph) * 2.6 : 0.0;
          final druck = _getippt == i
              ? 1 + .07 * math.sin(_tipp.value * math.pi)
              : 1.0;
          return Transform.translate(
            offset: Offset(0, schweben),
            child: Transform.scale(
              scale: (.2 + .8 * b) * druck,
              child: Opacity(opacity: b.clamp(0.0, 1.0), child: child),
            ),
          );
        },
        child: Semantics(
          button: onTap != null,
          label: label,
          child: Builder(
            builder: (ctx) => GestureDetector(
              key: key,
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => _tippen(i, ctx, onTap),
              child: CustomPaint(
                painter: _ScheibeMaler(
                  this,
                  f,
                  () =>
                      (glanz?.call() ?? 0) +
                      (_getippt == i ? math.sin(_tipp.value * math.pi) : 0),
                ),
                child: ClipOval(child: innen),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.streak;
    double jubelGlanz() => _jubel.value > 0 && _jubel.value < 1
        ? math.sin(_jubel.value * math.pi)
        : 0;
    final krone = SizedBox(
      width: _w,
      height: _h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _BaumMaler(this)),
            ),
          ),
          for (final (k, fr) in widget.fruechte.take(2).indexed) _frucht(k, fr),
          _scheibe(
            0,
            _coach,
            widget.coach,
            key: const ValueKey('krone-coach'),
            onTap: widget.onCoach,
            glanz: () => widget.jubelt ? .35 + .65 * jubelGlanz() : 0,
            label: 'Dein Coach',
          ),
          _scheibe(
            1,
            _tag,
            widget.tag,
            key: const ValueKey('dein-tag'),
            onTap: widget.onTag,
            label: 'Heute dran',
          ),
          _scheibe(
            2,
            _fokus,
            widget.fokus,
            key: widget.fokusKey ?? const ValueKey('krone-fokus'),
            onTap: widget.onFokus,
            glanz: jubelGlanz,
            label: 'Fokus der Woche',
          ),
          _scheibe(
            3,
            _tage,
            AnimatedBuilder(
              animation: _jubel,
              builder: (context, child) =>
                  Transform.scale(scale: 1 + .28 * jubelGlanz(), child: child),
              child: Column(
                key: const ValueKey('spross'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (r) =>
                        CoachStyle.goldGradient.createShader(r),
                    child: Text(
                      '$s',
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
                  const SizedBox(height: 3),
                  Text(
                    s == 1 ? 'TAG AM\nSTÜCK' : 'TAGE AM\nSTÜCK',
                    textAlign: TextAlign.center,
                    style: CoachStyle.goldLabel.copyWith(
                      fontFamily: 'Sora',
                      fontSize: 7.5,
                      height: 1.25,
                      letterSpacing: 1,
                      color: CoachStyle.gold,
                    ),
                  ),
                ],
              ),
            ),
            glanz: jubelGlanz,
            label: '$s Tage am Stück',
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _FunkenMaler(this)),
            ),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          width: w,
          height: _h * w / _w,
          child: FittedBox(child: krone),
        );
      },
    );
  }

  Widget _frucht(int k, Frucht fr) {
    final o = _fruchtOrte[k];
    return Positioned(
      left: o.dx - 40,
      top: o.dy - 2,
      width: 80,
      height: 76,
      child: AnimatedBuilder(
        animation: Listenable.merge([_puls, _auf]),
        builder: (context, child) {
          final b = Curves.easeOutBack.transform(
            ((_aufWert - .85) / .15).clamp(0.0, 1.0),
          );
          final pendel = _lebendig ? math.sin(_sek * 1.4 + k) * .07 : 0.0;
          return Transform.rotate(
            angle: pendel,
            alignment: Alignment.topCenter,
            child: Transform.scale(
              scale: b,
              alignment: Alignment.topCenter,
              child: child,
            ),
          );
        },
        child: Builder(
          builder: (ctx) => GestureDetector(
            key: ValueKey(
              fr.id == 'reality' ? 'reality-feld' : 'frucht-${fr.id}',
            ),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final box = ctx.findRenderObject() as RenderBox?;
              fr.onTap(
                box == null
                    ? Offset.zero
                    : box.localToGlobal(Offset(box.size.width / 2, 22)),
              );
            },
            child: Column(
              children: [
                SizedBox(
                  width: 80,
                  height: 44,
                  child: CustomPaint(painter: _FruchtMaler(this)),
                ),
                Text(
                  fr.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: CoachStyle.body.copyWith(
                    fontSize: 10.5,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF0C878),
                    shadows: const [Shadow(blurRadius: 8)],
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
