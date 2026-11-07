import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The pictures of the Körper pages (draft "Körper als Bilder" 4,
/// Phillip "So übernehmen" 2026-11-07): every page is one big picture on
/// deep black with glowing gold, each part keeps one quiet tone of its own.
/// All pictures are drawn on a 302 x 360 board and scaled to the screen.

/// Wraps a part of a picture so a tap opens the page behind tile [id].
typedef BildTipp = Widget Function(String id, Widget child);

const bildBreite = 302.0, bildHoehe = 360.0;

const _ink = Color(0xFFF4EEE4);
const _soft = Color(0xFF9E937F);
const _leise = Color(0xFF6F6658);
const _dunkel = Color(0xFF0B0B0B);
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
  colors: [Color(0xFF262422), Color(0xFF0C0C0B)],
).createShader(Rect.fromCircle(center: m, radius: r));

/// Scales what [male] draws around [m] (pop-in animation).
void _skaliert(Canvas c, Offset m, double q, void Function() male) {
  if (q <= 0) return;
  c.save();
  c.translate(m.dx, m.dy);
  c.scale(q);
  c.translate(-m.dx, -m.dy);
  male();
  c.restore();
}

/// A soft blurred glow around a path.
Paint _leuchtStrich(Color farbe, double breite, double blur) =>
    _strich(farbe, breite)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

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
    _text(c, s, const Offset(151, 342), color: _leise);

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

/// Two texts side by side in one line, centred (or left) on [p]; p.dy is
/// the baseline.
void _text2(
  Canvas c,
  String a,
  String b,
  Offset p, {
  double size = 11,
  Color farbeA = _ink,
  Color farbeB = _soft,
  FontWeight weightA = FontWeight.w600,
  FontWeight weightB = FontWeight.w400,
  bool soraA = false,
  TextAlign align = TextAlign.center,
  double maxBreite = 290,
}) {
  final tp = TextPainter(
    text: TextSpan(
      style: TextStyle(fontFamily: 'Figtree', fontSize: size, height: 1),
      children: [
        TextSpan(
          text: a,
          style: TextStyle(
            fontFamily: soraA ? 'Sora' : 'Figtree',
            fontWeight: weightA,
            color: farbeA,
          ),
        ),
        TextSpan(
          text: b,
          style: TextStyle(fontWeight: weightB, color: farbeB),
        ),
      ],
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxBreite);
  final x = align == TextAlign.left ? p.dx : p.dx - tp.width / 2;
  final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  tp.paint(c, Offset(x, p.dy - base));
}

/// A gold tick inside a circle of radius 10 around [m].
void _haken(Canvas c, Offset m, double r) {
  c.drawCircle(m, r, Paint()..shader = _goldR(m, r));
  c.drawPath(
    Path()
      ..moveTo(m.dx - r * .45, m.dy)
      ..relativeLineTo(r * .3, r * .3)
      ..relativeLineTo(r * .55, -r * .6),
    _strich(_goldInk, 2),
  );
}

// ------------------------------------------------------------- Training

/// One exercise of today: name, sets and weight, done, its sets.
typedef HeuteUebung = ({
  String name,
  String ziel,
  bool fertig,
  int saetze,
  int fertigeSaetze,
});

/// Today's exercises as plates on a bar; done ones are gold. Above the
/// training's name, below the next exercise and its sets.
class TrainingHeuteBild extends StatelessWidget {
  const TrainingHeuteBild({
    super.key,
    required this.uebungen,
    required this.titel,
    required this.unter,
    required this.tipp,
    required this.v,
    required this.t,
    this.leer,
  });

  final List<HeuteUebung> uebungen;

  /// Today's training, e.g. "Push", and "heute 17:30 · 4 Übungen".
  final String titel, unter;

  /// Shown instead of the next exercise: no plan yet, or a free day.
  final ({String label, String titel, String unter})? leer;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _HeuteMaler(v, t, uebungen, leer, titel, unter),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('t-heute', _flaeche()),
      ),
    ],
  );
}

class _HeuteMaler extends _Maler {
  _HeuteMaler(super.v, super.t, this.u, this.leer, this.titel, this.unter);
  final List<HeuteUebung> u;
  final ({String label, String titel, String unter})? leer;
  final String titel, unter;

  @override
  void paint(Canvas c, Size s) {
    final kopf = _teil(v, 0, .3);
    if (kopf > 0 && titel.isNotEmpty) {
      c.saveLayer(
        Offset.zero & s,
        Paint()..color = Color.fromRGBO(0, 0, 0, kopf),
      );
      _text(
        c,
        titel,
        const Offset(151, 44),
        size: 22,
        sora: true,
        weight: FontWeight.w700,
        color: _ink,
      );
      _text(c, unter, const Offset(151, 64), size: 11.5);
      c.restore();
    }
    c.save();
    c.translate(0, 48);
    final n = leer != null ? 4 : math.min(u.length, 6);
    final r = n <= 4 ? 24.0 : 19.0;
    c.drawOval(
      Rect.fromCenter(center: const Offset(151, 140), width: 256, height: 24),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 108, 282, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF3A3836),
    );
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
      final m = Offset(xs[i], 112);
      _skaliert(c, m, _plopp(v, .05 + i * .07), () {
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
            _strich(
              i == naechste ? tonTraining : _rand,
              i == naechste ? 1.6 : 1,
            ),
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
      });
    }
    final fertige = u.where((x) => x.fertig).length;
    _skaliert(c, const Offset(151, 112), _plopp(v, 0), () {
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
    });
    c.restore();
    final unten = _teil(v, .35, .7);
    if (unten > 0) {
      final o = Offset(0, 52 + (1 - unten) * 8);
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
        Paint()..color = Color.fromRGBO(0, 0, 0, unten),
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
    // The sets of the next exercise.
    final saetze = naechste < 0 ? 0 : math.min(u[naechste].saetze, 6);
    if (saetze > 0) {
      _text(
        c,
        'SÄTZE',
        const Offset(151, 292),
        size: 10,
        weight: FontWeight.w700,
        abstand: 1.2,
        color: _leise,
      );
      for (var i = 0; i < saetze; i++) {
        final m = Offset(151 + (i - (saetze - 1) / 2) * 30, 312);
        final an = i < u[naechste].fertigeSaetze;
        _skaliert(c, m, _plopp(v, .5 + i * .05), () {
          if (an) {
            c.drawCircle(m, 10, Paint()..shader = _goldR(m, 10));
          } else {
            c.drawCircle(m, 10, Paint()..color = const Color(0x0AFFF0D7));
            c.drawCircle(m, 10, _strich(_rand, 1));
          }
          _text(
            c,
            '${i + 1}',
            m + const Offset(0, 4),
            size: 10,
            sora: true,
            weight: FontWeight.w700,
            color: an ? _goldInk : _soft,
          );
        });
      }
    }
    _zeile(
      c,
      leer != null
          ? 'Tipp aufs Bild, um weiterzumachen'
          : 'Tipp aufs Bild, dann trägst du ein',
    );
  }
}

/// One day of the plan: "Mo", training name ('' = rest), time, exercises,
/// done (null = no training), today.
typedef WochenTag = ({
  String tag,
  String name,
  String zeit,
  String uebungen,
  bool? fertig,
  bool heute,
});

/// The week as a training plan: one row per day, Monday to Sunday.
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

  @override
  void paint(Canvas c, Size s) {
    final plan = tage.take(7).toList();
    final geplant = plan.where((d) => d.fertig != null).length;
    final gemacht = plan.where((d) => d.fertig == true).length;
    _text(
      c,
      'DEIN PLAN DIESE WOCHE',
      const Offset(22, 34),
      size: 10,
      weight: FontWeight.w700,
      abstand: 1.2,
      color: tonTraining,
      align: TextAlign.left,
    );
    _text(
      c,
      geplant == 0 ? 'kein Plan' : '$gemacht von $geplant',
      const Offset(280, 36),
      size: 20,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
      align: TextAlign.right,
    );
    if (geplant > 0) {
      final w = (258 - 7.0 * (geplant - 1)) / geplant;
      for (var i = 0; i < geplant; i++) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(22 + i * (w + 7), 48, w, 6),
          const Radius.circular(3),
        );
        _skaliert(c, r.center, _plopp(v, .02 + i * .04), () {
          c.drawRRect(
            r,
            i < gemacht
                ? (Paint()..shader = _goldLinear(r.outerRect))
                : (Paint()..color = const Color(0x14FFF0D7)),
          );
        });
      }
    }
    // Row heights: shrink a little when the week is full of training.
    final voll = geplant * 34.0 + (plan.length - geplant) * 24 + 6 * 8;
    final eng = voll > 260;
    final hT = eng ? 30.0 : 34.0,
        hP = eng ? 22.0 : 24.0,
        abstand = eng ? 6.0 : 8.0;
    var y = 66.0;
    for (var i = 0; i < plan.length; i++) {
      final d = plan[i];
      final training = d.fertig != null;
      final h = training ? hT : hP;
      final cy = y + h / 2;
      final zeile = RRect.fromRectAndRadius(
        Rect.fromLTWH(16, y, 270, h),
        Radius.circular(h / 2),
      );
      _skaliert(c, Offset(151, cy), _plopp(v, .08 + i * .06), () {
        if (d.heute) {
          c.drawRRect(
            zeile.inflate(2),
            Paint()
              ..color = const Color(0x1AF5DFAE)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
          );
        }
        c.drawRRect(
          zeile,
          Paint()
            ..color = training
                ? const Color(0xFF121211)
                : const Color(0xFF0A0A0A),
        );
        c.drawRRect(
          zeile,
          _strich(
            d.heute
                ? tonTraining
                : training
                ? _rand
                : const Color(0x0DFFF0D7),
            d.heute ? 1.4 : 1,
          ),
        );
        _text(
          c,
          d.tag,
          Offset(36, cy + 4),
          weight: FontWeight.w700,
          color: d.heute
              ? tonTraining
              : training
              ? _soft
              : _leise,
          align: TextAlign.left,
        );
        if (training) {
          final zeit = [
            if (d.zeit.isNotEmpty) d.zeit,
            if (d.heute) 'heute',
          ].join(' · ');
          _text2(
            c,
            d.name,
            zeit.isEmpty ? '' : '  $zeit',
            Offset(64, d.uebungen.isEmpty ? cy + 4.5 : y + (eng ? 13 : 15)),
            size: 12,
            soraA: true,
            weightA: FontWeight.w700,
            farbeB: d.heute ? tonTraining : _soft,
            weightB: FontWeight.w600,
            align: TextAlign.left,
            maxBreite: 180,
          );
          if (d.uebungen.isNotEmpty) {
            _text(
              c,
              d.uebungen,
              Offset(64, y + (eng ? 25 : 28)),
              size: 9.5,
              color: _leise,
              align: TextAlign.left,
              maxBreite: 180,
            );
          }
          final m = Offset(266, cy);
          if (d.fertig == true) {
            _haken(c, m, 10);
          } else if (d.heute) {
            final puls = (t * .42) % 1;
            c.drawCircle(
              m,
              9 + 3 * math.sin(puls * math.pi),
              _strich(tonTraining, 1.6),
            );
            c.drawCircle(m, 3.5, Paint()..color = tonTraining);
          } else {
            c.drawCircle(m, 10, _strich(_rand, 1.2));
          }
        } else {
          _text(
            c,
            'Pause',
            Offset(64, cy + 4),
            size: 10.5,
            color: _leise,
            align: TextAlign.left,
          );
          c.drawCircle(
            Offset(266, cy),
            5,
            Paint()..color = const Color(0x24FFF0D7),
          );
          c.drawCircle(
            Offset(268.5, cy - 2),
            4.4,
            Paint()..color = const Color(0xFF0A0A0A),
          );
        }
      });
      y += h + abstand;
    }
    _zeile(
      c,
      geplant == 0
          ? 'Leg einmal deinen Plan an'
          : 'Gold = geschafft · Ring = heute · Zeile tippen = Übungen',
    );
  }
}

/// One exercise's best weights as gold columns, one per training; every
/// record grows a sprout on its column.
class TrainingVerlaufBild extends StatelessWidget {
  const TrainingVerlaufBild({
    super.key,
    required this.uebungen,
    required this.werte,
    required this.labels,
    required this.einheit,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// Up to three exercises as chips, the first is shown.
  final List<String> uebungen;
  final List<double> werte;

  /// Under each column, e.g. "3.11." or "heute".
  final List<String> labels;
  final String einheit;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _VerlaufMaler(v, t, uebungen, werte, labels, einheit),
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
    this.labels,
    this.einheit,
  );
  final List<String> namen;
  final List<double> werte;
  final List<String> labels;
  final String einheit;

  @override
  void paint(Canvas c, Size s) {
    if (namen.isNotEmpty) _pillen(c, namen.take(3).toList(), 0);
    final mit = einheit.isEmpty ? '' : ' $einheit';
    if (werte.length < 2) {
      _text(
        c,
        werte.isEmpty ? 'Noch keine Einträge' : '${_zahl(werte.first)}$mit',
        const Offset(151, 160),
        size: 18,
        sora: true,
        weight: FontWeight.w700,
        color: _ink,
      );
      _text(
        c,
        'Nach dem zweiten Training wachsen hier deine Säulen',
        const Offset(151, 180),
      );
      _zeile(c, 'Eine Säule pro Training · Trieb = Rekord');
      return;
    }
    final w = werte.length > 8 ? werte.sublist(werte.length - 8) : werte;
    final lab = labels.length > 8 ? labels.sublist(labels.length - 8) : labels;
    final hi = werte.reduce(math.max);
    final lo = w.reduce(math.min), top = w.reduce(math.max);
    final spanne = top - lo;
    final neu =
        werte.last >= hi &&
        werte.sublist(0, werte.length - 1).every((x) => x < werte.last);
    _text(
      c,
      '${_zahl(hi)}$mit',
      const Offset(22, 82),
      size: 26,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
      align: TextAlign.left,
    );
    final plus = werte.last - werte.first;
    _text(
      c,
      '${neu ? 'neuer Rekord' : 'dein Rekord'} · '
      '${plus >= 0 ? '+' : '−'}${_zahl(plus.abs())}$mit seit Start',
      const Offset(22, 100),
      color: tonTraining,
      align: TextAlign.left,
    );
    c.drawLine(
      const Offset(16, 300),
      const Offset(286, 300),
      _strich(const Color(0x1AFFF0D7), 1),
    );
    final n = w.length;
    final schritt = math.min(33.0, 240 / (n - 1));
    final x0 = 151 - (n - 1) * schritt / 2;
    var best = werte.length > n
        ? werte.sublist(0, werte.length - n).reduce(math.max)
        : double.negativeInfinity;
    for (var i = 0; i < n; i++) {
      final x = x0 + i * schritt;
      final hVoll = spanne == 0 ? 110.0 : 65 + 97 * (w[i] - lo) / spanne;
      final wachs = Curves.easeOutCubic.transform(
        _teil(v, .05 + i * .05, .45 + i * .05),
      );
      final h = hVoll * wachs;
      final letzt = i == n - 1;
      final rekord = i > 0 || werte.length > n ? w[i] > best : false;
      if (w[i] > best) best = w[i];
      if (h > 0) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 10, 300 - h, 20, h),
          const Radius.circular(7),
        );
        if (letzt) {
          c.drawRRect(
            r.inflate(4),
            Paint()
              ..color = const Color(0x38F5DFAE)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
          );
        }
        c.saveLayer(
          r.outerRect.inflate(1),
          Paint()..color = Color.fromRGBO(0, 0, 0, letzt ? 1 : .55 + i * .05),
        );
        c.drawRRect(
          r,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5DFAE), Color(0xBFC49A55), Color(0x14C49A55)],
              stops: [0, .55, 1],
            ).createShader(Rect.fromLTWH(x - 10, 300 - hVoll, 20, hVoll)),
        );
        c.restore();
      }
      _text(
        c,
        i < lab.length ? lab[i] : '',
        Offset(x, 318),
        size: 10,
        weight: FontWeight.w600,
        color: letzt ? tonTraining : _soft,
        maxBreite: schritt + 4,
      );
      if (rekord) {
        final m = Offset(x, 300 - hVoll);
        _skaliert(c, m, _plopp(v, .5 + i * .05), () {
          c.drawPath(
            Path()
              ..moveTo(m.dx, m.dy - 3)
              ..quadraticBezierTo(m.dx - 2, m.dy - 14, m.dx, m.dy - 25),
            _strich(const Color(0xFFC9A25C), 1.8),
          );
          for (final (dx, dy, a) in [(-6.0, -17.0, -.56), (6.0, -23.0, .56)]) {
            c.save();
            c.translate(m.dx + dx, m.dy + dy);
            c.rotate(a);
            final b = Rect.fromCenter(
              center: Offset.zero,
              width: 13,
              height: 6.4,
            );
            c.drawOval(b, Paint()..shader = _goldLinear(b));
            c.restore();
          }
        });
      }
    }
    _zeile(c, 'Eine Säule pro Training · Trieb = Rekord');
  }
}

// ------------------------------------------------------------ Ernährung

/// The energy curve of the day as three bezier pieces (draft 4).
const _kurve = [
  [Offset(14, 150), Offset(50, 74), Offset(82, 62), Offset(110, 102)],
  [Offset(110, 102), Offset(138, 142), Offset(152, 166), Offset(182, 118)],
  [Offset(182, 118), Offset(212, 70), Offset(242, 74), Offset(288, 132)],
];

Offset _kp(List<Offset> s, double t) {
  final u = 1 - t;
  return s[0] * (u * u * u) +
      s[1] * (3 * u * u * t) +
      s[2] * (3 * u * t * t) +
      s[3] * (t * t * t);
}

/// The point of the curve at [x].
Offset _aufKurve(double x) {
  final s = _kurve.firstWhere((g) => x <= g[3].dx, orElse: () => _kurve[2]);
  var a = 0.0, b = 1.0;
  for (var i = 0; i < 30; i++) {
    final m = (a + b) / 2;
    if (_kp(s, m).dx < x) {
      a = m;
    } else {
      b = m;
    }
  }
  return _kp(s, a);
}

Path _kurvenPfad() {
  final p = Path()..moveTo(_kurve[0][0].dx, _kurve[0][0].dy);
  for (final s in _kurve) {
    p.cubicTo(s[1].dx, s[1].dy, s[2].dx, s[2].dy, s[3].dx, s[3].dy);
  }
  return p;
}

/// Meals as small plates on a glowing gold band, the plate and the glass.
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
      (const Rect.fromLTWH(0, 0, bildBreite, 200), tipp('e-essen', _flaeche())),
      (const Rect.fromLTWH(0, 200, 182, 160), tipp('e-essen', _flaeche())),
      (const Rect.fromLTWH(182, 200, 120, 160), tipp('e-trinken', _flaeche())),
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

  @override
  void paint(Canvas c, Size s) {
    _text(
      c,
      'DEINE ENERGIE HEUTE',
      const Offset(22, 34),
      size: 10,
      weight: FontWeight.w700,
      abstand: 1.2,
      color: tonErnaehrung,
      align: TextAlign.left,
    );
    final kurve = _kurvenPfad();
    final a = _teil(v, .05, .5);
    final f = _teil(v, 0, .55);
    c.drawPath(
      _stueck(kurve, f),
      _leuchtStrich(Color.fromRGBO(245, 223, 174, .13 * a), 26, 8),
    );
    c.drawPath(
      _stueck(kurve, f),
      _strich(Color.fromRGBO(232, 201, 139, .14 * a), 12),
    );
    c.drawPath(_stueck(kurve, f), _leuchtStrich(const Color(0x8CF5DFAE), 6, 5));
    c.drawPath(
      _stueck(kurve, f),
      _strich(Colors.white, 4.5)
        ..shader = const LinearGradient(
          colors: [Color(0xFFA8823F), Color(0xFFF5DFAE), Color(0xFFC49A55)],
          stops: [0, .45, 1],
        ).createShader(const Rect.fromLTWH(14, 0, 274, 200)),
    );
    final sonne = _teil(v, .45, .9);
    if (sonne > 0) {
      final sm = _aufKurve(14 + jetzt.clamp(0.0, 1.0) * 274 * sonne);
      _glow(c, sm, 14, const Color(0x59F5DFAE));
      c.drawCircle(sm, 5, Paint()..color = const Color(0xFFFFF6E2));
      if (sonne >= 1) {
        _text(
          c,
          'jetzt',
          sm + const Offset(0, -16),
          size: 10,
          weight: FontWeight.w700,
          color: _goldHell,
        );
      }
    }
    for (var i = 0; i < m.length; i++) {
      final (pos, gegessen, zeit) = m[i];
      final p = _aufKurve(14 + pos.clamp(0.0, 1.0) * 274);
      _skaliert(c, p, _plopp(v, .3 + i * .07), () {
        c.drawCircle(
          p + const Offset(0, 1.5),
          12,
          Paint()..color = const Color(0x99000000),
        );
        if (gegessen) {
          c.drawCircle(p, 12, Paint()..shader = _goldR(p, 12));
        } else {
          c.drawCircle(p, 12, Paint()..color = const Color(0xFF141413));
          c.drawCircle(p, 12, _strich(tonErnaehrung, 1.4));
        }
        c.drawCircle(
          p,
          7.5,
          _strich(
            gegessen ? const Color(0x591A130B) : const Color(0x66DCCB92),
            1,
          ),
        );
        _text(c, zeit, p + const Offset(0, -19), size: 10);
      });
    }
    c.save();
    c.translate(0, 80);
    // The plate: three arcs, one per part.
    const tm = Offset(88, 178);
    _skaliert(c, tm, _plopp(v, .35), () {
      c.drawCircle(tm, 34, Paint()..shader = _dunkelR(tm, 34));
      final rect = Rect.fromCircle(center: tm, radius: 44);
      for (var i = 0; i < 3; i++) {
        final start = i / 3 * math.pi * 2 - math.pi / 2 + .08;
        const lang = math.pi * 2 / 3 - .16;
        c.drawArc(
          rect,
          start,
          lang,
          false,
          _strich(const Color(0x12FFF0D7), 10),
        );
        final w = (i < teller.length ? teller[i] : 0.0).clamp(0.0, 1.0);
        if (w > .01) {
          c.drawArc(
            rect,
            start,
            lang * w * _teil(v, .4, .9),
            false,
            _strich(
              tonErnaehrung.withValues(alpha: const [1.0, .95, .6][i]),
              10,
            ),
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
    });
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
    c.restore();
    _zeile(c, 'Teller tippen = gegessen · Glas tippen = ein Glas Wasser');
  }
}

/// One dish of the cookbook: name, cooked and kept (full leaf), rescue
/// dish, today's dish for the user.
typedef KuechenBlatt = ({String name, bool voll, bool rettung, bool heute});

/// The cookbook as a growing plant: every dish a leaf with its name; a bud
/// on top for the next dish from the coach, the basket at the bottom.
class KuecheBild extends StatelessWidget {
  const KuecheBild({
    super.key,
    required this.blaetter,
    required this.korb,
    required this.tipp,
    required this.v,
    required this.t,
    this.knospe,
  });

  final List<KuechenBlatt> blaetter;
  final int korb;

  /// When the next dish opens, e.g. "nach 2 Mal kochen"; null hides the bud.
  final String? knospe;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _KuecheMaler(v, t, blaetter, korb, knospe),
    punkte: [
      (const Rect.fromLTWH(0, 0, bildBreite, 270), tipp('e-koch', _flaeche())),
      (const Rect.fromLTWH(0, 270, 230, 90), tipp('e-koch', _flaeche())),
      (const Rect.fromLTWH(230, 270, 72, 72), tipp('e-einkauf', _flaeche())),
    ],
  );
}

class _KuecheMaler extends _Maler {
  _KuecheMaler(super.v, super.t, this.b, this.korb, this.knospe);
  final List<KuechenBlatt> b;
  final int korb;
  final String? knospe;

  static double _sx(double y) =>
      151 - math.sin((y - 60) / 262 * math.pi * 2) * 16;

  @override
  void paint(Canvas c, Size s) {
    _pillen(c, const ['Alle', 'Basis', 'Rettung'], 0);
    final stiel = Path()..moveTo(_sx(322), 322);
    for (var k = 1; k <= 26; k++) {
      final y = 322.0 - k * 10;
      stiel.lineTo(_sx(y), y);
    }
    c.drawPath(
      _stueck(stiel, _teil(v, 0, .55)),
      _strich(const Color(0xFF9C8150), 3),
    );
    final n = math.min(b.length, 6);
    for (var i = 0; i < n; i++) {
      final y = 300.0 - i * 38;
      final dir = i.isOdd ? 1.0 : -1.0;
      final x = _sx(y), e = x + dir * 36;
      final g = b[i];
      _skaliert(c, Offset(x, y), _plopp(v, .25 + i * .07), () {
        if (g.heute) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(x + dir * 18, y - 3),
              width: 52,
              height: 28,
            ),
            Paint()
              ..color = const Color(0x4DF5DFAE)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
          );
        }
        final blatt = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + dir * 14, y - 17, e, y - 6)
          ..quadraticBezierTo(x + dir * 20, y + 9, x, y)
          ..close();
        if (g.voll) {
          c.drawPath(blatt, Paint()..shader = _goldLinear(blatt.getBounds()));
        } else {
          c.drawPath(blatt, Paint()..color = const Color(0xFF121211));
          c.drawPath(blatt, _strich(tonErnaehrung, 1.4));
        }
        c.drawPath(
          Path()
            ..moveTo(x + dir * 4, y - 1)
            ..quadraticBezierTo(x + dir * 18, y - 6, e - dir * 5, y - 6),
          _strich(
            g.voll ? const Color(0x4D1A130B) : const Color(0x73DCCB92),
            1,
          ),
        );
        final al = dir > 0 ? TextAlign.left : TextAlign.right;
        _text(
          c,
          g.name,
          Offset(e + dir * 8, y - 2),
          size: 11.5,
          weight: FontWeight.w600,
          color: g.heute ? _goldHell : _ink,
          align: al,
          maxBreite: 96,
        );
        _text(
          c,
          g.heute
              ? 'heute für dich'
              : g.voll
              ? 'Basis'
              : 'Rettung',
          Offset(e + dir * 8, y + 12),
          size: 9.5,
          color: g.heute ? tonErnaehrung : _leise,
          align: al,
          maxBreite: 96,
        );
      });
    }
    if (b.isEmpty) {
      _text(
        c,
        'Jedes Gericht, das du kochst, wird ein Blatt',
        const Offset(151, 196),
      );
    }
    if (knospe != null) {
      final x = _sx(64);
      _skaliert(c, Offset(x, 64), _plopp(v, .6), () {
        _glow(c, Offset(x, 64), 14, const Color(0x2EF5DFAE));
        final k = Path()
          ..moveTo(x, 72)
          ..quadraticBezierTo(x - 9, 62, x, 52)
          ..quadraticBezierTo(x + 9, 62, x, 72)
          ..close();
        c.drawPath(k, Paint()..color = const Color(0xFF121211));
        c.drawPath(k, _strich(tonErnaehrung, 1.4));
        _text(
          c,
          'neu vom Coach',
          Offset(x + 16, 62),
          size: 10.5,
          weight: FontWeight.w600,
          color: tonErnaehrung,
          align: TextAlign.left,
        );
        _text(
          c,
          knospe!,
          Offset(x + 16, 75),
          size: 9.5,
          color: _leise,
          align: TextAlign.left,
        );
      });
    }
    const km = Offset(262, 300);
    _skaliert(c, km, _plopp(v, .45), () {
      c.drawCircle(km, 22, Paint()..shader = _dunkelR(km, 22));
      c.drawCircle(km, 22, _strich(_rand, 1));
      c.drawPath(
        Path()
          ..moveTo(251, 295)
          ..lineTo(273, 295)
          ..lineTo(270, 308)
          ..lineTo(254, 308)
          ..close(),
        _strich(_ink, 1.5),
      );
      c.drawPath(
        Path()
          ..moveTo(256, 295)
          ..lineTo(262, 288)
          ..lineTo(268, 295),
        _strich(_ink, 1.5),
      );
      if (korb > 0) {
        const bm = Offset(279, 283);
        c.drawCircle(bm, 9, Paint()..shader = _goldR(bm, 9));
        _text(
          c,
          '$korb',
          bm + const Offset(0, 4),
          size: 10,
          sora: true,
          weight: FontWeight.w700,
          color: _goldInk,
        );
      }
    });
    _zeile(
      c,
      b.isEmpty
          ? 'Jedes Gericht, das du kochst, wird ein Blatt'
          : 'Volles Blatt = Basis · leeres Blatt = Rettung',
    );
  }
}

/// The weight as a scale: the needle swings to today's weight, the gold
/// band is the goal range, the dashed line the weight two weeks ago.
/// On top the kcal goal, below the supplement capsules.
class ZielBild extends StatelessWidget {
  const ZielBild({
    super.key,
    required this.kcal,
    required this.kg,
    required this.kgAlt,
    required this.bereich,
    required this.unter,
    required this.unterGold,
    required this.kapseln,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final int? kcal;
  final double? kg, kgAlt;

  /// The goal range, from and to kg.
  final (double, double)? bereich;

  /// Under the weight, e.g. "−0,6 in 2 Wochen · " and "passt zum Ziel".
  final String unter, unterGold;

  /// Name and taken.
  final List<(String, bool)> kapseln;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _ZielMaler(
      v,
      t,
      kcal,
      kg,
      kgAlt,
      bereich,
      unter,
      unterGold,
      kapseln,
    ),
    punkte: [
      (const Rect.fromLTWH(0, 0, bildBreite, 272), tipp('e-ziel', _flaeche())),
      (const Rect.fromLTWH(0, 272, bildBreite, 88), tipp('e-supp', _flaeche())),
    ],
  );
}

class _ZielMaler extends _Maler {
  _ZielMaler(
    super.v,
    super.t,
    this.kcal,
    this.kg,
    this.kgAlt,
    this.bereich,
    this.unter,
    this.unterGold,
    this.k,
  );
  final int? kcal;
  final double? kg, kgAlt;
  final (double, double)? bereich;
  final String unter, unterGold;
  final List<(String, bool)> k;

  static const _m = Offset(151, 212);
  static const _r = 112.0;

  /// Angle in degrees, 0 = up, clockwise.
  Offset _wp(double a, double r) => Offset(
    _m.dx + r * math.sin(a * math.pi / 180),
    _m.dy - r * math.cos(a * math.pi / 180),
  );

  void _bogen(Canvas c, double a0, double a1, Paint p) => c.drawArc(
    Rect.fromCircle(center: _m, radius: _r),
    (a0 - 90) * math.pi / 180,
    (a1 - a0) * math.pi / 180,
    false,
    p..strokeCap = StrokeCap.butt,
  );

  @override
  void paint(Canvas c, Size s) {
    // kcal pill on top.
    final pille = RRect.fromRectAndRadius(
      const Rect.fromLTWH(46, 14, 210, 32),
      const Radius.circular(16),
    );
    _skaliert(c, pille.center, _plopp(v, 0), () {
      c.drawRRect(pille, Paint()..color = const Color(0x0AFFF0D7));
      c.drawRRect(pille, _strich(_rand, 1));
      _text2(
        c,
        kcal == null ? 'kcal-Ziel' : '${_tausend(kcal!)} kcal',
        kcal == null ? '  einrichten' : '  am Tag · Orientierung',
        const Offset(151, 35),
        size: 12,
        soraA: true,
        weightA: FontWeight.w700,
        maxBreite: 200,
      );
    });
    final mitte = (kgAlt ?? kg ?? 0).roundToDouble();
    double winkel(double w) => ((w - mitte) / 4 * 90).clamp(-90.0, 90.0);
    _bogen(c, -90, 90, _strich(const Color(0x0FFFF0D7), 18));
    if (bereich != null) {
      final (von, bis) = bereich!;
      final a0 = winkel(von), a1 = winkel(bis);
      final f = _teil(v, .05, .6);
      _bogen(
        c,
        a0,
        a0 + (a1 - a0) * f,
        _leuchtStrich(const Color(0x2EF5DFAE), 22, 8),
      );
      _bogen(
        c,
        a0,
        a0 + (a1 - a0) * f,
        _strich(Colors.white, 18)
          ..shader = _goldLinear(Rect.fromCircle(center: _m, radius: _r))
          ..color = const Color(0xD9FFFFFF),
      );
      final z = _wp((a0 + a1) / 2, _r + 22);
      _text(
        c,
        'ZIEL',
        z + const Offset(0, 4),
        size: 10,
        weight: FontWeight.w700,
        abstand: 1,
        color: tonErnaehrung,
      );
    }
    for (var i = 0; i <= 32; i++) {
      final w = mitte - 4 + i * .25;
      final a = winkel(w);
      final gross = i % 4 == 0;
      c.drawLine(
        _wp(a, _r - 15),
        _wp(a, _r - 15 - (gross ? 10 : 5)),
        _strich(
          gross ? const Color(0x73FFF0D7) : const Color(0x29FFF0D7),
          gross ? 1.6 : 1,
        ),
      );
      if (gross) {
        _text(
          c,
          _zahl(w),
          _wp(a, _r - 40) + const Offset(0, 4),
          size: 10,
          color: _leise,
        );
      }
    }
    if (kgAlt != null) {
      final a = winkel(kgAlt!);
      for (var r = _r - 4; r > _r - 62; r -= 7) {
        c.drawLine(
          _wp(a, r),
          _wp(a, math.max(r - 3, _r - 62)),
          _strich(const Color(0x38FFF0D7), 2),
        );
      }
    }
    if (kg != null) {
      final ziel = winkel(kg!);
      final q = Curves.easeOutBack.transform(_teil(v, .1, .8));
      final a = -88 + (ziel + 88) * q;
      c.save();
      c.translate(_m.dx, _m.dy);
      c.rotate(a * math.pi / 180);
      final nadel = Path()
        ..moveTo(-3.2, 0)
        ..lineTo(0, -_r + 6)
        ..lineTo(3.2, 0)
        ..close();
      c.drawPath(
        nadel,
        Paint()
          ..color = const Color(0x99F5DFAE)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      c.drawPath(nadel, Paint()..color = _goldHell);
      c.restore();
    }
    c.drawCircle(_m, 9, Paint()..shader = _goldR(_m, 9));
    c.drawCircle(_m, 3, Paint()..color = _goldInk);
    _text(
      c,
      kg == null ? 'Gewicht eintragen' : '${_zahl(kg!)} kg',
      const Offset(151, 250),
      size: kg == null ? 20 : 28,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    _text2(
      c,
      unter,
      unterGold,
      const Offset(151, 268),
      farbeA: _soft,
      weightA: FontWeight.w400,
      farbeB: tonErnaehrung,
    );
    final n = math.min(k.length, 4);
    if (n == 0) {
      _text(
        c,
        'Supplements einmal festlegen, dann abhaken',
        const Offset(151, 300),
      );
    }
    final w = n <= 3 ? 82.0 : 64.0;
    final x0 = 151 - (n * w + (n - 1) * 8) / 2;
    for (var i = 0; i < n; i++) {
      final (name, genommen) = k[i];
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x0 + i * (w + 8), 280, w, 32),
        const Radius.circular(16),
      );
      _skaliert(c, r.center, _plopp(v, .4 + i * .07), () {
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
      });
    }
    _zeile(
      c,
      [
        if (kgAlt != null) 'Gestrichelt = vor 2 Wochen',
        if (n > 0) 'Kapsel tippen = genommen',
      ].join(' · '),
    );
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
      const Rect.fromLTWH(0, 0, 302, 250),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050505),
            Color(0xFF15110A),
            Color(0xFF7A5C2C),
            Color(0xFFE3BC74),
          ],
          stops: [0, .55, .85, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 302, 250)),
    );
    _sterne(c, 22, const Rect.fromLTWH(0, 0, 302, 140), t);
    final hoch = Curves.easeOutCubic.transform(_teil(v, 0, .7));
    final sm = Offset(151, 232 + (1 - hoch) * 60);
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
      ..moveTo(0, 248)
      ..quadraticBezierTo(76, 232, 151, 242)
      ..quadraticBezierTo(226, 252, 302, 236)
      ..lineTo(302, 360)
      ..lineTo(0, 360)
      ..close();
    c.drawPath(berg, Paint()..color = const Color(0xFF080808));
    _text(
      c,
      'WIE BIST DU AUFGEWACHT?',
      const Offset(151, 276),
      size: 10,
      weight: FontWeight.w700,
      abstand: 1.2,
      color: tonSchlaf,
    );
    const namen = ['Frisch', 'Okay', 'Gerädert'];
    for (var i = 0; i < 3; i++) {
      final m = Offset(79 + i * 72.0, 304);
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
      (const Rect.fromLTWH(0, 0, bildBreite, 236), tipp('s-wert', _flaeche())),
      (
        const Rect.fromLTWH(0, 236, bildBreite, 124),
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
      u * u * 180 + 2 * u * f * 0 + f * f * 180,
    );
  }

  @override
  void paint(Canvas c, Size s) {
    _sterne(c, 30, const Rect.fromLTWH(0, 0, 302, 200), t, saat: 3);
    final bogen = Path()
      ..moveTo(40, 180)
      ..quadraticBezierTo(151, 0, 262, 180);
    c.drawPath(bogen, _strich(const Color(0x29E8C98B), 2));
    final f = _teil(v, 0, .7);
    c.drawPath(_stueck(bogen, f * .82), _strich(const Color(0xFFE8C98B), 2.2));
    c.drawCircle(
      const Offset(40, 180),
      4,
      Paint()..color = const Color(0xFFE8C98B),
    );
    c.drawCircle(
      const Offset(262, 180),
      4,
      Paint()..color = const Color(0x66E8C98B),
    );
    _text(
      c,
      bett,
      const Offset(40, 200),
      sora: true,
      weight: FontWeight.w600,
      color: _ink,
    );
    _text(
      c,
      auf,
      const Offset(262, 200),
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
      const Offset(151, 138),
      size: 36,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    _text(c, unter, const Offset(151, 158), color: tonSchlaf);
    if (n.isEmpty) {
      _text(
        c,
        'Nach dem ersten Morgen siehst du hier deine Nächte',
        const Offset(151, 292),
      );
    }
    for (var i = 0; i < n.length && i < 7; i++) {
      final (h, tag) = n[i];
      final x = 151 + (i - (math.min(n.length, 7) - 1) / 2) * 37;
      const y = 286.0;
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
        Offset(x, 312),
        size: 10.5,
        weight: FontWeight.w600,
        color: i == n.length - 1 ? tonSchlaf : _soft,
      );
      c.restore();
    }
    _zeile(c, 'Großer, heller Mond = lange Nacht');
  }
}

/// The evening: a big window with six stars for the journal, three
/// candles on the sill for the routine; below the steps to Gute Nacht.
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
      (const Rect.fromLTWH(34, 14, 234, 124), tipp('s-journal', _flaeche())),
      (
        const Rect.fromLTWH(0, 138, bildBreite, 120),
        tipp('s-routine', _flaeche()),
      ),
      (
        const Rect.fromLTWH(0, 258, bildBreite, 102),
        tipp('s-journal', _flaeche()),
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
      const Rect.fromLTWH(34, 14, 234, 196),
      const Radius.circular(30),
    );
    c.drawRRect(
      fenster,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050506), Color(0xFF17150F)],
        ).createShader(fenster.outerRect),
    );
    final kerzen = k.take(3).toList();
    final brennen = kerzen.where((x) => x.$2).length;
    c.save();
    c.clipRRect(fenster);
    _sterne(c, 22, const Rect.fromLTWH(34, 14, 234, 180), t, saat: 11);
    _glow(c, const Offset(232, 46), 20, const Color(0x1FE9ECFF));
    c.drawCircle(
      const Offset(232, 46),
      12,
      Paint()..color = const Color(0xE6E9ECFF),
    );
    c.drawCircle(
      const Offset(238, 41),
      11,
      Paint()..color = const Color(0xFF0A0A0B),
    );
    if (brennen > 0) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(151, 210),
          width: 260,
          height: 120,
        ),
        Paint()
          ..color = Color.fromRGBO(247, 207, 146, .22 * brennen / 3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    c.restore();
    c.drawRRect(fenster, _strich(const Color(0x4DE8C98B), 1.5));
    const sterne = [
      Offset(78, 96),
      Offset(103, 70),
      Offset(128, 96),
      Offset(174, 96),
      Offset(199, 70),
      Offset(224, 96),
    ];
    for (var i = 0; i < 6; i++) {
      final m = sterne[i];
      final voll = i < 3 ? i < dankbar : i - 3 < besser;
      const r = 12.0;
      final stern = Path()
        ..moveTo(m.dx, m.dy - r)
        ..quadraticBezierTo(m.dx + r * .15, m.dy - r * .15, m.dx + r, m.dy)
        ..quadraticBezierTo(m.dx + r * .15, m.dy + r * .15, m.dx, m.dy + r)
        ..quadraticBezierTo(m.dx - r * .15, m.dy + r * .15, m.dx - r, m.dy)
        ..quadraticBezierTo(m.dx - r * .15, m.dy - r * .15, m.dx, m.dy - r)
        ..close();
      _skaliert(c, m, _plopp(v, .2 + i * .06), () {
        if (voll) {
          _glow(c, m, 11, const Color(0x66E8C98B));
          c.drawPath(stern, Paint()..color = const Color(0xFFE8C98B));
        } else {
          c.drawPath(stern, _strich(tonSchlaf, 1.3));
        }
      });
    }
    _text2(
      c,
      'dankbar ',
      '${math.min(dankbar, 3)}/3',
      const Offset(103, 128),
      size: 10.5,
      farbeA: _soft,
      farbeB: tonSchlaf,
      weightB: FontWeight.w600,
    );
    _text2(
      c,
      'morgen besser ',
      '${math.min(besser, 3)}/3',
      const Offset(199, 128),
      size: 10.5,
      farbeA: _soft,
      farbeB: tonSchlaf,
      weightB: FontWeight.w600,
    );
    for (var i = 0; i < kerzen.length; i++) {
      final (name, brennt) = kerzen[i];
      final x = 151 + (i - (kerzen.length - 1) / 2) * 81;
      _skaliert(c, Offset(x, 190), _plopp(v, .45 + i * .07), () {
        if (brennt) {
          final flacker = 1 + math.sin(t * 9 + i) * .06;
          _glow(c, Offset(x, 150), 22, const Color(0x73F7CF92));
          c.save();
          c.translate(x, 157);
          c.scale(1, flacker);
          c.drawPath(
            Path()
              ..moveTo(0, -21)
              ..quadraticBezierTo(9, -11, 0, 0)
              ..quadraticBezierTo(-9, -11, 0, -21)
              ..close(),
            Paint()..color = const Color(0xFFFFE2A8),
          );
          c.drawPath(
            Path()
              ..moveTo(0, -13)
              ..quadraticBezierTo(4, -7.5, 0, -2)
              ..quadraticBezierTo(-4, -7.5, 0, -13)
              ..close(),
            Paint()..color = const Color(0xFFFFF6E2),
          );
          c.restore();
        }
        c.drawLine(
          Offset(x, 166),
          Offset(x, 159),
          _strich(const Color(0xFF6A6258), 1.6),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 12, 166, 24, 44),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFFEDE4D3),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 12, 166, 8, 44),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0x73FFFFFF),
        );
        _text(
          c,
          name,
          Offset(x, 244),
          weight: FontWeight.w600,
          color: _ink,
          maxBreite: 78,
        );
      });
    }
    final bank = RRect.fromRectAndRadius(
      const Rect.fromLTWH(16, 208, 270, 14),
      const Radius.circular(7),
    );
    c.drawRRect(bank, Paint()..color = const Color(0xFF2A2826));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 208, 270, 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0x24FFF0D7),
    );
    if (kerzen.isEmpty) {
      _text(c, 'Leg einmal deine Abendroutine fest', const Offset(151, 244));
    }
    final fertig = math.min(dankbar, 3) + math.min(besser, 3);
    for (var i = 0; i < 6; i++) {
      c.drawCircle(
        Offset(151 + (i - 2.5) * 10, 290),
        3,
        Paint()
          ..color = i < fertig
              ? const Color(0xFFE8C98B)
              : const Color(0x1FFFF0D7),
      );
    }
    _text(
      c,
      fertig >= 6
          ? 'Bereit für Gute Nacht'
          : 'Noch ${6 - fertig} ${6 - fertig == 1 ? 'Schritt' : 'Schritte'} bis Gute Nacht',
      const Offset(151, 312),
    );
    _zeile(c, 'Kerze = Routine · Stern = ein Satz');
  }
}
