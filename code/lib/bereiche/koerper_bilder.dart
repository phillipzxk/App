import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The pictures of the Körper pages (draft "Körper als Bilder" 3b,
/// Phillip "ja sehr gut genauso" 2026-11-07): every page is one picture
/// in black and gold, each part keeps only one quiet tone of its own.
/// All pictures are drawn on a 302 x 270 board and scaled to the screen.

/// Wraps a part of a picture so a tap opens the page behind tile [id].
typedef BildTipp = Widget Function(String id, Widget child);

const bildBreite = 302.0, bildHoehe = 270.0;

const _ink = Color(0xFFF4EEE4);
const _soft = Color(0xFF9E937F);
const _leise = Color(0xFF6F6658);
const _dunkel = Color(0xFF100D0A);
const _rand = Color(0x24FFF0D7);
const _goldHell = Color(0xFFF5DFAE);
const _goldInk = Color(0xFF1A130B);

/// The quiet tone of each part.
const tonTraining = Color(0xFFE6B88A);
const tonErnaehrung = Color(0xFFDCCB92);
const tonSchlaf = Color(0xFFCFCBE6);

double _teil(double v, double von, double bis) =>
    ((v - von) / (bis - von)).clamp(0.0, 1.0);

double _plopp(double v, double von) =>
    Curves.easeOutBack.transform(_teil(v, von, von + .35));

Shader _goldR(Offset m, double r) => const RadialGradient(
  center: Alignment(-.24, -.36),
  radius: .85,
  colors: [Color(0xFFFFEBC4), Color(0xFFDDB46C), Color(0xFFA8823F)],
  stops: [0, .6, 1],
).createShader(Rect.fromCircle(center: m, radius: r));

Shader _dunkelR(Offset m, double r) => const RadialGradient(
  center: Alignment(-.24, -.36),
  radius: .9,
  colors: [Color(0xFF2E261D), Color(0xFF13100C)],
).createShader(Rect.fromCircle(center: m, radius: r));

Shader _goldLinear(Rect r) => const LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF0D49A), Color(0xFFC49A55)],
).createShader(r);

/// Text centred (or left/right) on [p], where p.dy is the baseline.
void _text(
  Canvas c,
  String s,
  Offset p, {
  double size = 11,
  Color color = _soft,
  FontWeight weight = FontWeight.w400,
  bool sora = false,
  TextAlign align = TextAlign.center,
  double abstand = 0,
  double maxBreite = 290,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: sora ? 'Sora' : 'Figtree',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: abstand,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxBreite);
  final x = switch (align) {
    TextAlign.left => p.dx,
    TextAlign.right => p.dx - tp.width,
    _ => p.dx - tp.width / 2,
  };
  final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  tp.paint(c, Offset(x, p.dy - base));
}

void _zeile(Canvas c, String s) =>
    _text(c, s, const Offset(151, 252), color: _leise);

void _glow(Canvas c, Offset m, double r, Color farbe) => c.drawCircle(
  m,
  r,
  Paint()
    ..color = farbe
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .5),
);

Path _stueck(Path p, double f) {
  final out = Path();
  for (final m in p.computeMetrics()) {
    out.addPath(m.extractPath(0, m.length * f.clamp(0.0, 1.0)), Offset.zero);
  }
  return out;
}

Paint _strich(Color farbe, double breite) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = breite
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = farbe;

/// Gold pills on top of a picture (exercise or filter chips).
void _pillen(Canvas c, List<String> namen, int an, {double y = 16}) {
  final breiten = [for (final n in namen) n.length * 6.4 + 26];
  var x =
      151 - (breiten.fold(0.0, (a, b) => a + b) + (namen.length - 1) * 6) / 2;
  for (var i = 0; i < namen.length; i++) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, breiten[i], 26),
      const Radius.circular(13),
    );
    if (i == an) {
      c.drawRRect(r, Paint()..shader = _goldLinear(r.outerRect));
    } else {
      c.drawRRect(r, Paint()..color = const Color(0x0AFFF0D7));
      c.drawRRect(r, _strich(_rand, 1));
    }
    _text(
      c,
      namen[i],
      Offset(x + breiten[i] / 2, y + 17),
      weight: FontWeight.w600,
      color: i == an ? _goldInk : _soft,
    );
    x += breiten[i] + 6;
  }
}

/// The board with its painter and tap areas.
class _Brett extends StatelessWidget {
  const _Brett({required this.maler, this.punkte = const []});
  final CustomPainter maler;
  final List<(Rect, Widget)> punkte;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: bildBreite,
    height: bildHoehe,
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: maler)),
        for (final (r, w) in punkte) Positioned.fromRect(rect: r, child: w),
      ],
    ),
  );
}

Widget _flaeche() => const SizedBox.expand();

abstract class _Maler extends CustomPainter {
  _Maler(this.v, this.t);

  /// 0 to 1 once when the page appears.
  final double v;

  /// Endless time in seconds for twinkling and waves (0 without motion).
  final double t;

  @override
  bool shouldRepaint(_Maler old) => old.v != v || old.t != t;
}

// ------------------------------------------------------------- Training

/// One exercise of today: name, sets and weight, done.
typedef HeuteUebung = ({String name, String ziel, bool fertig});

/// Today's exercises as plates on a bar; done ones are gold.
class TrainingHeuteBild extends StatelessWidget {
  const TrainingHeuteBild({
    super.key,
    required this.uebungen,
    required this.tipp,
    required this.v,
    required this.t,
    this.leer,
  });

  final List<HeuteUebung> uebungen;

  /// Shown instead of the next exercise: no plan yet, or a free day.
  final ({String label, String titel, String unter})? leer;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _HeuteMaler(v, t, uebungen, leer),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('t-heute', _flaeche()),
      ),
    ],
  );
}

class _HeuteMaler extends _Maler {
  _HeuteMaler(super.v, super.t, this.u, this.leer);
  final List<HeuteUebung> u;
  final ({String label, String titel, String unter})? leer;

  @override
  void paint(Canvas c, Size s) {
    final n = leer != null ? 4 : math.min(u.length, 6);
    final r = n <= 4 ? 24.0 : 19.0;
    c.drawOval(
      Rect.fromCenter(center: const Offset(151, 140), width: 256, height: 24),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    final stange = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 108, 282, 8),
      const Radius.circular(4),
    );
    c.drawRRect(stange, Paint()..color = const Color(0xFF5B4C3B));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 108, 282, 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0x2EFFF0D7),
    );
    final links = (n + 1) ~/ 2;
    final xs = <double>[
      for (var k = links - 1; k >= 0; k--) 151 - 27 - r - k * (2 * r + 5),
      for (var k = 0; k < n - links; k++) 151 + 27 + r + k * (2 * r + 5),
    ];
    final naechste = leer != null ? -1 : u.indexWhere((x) => !x.fertig);
    for (var i = 0; i < n; i++) {
      final p = _plopp(v, .05 + i * .07);
      if (p <= 0) continue;
      final m = Offset(xs[i], 112);
      c.save();
      c.translate(m.dx, m.dy);
      c.scale(p);
      c.translate(-m.dx, -m.dy);
      final fertig = leer == null && u[i].fertig;
      c.drawCircle(
        m,
        r,
        Paint()..shader = fertig ? _goldR(m, r) : _dunkelR(m, r),
      );
      if (!fertig) {
        c.drawCircle(
          m,
          r,
          _strich(i == naechste ? tonTraining : _rand, i == naechste ? 1.6 : 1),
        );
      }
      c.drawCircle(m, r * .62, _strich(const Color(0x14FFF0D7), 1));
      _text(
        c,
        leer != null ? '' : '${i + 1}',
        m + const Offset(0, 5),
        size: n <= 4 ? 14 : 12,
        sora: true,
        weight: FontWeight.w700,
        color: fertig
            ? _goldInk
            : i == naechste
            ? tonTraining
            : _soft,
      );
      c.restore();
    }
    final fertige = u.where((x) => x.fertig).length;
    final mp = _plopp(v, 0);
    c.save();
    c.translate(151, 112);
    c.scale(mp);
    c.translate(-151, -112);
    c.drawCircle(const Offset(151, 112), 21, Paint()..color = _dunkel);
    c.drawCircle(const Offset(151, 112), 21, _strich(_rand, 1));
    _text(
      c,
      leer != null ? '–' : '$fertige/${u.length}',
      const Offset(151, 115),
      size: 13,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    _text(c, 'fertig', const Offset(151, 126), size: 8.5);
    c.restore();
    final unten = _teil(v, .35, .7);
    final o = Offset(0, (1 - unten) * 8);
    final farbe = Color.fromRGBO(0, 0, 0, 1);
    if (unten > 0) {
      final (label, titel, unter) = leer != null
          ? (leer!.label, leer!.titel, leer!.unter)
          : naechste < 0
          ? ('GESCHAFFT', 'Alle ${u.length} Übungen', 'stark durchgezogen')
          : (
              'ALS NÄCHSTES · ${naechste + 1}',
              u[naechste].name,
              u[naechste].ziel,
            );
      c.saveLayer(
        Offset.zero & s,
        Paint()..color = farbe.withValues(alpha: unten),
      );
      _text(
        c,
        label,
        const Offset(151, 180) + o,
        size: 10,
        weight: FontWeight.w700,
        abstand: 1.2,
        color: tonTraining,
      );
      _text(
        c,
        titel,
        const Offset(151, 202) + o,
        size: 16,
        sora: true,
        weight: FontWeight.w700,
        color: _ink,
      );
      _text(c, unter, const Offset(151, 220) + o, size: 12);
      c.restore();
    }
    _zeile(
      c,
      leer != null
          ? 'Tipp aufs Bild, um weiterzumachen'
          : 'Tipp aufs Bild, dann trägst du ein',
    );
  }
}

/// One day of the week strip: letter, training name, state.
typedef WochenTag = ({String tag, String name, bool? fertig, bool heute});

/// The week as a path of days; done days are gold, today has a ring.
class TrainingWocheBild extends StatelessWidget {
  const TrainingWocheBild({
    super.key,
    required this.tage,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final List<WochenTag> tage;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _WocheMaler(v, t, tage),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('t-woche', _flaeche()),
      ),
    ],
  );
}

class _WocheMaler extends _Maler {
  _WocheMaler(super.v, super.t, this.tage);
  final List<WochenTag> tage;

  static const _ys = [176.0, 146.0, 118.0, 128.0, 146.0, 120.0, 92.0];
  static double _x(int i) => 26 + i * 41.7;

  @override
  void paint(Canvas c, Size s) {
    final weg = Path()..moveTo(_x(0), _ys[0]);
    for (var i = 1; i < 7; i++) {
      weg.lineTo(_x(i), _ys[i]);
    }
    c.drawPath(
      _stueck(weg, _teil(v, 0, .6)),
      _strich(tonTraining.withValues(alpha: .45), 2),
    );
    for (var i = 0; i < tage.length && i < 7; i++) {
      final d = tage[i];
      final m = Offset(_x(i), _ys[i]);
      final p = _plopp(v, .1 + i * .06);
      if (p <= 0) continue;
      final training = d.fertig != null;
      final r = training ? 16.0 : 6.0;
      c.save();
      c.translate(m.dx, m.dy);
      c.scale(p);
      c.translate(-m.dx, -m.dy);
      if (d.heute) {
        final puls = (t * .42) % 1;
        c.drawCircle(
          m,
          r + 3 + 9 * puls,
          _strich(tonTraining.withValues(alpha: .6 * (1 - puls)), 1),
        );
      }
      if (d.fertig == true) {
        c.drawCircle(m, r, Paint()..shader = _goldR(m, r));
        c.drawPath(
          Path()
            ..moveTo(m.dx - 5.5, m.dy)
            ..relativeLineTo(3.8, 3.8)
            ..relativeLineTo(7, -7.5),
          _strich(_goldInk, 2.2),
        );
      } else if (training) {
        c.drawCircle(
          m,
          r,
          Paint()
            ..shader = d.heute ? null : _dunkelR(m, r)
            ..color = _dunkel,
        );
        c.drawCircle(m, r, _strich(d.heute ? tonTraining : _rand, 1.6));
      } else {
        c.drawCircle(m, r, Paint()..color = const Color(0xFF2A231C));
      }
      _text(
        c,
        d.tag,
        m + Offset(0, training ? 32 : 22),
        size: 10.5,
        weight: FontWeight.w600,
        color: d.heute ? tonTraining : _soft,
      );
      if (training) {
        _text(
          c,
          d.name,
          m + const Offset(0, -24),
          size: 11,
          weight: FontWeight.w600,
          color: _ink,
          maxBreite: 70,
        );
      }
      c.restore();
    }
    _zeile(c, 'Gold = geschafft · Ring = heute');
  }
}

/// One exercise's best weights over time; every record grows a sprout.
class TrainingVerlaufBild extends StatelessWidget {
  const TrainingVerlaufBild({
    super.key,
    required this.uebungen,
    required this.werte,
    required this.einheit,
    required this.videos,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// Up to three exercises as chips, the first is shown.
  final List<String> uebungen;
  final List<double> werte;
  final String einheit;
  final int videos;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _VerlaufMaler(v, t, uebungen, werte, einheit, videos),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('t-kurve', _flaeche()),
      ),
    ],
  );
}

String _zahl(double w) {
  final r = (w * 10).round() / 10;
  return (r == r.roundToDouble() ? r.toInt().toString() : r.toString())
      .replaceAll('.', ',');
}

class _VerlaufMaler extends _Maler {
  _VerlaufMaler(
    super.v,
    super.t,
    this.namen,
    this.werte,
    this.einheit,
    this.videos,
  );
  final List<String> namen;
  final List<double> werte;
  final String einheit;
  final int videos;

  @override
  void paint(Canvas c, Size s) {
    if (namen.isNotEmpty) _pillen(c, namen.take(3).toList(), 0);
    if (werte.length < 2) {
      c.drawPath(
        Path()
          ..moveTo(16, 200)
          ..cubicTo(90, 196, 170, 170, 286, 130),
        _strich(const Color(0x33E6B88A), 2)..strokeCap = StrokeCap.round,
      );
      _text(
        c,
        werte.isEmpty
            ? 'Noch keine Einträge'
            : '${_zahl(werte.first)} $einheit',
        const Offset(151, 110),
        size: 18,
        sora: true,
        weight: FontWeight.w700,
        color: _ink,
      );
      _text(
        c,
        'Nach dem zweiten Training wächst hier deine Kurve',
        const Offset(151, 130),
      );
      _zeile(c, 'Trieb = Rekord');
      return;
    }
    final lo = werte.reduce(math.min), hi = werte.reduce(math.max);
    final spanne = hi - lo == 0 ? 1 : hi - lo;
    Offset p(int i) => Offset(
      16 + 270 * i / (werte.length - 1),
      214 - 100 * (werte[i] - lo) / spanne,
    );
    final linie = Path()..moveTo(p(0).dx, p(0).dy);
    for (var i = 1; i < werte.length; i++) {
      linie.lineTo(p(i).dx, p(i).dy);
    }
    final a = _teil(v, .1, .5);
    final flaeche = Path.from(linie)
      ..lineTo(286, 226)
      ..lineTo(16, 226)
      ..close();
    c.drawPath(
      flaeche,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tonTraining.withValues(alpha: .28 * a),
            tonTraining.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(0, 100, 302, 126)),
    );
    c.drawPath(_stueck(linie, _teil(v, 0, .6)), _strich(tonTraining, 2.6));
    var best = werte.first;
    for (var i = 1; i < werte.length; i++) {
      if (werte[i] <= best) continue;
      best = werte[i];
      final q = _plopp(v, .4 + i / werte.length * .3);
      if (q <= 0) continue;
      final m = p(i);
      c.save();
      c.translate(m.dx, m.dy);
      c.scale(q);
      c.translate(-m.dx, -m.dy);
      c.drawPath(
        Path()
          ..moveTo(m.dx, m.dy)
          ..quadraticBezierTo(m.dx - 2, m.dy - 11, m.dx, m.dy - 22),
        _strich(const Color(0xFFC9A25C), 1.8),
      );
      for (final (dx, dy, w) in [(-6.0, -16.0, -.56), (6.0, -22.0, .56)]) {
        c.save();
        c.translate(m.dx + dx, m.dy + dy);
        c.rotate(w);
        final r = Rect.fromCenter(center: Offset.zero, width: 13, height: 6.4);
        c.drawOval(r, Paint()..shader = _goldLinear(r));
        c.restore();
      }
      c.drawCircle(m, 3.5, Paint()..color = _goldHell);
      c.restore();
    }
    _text(
      c,
      '${_zahl(hi)} $einheit',
      const Offset(22, 78),
      size: 24,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
      align: TextAlign.left,
    );
    _text(
      c,
      'dein Rekord',
      const Offset(22, 95),
      color: tonTraining,
      align: TextAlign.left,
    );
    _zeile(
      c,
      videos > 0 ? 'Trieb = Rekord · $videos Form-Videos' : 'Trieb = Rekord',
    );
  }
}

// ------------------------------------------------------------ Ernährung

/// Meals on the energy curve, the plate and the water glass.
class EssenHeuteBild extends StatelessWidget {
  const EssenHeuteBild({
    super.key,
    required this.mahlzeiten,
    required this.jetzt,
    required this.teller,
    required this.liter,
    required this.ziel,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// Each meal: position over the day (0..1), eaten, time.
  final List<(double, bool, String)> mahlzeiten;
  final double jetzt;

  /// Protein, vegetables, energy, each 0..1.
  final List<double> teller;
  final double liter, ziel;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _EssenMaler(v, t, mahlzeiten, jetzt, teller, liter, ziel),
    punkte: [
      (const Rect.fromLTWH(0, 0, 182, bildHoehe), tipp('e-essen', _flaeche())),
      (const Rect.fromLTWH(182, 120, 120, 150), tipp('e-trinken', _flaeche())),
    ],
  );
}

class _EssenMaler extends _Maler {
  _EssenMaler(
    super.v,
    super.t,
    this.m,
    this.jetzt,
    this.teller,
    this.liter,
    this.ziel,
  );
  final List<(double, bool, String)> m;
  final double jetzt;
  final List<double> teller;
  final double liter, ziel;

  static double _y(double x) =>
      66 - 24 * math.sin((x - 14) / 274 * math.pi * 2.3 + .4);

  @override
  void paint(Canvas c, Size s) {
    final kurve = Path()..moveTo(14, _y(14));
    for (var x = 16.0; x <= 288; x += 2) {
      kurve.lineTo(x, _y(x));
    }
    final a = _teil(v, .05, .5);
    c.drawPath(
      Path.from(kurve)
        ..lineTo(288, 112)
        ..lineTo(14, 112)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tonErnaehrung.withValues(alpha: .22 * a),
            tonErnaehrung.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(0, 30, 302, 82)),
    );
    c.drawPath(_stueck(kurve, _teil(v, 0, .55)), _strich(tonErnaehrung, 2.4));
    for (var i = 0; i < m.length; i++) {
      final (pos, gegessen, zeit) = m[i];
      final q = _plopp(v, .3 + i * .07);
      if (q <= 0) continue;
      final x = 14 + pos * 274, mm = Offset(x, _y(x));
      c.save();
      c.translate(mm.dx, mm.dy);
      c.scale(q);
      c.translate(-mm.dx, -mm.dy);
      if (gegessen) {
        c.drawCircle(mm, 7.5, Paint()..shader = _goldR(mm, 7.5));
      } else {
        c.drawCircle(mm, 7.5, Paint()..color = _dunkel);
        c.drawCircle(mm, 7.5, _strich(tonErnaehrung, 1.6));
      }
      _text(c, zeit, mm + const Offset(0, -14), size: 10);
      c.restore();
    }
    final sonne = _teil(v, .45, .9);
    if (sonne > 0) {
      final x = 14 + jetzt.clamp(0.0, 1.0) * 274 * sonne;
      final sm = Offset(x, _y(x));
      _glow(c, sm, 12, const Color(0x4DF5DFAE));
      c.drawCircle(sm, 5, Paint()..color = _goldHell);
    }
    // The plate: three arcs, one per part.
    final tp = _plopp(v, .35);
    const tm = Offset(88, 178);
    c.save();
    c.translate(tm.dx, tm.dy);
    c.scale(tp);
    c.translate(-tm.dx, -tm.dy);
    c.drawCircle(tm, 34, Paint()..shader = _dunkelR(tm, 34));
    final rect = Rect.fromCircle(center: tm, radius: 44);
    for (var i = 0; i < 3; i++) {
      final start = i / 3 * math.pi * 2 - math.pi / 2 + .08;
      const lang = math.pi * 2 / 3 - .16;
      c.drawArc(rect, start, lang, false, _strich(const Color(0x12FFF0D7), 10));
      final w = (i < teller.length ? teller[i] : 0.0).clamp(0.0, 1.0);
      if (w > .01) {
        c.drawArc(
          rect,
          start,
          lang * w * _teil(v, .4, .9),
          false,
          _strich(tonErnaehrung.withValues(alpha: const [1.0, .95, .6][i]), 10),
        );
      }
    }
    final fehlt = teller.length == 3
        ? ['Eiweiß', 'Gemüse', 'Energie'][teller.indexOf(
            teller.reduce(math.min),
          )]
        : '';
    _text(
      c,
      'Teller',
      tm + const Offset(0, -2),
      size: 13,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    _text(
      c,
      teller.every((w) => w >= .95) ? 'voll' : '$fehlt fehlt',
      tm + const Offset(0, 13),
      size: 10,
    );
    c.restore();
    // The glass with a gently moving water line.
    final glas = Path()
      ..moveTo(196, 140)
      ..quadraticBezierTo(196, 136, 200, 136)
      ..lineTo(236, 136)
      ..quadraticBezierTo(240, 136, 240, 140)
      ..lineTo(234, 214)
      ..quadraticBezierTo(233.5, 220, 228, 220)
      ..lineTo(208, 220)
      ..quadraticBezierTo(202.5, 220, 202, 214)
      ..close();
    c.save();
    c.clipPath(glas);
    c.drawRect(
      const Rect.fromLTWH(190, 130, 56, 94),
      Paint()..color = const Color(0x0AFFF0D7),
    );
    final anteil = ziel <= 0 ? 0.0 : (liter / ziel).clamp(0.0, 1.0);
    final top = 220 - 82 * anteil * _teil(v, .2, .8);
    if (anteil > 0) {
      final welle = Path()..moveTo(190, top);
      for (var x = 190.0; x <= 246; x += 2) {
        welle.lineTo(x, top + math.sin(x / 9 + t * 2.6) * 1.6);
      }
      welle
        ..lineTo(246, 224)
        ..lineTo(190, 224)
        ..close();
      c.drawPath(welle, Paint()..color = tonErnaehrung.withValues(alpha: .8));
    }
    c.restore();
    c.drawPath(glas, _strich(const Color(0x80FFF0D7), 1.6));
    c.drawLine(
      const Offset(204, 146),
      const Offset(207, 206),
      _strich(const Color(0x38FFFFFF), 3),
    );
    _text(
      c,
      '${_liter(liter)} von ${_liter(ziel)} l',
      const Offset(218, 238),
      weight: FontWeight.w600,
      color: tonErnaehrung,
    );
    _zeile(c, 'Tipp aufs Glas, wenn du trinkst');
  }
}

/// The cookbook as a vine: every dish a leaf, rescue dishes hollow.
class KuecheBild extends StatelessWidget {
  const KuecheBild({
    super.key,
    required this.blaetter,
    required this.korb,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// One entry per dish: in the cookbook (full), rescue dish (hollow).
  final List<({bool voll, bool rettung})> blaetter;
  final int korb;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _KuecheMaler(v, t, blaetter, korb),
    punkte: [
      (const Rect.fromLTWH(0, 0, bildBreite, 168), tipp('e-koch', _flaeche())),
      (const Rect.fromLTWH(111, 166, 80, 66), tipp('e-einkauf', _flaeche())),
    ],
  );
}

class _KuecheMaler extends _Maler {
  _KuecheMaler(super.v, super.t, this.b, this.korb);
  final List<({bool voll, bool rettung})> b;
  final int korb;

  @override
  void paint(Canvas c, Size s) {
    final ranke = Path()
      ..moveTo(6, 100)
      ..cubicTo(60, 72, 100, 128, 151, 100)
      ..cubicTo(202, 72, 250, 72, 296, 100);
    c.drawPath(
      _stueck(ranke, _teil(v, 0, .55)),
      _strich(const Color(0xFF9C8150), 2.4),
    );
    final n = math.min(b.length, 9);
    for (var i = 0; i < 9; i++) {
      final x = 24 + i * 32.0;
      final o = i.isOdd ? 1.0 : -1.0;
      final y = 100 + o * (14 + (i % 3) * 2) - math.sin(i * 1.1) * 8;
      final q = _plopp(v, .25 + i * .05);
      if (q <= 0) continue;
      c.save();
      c.translate(x, y);
      c.scale(q);
      c.rotate(o * .56);
      final blatt = Path()
        ..moveTo(-15, 0)
        ..quadraticBezierTo(0, -10, 15, 0)
        ..quadraticBezierTo(0, 10, -15, 0)
        ..close();
      if (i >= n) {
        // An empty bud: the next dish grows here.
        c.drawCircle(Offset.zero, 3, Paint()..color = const Color(0x55DCCB92));
      } else if (b[i].rettung) {
        c.drawPath(blatt, Paint()..color = _dunkel);
        c.drawPath(blatt, _strich(tonErnaehrung, 1.4));
      } else {
        c.drawPath(
          blatt,
          Paint()
            ..color = b[i].voll
                ? tonErnaehrung
                : tonErnaehrung.withValues(alpha: .35),
        );
        c.drawLine(
          const Offset(-10, 0),
          const Offset(10, 0),
          _strich(const Color(0x38000000), 1),
        );
      }
      c.restore();
    }
    const km = Offset(151, 196);
    final kq = _plopp(v, .45);
    c.save();
    c.translate(km.dx, km.dy);
    c.scale(kq);
    c.translate(-km.dx, -km.dy);
    c.drawCircle(km, 27, Paint()..shader = _dunkelR(km, 27));
    c.drawCircle(km, 27, _strich(_rand, 1));
    c.drawPath(
      Path()
        ..moveTo(137, 190)
        ..lineTo(165, 190)
        ..lineTo(161, 206)
        ..lineTo(141, 206)
        ..close(),
      _strich(_ink, 1.6),
    );
    c.drawPath(
      Path()
        ..moveTo(144, 190)
        ..lineTo(151, 182)
        ..lineTo(158, 190),
      _strich(_ink, 1.6),
    );
    if (korb > 0) {
      const bm = Offset(171, 176);
      c.drawCircle(bm, 10, Paint()..shader = _goldR(bm, 10));
      _text(
        c,
        '$korb',
        bm + const Offset(0, 4),
        size: 10.5,
        sora: true,
        weight: FontWeight.w700,
        color: _goldInk,
      );
    }
    c.restore();
    _zeile(
      c,
      b.isEmpty
          ? 'Jedes Gericht, das du kochst, wird ein Blatt'
          : 'Volles Blatt = Basis · leeres Blatt = Rettung',
    );
  }
}

/// kcal arc, the weight line inside it and the supplement capsules.
class ZielBild extends StatelessWidget {
  const ZielBild({
    super.key,
    required this.kcal,
    required this.gewichte,
    required this.kapseln,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final int? kcal;
  final List<double> gewichte;

  /// Name and taken.
  final List<(String, bool)> kapseln;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _ZielMaler(v, t, kcal, gewichte, kapseln),
    punkte: [
      (const Rect.fromLTWH(0, 0, bildBreite, 190), tipp('e-ziel', _flaeche())),
      (const Rect.fromLTWH(0, 190, bildBreite, 80), tipp('e-supp', _flaeche())),
    ],
  );
}

class _ZielMaler extends _Maler {
  _ZielMaler(super.v, super.t, this.kcal, this.g, this.k);
  final int? kcal;
  final List<double> g;
  final List<(String, bool)> k;

  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromCircle(center: const Offset(151, 170), radius: 100);
    c.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      _strich(const Color(0x12FFF0D7), 12),
    );
    if (kcal != null) {
      c.drawArc(
        rect,
        math.pi,
        math.pi * .78 * _teil(v, 0, .6),
        false,
        _strich(tonErnaehrung, 12),
      );
    }
    _text(
      c,
      kcal == null ? 'Einrichten' : _tausend(kcal!),
      const Offset(151, 126),
      size: kcal == null ? 22 : 32,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    _text(
      c,
      kcal == null
          ? 'aus Größe, Alter und Ziel'
          : 'kcal am Tag · nur Orientierung',
      const Offset(151, 144),
    );
    if (g.length >= 2) {
      final letzte = g.length > 8 ? g.sublist(g.length - 8) : g;
      final lo = letzte.reduce(math.min), hi = letzte.reduce(math.max);
      final sp = hi - lo == 0 ? 1 : hi - lo;
      Offset p(int i) => Offset(
        104 + 96 * i / (letzte.length - 1),
        176 - 10 * (letzte[i] - lo) / sp,
      );
      final l = Path()..moveTo(p(0).dx, p(0).dy);
      for (var i = 1; i < letzte.length; i++) {
        l.lineTo(p(i).dx, p(i).dy);
      }
      c.drawPath(
        _stueck(l, _teil(v, .3, .8)),
        _strich(tonErnaehrung.withValues(alpha: .7), 2),
      );
      if (v > .8) {
        c.drawCircle(p(letzte.length - 1), 3.5, Paint()..color = tonErnaehrung);
      }
    }
    final n = math.min(k.length, 4);
    if (n == 0) {
      _text(
        c,
        'Supplements einmal festlegen, dann abhaken',
        const Offset(151, 218),
      );
    }
    final w = n <= 3 ? 82.0 : 64.0;
    final x0 = 151 - (n * w + (n - 1) * 8) / 2;
    for (var i = 0; i < n; i++) {
      final (name, genommen) = k[i];
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x0 + i * (w + 8), 198, w, 32),
        const Radius.circular(16),
      );
      final q = _plopp(v, .4 + i * .07);
      if (q <= 0) continue;
      c.save();
      c.translate(r.center.dx, r.center.dy);
      c.scale(q);
      c.translate(-r.center.dx, -r.center.dy);
      if (genommen) {
        c.drawRRect(r, Paint()..shader = _goldLinear(r.outerRect));
      } else {
        c.drawRRect(r, Paint()..color = const Color(0x0AFFF0D7));
        c.drawRRect(r, _strich(_rand, 1));
      }
      _text(
        c,
        name,
        r.center + const Offset(0, 4),
        size: n <= 3 ? 11.5 : 10.5,
        weight: FontWeight.w600,
        color: genommen ? _goldInk : _ink,
        maxBreite: w - 10,
      );
      c.restore();
    }
    _zeile(c, n == 0 ? '' : 'Gold = heute genommen');
  }
}

/// "1,5" or "3,25": liters with up to two decimals.
String _liter(double l) {
  final r = (l * 100).round() / 100;
  var t = r.toStringAsFixed(2);
  while (t.endsWith('0')) {
    t = t.substring(0, t.length - 1);
  }
  if (t.endsWith('.')) t = t.substring(0, t.length - 1);
  return t.replaceAll('.', ',');
}

String _tausend(int n) {
  final s = '$n';
  return s.length > 3
      ? '${s.substring(0, s.length - 3)}.${s.substring(s.length - 3)}'
      : s;
}

// --------------------------------------------------------------- Schlaf

/// Stars that twinkle, always at the same places.
void _sterne(Canvas c, int n, Rect feld, double t, {int saat = 7}) {
  final z = math.Random(saat);
  for (var i = 0; i < n; i++) {
    final p = Offset(
      feld.left + z.nextDouble() * feld.width,
      feld.top + z.nextDouble() * feld.height,
    );
    final r = z.nextDouble() * 1 + .35;
    final phase = z.nextDouble() * math.pi * 2;
    final hell = .25 + .65 * (.5 + .5 * math.sin(t * 1.6 + phase));
    c.drawCircle(p, r, Paint()..color = Color.fromRGBO(240, 236, 230, hell));
  }
}

/// Sunrise: the sun rises, its ring fills with the light minutes; three
/// round buttons below for how the user woke up.
class MorgenBild extends StatelessWidget {
  const MorgenBild({
    super.key,
    required this.licht,
    required this.gewaehlt,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// Light minutes reached, 0..1.
  final double licht;

  /// 0 frisch, 1 okay, 2 gerädert, null not yet.
  final int? gewaehlt;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _MorgenMaler(v, t, licht, gewaehlt),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('s-himmel', _flaeche()),
      ),
    ],
  );
}

class _MorgenMaler extends _Maler {
  _MorgenMaler(super.v, super.t, this.licht, this.gewaehlt);
  final double licht;
  final int? gewaehlt;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      const Rect.fromLTWH(0, 0, 302, 172),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF12100D),
            Color(0xFF3A2C22),
            Color(0xFFA9784C),
            Color(0xFFE8B678),
          ],
          stops: [0, .5, .85, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 302, 172)),
    );
    _sterne(c, 14, const Rect.fromLTWH(0, 0, 302, 80), t);
    final hoch = Curves.easeOutCubic.transform(_teil(v, 0, .7));
    final sm = Offset(151, 150 + (1 - hoch) * 60);
    _glow(c, sm, 56, const Color(0x73F7CF92));
    c.drawCircle(
      sm,
      27,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF6E2), Color(0xFFF7CF92)],
        ).createShader(Rect.fromCircle(center: sm, radius: 27)),
    );
    final ring = Rect.fromCircle(center: sm, radius: 40);
    c.drawArc(ring, 0, math.pi * 2, false, _strich(const Color(0x38FFF6E2), 4));
    if (licht > 0) {
      c.drawArc(
        ring,
        -math.pi / 2,
        math.pi * 2 * licht.clamp(0.0, 1.0) * _teil(v, .5, 1),
        false,
        _strich(const Color(0xFFFFF6E2), 4),
      );
    }
    final berg = Path()
      ..moveTo(0, 166)
      ..quadraticBezierTo(76, 150, 151, 160)
      ..quadraticBezierTo(226, 170, 302, 154)
      ..lineTo(302, 270)
      ..lineTo(0, 270)
      ..close();
    c.drawPath(berg, Paint()..color = const Color(0xFF0E0C0A));
    _text(
      c,
      'WIE BIST DU AUFGEWACHT?',
      const Offset(151, 194),
      size: 10,
      weight: FontWeight.w700,
      abstand: 1.2,
      color: tonSchlaf,
    );
    const namen = ['Frisch', 'Okay', 'Gerädert'];
    for (var i = 0; i < 3; i++) {
      final m = Offset(79 + i * 72.0, 222);
      final q = _plopp(v, .4 + i * .08);
      if (q <= 0) continue;
      c.save();
      c.translate(m.dx, m.dy);
      c.scale(q);
      c.translate(-m.dx, -m.dy);
      final an = gewaehlt == i;
      if (an) {
        c.drawCircle(m, 19, Paint()..shader = _goldR(m, 19));
      } else {
        c.drawCircle(m, 19, Paint()..color = const Color(0x0AFFF0D7));
        c.drawCircle(m, 19, _strich(_rand, 1));
      }
      final f = Paint()..color = an ? _goldInk : _soft;
      switch (i) {
        case 0:
          c.drawCircle(m, 6, f);
          for (var k = 0; k < 8; k++) {
            final a = k / 8 * math.pi * 2;
            c.drawLine(
              m + Offset(math.cos(a) * 9, math.sin(a) * 9),
              m + Offset(math.cos(a) * 11.5, math.sin(a) * 11.5),
              _strich(f.color, 1.6),
            );
          }
        case 1:
          c.drawArc(
            Rect.fromCircle(center: m + const Offset(0, 4), radius: 9),
            math.pi,
            math.pi,
            true,
            f,
          );
          c.drawLine(
            m + const Offset(-12, 5),
            m + const Offset(12, 5),
            _strich(f.color, 1.6),
          );
        default:
          c.drawCircle(m + const Offset(-4, 1), 5, f);
          c.drawCircle(m + const Offset(2, -2), 6.5, f);
          c.drawCircle(m + const Offset(7, 2), 4.5, f);
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(m.dx - 9, m.dy + 1, m.dx + 11.5, m.dy + 6.5),
              const Radius.circular(3),
            ),
            f,
          );
      }
      _text(
        c,
        namen[i],
        m + const Offset(0, 34),
        weight: FontWeight.w600,
        color: an ? _ink : _soft,
      );
      c.restore();
    }
  }
}

/// Last night as a moon arc from bedtime to wake time with the sleep
/// value in the middle; below seven moons for the last nights.
class NachtBild extends StatelessWidget {
  const NachtBild({
    super.key,
    required this.bett,
    required this.auf,
    required this.wert,
    required this.unter,
    required this.naechte,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final String bett, auf;
  final String wert, unter;

  /// Hours and day letter, oldest first.
  final List<(double, String)> naechte;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _NachtMaler(v, t, bett, auf, wert, unter, naechte),
    punkte: [
      (const Rect.fromLTWH(0, 0, bildBreite, 180), tipp('s-wert', _flaeche())),
      (
        const Rect.fromLTWH(0, 180, bildBreite, 90),
        tipp('s-naechte', _flaeche()),
      ),
    ],
  );
}

class _NachtMaler extends _Maler {
  _NachtMaler(
    super.v,
    super.t,
    this.bett,
    this.auf,
    this.wert,
    this.unter,
    this.n,
  );
  final String bett, auf, wert, unter;
  final List<(double, String)> n;

  static Offset _bogen(double f) {
    final u = 1 - f;
    return Offset(
      u * u * 40 + 2 * u * f * 151 + f * f * 262,
      u * u * 150 + 2 * u * f * -30 + f * f * 150,
    );
  }

  @override
  void paint(Canvas c, Size s) {
    _sterne(c, 26, const Rect.fromLTWH(0, 0, 302, 170), t, saat: 3);
    final bogen = Path()
      ..moveTo(40, 150)
      ..quadraticBezierTo(151, -30, 262, 150);
    c.drawPath(bogen, _strich(const Color(0x29E8C98B), 2));
    final f = _teil(v, 0, .7);
    c.drawPath(_stueck(bogen, f * .82), _strich(const Color(0xFFE8C98B), 2.2));
    c.drawCircle(
      const Offset(40, 150),
      4,
      Paint()..color = const Color(0xFFE8C98B),
    );
    c.drawCircle(
      const Offset(262, 150),
      4,
      Paint()..color = const Color(0x66E8C98B),
    );
    _text(
      c,
      bett,
      const Offset(40, 170),
      sora: true,
      weight: FontWeight.w600,
      color: _ink,
    );
    _text(
      c,
      auf,
      const Offset(262, 170),
      sora: true,
      weight: FontWeight.w600,
      color: _ink,
    );
    final mm = _bogen(.82 * Curves.easeOutCubic.transform(f));
    _glow(c, mm, 18, tonSchlaf.withValues(alpha: .4));
    c.drawCircle(
      mm,
      10,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.2, -.3),
          colors: [Color(0xFFFFFFFF), Color(0xFFC9D0FA)],
        ).createShader(Rect.fromCircle(center: mm, radius: 10)),
    );
    _text(
      c,
      wert,
      const Offset(151, 108),
      size: 36,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    _text(c, unter, const Offset(151, 128), color: tonSchlaf);
    if (n.isEmpty) {
      _text(
        c,
        'Nach dem ersten Morgen siehst du hier deine Nächte',
        const Offset(151, 206),
      );
    }
    for (var i = 0; i < n.length && i < 7; i++) {
      final (h, tag) = n[i];
      final x = 151 + (i - (math.min(n.length, 7) - 1) / 2) * 37;
      const y = 200.0;
      final q = _plopp(v, .35 + i * .06);
      if (q <= 0) continue;
      final kurz = h < 6.5;
      final r = (4 + (h - 5.5) * 2.6).clamp(3.0, 12.0);
      c.save();
      c.translate(x, y);
      c.scale(q);
      c.translate(-x, -y);
      if (!kurz) {
        _glow(c, Offset(x, y), r + 5, tonSchlaf.withValues(alpha: .22));
      }
      c.drawCircle(
        Offset(x, y),
        r,
        kurz
            ? (Paint()..color = const Color(0x40CFCBE6))
            : (Paint()
                ..shader =
                    const RadialGradient(
                      center: Alignment(-.2, -.3),
                      colors: [Color(0xFFFFFFFF), Color(0xFFC9D0FA)],
                    ).createShader(
                      Rect.fromCircle(center: Offset(x, y), radius: r),
                    )),
      );
      _text(
        c,
        tag,
        Offset(x, 226),
        size: 10.5,
        weight: FontWeight.w600,
        color: i == n.length - 1 ? tonSchlaf : _soft,
      );
      c.restore();
    }
    _zeile(c, 'Großer, heller Mond = lange Nacht');
  }
}

/// The evening: a window with six stars for the journal, three candles
/// on the sill for the routine.
class AbendBild extends StatelessWidget {
  const AbendBild({
    super.key,
    required this.kerzen,
    required this.dankbar,
    required this.besser,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// Routine steps (up to three) and whether their time has come.
  final List<(String, bool)> kerzen;
  final int dankbar, besser;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _AbendMaler(v, t, kerzen, dankbar, besser),
    punkte: [
      (const Rect.fromLTWH(40, 10, 222, 120), tipp('s-journal', _flaeche())),
      (
        const Rect.fromLTWH(0, 130, bildBreite, 80),
        tipp('s-routine', _flaeche()),
      ),
    ],
  );
}

class _AbendMaler extends _Maler {
  _AbendMaler(super.v, super.t, this.k, this.dankbar, this.besser);
  final List<(String, bool)> k;
  final int dankbar, besser;

  @override
  void paint(Canvas c, Size s) {
    final fenster = RRect.fromRectAndRadius(
      const Rect.fromLTWH(42, 16, 218, 152),
      const Radius.circular(28),
    );
    c.drawRRect(
      fenster,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14110E), Color(0xFF241D16)],
        ).createShader(fenster.outerRect),
    );
    c.save();
    c.clipRRect(fenster);
    _sterne(c, 16, const Rect.fromLTWH(42, 16, 218, 140), t, saat: 11);
    c.drawCircle(
      const Offset(234, 40),
      10,
      Paint()..color = const Color(0xD9E9ECFF),
    );
    c.drawCircle(
      const Offset(239, 36),
      9,
      Paint()..color = const Color(0xFF1A1611),
    );
    c.restore();
    c.drawRRect(fenster, _strich(const Color(0x4DE8C98B), 1.5));
    const ys = [86.0, 62.0, 48.0, 48.0, 62.0, 86.0];
    for (var i = 0; i < 6; i++) {
      final m = Offset(68 + i * 30.0, ys[i]);
      final voll = i < 3 ? i < dankbar : i - 3 < besser;
      final q = _plopp(v, .2 + i * .06);
      if (q <= 0) continue;
      final stern = Path()
        ..moveTo(m.dx, m.dy - 11)
        ..quadraticBezierTo(m.dx + 1.6, m.dy - 1.6, m.dx + 11, m.dy)
        ..quadraticBezierTo(m.dx + 1.6, m.dy + 1.6, m.dx, m.dy + 11)
        ..quadraticBezierTo(m.dx - 1.6, m.dy + 1.6, m.dx - 11, m.dy)
        ..quadraticBezierTo(m.dx - 1.6, m.dy - 1.6, m.dx, m.dy - 11)
        ..close();
      c.save();
      c.translate(m.dx, m.dy);
      c.scale(q);
      c.translate(-m.dx, -m.dy);
      if (voll) {
        _glow(c, m, 10, const Color(0x66E8C98B));
        c.drawPath(stern, Paint()..color = const Color(0xFFE8C98B));
      } else {
        c.drawPath(stern, _strich(tonSchlaf, 1.3));
      }
      c.restore();
    }
    _text(c, 'dankbar', const Offset(98, 116), size: 9.5);
    _text(c, 'morgen besser', const Offset(188, 116), size: 9.5);
    final bank = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 166, 258, 12),
      const Radius.circular(6),
    );
    c.drawRRect(bank, Paint()..color = const Color(0xFF2B241D));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 166, 258, 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0x1FFFF0D7),
    );
    for (var i = 0; i < k.length && i < 3; i++) {
      final (name, brennt) = k[i];
      final x = 60 + i * 91.0;
      final q = _plopp(v, .45 + i * .07);
      if (q <= 0) continue;
      c.save();
      c.translate(x, 166);
      c.scale(q);
      c.translate(-x, -166);
      if (brennt) {
        final flacker = 1 + math.sin(t * 9 + i) * .06;
        _glow(c, Offset(x, 128), 18, const Color(0x66F7CF92));
        c.save();
        c.translate(x, 135);
        c.scale(1, flacker);
        c.drawPath(
          Path()
            ..moveTo(0, -19)
            ..quadraticBezierTo(8, -10, 0, 0)
            ..quadraticBezierTo(-8, -10, 0, -19)
            ..close(),
          Paint()..color = const Color(0xFFFFE2A8),
        );
        c.restore();
      }
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 9, 138, 18, 28),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFFEDE4D3),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 9, 138, 6, 28),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0x66FFFFFF),
      );
      c.drawLine(
        Offset(x, 138),
        Offset(x, 133),
        _strich(const Color(0xFF3A3028), 1.5),
      );
      _text(
        c,
        name,
        Offset(x, 198),
        weight: FontWeight.w600,
        color: _ink,
        maxBreite: 88,
      );
      c.restore();
    }
    if (k.isEmpty) {
      _text(c, 'Leg einmal deine Abendroutine fest', const Offset(151, 198));
    }
    _zeile(c, 'Stern = ein Satz im Journal · Kerze = Routine');
  }
}
