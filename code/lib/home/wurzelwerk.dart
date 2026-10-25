import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../ui/coach_style.dart';

/// "Home-Feed als Wurzelwerk" (vault Umsetzung/Home-Schichten.md, decided
/// with Phillip 2026-10-25): below the gold ground line a drawn root system
/// with a small tree on top. Each area hangs on its own root at a different
/// depth. Tapping one: light runs down its root, sparks fly, then the area
/// opens over the whole screen ([oeffneMitKreis]).

/// What one area node shows.
class WurzelBereich {
  const WurzelBereich({
    required this.bereich,
    required this.name,
    required this.icon,
    this.wert,
    this.diff,
  });

  final Bereich bereich;
  final String name;
  final IconData icon;

  /// Today's score 1..10 from the coach, null before the first rating.
  final int? wert;

  /// Change to the day before, null if unknown.
  final int? diff;
}

/// Where the four areas hang: x as share of the width, y as share of the
/// depth below the ground line. Not in one line on purpose.
const _lagen = [
  Offset(.74, .10),
  Offset(.22, .34),
  Offset(.72, .58),
  Offset(.36, .86),
];

class _Rnd {
  _Rnd(this.s);
  int s;
  double next() {
    s = (s * 16807) % 2147483647;
    return (s - 1) / 2147483646;
  }
}

class _P {
  const _P(this.x, this.y, this.w);
  final double x, y, w;
  Offset get o => Offset(x, y);
}

class _Ast {
  _Ast(this.a, this.b, this.w, this.tiefe, this.ph, this.s);
  final Offset a, b;
  final double w, ph, s;
  final int tiefe;
}

/// Everything that stays put: computed once per size.
class _Geo {
  _Geo(this.size, this.boden, this.ziele, this.haupt, this.picture, this.baum);
  final Size size;
  final double boden;
  final List<Offset> ziele;
  final List<List<_P>> haupt;
  final ui.Picture picture;
  final List<_Ast> baum;
}

_Geo _baue(Size size, double boden, int wurzeln, {double stamm = 0}) {
  final r = _Rnd(11);
  final w = size.width, h = size.height, cx = w * .5;
  final unten = h - boden - 96;
  final ziele = [
    for (final l in _lagen) Offset(l.dx * w, boden + 34 + l.dy * unten),
  ];

  List<_P> pfad(Offset a, Offset b, double w0, double w1, double wob) {
    final pts = <_P>[];
    const n = 46;
    final ph1 = r.next() * 6, ph2 = r.next() * 6;
    final c1 = Offset(a.dx + (b.dx - a.dx) * .08, a.dy + (b.dy - a.dy) * .55);
    final c2 = Offset(a.dx + (b.dx - a.dx) * .7, b.dy - (b.dy - a.dy) * .12);
    var prev = a;
    for (var i = 0; i <= n; i++) {
      final t = i / n, u = 1 - t;
      final p =
          a * (u * u * u) +
          c1 * (3 * u * u * t) +
          c2 * (3 * u * t * t) +
          b * (t * t * t);
      final d = p - prev;
      final l = d.distance == 0 ? 1.0 : d.distance;
      final nrm = Offset(-d.dy / l, d.dx / l);
      final off =
          (math.sin(t * 9 + ph1) * .6 + math.sin(t * 23 + ph2) * .4) *
          wob *
          math.sin(math.pi * t);
      prev = p;
      pts.add(
        _P(
          p.dx + nrm.dx * off,
          p.dy + nrm.dy * off,
          w0 + (w1 - w0) * math.pow(t, .8),
        ),
      );
    }
    return pts;
  }

  final neben = <List<_P>>[];
  void ast(double x, double y, double a, double len, double wd, int tiefe) {
    final pts = <_P>[_P(x, y, wd)];
    final steps = math.max(4, len ~/ 7);
    for (var i = 1; i <= steps; i++) {
      a += (r.next() - .5) * .5 + (math.pi / 2 - a) * .04;
      x += math.cos(a) * len / steps;
      y += math.sin(a) * len / steps;
      final p = _P(x, y, wd * (1 - i / steps * .85));
      pts.add(p);
      if (tiefe > 0 && i > 2 && r.next() < .16) {
        final s = r.next() < .5 ? -1 : 1;
        ast(
          x,
          y,
          a + s * (.5 + r.next() * .7),
          len * (.35 + r.next() * .3),
          p.w * .8,
          tiefe - 1,
        );
      }
    }
    neben.add(pts);
  }

  final haupt = [
    for (final z in ziele)
      pfad(
        Offset(
          cx +
              (stamm > 0 ? (ziele.indexOf(z) - 1.5) * stamm / 5 : 0) +
              (r.next() - .5) * 6,
          stamm > 0 ? boden - 6 : boden,
        ),
        z.translate(0, -26),
        stamm > 0 ? 13 : 10,
        2.6,
        10 + r.next() * 8,
      ),
  ];
  for (final p in haupt) {
    for (var k = 0; k < 4; k++) {
      final i = 8 + (r.next() * 30).floor();
      final a = p[i], b = p[i + 1];
      final dir = math.atan2(b.y - a.y, b.x - a.x);
      final s = r.next() < .5 ? -1 : 1;
      ast(
        a.x,
        a.y,
        dir + s * (.6 + r.next() * .8),
        40 + r.next() * 80,
        a.w * .55,
        2,
      );
    }
  }
  // Roots that lead nowhere, so it reads as a real root ball. They reach
  // deeper with each "Heute geschafft" of the week.
  final tief = .7 + wurzeln.clamp(0, 7) / 7 * .5;
  for (var k = 0; k < 5; k++) {
    ast(
      cx + (r.next() - .5) * 10,
      boden + 4,
      math.pi / 2 + (r.next() - .5) * 2.2,
      (70 + r.next() * 120) * tief,
      5 + r.next() * 3,
      2,
    );
  }

  // Tree above the ground: short trunk that splits, gold leaves at the tips.
  final baum = <_Ast>[];
  void zweig(Offset a, double ang, double len, double wd, int d) {
    final b = a + Offset(math.cos(ang) * len, math.sin(ang) * len);
    baum.add(_Ast(a, b, wd, d, r.next() * 6, .6 + r.next() * .4));
    if (d == 0) return;
    final n = d > 2 ? 2 : 2 + (r.next() < .4 ? 1 : 0);
    for (var i = 0; i < n; i++) {
      zweig(
        b,
        ang + (i - (n - 1) / 2) * (.55 + r.next() * .3) + (r.next() - .5) * .2,
        len * (.68 + r.next() * .12),
        wd * .66,
        d - 1,
      );
    }
  }

  // With the big tree above (BaumKrone), only its trunk foot shows here.
  if (stamm == 0) zweig(Offset(cx, boden), -math.pi / 2, 28, 6.5, 4);

  // Draw soil and roots once.
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final erde = Rect.fromLTRB(0, boden, w, h);
  c.drawRect(
    erde,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A1F15), Color(0xFF1F170F), Color(0xF2120D09)],
        stops: [0, .4, 1],
      ).createShader(erde),
  );
  for (var b = 0; b < 6; b++) {
    final y = boden + 40 + b * (h - boden) / 6 + r.next() * 20;
    final path = Path()..moveTo(0, y);
    for (double x = 0; x <= w; x += 20) {
      path.lineTo(x, y + math.sin(x / 60 + b) * 6 + r.next() * 3);
    }
    path
      ..lineTo(w, y + 30)
      ..lineTo(0, y + 30)
      ..close();
    c.drawPath(path, Paint()..color = Color.fromARGB(30, 60 + b * 4, 44, 28));
  }
  final speck = Paint();
  for (var i = 0; i < w * (h - boden) / 260; i++) {
    speck.color = Color.fromARGB(
      (13 + r.next() * 30).round(),
      (150 + r.next() * 80).round(),
      (110 + r.next() * 60).round(),
      (70 + r.next() * 40).round(),
    );
    c.drawCircle(
      Offset(r.next() * w, boden + r.next() * (h - boden)),
      r.next() * 1.4 + .3,
      speck,
    );
  }
  for (var i = 0; i < 8; i++) {
    final o = Offset(r.next() * w, boden + 30 + r.next() * (h - boden - 50));
    final rx = 4 + r.next() * 9, ry = rx * (.55 + r.next() * .3);
    final rect = Rect.fromCenter(center: o, width: rx * 2, height: ry * 2);
    c.drawOval(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.4),
          colors: [Color(0xFF5A4A3A), Color(0xFF241A12)],
        ).createShader(rect),
    );
  }
  c.drawRect(
    Rect.fromLTWH(0, boden - 8, w, 8),
    Paint()..color = const Color(0x14F0C878),
  );
  c.drawLine(
    Offset(0, boden),
    Offset(w, boden),
    Paint()
      ..strokeWidth = 2
      ..shader = const LinearGradient(
        colors: [
          Color(0x00C9A25C),
          Color(0xFFC9A25C),
          Color(0xFFC9A25C),
          Color(0x00C9A25C),
        ],
        stops: [0, .12, .88, 1],
      ).createShader(Rect.fromLTWH(0, boden, w, 2)),
  );

  if (stamm > 0) {
    // The trunk foot flares out into the roots; outlined only at the sides
    // so it joins the trunk above without a seam.
    final rand = stamm / 2 + 1.2;
    Path seite(double s) => Path()
      ..moveTo(cx + s * rand, 0)
      ..quadraticBezierTo(
        cx + s * rand,
        boden * .9,
        cx + s * stamm * 1.5,
        boden + 14,
      );
    final fuss = Path()
      ..moveTo(cx - rand, 0)
      ..lineTo(cx + rand, 0)
      ..quadraticBezierTo(cx + rand, boden * .9, cx + stamm * 1.5, boden + 14)
      ..quadraticBezierTo(cx, boden + 4, cx - stamm * 1.5, boden + 14)
      ..quadraticBezierTo(cx - rand, boden * .9, cx - rand, 0)
      ..close();
    c.drawPath(fuss, Paint()..color = const Color(0xFF7E5A36));
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
        seite(s),
        Paint()
          ..color = const Color(0xFF1A120B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
    c.drawLine(
      Offset(cx - stamm * .28, 0),
      Offset(cx - stamm * .32, boden),
      Paint()
        ..color = const Color(0x55EBC994)
        ..strokeWidth = stamm * .22
        ..strokeCap = StrokeCap.round,
    );
  }
  final haar = Paint()
    ..color = const Color(0x73967046)
    ..strokeWidth = .6;
  for (final pts in [...haupt, ...neben]) {
    for (var i = 0; i < pts.length; i += 3) {
      final p = pts[i];
      if (p.w < 1 || r.next() > .6) continue;
      final a = r.next() * math.pi * 2, l = 4 + r.next() * 10;
      c.drawLine(
        p.o,
        p.o + Offset(math.cos(a) * l, (math.sin(a)).abs() * l + 2),
        haar,
      );
    }
  }
  for (final p in neben) {
    _linie(c, p, (q) => q.w + 1.4, const Color(0xFF20160D));
    _linie(c, p, (q) => q.w, const Color(0xFF6E5032));
  }
  for (final p in haupt) {
    _linie(c, p, (q) => q.w + 2.2, const Color(0xFF1D140C));
    _linie(c, p, (q) => q.w, const Color(0xFF86613B));
    _linie(
      c,
      [for (final q in p) _P(q.x - q.w * .18, q.y, q.w)],
      (q) => math.max(.6, q.w * .25),
      const Color(0x66E8C691),
    );
  }
  return _Geo(size, boden, ziele, haupt, rec.endRecording(), baum);
}

void _linie(
  Canvas c,
  List<_P> pts,
  double Function(_P) breite,
  Color farbe, {
  double blur = 0,
}) {
  final p = Paint()
    ..color = farbe
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  if (blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  for (var i = 1; i < pts.length; i++) {
    p.strokeWidth = breite(pts[i]);
    c.drawLine(pts[i - 1].o, pts[i].o, p);
  }
}

class _Maler extends CustomPainter {
  _Maler({
    required this.geo,
    required this.zeit,
    required this.lebendig,
    required this.licht,
    required this.lichtWert,
    required this.funken,
    required this.funkenWo,
    required this.jubel,
    required this.blaetter,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _Geo geo;
  final double Function() zeit;
  final bool lebendig;
  final int licht;
  final double Function() lichtWert;
  final double Function() funken;
  final Offset? Function() funkenWo;
  final double Function() jubel;
  final int blaetter;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(geo.picture);
    final ms = zeit();
    // Sap: a soft light travels down each root to its area.
    if (lebendig) {
      for (var i = 0; i < geo.haupt.length; i++) {
        final r = geo.haupt[i];
        final ph = ((ms / 3600) + i * .27) % 1;
        final n = r.length, c = (ph * n * 1.25).floor();
        final a = math.max(0, c - 9), b = math.min(n, c);
        if (b - a > 1) {
          _linie(
            canvas,
            r.sublist(a, b),
            (q) => q.w * .45 + 1,
            const Color(0x80F5D796),
            blur: 2.5,
          );
        }
      }
    }
    // The chosen root lights up fully; on a cheer all of them do.
    final j = jubel();
    for (var i = 0; i < geo.haupt.length; i++) {
      final t = i == licht ? lichtWert() : (j > 0 && j < 1 ? j : 0.0);
      if (t <= 0) continue;
      final r = geo.haupt[i];
      final k = math.max(2, (t * r.length).ceil());
      final fade = i == licht ? 1.0 : math.sin(t * math.pi);
      _linie(
        canvas,
        r.sublist(0, math.min(k, r.length)),
        (q) => q.w * .75 + 1.2,
        Color.fromRGBO(245, 217, 154, .45 * fade),
        blur: 6,
      );
      _linie(
        canvas,
        r.sublist(0, math.min(k, r.length)),
        (q) => q.w * .55 + .8,
        Color.fromRGBO(245, 217, 154, fade),
      );
    }
    // Tree, swaying slightly. Leaves come with the days in a row.
    final stamm = Paint()
      ..color = const Color(0xFF8A6640)
      ..strokeCap = StrokeCap.round;
    var blatt = 0;
    for (final b in geo.baum) {
      final sw = lebendig
          ? math.sin(ms / 1300 + b.ph) * .36 * (4 - b.tiefe)
          : 0.0;
      final end = b.b.translate(sw, 0);
      stamm.strokeWidth = b.w;
      canvas.drawLine(b.a, end, stamm);
      if (b.tiefe != 0) continue;
      // More days in a row: fuller, bigger leaves.
      for (var k = 0; k < 3; k++) {
        if (blatt++ % 3 >= blaetter) continue;
        final ang =
            -1.2 +
            k * 1.2 +
            b.ph +
            (lebendig ? math.sin(ms / 900 + b.ph + k) * .12 : 0);
        final g = b.s * (.75 + blaetter * .12);
        canvas.save();
        canvas.translate(end.dx, end.dy);
        canvas.rotate(ang);
        final rect = Rect.fromCenter(
          center: Offset(6 * g, 0),
          width: 14 * g,
          height: 6.8 * g,
        );
        canvas.drawOval(
          rect,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFF5DFAE), Color(0xFFB8894A)],
            ).createShader(rect),
        );
        canvas.restore();
      }
    }
    // Motes rising through the soil.
    if (lebendig) {
      final m = Paint();
      final tiefe = size.height - geo.boden;
      for (var i = 0; i < 26; i++) {
        final r = _Rnd(100 + i * 7);
        final x0 = r.next() * size.width, v = .012 + r.next() * .03;
        final y = size.height - ((ms * v + r.next() * tiefe) % tiefe);
        m.color = Color.fromRGBO(240, 207, 138, .3 * (y - geo.boden) / tiefe);
        canvas.drawCircle(
          Offset(x0 + math.sin(y / 28) * 3, y),
          .5 + r.next() * 1.4,
          m,
        );
      }
    }
    // Sparks when an area bursts open or a cheer happens.
    final f = funken(), wo = funkenWo();
    if (wo != null && f > 0 && f < 1) {
      final r = _Rnd(5);
      final p = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      for (var i = 0; i < 60; i++) {
        final a = r.next() * math.pi * 2, v = 60 + r.next() * 150;
        final t = Curves.easeOutCubic.transform(f);
        final pos =
            wo +
            Offset(math.cos(a) * v * t, math.sin(a) * v * t - 30 * t) +
            Offset(0, 60 * f * f);
        p.color = Color.fromRGBO(245, 215, 150, (1 - f) * .95);
        canvas.drawCircle(pos, (1 + r.next() * 2.4) * (1 - f * .6), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Maler old) =>
      old.geo != geo || old.licht != licht || old.blaetter != blaetter;
}

/// The root system with the four areas. [onOpen] gets the area and the
/// node's centre on screen once the light reached it; when its future
/// completes, the light goes out again.
class Wurzelwerk extends StatefulWidget {
  const Wurzelwerk({
    super.key,
    required this.bereiche,
    required this.onOpen,
    this.streak = 0,
    this.wurzeln = 0,
    this.jubelTick = 0,
    this.hoehe = 600,
    this.stamm = 0,
  });

  final List<WurzelBereich> bereiche;
  final Future<void> Function(Bereich b, Offset mitte) onOpen;
  final int streak;
  final int wurzeln;
  final int jubelTick;
  final double hoehe;

  /// Width of the big tree's trunk above (see BaumKrone). When set, the
  /// small tree and the days in a row are left out: the crown shows them.
  final double stamm;

  @override
  State<Wurzelwerk> createState() => _WurzelwerkState();
}

class _WurzelwerkState extends State<Wurzelwerk> with TickerProviderStateMixin {
  // Ambient motion runs forever, so it is off in widget tests (they wait for
  // all animations to end) and for people who turned motion off.
  late final bool _lebendig = !WidgetsBinding.instance.runtimeType
      .toString()
      .contains('Test');
  late final _zeit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );
  late final _licht = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );
  late final _funken = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _jubel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  int _wahl = -1;
  bool _offen = false;
  Offset? _funkenWo;
  _Geo? _geo;
  final _box = GlobalKey();

  double get _boden => widget.stamm > 0 ? 26.0 : 112.0;

  @override
  void initState() {
    super.initState();
    if (_lebendig) _zeit.repeat();
    _licht.addListener(() {
      if (_wahl >= 0 && !_offen && _licht.value > .75 && !_funken.isAnimating) {
        if (_funken.value == 0) {
          _funkenWo = _geo?.ziele[_wahl];
          _funken.forward(from: 0);
        }
      }
    });
    _licht.addStatusListener((s) async {
      if (s != AnimationStatus.completed || _wahl < 0 || _offen) return;
      _offen = true;
      final i = _wahl;
      final box = _box.currentContext?.findRenderObject() as RenderBox?;
      final z = _geo!.ziele[i];
      final mitte = box?.localToGlobal(z) ?? z;
      await widget.onOpen(widget.bereiche[i].bereich, mitte);
      if (!mounted) return;
      _funken.value = 0;
      await _licht.reverse();
      if (!mounted) return;
      setState(() {
        _wahl = -1;
        _offen = false;
      });
    });
  }

  @override
  void didUpdateWidget(Wurzelwerk old) {
    super.didUpdateWidget(old);
    if (old.wurzeln != widget.wurzeln) _geo = null;
    if (widget.jubelTick > old.jubelTick) {
      _funkenWo = _geo == null
          ? null
          : Offset(_geo!.size.width / 2, _boden - 40);
      _funken.forward(from: 0);
      _jubel.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _zeit.dispose();
    _licht.dispose();
    _funken.dispose();
    _jubel.dispose();
    super.dispose();
  }

  void _tippen(int i) {
    if (_wahl >= 0) return;
    setState(() => _wahl = i);
    _licht.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, widget.hoehe);
        if (_geo == null || _geo!.size != size) {
          _geo = _baue(size, _boden, widget.wurzeln, stamm: widget.stamm);
        }
        final geo = _geo!;
        final s = widget.streak;
        final blaetter = (1 + s ~/ 3).clamp(1, 3);
        final schwach = _schwaechster();
        return SizedBox(
          key: _box,
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _Maler(
                      geo: geo,
                      zeit: () => _zeit.value * 60000,
                      lebendig: _lebendig,
                      licht: _wahl,
                      lichtWert: () => _licht.value,
                      funken: () => _funken.value,
                      funkenWo: () => _funkenWo,
                      jubel: () => _jubel.value,
                      blaetter: blaetter,
                      repaint: Listenable.merge([
                        _zeit,
                        _licht,
                        _funken,
                        _jubel,
                      ]),
                    ),
                  ),
                ),
              ),
              // Days in a row next to the tree.
              if (widget.stamm == 0) ...[
                Positioned(
                  left: size.width / 2 - 60,
                  top: 0,
                  width: 120,
                  height: _boden,
                  child: const SizedBox(key: ValueKey('spross')),
                ),
                Positioned(
                  left: size.width / 2 + 54,
                  top: _boden - 58,
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s == 1 ? 'TAG AM STÜCK' : 'TAGE AM STÜCK',
                          style: CoachStyle.goldLabel.copyWith(
                            fontFamily: 'Sora',
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                            color: CoachStyle.gold,
                          ),
                        ),
                        Text(
                          '$s',
                          key: const ValueKey('spross-tage'),
                          style: CoachStyle.title.copyWith(
                            fontSize: 18,
                            height: 1.1,
                            color: const Color(0xFFF5DFAE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              for (var i = 0; i < widget.bereiche.length && i < 4; i++)
                ..._knoten(i, geo.ziele[i], i == schwach),
            ],
          ),
        );
      },
    );
  }

  /// The area the coach would point at: the lowest score, if it is 5 or
  /// less. Only there a small speech bubble shows.
  int _schwaechster() {
    var best = -1;
    for (var i = 0; i < widget.bereiche.length; i++) {
      final w = widget.bereiche[i].wert;
      if (w == null || w > 5) continue;
      if (best < 0 || w < widget.bereiche[best].wert!) best = i;
    }
    return best;
  }

  List<Widget> _knoten(int i, Offset z, bool sagt) {
    final b = widget.bereiche[i];
    final dim = _wahl >= 0 && _wahl != i;
    final (pfeil, farbe) = switch (b.diff) {
      null || 0 => ('', CoachStyle.inkSoft),
      > 0 => ('↑', const Color(0xFF9BCB8A)),
      _ => ('↓', const Color(0xFFE39A7E)),
    };
    return [
      Positioned(
        left: z.dx - 33,
        top: z.dy - 33,
        width: 66,
        height: 66,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + i * 180),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(
            scale: (0.3 + 0.7 * v) * (_wahl == i ? 1.12 : (dim ? .9 : 1)),
            child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: dim ? .45 : 1,
            child: Semantics(
              button: true,
              label: b.name,
              child: GestureDetector(
                key: ValueKey('wurzel-${b.bereich.name}'),
                onTap: () => _tippen(i),
                child: CustomPaint(
                  painter: _Ring(b.wert),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (r) =>
                          CoachStyle.goldGradient.createShader(r),
                      child: Icon(b.icon, size: 28, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: z.dx - 90,
        top: z.dy + 38,
        width: 180,
        child: IgnorePointer(
          child: Column(
            children: [
              Text(
                b.name,
                textAlign: TextAlign.center,
                style: CoachStyle.title.copyWith(
                  fontSize: 14,
                  color: CoachStyle.ink,
                  shadows: const [Shadow(blurRadius: 8)],
                ),
              ),
              Text.rich(
                key: ValueKey('knoten-wert-${b.bereich.name}'),
                TextSpan(
                  children: [
                    TextSpan(
                      text: b.wert?.toString() ?? '–',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CoachStyle.ink,
                      ),
                    ),
                    if (b.wert != null) const TextSpan(text: '/10 '),
                    TextSpan(
                      text: pfeil,
                      style: TextStyle(color: farbe),
                    ),
                  ],
                ),
                style: CoachStyle.body.copyWith(
                  fontSize: 12,
                  color: CoachStyle.beigeLabel,
                  shadows: const [Shadow(blurRadius: 8)],
                ),
              ),
              if (sagt)
                Container(
                  key: ValueKey('knoten-sagt-${b.bereich.name}'),
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE3C8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Hier hängt es gerade',
                    style: CoachStyle.body.copyWith(
                      fontSize: 11.5,
                      color: const Color(0xFF1A140E),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Dark round node with the score as a gold ring.
class _Ring extends CustomPainter {
  _Ring(this.wert);
  final int? wert;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r + 10,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x47F0C878), Color(0x00F0C878)],
        ).createShader(Rect.fromCircle(center: c, radius: r + 10)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.4),
          colors: [Color(0xFF3A2D1F), Color(0xFF18120D)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2E251B)
        ..strokeWidth = 3,
    );
    final w = wert;
    if (w == null) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * (w / 10).clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..shader = CoachStyle.goldGradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.wert != wert;
}

/// Opens [builder]'s page growing as a circle out of [mitte] (a point on
/// screen), with a short gold flash.
Future<void> oeffneMitKreis(
  BuildContext context,
  Offset mitte,
  WidgetBuilder builder,
) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 750),
      reverseTransitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, a, b) => builder(context),
      transitionsBuilder: (context, a, b, child) {
        final kurve = CurvedAnimation(
          parent: a,
          curve: const Cubic(.7, 0, .2, 1),
        );
        return AnimatedBuilder(
          animation: kurve,
          child: child,
          builder: (context, child) {
            final s = MediaQuery.sizeOf(context);
            final maxR =
                [
                  mitte,
                  mitte - Offset(s.width, 0),
                  mitte - Offset(0, s.height),
                  mitte - Offset(s.width, s.height),
                ].map((o) => o.distance).reduce(math.max) +
                20;
            final v = kurve.value;
            return ClipPath(
              clipper: _Kreis(mitte, 30 + (maxR - 30) * v),
              child: Stack(
                children: [
                  child!,
                  if (v < 1)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - v).clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(
                                  mitte.dx / s.width * 2 - 1,
                                  mitte.dy / s.height * 2 - 1,
                                ),
                                radius: 1.1,
                                colors: const [
                                  Color(0x8CF5D796),
                                  Color(0x26D6AA5E),
                                  Color(0x00000000),
                                ],
                                stops: const [0, .4, .75],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class _Kreis extends CustomClipper<Path> {
  _Kreis(this.mitte, this.r);
  final Offset mitte;
  final double r;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: mitte, radius: r));

  @override
  bool shouldReclip(_Kreis old) => old.r != r || old.mitte != mitte;
}
