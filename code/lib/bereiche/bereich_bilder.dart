part of 'koerper_bilder.dart';

// The pictures of Fokus & Arbeit, Ausstrahlung and Mindset (draft
// "Bereiche als Bilder" 3, Phillip "Das ist perfekt die farbe", 2026-11-07):
// same discs, glowing bands, rails, leaves and sky as Körper, on the same
// dark brown. Every part of a picture opens one of the page's tiles.

/// The quiet tone of each area.
const tonFokus = Color(0xFFE8C07E);
const tonAusstrahlung = Color(0xFFE8BFA0);
const tonMindset = Color(0xFFDCCDA8);

const _fuell = Color(0xFF1C150E);
const _fuell2 = Color(0xFF271F15);
const _bankF = Color(0xFF382D21);
const _fein = Color(0x14FFF0D7);

// ------------------------------------------------------------- helpers

/// A disc like a plate: shadow, dark or gold, a fine inner ring.
void _scheibe(Canvas c, Offset m, double r, {bool gold = false, Color? an}) {
  c.drawCircle(m.translate(0, 2), r, Paint()..color = const Color(0x8C000000));
  c.drawCircle(m, r, Paint()..shader = gold ? _goldR(m, r) : _dunkelR(m, r));
  if (gold) return;
  c.drawCircle(m, r, _strich(an ?? _rand, an != null ? 1.6 : 1));
  c.drawCircle(m, r * .62, _strich(_fein, 1));
}

/// A rail like the bar of the training picture.
void _schiene(Canvas c, double x, double y, double w, {double h = 8}) {
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(h / 2)),
    Paint()..color = const Color(0xFF43372A),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, 3),
      const Radius.circular(1.5),
    ),
    Paint()..color = const Color(0x2EFFF0D7),
  );
}

/// Big title with a small line under it, centred.
void _titelB(Canvas c, String t, String u, double y) {
  _text(
    c,
    t,
    Offset(151, y),
    size: 21,
    sora: true,
    weight: FontWeight.w700,
    color: _ink,
    maxBreite: 280,
  );
  _text(c, u, Offset(151, y + 20), size: 11.5);
}

/// A small spaced label in capitals.
void _lab(
  Canvas c,
  double x,
  double y,
  String t,
  Color f, {
  TextAlign align = TextAlign.left,
}) => _text(
  c,
  t,
  Offset(x, y),
  size: 10,
  weight: FontWeight.w700,
  abstand: 1.2,
  color: f,
  align: align,
  maxBreite: 270,
);

/// Only the tick, without its circle.
void _tick(Canvas c, Offset m, {Color farbe = _goldInk}) => c.drawPath(
  Path()
    ..moveTo(m.dx - 4.5, m.dy)
    ..relativeLineTo(3, 3)
    ..relativeLineTo(5.5, -6),
  _strich(farbe, 2),
);

/// Soft gold light (the draft's glow filter).
Paint _wolke(double o, {double blur = 7, Color farbe = _goldHell}) => Paint()
  ..color = farbe.withValues(alpha: o.clamp(0.0, 1.0))
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

Shader _bandShader(Rect r) => const LinearGradient(
  colors: [Color(0xFFA8823F), Color(0xFFF5DFAE), Color(0xFFC49A55)],
  stops: [0, .45, 1],
).createShader(r);

/// The glowing gold band, drawn up to [f].
void _band(Canvas c, Path p, double f) {
  c.drawPath(p, _leuchtStrich(_goldHell.withValues(alpha: .13), 26, 7));
  c.drawPath(p, _strich(const Color(0x24E8C98B), 12));
  final teil = _stueck(p, f);
  c.drawPath(teil, _leuchtStrich(const Color(0x8CF5DFAE), 6, 5));
  c.drawPath(
    teil,
    _strich(_goldHell, 4.5)..shader = _bandShader(p.getBounds()),
  );
}

/// A smooth line through the points.
Path _glatt(List<Offset> p) {
  final out = Path()..moveTo(p.first.dx, p.first.dy);
  for (var i = 0; i < p.length - 1; i++) {
    final a = i == 0 ? p[i] : p[i - 1];
    final b = p[i], n = p[i + 1];
    final d = i + 2 < p.length ? p[i + 2] : n;
    out.cubicTo(
      b.dx + (n.dx - a.dx) / 6,
      b.dy + (n.dy - a.dy) / 6,
      n.dx - (d.dx - b.dx) / 6,
      n.dy - (d.dy - b.dy) / 6,
      n.dx,
      n.dy,
    );
  }
  return out;
}

/// Draws [p] dashed, up to [f] of its length.
void _gestrichelt(
  Canvas c,
  Path p,
  Paint paint,
  double an,
  double aus, [
  double f = 1,
]) {
  for (final m in p.computeMetrics()) {
    final ende = m.length * f.clamp(0.0, 1.0);
    var d = 0.0;
    while (d < ende) {
      c.drawPath(m.extractPath(d, math.min(d + an, ende)), paint);
      d += an + aus;
    }
  }
}

/// Text over up to [zeilen] lines; [oben] is the top (centre or left).
void _absatz(
  Canvas c,
  String s,
  Offset oben, {
  double breite = 260,
  double size = 11,
  Color color = _soft,
  FontWeight weight = FontWeight.w400,
  bool sora = false,
  int zeilen = 2,
  TextAlign align = TextAlign.center,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: sora ? 'Sora' : 'Figtree',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.3,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    textWidthBasis: TextWidthBasis.longestLine,
    maxLines: zeilen,
    ellipsis: '…',
  )..layout(maxWidth: breite);
  final x = align == TextAlign.left ? oben.dx : oben.dx - tp.width / 2;
  tp.paint(c, Offset(x, oben.dy));
}

double _breite(String s, double size, FontWeight weight) => (TextPainter(
  text: TextSpan(
    text: s,
    style: TextStyle(fontFamily: 'Figtree', fontSize: size, fontWeight: weight),
  ),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout()).width;

/// Fades what [male] draws in by [q].
void _blende(Canvas c, double q, void Function() male) {
  if (q <= 0) return;
  if (q >= 1) {
    male();
    return;
  }
  c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, q));
  male();
  c.restore();
}

RRect _rr(double x, double y, double w, double h, double r) =>
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

/// A tap area that does something itself instead of opening a tile.
Widget _drueck(String key, VoidCallback onTap) => GestureDetector(
  key: ValueKey(key),
  behavior: HitTestBehavior.opaque,
  onTap: onTap,
  child: _flaeche(),
);

// ======================================================= FOKUS & ARBEIT

/// The day's energy as a line on the board (wake to bed).
class _Kurve {
  _Kurve(List<(int, double)> w)
    : w = w.length >= 2 ? w : const [(420, .5), (1380, .5)];
  final List<(int, double)> w;

  int get m0 => w.first.$1;
  int get m1 => w.last.$1;
  double get _lo => w.map((e) => e.$2).reduce(math.min);
  double get _hi => w.map((e) => e.$2).reduce(math.max);

  double x(num m) => 14 + (m - m0) / math.max(1, m1 - m0) * 274;
  double y(double e) {
    final span = _hi - _lo;
    return 236 - (span <= 0 ? .5 : (e - _lo) / span) * 98;
  }

  double wert(num m) {
    if (m <= m0) return w.first.$2;
    for (var i = 1; i < w.length; i++) {
      if (m <= w[i].$1) {
        final a = w[i - 1], b = w[i];
        return a.$2 + (b.$2 - a.$2) * (m - a.$1) / math.max(1, b.$1 - a.$1);
      }
    }
    return w.last.$2;
  }

  Offset at(num m) => Offset(x(m), y(wert(m)));
  Path pfad() => _glatt([for (final p in w) Offset(x(p.$1), y(p.$2))]);

  /// The second high after the dip, if there is one.
  int? zweitesHoch(int tief) {
    (int, double)? best;
    for (final p in w) {
      if (p.$1 < tief + 60 || p.$1 > m1 - 60) continue;
      if (best == null || p.$2 > best.$2) best = p;
    }
    if (best == null || best.$2 <= wert(tief) + (_hi - _lo) * .12) return null;
    return best.$1;
  }
}

/// Heute: the one thing on top, the energy curve with the focus block in
/// the high, the dip and the second high.
class FokusHeuteBild extends StatelessWidget {
  const FokusHeuteBild({
    super.key,
    required this.sache,
    required this.erledigt,
    required this.energie,
    required this.hoch,
    required this.tief,
    required this.tiefText,
    required this.block,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final String? sache;
  final bool erledigt;
  final List<(int, double)> energie;
  final (int, int) hoch;
  final int tief;

  /// "Tief 14:30".
  final String tiefText;
  final int block;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) {
    final k = _Kurve(energie);
    final pb = k.at((hoch.$1 + hoch.$2) / 2);
    return _Brett(
      maler: _FokusHeuteMaler(v, t, this, k),
      punkte: [
        (
          const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
          tipp('p-energie', _flaeche()),
        ),
        (const Rect.fromLTWH(16, 8, 270, 100), tipp('p-fokus', _flaeche())),
        (
          Rect.fromCenter(center: pb, width: 48, height: 48),
          tipp('p-block', _flaeche()),
        ),
        (const Rect.fromLTWH(16, 284, 270, 34), tipp('p-block', _flaeche())),
      ],
    );
  }
}

class _FokusHeuteMaler extends _Maler {
  _FokusHeuteMaler(super.v, super.t, this.b, this.k);
  final FokusHeuteBild b;
  final _Kurve k;

  @override
  void paint(Canvas c, Size s) {
    _blende(
      c,
      _teil(v, 0, .3),
      () => _titelB(
        c,
        b.sache ?? 'Was zählt heute?',
        b.sache == null ? 'die eine Sache, mehr nicht' : 'die eine Sache heute',
        40,
      ),
    );
    const m = Offset(151, 88);
    _skaliert(c, m, _plopp(v, .05), () {
      _scheibe(c, m, 14, gold: b.erledigt, an: b.erledigt ? null : tonFokus);
      if (b.erledigt) _tick(c, m);
    });
    _band(c, k.pfad(), _teil(v, .1, .7));
    final pb = k.at((b.hoch.$1 + b.hoch.$2) / 2);
    _skaliert(c, pb, _plopp(v, .35), () {
      c.drawCircle(pb, 30, _wolke(.25));
      c.drawCircle(pb, 21, Paint()..shader = _goldR(pb, 21));
      _text(
        c,
        '${b.block}',
        pb.translate(0, -1),
        size: 11,
        sora: true,
        weight: FontWeight.w700,
        color: _goldInk,
      );
      _text(
        c,
        'Min',
        pb.translate(0, 10),
        size: 8,
        weight: FontWeight.w700,
        color: const Color(0xFF3A2A14),
      );
    });
    final pt = k.at(b.tief);
    _skaliert(c, pt, _plopp(v, .45), () {
      _scheibe(c, pt, 7);
      _text(c, b.tiefText, pt.translate(0, 26), size: 10);
    });
    if (k.zweitesHoch(b.tief) case final z?) {
      final pz = k.at(z);
      _skaliert(c, pz, _plopp(v, .5), () {
        _scheibe(c, pz, 7, an: tonFokus);
        _text(
          c,
          'zweites Hoch',
          pz.translate(0, -18),
          size: 10,
          weight: FontWeight.w600,
          color: tonFokus,
        );
      });
    }
    for (var i = 0; i <= 5; i++) {
      final mm = ((k.m0 + (k.m1 - k.m0) * i / 5) / 60).round() * 60;
      _text(
        c,
        '${(mm ~/ 60) % 24}',
        Offset(k.x(mm), 268),
        size: 9.5,
        color: _leise,
      );
    }
    const r = Offset(38, 302);
    c.drawCircle(r, 9, _strich(const Color(0x1AFFF0D7), 3));
    c.drawArc(
      Rect.fromCircle(center: r, radius: 9),
      -math.pi / 2,
      math.pi * 2 * .02,
      false,
      _strich(tonFokus, 3),
    );
    _text(
      c,
      'Fokus-Block ${b.block} Min · tippen = starten',
      const Offset(56, 306),
      size: 10.5,
      align: TextAlign.left,
    );
    _zeile(c, 'Gold = dein Fokus-Block · er liegt in deinem Hoch');
  }
}

/// One milestone leaf: 2 done, 1 next, 0 later, -1 the big goal (bud).
typedef ZielBlatt = ({String name, int art});

/// Ziele: the lever of the week on top, a branch with the milestones as
/// leaves, the skill as a ladder on the right.
class FokusZieleBild extends StatelessWidget {
  const FokusZieleBild({
    super.key,
    required this.hebel,
    required this.hebelFertig,
    required this.blaetter,
    required this.skill,
    required this.stufen,
    required this.erreicht,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final String? hebel;
  final bool hebelFertig;
  final List<ZielBlatt> blaetter;

  /// Name of the skill, null without one.
  final String? skill;
  final int stufen, erreicht;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _ZieleMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('b-baum', _flaeche()),
      ),
      (const Rect.fromLTWH(16, 6, 270, 92), tipp('b-hebel', _flaeche())),
      (const Rect.fromLTWH(246, 104, 54, 236), tipp('b-skill', _flaeche())),
    ],
  );
}

class _ZieleMaler extends _Maler {
  _ZieleMaler(super.v, super.t, this.b);
  final FokusZieleBild b;

  static double _zx(double y) =>
      128 - math.sin((y - 110) / 220 * math.pi * 2) * 12;

  @override
  void paint(Canvas c, Size s) {
    _blende(
      c,
      _teil(v, 0, .3),
      () => _titelB(
        c,
        b.hebel ?? 'Was bringt dich weiter?',
        'Hebel der Woche',
        36,
      ),
    );
    const m = Offset(151, 82);
    _skaliert(c, m, _plopp(v, .05), () {
      _scheibe(
        c,
        m,
        12,
        gold: b.hebelFertig,
        an: b.hebelFertig ? null : tonFokus,
      );
      if (b.hebelFertig) _tick(c, m);
    });
    final stiel = Path();
    for (var k = 0; k < 22; k++) {
      final y = 326.0 - k * 10;
      k == 0 ? stiel.moveTo(_zx(y), y) : stiel.lineTo(_zx(y), y);
    }
    c.drawPath(
      _stueck(stiel, _teil(v, .05, .6)),
      _strich(const Color(0xFF9C8150), 3),
    );
    for (final (i, bl) in b.blaetter.take(4).indexed) {
      final y = 296.0 - i * 46, dir = i.isOdd ? -1.0 : 1.0, x = _zx(y);
      final p = Offset(x, y);
      _skaliert(c, p, _plopp(v, .2 + i * .08), () {
        if (bl.art < 0) {
          c.drawCircle(p, 14, _wolke(.18));
          final knospe = Path()
            ..moveTo(x, y + 8)
            ..quadraticBezierTo(x - 9, y - 2, x, y - 12)
            ..quadraticBezierTo(x + 9, y - 2, x, y + 8)
            ..close();
          c.drawPath(knospe, Paint()..color = _fuell);
          c.drawPath(knospe, _strich(tonFokus, 1.4));
          _text(
            c,
            bl.name,
            Offset(x + 14, y - 1),
            size: 11,
            weight: FontWeight.w600,
            color: tonFokus,
            align: TextAlign.left,
            maxBreite: 100,
          );
          _text(
            c,
            'dein großes Ziel',
            Offset(x + 14, y + 12),
            size: 9.5,
            color: _leise,
            align: TextAlign.left,
          );
          return;
        }
        final e = x + dir * 34;
        if (bl.art == 1) {
          c.drawOval(
            Rect.fromCenter(
              center: Offset(x + dir * 17, y - 3),
              width: 52,
              height: 28,
            ),
            _wolke(.3),
          );
        }
        final blatt = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + dir * 13, y - 16, e, y - 6)
          ..quadraticBezierTo(x + dir * 19, y + 9, x, y)
          ..close();
        if (bl.art == 2) {
          c.drawPath(blatt, Paint()..shader = _goldLinear(blatt.getBounds()));
        } else {
          c.drawPath(blatt, Paint()..color = _fuell);
          c.drawPath(blatt, _strich(tonFokus, 1.4));
        }
        final al = dir > 0 ? TextAlign.left : TextAlign.right;
        final mb = dir > 0 ? 250 - (e + 7) : e - 7 - 8;
        _text(
          c,
          bl.name,
          Offset(e + dir * 7, y - 2),
          size: 10.5,
          weight: FontWeight.w600,
          color: bl.art == 1 ? _goldHell : _ink,
          align: al,
          maxBreite: mb,
        );
        _text(
          c,
          switch (bl.art) {
            2 => 'geschafft',
            1 => 'als Nächstes',
            _ => 'später',
          },
          Offset(e + dir * 7, y + 11),
          size: 9.5,
          color: bl.art == 1 ? tonFokus : _leise,
          align: al,
        );
      });
    }
    _lab(c, 273, 118, 'SKILL', _leise, align: TextAlign.center);
    final n = b.skill == null || b.stufen == 0 ? 7 : math.min(b.stufen, 7);
    for (var i = 0; i < n; i++) {
      final y = 306.0 - i * 28;
      final gold = b.skill != null && i < b.erreicht;
      final an = b.skill != null && i == b.erreicht;
      _skaliert(c, Offset(273, y), _plopp(v, .15 + i * .05), () {
        if (an) c.drawRRect(_rr(248, y - 8, 50, 16, 8), _wolke(.3));
        if (gold) {
          final r = _rr(254, y - 4, 38, 8, 4);
          c.drawRRect(r, Paint()..shader = _goldLinear(r.outerRect));
        } else {
          _schiene(c, 254, y - 4, 38);
        }
        if (an) c.drawRRect(_rr(254, y - 4, 38, 8, 4), _strich(tonFokus, 1.4));
      });
    }
    _text(
      c,
      b.skill ?? 'Skill wählen',
      const Offset(273, 330),
      size: 10,
      weight: FontWeight.w600,
      color: b.skill == null ? _leise : tonFokus,
      maxBreite: 70,
    );
    _zeile(c, 'Volles Blatt = geschafft · Leiter = dein Skill');
  }
}

/// Handy: the phone with today's distractions and the "Ich will
/// ablenken" button, below the phone-free time of the day.
class HandyBild extends StatelessWidget {
  const HandyBild({
    super.key,
    required this.n,
    required this.gruende,
    required this.frei,
    required this.freiLinks,
    required this.freiRechts,
    required this.tipp,
    required this.v,
    required this.t,
    this.onDrang,
  });

  /// Taps on the button today.
  final int n;

  /// The most frequent reasons and how often.
  final List<(String, int)> gruende;

  /// The phone-free time as part of the day (0 to 1), null without one.
  final (double, double)? frei;
  final String freiLinks, freiRechts;
  final VoidCallback? onDrang;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _HandyMaler(v, t, this),
    punkte: [
      // The phone around the button (the button counts by itself).
      (
        const Rect.fromLTWH(0, 0, bildBreite, 122),
        tipp('p-spiegel', _flaeche()),
      ),
      (const Rect.fromLTWH(0, 122, 113, 136), tipp('p-spiegel', _flaeche())),
      (const Rect.fromLTWH(189, 122, 113, 136), tipp('p-spiegel', _flaeche())),
      (const Rect.fromLTWH(113, 198, 76, 60), tipp('p-spiegel', _flaeche())),
      (const Rect.fromLTWH(10, 258, 282, 64), tipp('p-handyfrei', _flaeche())),
      (
        Rect.fromCircle(center: const Offset(151, 160), radius: 36),
        onDrang == null
            ? tipp('p-drang', _flaeche())
            : _drueck('drang-bild', onDrang!),
      ),
    ],
  );
}

class _HandyMaler extends _Maler {
  _HandyMaler(super.v, super.t, this.b);
  final HandyBild b;

  @override
  void paint(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(center: const Offset(151, 250), width: 160, height: 16),
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    final handy = _rr(91, 18, 120, 226, 26);
    c.drawRRect(handy, Paint()..shader = _dunkelR(const Offset(151, 131), 130));
    c.drawRRect(
      handy,
      _strich(_goldHell, 2)..shader = _goldLinear(handy.outerRect),
    );
    c.drawRRect(
      _rr(131, 26, 40, 8, 4),
      Paint()..color = const Color(0xFF2A2117),
    );
    c.drawRRect(
      _rr(99, 40, 104, 196, 18),
      Paint()
        ..shader = _dunkelR(const Offset(151, 138), 110)
        ..color = const Color(0xCC000000),
    );
    _lab(c, 151, 62, 'HEUTE ABGELENKT', _leise, align: TextAlign.center);
    _text(
      c,
      '${b.n}×',
      const Offset(151, 98),
      size: 34,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    const m = Offset(151, 160);
    _skaliert(c, m, _plopp(v, .15), () {
      c.drawCircle(m, 40, _wolke(.14));
      c.drawCircle(m, 32, Paint()..shader = _goldR(m, 32));
      _text(
        c,
        'Ich will',
        const Offset(151, 157),
        size: 10,
        weight: FontWeight.w700,
        color: _goldInk,
      );
      _text(
        c,
        'ablenken',
        const Offset(151, 169),
        size: 10,
        weight: FontWeight.w700,
        color: _goldInk,
      );
    });
    final top = b.gruende.isEmpty
        ? 1
        : b.gruende.map((g) => g.$2).reduce(math.max);
    for (final (i, (name, z)) in b.gruende.take(3).indexed) {
      final y = 208.0 + i * 10;
      final w = math.max(4.0, z / top * 42 * _teil(v, .2 + i * .08, .7));
      c.drawRRect(
        _rr(110, y, w, 5, 2.5),
        Paint()..color = tonFokus.withValues(alpha: 1 - i * .25),
      );
      _text(c, name, Offset(192, y + 5), size: 7.5, align: TextAlign.right);
    }
    _lab(c, 22, 272, 'HANDYFREI', tonFokus);
    c.drawRRect(_rr(16, 282, 270, 14, 7), Paint()..color = _bankF);
    c.drawRRect(
      _rr(16, 282, 270, 4, 2),
      Paint()..color = const Color(0x24FFF0D7),
    );
    if (b.frei case (final von, final bis)) {
      final w = math.max(14.0, 270 * (bis - von) * _teil(v, .2, .7));
      final r = _rr(16 + 270 * von, 282, w, 14, 7);
      c.drawRRect(r, Paint()..shader = _goldLinear(r.outerRect));
    }
    _text(
      c,
      b.freiLinks,
      const Offset(22, 312),
      size: 10,
      weight: FontWeight.w600,
      color: tonFokus,
      align: TextAlign.left,
    );
    _text(
      c,
      b.freiRechts,
      const Offset(280, 312),
      size: 10,
      align: TextAlign.right,
    );
    _zeile(c, 'Knopf tippen statt Handy aufmachen');
  }
}

/// One pattern that gives or takes energy.
typedef GeberPunkt = ({String text, bool gut});

/// Rhythmus: the day as an arc from waking to bed, the best hours in gold,
/// the dip and the training; below what gives and takes energy.
class RhythmusBild extends StatelessWidget {
  const RhythmusBild({
    super.key,
    required this.von,
    required this.bis,
    required this.hoch,
    required this.tief,
    required this.training,
    required this.vonText,
    required this.bisText,
    required this.hochText,
    required this.geber,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// Waking and bed in minutes (bed can be past midnight, over 1440).
  final int von, bis;
  final (int, int) hoch;
  final int tief;
  final int? training;
  final String vonText, bisText, hochText;
  final List<GeberPunkt> geber;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _RhythmusMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('p-stunden', _flaeche()),
      ),
      (const Rect.fromLTWH(0, 214, 302, 108), tipp('p-geber', _flaeche())),
    ],
  );
}

class _RhythmusMaler extends _Maler {
  _RhythmusMaler(super.v, super.t, this.b);
  final RhythmusBild b;

  Offset _rb(double q) {
    final u = q.clamp(0.0, 1.0);
    return Offset(
      (1 - u) * (1 - u) * 36 + 2 * (1 - u) * u * 151 + u * u * 266,
      (1 - u) * (1 - u) * 170 + 2 * (1 - u) * u * -20 + u * u * 170,
    );
  }

  double _rh(num m) => (m - b.von) / math.max(1, b.bis - b.von);

  Path _bog(num m0, num m1) {
    final p = Path();
    for (var k = 0; k <= 20; k++) {
      final o = _rb(_rh(m0) + (_rh(m1) - _rh(m0)) * k / 20);
      k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  @override
  void paint(Canvas c, Size s) {
    final mitte = (b.hoch.$1 + b.hoch.$2) / 2;
    _gestrichelt(
      c,
      _bog(b.von, b.bis),
      _strich(const Color(0x2EE8C98B), 2),
      2,
      5,
    );
    c.drawPath(
      _stueck(_bog(b.von, mitte), _teil(v, .05, .6)),
      _strich(const Color(0xFFE8C98B), 2.2),
    );
    final hoch = _bog(b.hoch.$1, b.hoch.$2);
    c.drawPath(hoch, _leuchtStrich(const Color(0x33F5DFAE), 22, 7));
    c.drawPath(
      hoch,
      _strich(_goldHell, 9)..shader = _goldLinear(hoch.getBounds()),
    );
    c.drawPath(
      _bog(b.tief - 30, b.tief + 30),
      _strich(const Color(0x33FFF0D7), 9),
    );
    if (b.training case final tr?) {
      c.drawPath(_bog(tr, tr + 90), _strich(tonFokus.withValues(alpha: .6), 9));
    }
    final sonne = _rb(_rh(mitte));
    _skaliert(c, sonne, _plopp(v, .3), () {
      c.drawCircle(sonne, 20, _wolke(.45, farbe: const Color(0xFFF7CF92)));
      c.drawCircle(
        sonne,
        10,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFFF6E2), Color(0xFFF7CF92)],
          ).createShader(Rect.fromCircle(center: sonne, radius: 10)),
      );
    });
    c.drawCircle(const Offset(36, 170), 4, Paint()..color = tonFokus);
    c.drawCircle(
      const Offset(266, 170),
      4,
      Paint()..color = const Color(0x66E8C98B),
    );
    for (final (x, s) in [(36.0, b.vonText), (266.0, b.bisText)]) {
      _text(
        c,
        s,
        Offset(x, 190),
        size: 11,
        sora: true,
        weight: FontWeight.w600,
        color: _ink,
      );
    }
    _text(
      c,
      b.hochText,
      const Offset(151, 128),
      size: 34,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    _text(c, 'deine besten Stunden', const Offset(151, 148), color: tonFokus);
    _lab(c, 151, 232, 'GEBER UND RÄUBER', _leise, align: TextAlign.center);
    final g = b.geber.take(3).toList();
    if (g.isEmpty) {
      _text(c, 'Kommt nach 14 Morgen', const Offset(151, 268), size: 11);
    }
    for (final (i, x) in g.indexed) {
      final mx = 151 + (i - (g.length - 1) / 2) * 91;
      final m = Offset(mx, 262);
      _skaliert(c, m, _plopp(v, .3 + i * .07), () {
        if (x.gut) c.drawCircle(m, 20, _wolke(.2));
        _scheibe(c, m, 15, gold: x.gut);
        final pfeil = x.gut
            ? (Path()
                ..moveTo(mx, 268)
                ..lineTo(mx, 256)
                ..moveTo(mx - 5, 261)
                ..lineTo(mx, 255)
                ..lineTo(mx + 5, 261))
            : (Path()
                ..moveTo(mx, 256)
                ..lineTo(mx, 268)
                ..moveTo(mx - 5, 263)
                ..lineTo(mx, 269)
                ..lineTo(mx + 5, 263));
        c.drawPath(pfeil, _strich(x.gut ? _goldInk : _soft, 1.8));
        _absatz(
          c,
          x.text,
          Offset(mx, 284),
          breite: 88,
          size: 10,
          weight: FontWeight.w600,
          color: x.gut ? _ink : _soft,
        );
      });
    }
    _zeile(c, 'Bogen tippen = was in die Zeit gehört');
  }
}

/// One docked habit.
typedef KettenGlied = ({
  String anker,
  String neu,
  String unter,
  bool heute,
  bool aktiv,
});

/// Routinen: the habits as pills on a chain, gold when done today.
class RoutinenBild extends StatelessWidget {
  const RoutinenBild({
    super.key,
    required this.ketten,
    required this.laeuftText,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final List<KettenGlied> ketten;
  final String laeuftText;
  final BildTipp tipp;
  final double v, t;

  double get _neuY => ketten.length < 3 ? 72.0 + ketten.length * 62 : 262;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _RoutinenMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('p-andock', _flaeche()),
      ),
      (Rect.fromLTWH(16, _neuY, 270, 34), tipp('p-neu', _flaeche())),
      (const Rect.fromLTWH(16, 306, 270, 22), tipp('p-laeuft', _flaeche())),
    ],
  );
}

class _RoutinenMaler extends _Maler {
  _RoutinenMaler(super.v, super.t, this.b);
  final RoutinenBild b;

  @override
  void paint(Canvas c, Size s) {
    final k = b.ketten.take(3).toList();
    final gemacht = k.where((x) => x.heute).length;
    _lab(c, 22, 34, 'DEINE GEWOHNHEITEN', tonFokus);
    if (k.isNotEmpty) {
      _text(
        c,
        '$gemacht von ${k.length}',
        const Offset(280, 36),
        size: 20,
        sora: true,
        weight: FontWeight.w700,
        color: _ink,
        align: TextAlign.right,
      );
      final w = (258 - (k.length - 1) * 6) / k.length;
      for (var i = 0; i < k.length; i++) {
        final r = _rr(22 + i * (w + 6), 48, w, 6, 3);
        _skaliert(c, r.center, _plopp(v, .05 + i * .06), () {
          c.drawRRect(
            r,
            i < gemacht
                ? (Paint()..shader = _goldLinear(r.outerRect))
                : (Paint()..color = _fein),
          );
        });
      }
    }
    for (final (i, x) in k.indexed) {
      final y = 72.0 + i * 62, cy = y + 24;
      _skaliert(c, Offset(151, cy), _plopp(v, .12 + i * .08), () {
        if (x.aktiv) c.drawRRect(_rr(14, y - 2, 274, 52, 26), _wolke(.1));
        final r = _rr(16, y, 270, 48, 24);
        c.drawRRect(r, Paint()..color = _fuell);
        c.drawRRect(r, _strich(x.aktiv ? tonFokus : _rand, x.aktiv ? 1.4 : 1));
        _text(
          c,
          x.anker,
          Offset(38, y + 19),
          size: 10,
          weight: FontWeight.w600,
          color: x.aktiv ? tonFokus : _soft,
          align: TextAlign.left,
          maxBreite: 150,
        );
        final unterB = _breite(x.unter, 9.5, FontWeight.w400);
        _text(
          c,
          x.neu,
          Offset(38, y + 35),
          size: 13,
          sora: true,
          weight: FontWeight.w700,
          color: _ink,
          align: TextAlign.left,
          maxBreite: math.max(60, 240 - unterB - 10 - 38),
        );
        _text(
          c,
          x.unter,
          Offset(240, y + 29),
          size: 9.5,
          color: _leise,
          align: TextAlign.right,
        );
        final m = Offset(262, cy);
        if (x.heute) {
          c.drawCircle(m, 11, Paint()..shader = _goldR(m, 11));
          _tick(c, m);
        } else {
          c.drawCircle(m, 11, _strich(tonFokus, 1.6));
        }
      });
    }
    final ny = b._neuY;
    _skaliert(c, Offset(151, ny + 17), _plopp(v, .4), () {
      _gestrichelt(
        c,
        Path()..addRRect(_rr(16, ny, 270, 34, 17)),
        _strich(const Color(0x33FFF0D7), 1),
        4,
        5,
      );
      _text(
        c,
        '+ Neue Gewohnheit andocken',
        Offset(151, ny + 21),
        weight: FontWeight.w600,
      );
    });
    _text(c, b.laeuftText, const Offset(151, 320), size: 10, color: _leise);
    _zeile(c, 'Gold = heute gemacht · Ring = noch offen');
  }
}

// ========================================================= AUSSTRAHLUNG

/// One care step of the morning.
typedef PflegeSchritt = ({String name, bool fertig});

/// Heute: the mirror with the morning's care steps as drops, the 10
/// minutes of learning, the voice.
class PflegeHeuteBild extends StatelessWidget {
  const PflegeHeuteBild({
    super.key,
    required this.schritte,
    required this.lern,
    required this.tipp,
    required this.v,
    required this.t,
    this.onSchritt,
  });

  final List<PflegeSchritt> schritte;

  /// Minutes learned today (of 10).
  final int lern;

  /// Ticks a step off (or on again) right in the picture.
  final ValueChanged<int>? onSchritt;
  final BildTipp tipp;
  final double v, t;

  double get _abstand => schritte.length <= 3 ? 50 : 42;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _PflegeHeuteMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('pe-pflege', _flaeche()),
      ),
      (const Rect.fromLTWH(14, 250, 176, 52), tipp('pe-lern', _flaeche())),
      (const Rect.fromLTWH(194, 250, 100, 52), tipp('pe-stimme', _flaeche())),
      if (onSchritt != null)
        for (var i = 0; i < math.min(schritte.length, 4); i++)
          (
            Rect.fromLTWH(160, 74 + i * _abstand - 22, 136, 40),
            _drueck('pflege-bild-$i', () => onSchritt!(i)),
          ),
    ],
  );
}

class _PflegeHeuteMaler extends _Maler {
  _PflegeHeuteMaler(super.v, super.t, this.b);
  final PflegeHeuteBild b;

  @override
  void paint(Canvas c, Size s) {
    final spiegel = Rect.fromCenter(
      center: const Offset(88, 142),
      width: 128,
      height: 184,
    );
    c.drawOval(spiegel.inflate(10), _wolke(.06));
    c.drawOval(
      spiegel,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.2, -.4),
          radius: .9,
          colors: [Color(0xFF2A2723), Color(0xFF150F0A)],
        ).createShader(spiegel),
    );
    c.drawOval(spiegel, _strich(_goldHell, 3)..shader = _goldLinear(spiegel));
    c.drawPath(
      Path()
        ..moveTo(52, 92)
        ..quadraticBezierTo(60, 70, 80, 62),
      _strich(const Color(0x1FFFFFFF), 6),
    );
    final l = b.schritte.take(4).toList();
    final fertig = l.where((x) => x.fertig).length;
    _text(
      c,
      l.isEmpty ? '–' : '$fertig/${l.length}',
      const Offset(88, 136),
      size: 22,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
    );
    _text(c, 'morgens', const Offset(88, 154), size: 10);
    if (l.isEmpty) {
      _absatz(
        c,
        'Leg deine Schritte für morgens fest',
        const Offset(232, 120),
        breite: 120,
        size: 11,
        color: _soft,
      );
    }
    for (final (i, x) in l.indexed) {
      final y = 74 + i * b._abstand;
      _skaliert(c, Offset(172, y), _plopp(v, .1 + i * .08), () {
        _gestrichelt(
          c,
          Path()
            ..moveTo(152, y)
            ..lineTo(166, y),
          _strich(const Color(0x24FFF0D7), 1),
          2,
          3,
        );
        final tropfen = Path()
          ..moveTo(182, y - 12)
          ..quadraticBezierTo(190, y - 2, 190, y + 4)
          ..arcToPoint(Offset(174, y + 4), radius: const Radius.circular(8))
          ..quadraticBezierTo(174, y - 2, 182, y - 12)
          ..close();
        if (x.fertig) {
          c.drawPath(tropfen, Paint()..shader = _goldR(Offset(182, y), 12));
        } else {
          c.drawPath(tropfen, Paint()..color = _fuell);
          c.drawPath(tropfen, _strich(tonAusstrahlung, 1.4));
        }
        _text(
          c,
          x.name,
          Offset(198, y + 5),
          size: 10.5,
          weight: FontWeight.w600,
          color: x.fertig ? _soft : _ink,
          align: TextAlign.left,
          maxBreite: 98,
        );
      });
    }
    _lab(c, 22, 268, 'LERN-ZIEL · 10 MIN', tonAusstrahlung);
    for (var i = 0; i < 10; i++) {
      final r = _rr(22.0 + i * 16, 278, 12, 18, 4);
      _skaliert(c, r.center, _plopp(v, .2 + i * .03), () {
        c.drawRRect(
          r,
          i < b.lern
              ? (Paint()..shader = _goldLinear(r.outerRect))
              : (Paint()..color = const Color(0x0FFFF0D7)),
        );
      });
    }
    _lab(c, 200, 268, 'STIMME', _leise);
    final q = _teil(v, .2, .8);
    for (var i = 0; i < 18; i++) {
      final h = (4 + (math.sin(i * 1.7)).abs() * 16) * q;
      c.drawRRect(
        _rr(200.0 + i * 5, 287 - h / 2, 2.6, h, 1.3),
        Paint()..color = tonAusstrahlung.withValues(alpha: .7),
      );
    }
    _zeile(c, 'Tropfen tippen = Schritt erledigt');
  }
}

/// One hint on the silhouette and the tile it opens.
typedef LookPunkt = ({String name, String ziel});

/// Look: a silhouette with pulsing gold hint points.
class LookBild extends StatelessWidget {
  const LookBild({
    super.key,
    required this.punkte,
    required this.unten,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// Four places: brows, beard, collar, posture (null leaves one out).
  final List<LookPunkt?> punkte;
  final String unten;
  final BildTipp tipp;
  final double v, t;

  static const orte = [
    Offset(150, 96),
    Offset(124, 132),
    Offset(176, 196),
    Offset(88, 236),
  ];

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _LookMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('pe-look', _flaeche()),
      ),
      for (final (i, p) in punkte.take(4).indexed)
        if (p != null)
          (
            Rect.fromCenter(center: orte[i], width: 44, height: 40),
            tipp(p.ziel, _flaeche()),
          ),
      (const Rect.fromLTWH(30, 310, 242, 24), tipp('pe-verlauf', _flaeche())),
    ],
  );
}

class _LookMaler extends _Maler {
  _LookMaler(super.v, super.t, this.b);
  final LookBild b;

  @override
  void paint(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(center: const Offset(151, 150), width: 240, height: 260),
      _wolke(.07),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(151, 304), width: 240, height: 20),
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    final koerper = Path()
      ..moveTo(151, 40)
      ..cubicTo(120, 40, 108, 66, 110, 96)
      ..cubicTo(111, 120, 120, 146, 136, 156)
      ..lineTo(134, 178)
      ..cubicTo(100, 186, 70, 200, 58, 230)
      ..lineTo(48, 300)
      ..lineTo(254, 300)
      ..lineTo(244, 230)
      ..cubicTo(232, 200, 202, 186, 168, 178)
      ..lineTo(166, 156)
      ..cubicTo(182, 146, 191, 120, 192, 96)
      ..cubicTo(194, 66, 182, 40, 151, 40)
      ..close();
    c.drawPath(
      koerper,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.16, -.5),
          radius: .9,
          colors: [Color(0xFF33291D), Color(0xFF1E170F), Color(0xFF120D08)],
          stops: [0, .6, 1],
        ).createShader(koerper.getBounds()),
    );
    final rechts = Path()
      ..moveTo(151, 40)
      ..cubicTo(182, 40, 194, 66, 192, 96)
      ..cubicTo(191, 120, 182, 146, 166, 156)
      ..lineTo(168, 178)
      ..cubicTo(202, 186, 232, 200, 244, 230)
      ..lineTo(254, 300);
    final links = Path()
      ..moveTo(151, 40)
      ..cubicTo(120, 40, 108, 66, 110, 96)
      ..cubicTo(111, 120, 120, 146, 136, 156)
      ..lineTo(134, 178)
      ..cubicTo(100, 186, 70, 200, 58, 230)
      ..lineTo(48, 300);
    c.drawPath(links, _strich(const Color(0x24FFF0D7), 1.4));
    final teil = _stueck(rechts, _teil(v, .05, .65));
    c.drawPath(teil, _leuchtStrich(const Color(0x80F5DFAE), 5, 5));
    c.drawPath(
      teil,
      _strich(_goldHell, 2.4)..shader = _goldLinear(rechts.getBounds()),
    );
    for (final (i, p) in b.punkte.take(4).indexed) {
      if (p == null) continue;
      final m = LookBild.orte[i];
      final q = ((t / 2.4 + i * .21) % 1);
      _skaliert(c, m, _plopp(v, .3 + i * .07), () {
        c.drawCircle(
          m,
          7 + 8 * math.sin(q * math.pi),
          _strich(tonAusstrahlung.withValues(alpha: .7 * (1 - q)), 1),
        );
        c.drawCircle(m, 9, _wolke(.35));
        c.drawCircle(m, 5.5, Paint()..shader = _goldR(m, 5.5));
        final r = m.dx > 151;
        _text(
          c,
          p.name,
          m.translate(r ? 12 : -12, -8),
          weight: FontWeight.w700,
          color: _goldHell,
          align: r ? TextAlign.left : TextAlign.right,
          maxBreite: 100,
        );
      });
    }
    _text(c, b.unten, const Offset(151, 326), size: 10, color: _leise);
    _zeile(c, 'Punkt tippen = was du ändern kannst');
  }
}

/// One small thing (or the haircut) and the tile it opens.
typedef KleinesPunkt = ({
  String name,
  String unter,
  bool an,
  bool fertig,
  String ziel,
});

/// Pflege: the 8-week skin plan as a gauge with a needle for this week,
/// below the small things that are due.
class HautBild extends StatelessWidget {
  const HautBild({
    super.key,
    required this.woche,
    required this.teiler,
    required this.gross,
    required this.klein,
    required this.kleine,
    required this.tipp,
    required this.v,
    required this.t,
  });

  /// Week of the plan 1..8, null without a plan.
  final int? woche;

  /// Weeks after which a new phase starts.
  final List<int> teiler;
  final String gross, klein;
  final List<KleinesPunkt> kleine;
  final BildTipp tipp;
  final double v, t;

  static double xAt(int i, int n) => 151 + (i - (n - 1) / 2) * 70;

  @override
  Widget build(BuildContext context) {
    final n = math.min(kleine.length, 4);
    return _Brett(
      maler: _HautMaler(v, t, this),
      punkte: [
        (
          const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
          tipp('pe-haut', _flaeche()),
        ),
        for (var i = 0; i < n; i++)
          (
            Rect.fromLTWH(xAt(i, n) - 34, 244, 68, 76),
            tipp(kleine[i].ziel, _flaeche()),
          ),
      ],
    );
  }
}

class _HautMaler extends _Maler {
  _HautMaler(super.v, super.t, this.b);
  final HautBild b;

  static const _p = Offset(151, 176);
  static const _r = 110.0;

  /// Angle of a week, -90 (left) to 90 (right) degrees, 0 is up.
  static double _w(double w) => -90 + w / 8 * 180;
  static Offset _pp(double a, double r) => Offset(
    _p.dx + r * math.sin(a * math.pi / 180),
    _p.dy - r * math.cos(a * math.pi / 180),
  );
  static Path _bog(double a0, double a1, double r) => Path()
    ..addArc(
      Rect.fromCircle(center: _p, radius: r),
      (a0 - 90) * math.pi / 180,
      (a1 - a0) * math.pi / 180,
    );

  @override
  void paint(Canvas c, Size s) {
    _lab(
      c,
      151,
      22,
      'DEIN HAUT-PLAN · 8 WOCHEN',
      tonAusstrahlung,
      align: TextAlign.center,
    );
    c.drawPath(
      _bog(-90, 90, _r),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = const Color(0x0FFFF0D7),
    );
    final w = b.woche;
    if (w != null) {
      final ziel = _w(w - .5);
      final bis = -90 + (ziel + 90) * _teil(v, .05, .65);
      final bog = _bog(-90, bis, _r);
      c.drawPath(
        bog,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..shader = _goldLinear(Rect.fromCircle(center: _p, radius: _r))
          ..color = const Color(0xD9000000),
      );
      c.drawPath(
        bog,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..color = const Color(0x2EF5DFAE)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    for (final t in b.teiler) {
      if (t <= 0 || t >= 8) continue;
      c.drawLine(
        _pp(_w(t.toDouble()), _r - 12),
        _pp(_w(t.toDouble()), _r + 12),
        _strich(const Color(0xFF130E09), 3),
      );
    }
    for (var i = 0; i < 8; i++) {
      final p = _pp(_w(i + .5), _r - 26);
      final jetzt = w != null && i == w - 1;
      _text(
        c,
        '${i + 1}',
        p.translate(0, 4),
        size: 10,
        weight: jetzt ? FontWeight.w700 : FontWeight.w600,
        color: jetzt
            ? tonAusstrahlung
            : w != null && i < w - 1
            ? _soft
            : _leise,
      );
    }
    if (w != null) {
      final ziel = _w(w - .5);
      final q = Curves.easeOutBack.transform(_teil(v, .1, .8));
      final a = -88 + (ziel + 88) * q;
      c.save();
      c.translate(_p.dx, _p.dy);
      c.rotate(a * math.pi / 180);
      final nadel = Path()
        ..moveTo(-3.2, 0)
        ..lineTo(0, -_r + 6)
        ..lineTo(3.2, 0)
        ..close();
      c.drawPath(nadel, _wolke(.6, blur: 6));
      c.drawPath(nadel, Paint()..color = _goldHell);
      c.restore();
    }
    c.drawCircle(_p, 9, Paint()..shader = _goldR(_p, 9));
    c.drawCircle(_p, 3, Paint()..color = _goldInk);
    _text(
      c,
      b.gross,
      const Offset(151, 208),
      size: w == null ? 14 : 15,
      sora: true,
      weight: FontWeight.w700,
      color: _ink,
      maxBreite: 270,
    );
    _text(c, b.klein, const Offset(151, 225), size: 10.5, maxBreite: 270);
    final k = b.kleine.take(4).toList();
    if (k.isEmpty) {
      _text(c, 'Zähne, Duft, Nägel, Brauen', const Offset(151, 272), size: 11);
    }
    for (final (i, x) in k.indexed) {
      final m = Offset(HautBild.xAt(i, k.length), 266);
      _skaliert(c, m, _plopp(v, .3 + i * .07), () {
        _scheibe(c, m, 18, gold: x.fertig, an: x.an ? tonAusstrahlung : null);
        if (x.fertig) _tick(c, m);
        _text(
          c,
          x.name,
          Offset(m.dx, 300),
          size: 10.5,
          weight: FontWeight.w600,
          color: _ink,
          maxBreite: 68,
        );
        _text(
          c,
          x.unter,
          Offset(m.dx, 314),
          size: 9,
          color: x.an ? tonAusstrahlung : _leise,
          maxBreite: 68,
        );
      });
    }
    _zeile(c, 'Nadel = deine Woche · Scheibe tippen = erledigt');
  }
}

/// One book: 3 put into practice, 2 reading now, 1 finished, 0 not yet.
typedef RegalBuch = ({String titel, int art});

/// Wissen: the skill course as a rail of lessons, the library as books on
/// a shelf.
class WissenBild extends StatelessWidget {
  const WissenBild({
    super.key,
    required this.skill,
    required this.lektionen,
    required this.erreicht,
    required this.lektionText,
    required this.buecher,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final String? skill;
  final int lektionen, erreicht;
  final String lektionText;
  final List<RegalBuch> buecher;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _WissenMaler(v, t, this),
    punkte: [
      (const Rect.fromLTWH(0, 0, bildBreite, 104), tipp('pe-kurs', _flaeche())),
      (
        const Rect.fromLTWH(0, 104, bildBreite, 186),
        tipp('pe-buecher', _flaeche()),
      ),
      (
        const Rect.fromLTWH(0, 290, bildBreite, 70),
        tipp('pe-umsetzen', _flaeche()),
      ),
    ],
  );
}

class _WissenMaler extends _Maler {
  _WissenMaler(super.v, super.t, this.b);
  final WissenBild b;

  static const _hoehen = [92.0, 84.0, 100.0, 78.0, 70.0];

  @override
  void paint(Canvas c, Size s) {
    _lab(
      c,
      22,
      34,
      b.skill == null ? 'DEIN SKILL' : 'DEIN SKILL · ${b.skill!.toUpperCase()}',
      tonAusstrahlung,
    );
    _schiene(c, 14, 54, 274);
    final n = b.lektionen <= 0 ? 12 : b.lektionen;
    final abst = n == 1 ? 0.0 : 250 / (n - 1);
    final r = math.min(9.0, math.max(4.0, abst * .4));
    for (var i = 0; i < n; i++) {
      final m = Offset(n == 1 ? 151 : 26 + i * abst, 58);
      final an = b.skill != null && i == b.erreicht;
      _skaliert(c, m, _plopp(v, .05 + i * .03), () {
        if (an) c.drawCircle(m, r + 5, _wolke(.3));
        _scheibe(
          c,
          m,
          r,
          gold: b.skill != null && i < b.erreicht,
          an: an ? tonAusstrahlung : null,
        );
      });
    }
    _text(
      c,
      b.lektionText,
      const Offset(22, 90),
      weight: FontWeight.w600,
      color: _ink,
      align: TextAlign.left,
      maxBreite: 262,
    );
    _lab(c, 22, 118, 'DEINE BIBLIOTHEK', _leise);
    if (b.buecher.isEmpty) {
      _text(
        c,
        'Noch keine Bücher und Podcasts',
        const Offset(151, 236),
        size: 11,
      );
    }
    for (final (i, x) in b.buecher.take(5).indexed) {
      final h =
          _hoehen[i] *
          Curves.easeOutCubic.transform(_teil(v, .1 + i * .07, .6 + i * .07));
      if (h <= 0) continue;
      final bx = 36.0 + i * 48, y = 272 - h;
      final r = _rr(bx, y, 38, h, 5);
      if (x.art == 2) c.drawRRect(r.inflate(4), _wolke(.22));
      if (x.art == 3) {
        c.drawRRect(r, Paint()..shader = _goldLinear(r.outerRect));
      } else {
        c.drawRRect(r, Paint()..color = x.art == 2 ? _fuell2 : _fuell);
        c.drawRRect(r, _strich(x.art == 2 ? tonAusstrahlung : _rand, 1.3));
      }
      c.save();
      c.translate(bx + 19 + 4, y + h - 10);
      c.rotate(-math.pi / 2);
      _text(
        c,
        x.titel,
        Offset.zero,
        size: 10,
        weight: FontWeight.w700,
        color: x.art == 3
            ? _goldInk
            : x.art > 0
            ? _ink
            : _soft,
        align: TextAlign.left,
        maxBreite: math.max(10, h - 18),
      );
      c.restore();
    }
    c.drawRRect(_rr(20, 272, 262, 8, 4), Paint()..color = _bankF);
    c.drawRRect(
      _rr(20, 272, 262, 3, 1.5),
      Paint()..color = const Color(0x24FFF0D7),
    );
    _text(
      c,
      'Gold = umgesetzt · Leuchten = liest du gerade',
      const Offset(151, 304),
      size: 10,
    );
    _zeile(c, 'Buch tippen = was du daraus machst');
  }
}

// ============================================================== MINDSET

/// One stone on the mountain.
typedef BergStein = ({String titel, String seit});

/// Heute: the mountain at dusk with the avoided things as stones on the
/// path up, the promises kept this week on top.
class BergBild extends StatelessWidget {
  const BergBild({
    super.key,
    required this.steine,
    required this.gehalten,
    required this.vorgenommen,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final List<BergStein> steine;
  final int gehalten, vorgenommen;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _BergMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('m-berg', _flaeche()),
      ),
      (const Rect.fromLTWH(10, 18, 190, 74), tipp('m-wort', _flaeche())),
    ],
  );
}

class _BergMaler extends _Maler {
  _BergMaler(super.v, super.t, this.b);
  final BergBild b;

  static const _orte = [Offset(78, 276), Offset(150, 226), Offset(118, 170)];

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      const Rect.fromLTWH(0, 0, bildBreite, 300),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF140F0A),
            Color(0xFF15110A),
            Color(0xFF6E5228),
            Color(0xFFC9A25C),
          ],
          stops: [0, .5, .8, 1],
        ).createShader(const Rect.fromLTWH(0, 0, bildBreite, 300)),
    );
    final zufall = math.Random(7);
    for (var i = 0; i < 16; i++) {
      final p = Offset(zufall.nextDouble() * 302, zufall.nextDouble() * 90);
      final r = zufall.nextDouble() + .35, dauer = 2 + zufall.nextDouble() * 3;
      final o = .15 + .75 * (.5 + .5 * math.sin(t / dauer * math.pi * 2 + i));
      c.drawCircle(p, r, Paint()..color = _ink.withValues(alpha: o));
    }
    c.drawCircle(
      const Offset(244, 150),
      40,
      _wolke(.35, blur: 12, farbe: const Color(0xFFF7CF92)),
    );
    final grat = Path()
      ..moveTo(0, 290)
      ..lineTo(70, 240)
      ..lineTo(120, 262)
      ..lineTo(200, 110)
      ..lineTo(250, 150)
      ..lineTo(302, 60);
    final berg = Path()
      ..addPath(grat, Offset.zero)
      ..lineTo(302, 360)
      ..lineTo(0, 360)
      ..close();
    c.drawPath(
      berg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF271F15), Color(0xFF130E09)],
        ).createShader(const Rect.fromLTWH(0, 60, 302, 300)),
    );
    final g = _stueck(grat, _teil(v, .05, .6));
    c.drawPath(g, _leuchtStrich(const Color(0x80F5DFAE), 5, 5));
    c.drawPath(
      g,
      _strich(_goldHell, 2.4)
        ..shader = _goldLinear(const Rect.fromLTWH(0, 60, 302, 230)),
    );
    final weg = Path()
      ..moveTo(40, 320)
      ..cubicTo(70, 300, 90, 290, 78, 276)
      ..cubicTo(66, 262, 140, 250, 150, 226)
      ..cubicTo(160, 202, 110, 190, 118, 170)
      ..cubicTo(126, 150, 170, 140, 200, 112);
    _gestrichelt(
      c,
      weg,
      _strich(const Color(0x38FFF0D7), 2),
      3,
      5,
      _teil(v, .15, .75),
    );
    _skaliert(c, const Offset(200, 104), _plopp(v, .45), () {
      c.drawCircle(const Offset(208, 92), 14, _wolke(.3));
      c.drawLine(
        const Offset(200, 112),
        const Offset(200, 84),
        _strich(tonMindset, 1.8),
      );
      final fahne = Path()
        ..moveTo(200, 84)
        ..lineTo(218, 91)
        ..lineTo(200, 98)
        ..close();
      c.drawPath(fahne, Paint()..shader = _goldLinear(fahne.getBounds()));
    });
    final st = b.steine.take(3).toList();
    if (st.isEmpty) {
      const m = Offset(150, 226);
      _gestrichelt(
        c,
        Path()..addOval(Rect.fromCenter(center: m, width: 34, height: 22)),
        _strich(const Color(0x40FFF0D7), 1.2),
        3,
        4,
      );
      _text(
        c,
        'Leg deinen ersten Stein',
        m.translate(-24, 4),
        weight: FontWeight.w700,
        color: _ink,
        align: TextAlign.right,
      );
    }
    for (final (i, x) in st.indexed) {
      final m = _orte[i];
      final mx = m.dx, my = m.dy;
      _skaliert(c, m, _plopp(v, .25 + i * .08), () {
        if (i == 0) {
          c.drawOval(
            Rect.fromCenter(center: m, width: 52, height: 36),
            _wolke(.22),
          );
        }
        c.drawOval(
          Rect.fromCenter(center: m.translate(0, 4), width: 36, height: 18),
          Paint()..color = const Color(0x99000000),
        );
        final stein = Path()
          ..moveTo(mx - 16, my + 4)
          ..quadraticBezierTo(mx - 15, my - 10, mx - 2, my - 11)
          ..quadraticBezierTo(mx + 15, my - 11, mx + 16, my + 2)
          ..quadraticBezierTo(mx + 10, my + 9, mx, my + 8)
          ..quadraticBezierTo(mx - 12, my + 9, mx - 16, my + 4)
          ..close();
        c.drawPath(stein, Paint()..shader = _dunkelR(m, 18));
        c.drawPath(stein, _strich(i == 0 ? tonMindset : _rand, 1.4));
        c.drawPath(
          Path()
            ..moveTo(mx - 9, my - 5)
            ..quadraticBezierTo(mx - 3, my - 9, mx + 5, my - 8),
          _strich(const Color(0x2EFFF0D7), 1.6),
        );
        final links = mx < 140;
        final tx = mx + (links ? 24 : -24);
        final al = links ? TextAlign.left : TextAlign.right;
        _text(
          c,
          x.titel,
          Offset(tx, my - 2),
          weight: FontWeight.w700,
          color: _ink,
          align: al,
          maxBreite: links ? 290 - tx : tx - 8,
        );
        _text(
          c,
          x.seit,
          Offset(tx, my + 11),
          size: 9.5,
          color: i == 0 ? tonMindset : _soft,
          align: al,
        );
      });
    }
    _lab(c, 22, 34, 'WORT GEHALTEN', tonMindset);
    final n = b.vorgenommen == 0 ? 5 : math.min(b.vorgenommen, 7);
    for (var i = 0; i < n; i++) {
      final m = Offset(30.0 + i * 24, 54);
      _skaliert(c, m, _plopp(v, .05 + i * .05), () {
        _scheibe(c, m, 8, gold: i < b.gehalten);
      });
    }
    _text(
      c,
      b.vorgenommen == 0
          ? 'Nimm dir morgens etwas vor'
          : '${b.gehalten} von ${b.vorgenommen} diese Woche',
      const Offset(22, 84),
      size: 10.5,
      align: TextAlign.left,
    );
    _zeile(c, 'Stein tippen = 2-Minuten-Start');
  }
}

/// Dranbleiben: the excuse mirror on top, the stairs to independence with
/// a light on your step, what you pulled through as gold stones.
class DranBild extends StatelessWidget {
  const DranBild({
    super.key,
    required this.ausreden,
    required this.stufe,
    required this.durch,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final List<({String text, int n})> ausreden;

  /// 1..5.
  final int stufe;

  /// Pulled through this week.
  final int durch;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _DranMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('m-stufe', _flaeche()),
      ),
      (const Rect.fromLTWH(10, 18, 282, 58), tipp('m-aus', _flaeche())),
      (const Rect.fromLTWH(8, 118, 60, 196), tipp('m-durch', _flaeche())),
    ],
  );
}

class _DranMaler extends _Maler {
  _DranMaler(super.v, super.t, this.b);
  final DranBild b;

  @override
  void paint(Canvas c, Size s) {
    _lab(c, 22, 34, 'AUSREDEN-SPIEGEL', _leise);
    final pillen = b.ausreden.isEmpty
        ? [('Noch keine Ausrede', true)]
        : [
            for (final (i, a) in b.ausreden.take(3).indexed)
              ('${a.text} · ${a.n}×', i == 0),
          ];
    var x = 16.0;
    for (final (i, (text, erste)) in pillen.indexed) {
      final w = _breite(text, 9.5, FontWeight.w400) + 22;
      if (x + w > 288) break;
      final r = _rr(x, 44, w, 24, 12);
      _skaliert(c, r.center, _plopp(v, .05 + i * .07), () {
        c.drawRRect(r, Paint()..color = const Color(0x06FFF0D7));
        if (erste) {
          _gestrichelt(c, Path()..addRRect(r), _strich(_rand, 1), 3, 3);
        } else {
          c.drawRRect(r, _strich(_rand, 1));
        }
        _text(
          c,
          text,
          Offset(r.center.dx, 60),
          size: 9.5,
          color: erste ? _soft : _leise,
        );
      });
      x += w + 6;
    }
    _lab(
      c,
      290,
      140,
      'SELBSTSTÄNDIG · STUFE ${b.stufe}',
      tonMindset,
      align: TextAlign.right,
    );
    for (var i = 0; i < 5; i++) {
      final sx = 110.0 + i * 36, y = 300.0 - i * 36;
      final an = i < b.stufe;
      _skaliert(c, Offset(sx + 18, y), _plopp(v, .1 + i * .07), () {
        c.drawRect(
          Rect.fromLTWH(sx, y - 8, 40, 8 + i * 36),
          Paint()
            ..color = an ? const Color(0xFF20180F) : const Color(0xFF150F0A),
        );
        final kante = _rr(sx, y - 8, 40, 4, 2);
        c.drawRRect(
          kante,
          an
              ? (Paint()..shader = _goldLinear(kante.outerRect))
              : (Paint()..color = const Color(0x1AFFF0D7)),
        );
        _text(
          c,
          '${i + 1}',
          Offset(sx + 20, y + 14),
          size: 10,
          weight: FontWeight.w700,
          color: an ? tonMindset : _leise,
        );
      });
    }
    final s1 = (b.stufe.clamp(1, 5)) - 1;
    final licht = Offset(110.0 + s1 * 36 + 20, 300.0 - s1 * 36 - 14);
    final puls = .3 + .1 * math.sin(t * 2);
    _skaliert(c, licht, _plopp(v, .5), () {
      c.drawCircle(licht, 14, _wolke(puls));
      c.drawCircle(licht, 6.5, Paint()..color = const Color(0xFFFFF6E2));
    });
    _lab(c, 22, 132, 'DURCHGEZOGEN', _leise);
    final n = math.min(b.durch, 4);
    if (n == 0) {
      _gestrichelt(
        c,
        Path()..addOval(
          Rect.fromCenter(center: const Offset(34, 156), width: 24, height: 18),
        ),
        _strich(const Color(0x40FFF0D7), 1.2),
        3,
        3,
      );
    }
    for (var i = 0; i < n; i++) {
      final m = Offset(34, 156.0 + i * 36);
      _skaliert(c, m, _plopp(v, .2 + i * .07), () {
        final o = Rect.fromCenter(center: m, width: 24, height: 18);
        c.drawOval(o, Paint()..shader = _goldR(m, 12));
        if (i == 0) {
          c.drawOval(
            Rect.fromCenter(center: m, width: 36, height: 28),
            _strich(const Color(0x66F5DFAE), 1),
          );
        }
      });
    }
    _zeile(c, 'Stein = durchgezogen · Licht = deine Stufe');
  }
}

/// One value as a lantern: how well you lived by it this week (0 to 1).
typedef WertLicht = ({String name, double? wert});

/// Ruhe: the evening question under the moon, the values as lanterns over
/// still water, the water takes your worries.
class RuheBild extends StatelessWidget {
  const RuheBild({
    super.key,
    required this.frage,
    required this.werte,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final String frage;
  final List<WertLicht> werte;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _RuheMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('m-werte', _flaeche()),
      ),
      (const Rect.fromLTWH(10, 20, 226, 70), tipp('m-abend', _flaeche())),
      (const Rect.fromLTWH(0, 240, 302, 90), tipp('m-sorgen', _flaeche())),
    ],
  );
}

class _RuheMaler extends _Maler {
  _RuheMaler(super.v, super.t, this.b);
  final RuheBild b;

  static double _x(int i, int n) => 151 + (i - (n - 1) / 2) * 81;

  @override
  void paint(Canvas c, Size s) {
    c.drawCircle(
      const Offset(248, 46),
      13,
      Paint()..color = const Color(0xFFE9E4D6),
    );
    c.drawCircle(
      const Offset(254, 41),
      11.5,
      Paint()..color = const Color(0xFF130E09),
    );
    _text(
      c,
      'Frage heute Abend',
      const Offset(22, 40),
      size: 10,
      weight: FontWeight.w700,
      color: tonMindset,
      align: TextAlign.left,
    );
    _absatz(
      c,
      '„${b.frage}“',
      const Offset(22, 47),
      breite: 214,
      size: 12,
      sora: true,
      weight: FontWeight.w600,
      color: _ink,
      align: TextAlign.left,
    );
    final w = b.werte.take(3).toList();
    if (w.isEmpty) {
      _text(c, 'Leg deine Werte fest', const Offset(151, 156), size: 11);
    }
    for (final (i, x) in w.indexed) {
      final m = Offset(_x(i, w.length), 150);
      final q = x.wert ?? .15;
      _skaliert(c, m, _plopp(v, .1 + i * .08), () {
        c.drawCircle(m, 18 + q * 10, _wolke(q * .35));
        if (q > .6) {
          c.drawCircle(m, 9, Paint()..shader = _goldR(m, 9));
        } else {
          c.drawCircle(m, 9, Paint()..color = _fuell2);
          c.drawCircle(m, 9, _strich(tonMindset, 1.4));
        }
        _text(
          c,
          x.name,
          m.translate(0, 30),
          weight: FontWeight.w700,
          color: _ink,
          maxBreite: 80,
        );
      });
    }
    const see = Rect.fromLTWH(0, 206, bildBreite, 154);
    c.drawRect(
      see,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A140D), Color(0xFF140F0A)],
        ).createShader(see),
    );
    c.drawLine(
      const Offset(0, 206),
      const Offset(bildBreite, 206),
      _strich(const Color(0x24FFF0D7), 1),
    );
    for (final (i, x) in w.indexed) {
      final q = x.wert ?? .15;
      final rx = 6 + q * 8 + 1.5 * (1 + math.sin(t / 3 * math.pi * 2 + i));
      c.drawOval(
        Rect.fromCenter(
          center: Offset(_x(i, w.length), 226),
          width: rx * 2,
          height: 5,
        ),
        Paint()..color = _goldHell.withValues(alpha: q * .3),
      );
    }
    _text(
      c,
      'Sorgen abgeben',
      const Offset(151, 282),
      size: 12,
      weight: FontWeight.w700,
    );
    _text(
      c,
      'tipp ins Wasser und schreib los',
      const Offset(151, 298),
      size: 10,
      color: _leise,
    );
    _zeile(c, 'Licht = wie gut du danach gelebt hast');
  }
}

/// One area of the life wheel, 1..10, null when not rated yet.
typedef RadAchse = ({String name, int? wert});

/// Langfristig: the life wheel, a sealed letter to yourself, the life
/// goals.
class LangBild extends StatelessWidget {
  const LangBild({
    super.key,
    required this.rad,
    required this.mitte,
    required this.briefText,
    required this.versiegelt,
    required this.ziele,
    required this.tipp,
    required this.v,
    required this.t,
  });

  final List<RadAchse> rad;

  /// The average in the middle, e.g. "6,2", empty before the first wheel.
  final String mitte;
  final String briefText;
  final bool versiegelt;
  final List<String> ziele;
  final BildTipp tipp;
  final double v, t;

  @override
  Widget build(BuildContext context) => _Brett(
    maler: _LangMaler(v, t, this),
    punkte: [
      (
        const Rect.fromLTWH(0, 0, bildBreite, bildHoehe),
        tipp('m-rad', _flaeche()),
      ),
      (const Rect.fromLTWH(200, 240, 100, 90), tipp('m-brief', _flaeche())),
      (const Rect.fromLTWH(14, 246, 180, 72), tipp('m-ziele', _flaeche())),
    ],
  );
}

class _LangMaler extends _Maler {
  _LangMaler(super.v, super.t, this.b);
  final LangBild b;

  static const _m = Offset(151, 138);
  static const _rr0 = 70.0;

  Offset _rp(int i, int n, double r) {
    final a = -math.pi / 2 + i / n * math.pi * 2;
    return _m + Offset(r * math.cos(a), r * math.sin(a));
  }

  Path _vieleck(List<Offset> p) => Path()..addPolygon(p, true);

  @override
  void paint(Canvas c, Size s) {
    final n = math.max(3, b.rad.length);
    for (final k in [.33, .66, 1.0]) {
      c.drawPath(
        _vieleck([for (var i = 0; i < n; i++) _rp(i, n, _rr0 * k)]),
        _strich(Color.fromRGBO(255, 240, 215, k == 1 ? .14 : .06), 1),
      );
    }
    for (var i = 0; i < n; i++) {
      c.drawLine(_m, _rp(i, n, _rr0), _strich(const Color(0x0FFFF0D7), 1));
    }
    final da = b.rad.any((a) => a.wert != null);
    int? tiefste;
    if (da) {
      for (final (i, a) in b.rad.indexed) {
        if (a.wert == null) continue;
        if (tiefste == null || a.wert! < b.rad[tiefste].wert!) tiefste = i;
      }
      final pts = [
        for (final (i, a) in b.rad.indexed)
          _rp(i, n, _rr0 * (a.wert ?? 0) / 10),
      ];
      _skaliert(c, _m, _plopp(v, .1), () {
        final p = _vieleck(pts);
        c.drawPath(p, Paint()..color = const Color(0x38E8C98B));
        c.drawPath(p, _leuchtStrich(const Color(0x59F5DFAE), 4, 6));
        c.drawPath(
          p,
          _strich(_goldHell, 3)..shader = _goldLinear(p.getBounds()),
        );
      });
      for (final (i, a) in b.rad.indexed) {
        if (a.wert == null) continue;
        final p = pts[i];
        _skaliert(c, p, _plopp(v, .3 + i * .05), () {
          c.drawCircle(p, 10, _wolke(.3));
          c.drawCircle(p, 6, Paint()..shader = _goldR(p, 6));
        });
      }
    } else {
      _gestrichelt(
        c,
        _vieleck([for (var i = 0; i < n; i++) _rp(i, n, _rr0 * .6)]),
        _strich(const Color(0x40FFF0D7), 1.2),
        3,
        4,
      );
    }
    for (final (i, a) in b.rad.indexed) {
      final p = _rp(i, n, _rr0 + 16);
      final farbe = i == tiefste ? tonMindset : _soft;
      if ((p.dx - _m.dx).abs() < 6) {
        _text(
          c,
          a.name,
          p.translate(0, 4),
          size: 10,
          weight: FontWeight.w600,
          color: farbe,
        );
      } else {
        final links = p.dx < _m.dx;
        final w = _breite(a.name, 10, FontWeight.w600);
        final x = links ? math.max(p.dx, 6 + w) : math.min(p.dx, 296 - w);
        _text(
          c,
          a.name,
          Offset(x, p.dy + 4),
          size: 10,
          weight: FontWeight.w600,
          color: farbe,
          align: links ? TextAlign.right : TextAlign.left,
        );
      }
    }
    _text(
      c,
      da ? b.mitte : 'Ausfüllen',
      _m.translate(0, 6),
      size: da ? 18 : 13,
      sora: da,
      weight: FontWeight.w700,
      color: da ? _ink : _soft,
    );
    _skaliert(c, const Offset(250, 274), _plopp(v, .4), () {
      final r = _rr(208, 250, 84, 54, 6);
      c.drawRRect(r, Paint()..color = const Color(0xFF1E170F));
      c.drawRRect(r, _strich(_rand, 1));
      c.drawPath(
        Path()
          ..moveTo(208, 254)
          ..lineTo(250, 282)
          ..lineTo(292, 254),
        _strich(const Color(0x33FFF0D7), 1.4),
      );
      if (b.versiegelt) {
        const m = Offset(250, 282);
        c.drawCircle(m, 11, Paint()..shader = _goldR(m, 11));
        _text(
          c,
          'G',
          const Offset(250, 286),
          size: 9,
          sora: true,
          weight: FontWeight.w700,
          color: _goldInk,
        );
      }
      _text(
        c,
        b.briefText,
        const Offset(250, 320),
        size: 9.5,
        color: tonMindset,
      );
    });
    _lab(c, 22, 262, 'LEBENSZIELE', _leise);
    final z = b.ziele.take(3).toList();
    if (z.isEmpty) {
      _text(
        c,
        '· Was willst du erreichen?',
        const Offset(22, 282),
        size: 10.5,
        align: TextAlign.left,
      );
    }
    for (final (i, x) in z.indexed) {
      _text(
        c,
        '· $x',
        Offset(22, 282.0 + i * 15),
        size: 10.5,
        color: _ink,
        align: TextAlign.left,
        maxBreite: 176,
      );
    }
    _zeile(c, 'Punkt tippen = Wert ansehen');
  }
}
