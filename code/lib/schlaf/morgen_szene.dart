import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'dart:ui' show PointMode;

import '../konto/konto_ui.dart' show bewegungAn;

/// The morning scene of the alarm (vault Umsetzung/Echter Wecker, "Schritte
/// echt zählen", Entwurf 3): app colours, hills with mist, grass in the
/// wind, gold roots under the ground line, shoe prints that climb the hill.
/// Every step pulls the sun higher; [durch] lets it break through with rays
/// and sparks, [trieb] grows a gold sprout.
class MorgenSzene extends StatefulWidget {
  const MorgenSzene({
    super.key,
    this.schritte = 0,
    this.ziel = 30,
    this.durch = 0,
    this.trieb = 0,
    this.child,
  });

  final int schritte;
  final int ziel;

  /// The sun breaking through, 0 to 1.
  final double durch;

  /// The sprout, 0 to 1.
  final double trieb;
  final Widget? child;

  @override
  State<MorgenSzene> createState() => _MorgenSzeneState();
}

class _Funke {
  _Funke(this.x, this.y, this.vx, this.vy, this.r);
  double x, y, vx, vy, r;
  double l = 1;
}

class _Daten extends ChangeNotifier {
  double zeit = 0;
  double p = 0;
  final spuren = <double>[]; // age of each print in seconds
  final funken = <_Funke>[];
  void tick() => notifyListeners();
}

class _MorgenSzeneState extends State<MorgenSzene>
    with SingleTickerProviderStateMixin {
  final _d = _Daten();
  final _zufall = math.Random(7);
  Ticker? _ticker;
  Duration _vorher = Duration.zero;
  Size _groesse = Size.zero;
  late final List<Offset> _korn = List.generate(
    900,
    (_) => Offset(_zufall.nextDouble(), _zufall.nextDouble()),
  );
  late final List<(double, double, double)> _sterne = List.generate(
    46,
    (_) => (
      _zufall.nextDouble(),
      _zufall.nextDouble() * .5,
      _zufall.nextDouble() * 6,
    ),
  );

  double get _ziel => widget.ziel == 0 ? 0 : widget.schritte / widget.ziel;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.schritte; i++) {
      _d.spuren.add(9);
    }
    _d.p = _ziel;
    if (bewegungAn) {
      _ticker = createTicker(_tick)..start();
    }
  }

  void _tick(Duration t) {
    final dt = ((t - _vorher).inMicroseconds / 1e6).clamp(0.0, .05);
    _vorher = t;
    _d.zeit += dt;
    _d.p += (_ziel - _d.p) * math.min(1, dt * 5);
    for (var i = 0; i < _d.spuren.length; i++) {
      _d.spuren[i] += dt;
    }
    for (final f in _d.funken) {
      f
        ..x += f.vx * dt
        ..y += f.vy * dt
        ..vx *= .985
        ..vy += 140 * dt
        ..l -= dt * .75;
    }
    _d.funken.removeWhere((f) => f.l <= 0);
    _d.tick();
  }

  void _funken(Offset o, int n, double kraft) {
    if (!bewegungAn) return;
    for (var i = 0; i < n; i++) {
      final a = _zufall.nextDouble() * math.pi * 2;
      final v = (_zufall.nextDouble() * kraft + 30);
      _d.funken.add(
        _Funke(
          o.dx,
          o.dy,
          math.cos(a) * v,
          math.sin(a) * v - 80,
          _zufall.nextDouble() * 2 + 1.2,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(MorgenSzene old) {
    super.didUpdateWidget(old);
    while (_d.spuren.length < widget.schritte) {
      _d.spuren.add(bewegungAn ? 0 : 9);
      if (_groesse != Size.zero) {
        _funken(
          _MorgenMaler.weg(
            (_d.spuren.length - 1) / math.max(1, widget.ziel - 1),
            _groesse,
          ),
          4,
          60,
        );
      }
    }
    if (_d.spuren.length > widget.schritte) {
      _d.spuren.length = widget.schritte;
    }
    if (old.durch == 0 && widget.durch > 0 && _groesse != Size.zero) {
      _funken(Offset(_groesse.width / 2, _groesse.height * .3), 60, 260);
    }
    if (!bewegungAn) {
      _d.p = _ziel;
      _d.tick();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      _groesse = c.biggest;
      return CustomPaint(
        painter: _MorgenMaler(
          d: _d,
          ziel: widget.ziel,
          durch: widget.durch,
          trieb: widget.trieb,
          korn: _korn,
          sterne: _sterne,
        ),
        child: widget.child ?? const SizedBox.expand(),
      );
    },
  );
}

Color _mix(int a, int b, double t) => Color.lerp(Color(a), Color(b), t)!;
double _ease(double t) => 1 - math.pow(1 - t.clamp(0.0, 1.0), 3).toDouble();
double _lerp(double a, double b, double t) => a + (b - a) * t;

class _MorgenMaler extends CustomPainter {
  _MorgenMaler({
    required this.d,
    required this.ziel,
    required this.durch,
    required this.trieb,
    required this.korn,
    required this.sterne,
  }) : super(repaint: d);

  final _Daten d;
  final int ziel;
  final double durch;
  final double trieb;
  final List<Offset> korn;
  final List<(double, double, double)> sterne;

  static double boden(double x, Size s) {
    final u = x / s.width;
    return s.height * .70 -
        math.sin(u * math.pi) * s.height * .10 -
        math.sin(u * 7 + 1) * s.height * .008;
  }

  /// Point t (0 to 1) of the path up the hill.
  static Offset weg(double t, Size s) {
    final x = s.width * (.18 + .64 * t) + math.sin(t * 9) * s.width * .03;
    return Offset(x, boden(x, s) - s.height * .012);
  }

  Path _linie(Size s, double Function(double) y) {
    final p = Path()..moveTo(0, y(0));
    for (var x = 3.0; x <= s.width; x += 3) {
      p.lineTo(x, y(x));
    }
    p.lineTo(s.width, y(s.width));
    return p;
  }

  Path _flaeche(Size s, double Function(double) y) => _linie(s, y)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  void _wurzel(
    Canvas c,
    Paint paint,
    Offset o,
    double a,
    double l,
    double b,
    int tiefe,
  ) {
    if (l < 5 || tiefe > 6) return;
    final k = .25 * math.sin(o.dx * .05 + tiefe);
    final ende = o + Offset(math.cos(a + k), math.sin(a + k)) * l;
    final mitte = o + Offset(math.cos(a - k), math.sin(a - k)) * (l * .5);
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(mitte.dx, mitte.dy, ende.dx, ende.dy),
      paint..strokeWidth = b,
    );
    _wurzel(c, paint, ende, a - .5, l * .68, b * .68, tiefe + 1);
    _wurzel(c, paint, ende, a + .45, l * .6, b * .65, tiefe + 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = d.p, zeit = d.zeit;
    final tt = math.min(1.0, p * .8 + durch * .35);

    // Sky: near black brown at night, deep amber to gold at dawn.
    final himmel = Offset.zero & size;
    canvas.drawRect(
      himmel,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mix(0xFF0B0907, 0xFF1E1711, tt),
            _mix(0xFF120E0B, 0xFF402D1C, tt),
            _mix(0xFF211912, 0xFF966C3A, tt),
            _mix(0xFF2E2217, 0xFFD6AA62, tt),
          ],
          stops: const [0, .32, .58, .72],
        ).createShader(himmel),
    );

    // Stars fade with the dawn.
    for (final (sx, sy, ph) in sterne) {
      final a = (1 - tt) * .85 * (.55 + .45 * math.sin(zeit * 1.6 + ph));
      if (a < .02) continue;
      canvas.drawCircle(
        Offset(sx * w, sy * h),
        1,
        Paint()..color = const Color(0xFFF3E9D6).withValues(alpha: a),
      );
    }

    // The sun climbs with every step.
    final sonne = Offset(
      w * .5,
      _lerp(h * .70, h * .30, _ease(math.min(1, p * .72 + durch * .28))),
    );
    final sr = w * .075 * (1 + durch * .12);
    final glowR = w * (.55 + durch * .35);
    canvas.drawCircle(
      sonne,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF0CE8C).withValues(alpha: .28 + .35 * tt),
            const Color(0xFFD6AA5E).withValues(alpha: .12 + .18 * tt),
            const Color(0x00D6AA5E),
          ],
          stops: const [0, .35, 1],
        ).createShader(Rect.fromCircle(center: sonne, radius: glowR)),
    );
    if (durch > 0) {
      canvas
        ..save()
        ..translate(sonne.dx, sonne.dy)
        ..rotate(zeit * .05);
      final l = h * .6;
      for (var i = 0; i < 9; i++) {
        canvas.rotate(math.pi * 2 / 9);
        final b = .09 + .04 * math.sin(zeit * .7 + i);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(l, -l * b)
            ..lineTo(l, l * b)
            ..close(),
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = LinearGradient(
              colors: [
                const Color(0xFFF5DFAE).withValues(alpha: .09 * durch),
                const Color(0x00F5DFAE),
              ],
            ).createShader(Rect.fromLTWH(0, -l * b, l, 2 * l * b)),
        );
      }
      canvas.restore();
    }
    canvas
      ..drawCircle(
        sonne,
        sr * 1.15,
        Paint()
          ..color = const Color(0xFFF5D696).withValues(alpha: .6 + .3 * tt)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + 16 * tt),
      )
      ..drawCircle(
        sonne,
        sr,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.2, -.2),
            colors: [Color(0xFFFFF6E0), Color(0xFFF5DFAE), Color(0xD9E0B46E)],
            stops: [0, .7, 1],
          ).createShader(Rect.fromCircle(center: sonne, radius: sr)),
      );

    // Thin cloud bands, lit from below.
    for (var i = 0; i < 4; i++) {
      final cw = w * (.28 + .08 * (i % 2));
      final cx =
          ((zeit * 3 * (i * .5 + .6) + i * w * .37) % (w * 1.6)) - w * .3;
      final cy = h * (.16 + i * .075);
      final r = Rect.fromCenter(
        center: Offset(cx, cy),
        width: cw * 2,
        height: h * .018,
      );
      final farbe = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mix(0xFF18130E, 0xFF463220, tt).withValues(alpha: .4 + .25 * tt),
            _mix(0xFF281E14, 0xFFE8BE78, tt).withValues(alpha: .4 + .25 * tt),
          ],
        ).createShader(r);
      canvas
        ..drawOval(r, farbe)
        ..drawOval(
          Rect.fromCenter(
            center: Offset(cx + cw * .35, cy - h * .006),
            width: cw * .9,
            height: h * .016,
          ),
          farbe,
        );
    }

    // Far hills, mist, middle hills.
    double huegel(double x, double basis, double amp, double f, double ph) {
      final u = x / w;
      return h * basis -
          amp *
              h *
              (math.sin(u * f + ph) * .5 +
                  math.sin(u * f * 2.3 + ph * 2) * .25 +
                  math.sin(u * f * 5.1) * .08);
    }

    canvas.drawPath(
      _flaeche(size, (x) => huegel(x, .66, .045, 4, 1)),
      Paint()..color = _mix(0xFF1C1610, 0xFF785834, tt),
    );
    final nebel = Rect.fromLTWH(0, h * .6, w, h * .12);
    canvas.drawRect(
      nebel,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00E0BF7E),
            const Color(0xFFE0BF7E).withValues(alpha: .05 + .12 * tt),
            const Color(0x00E0BF7E),
          ],
          stops: const [0, .6, 1],
        ).createShader(nebel),
    );
    canvas.drawPath(
      _flaeche(size, (x) => huegel(x, .69, .035, 6, 3)),
      Paint()..color = _mix(0xFF16110D, 0xFF4A3622, tt),
    );

    // The front hill.
    final vorne = Rect.fromLTWH(0, h * .6, w, h * .4);
    canvas.drawPath(
      _flaeche(size, (x) => boden(x, size)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mix(0xFF14100C, 0xFF2A2016, tt),
            const Color(0xFF120F0B),
            const Color(0xFF0D0B08),
          ],
          stops: const [0, .35, 1],
        ).createShader(vorne),
    );

    // Grass in the wind.
    final gras = Paint()
      ..color = _mix(0xFF1A140F, 0xFF342618, tt)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var x = 2.0; x < w; x += 5) {
      final y = boden(x, size);
      final l = 3 + (x * 7.3) % 5;
      final sw = math.sin(zeit * 1.4 + x * .02) * 1.5;
      canvas.drawPath(
        Path()
          ..moveTo(x, y + 1)
          ..quadraticBezierTo(x + sw * .5, y - l * .5, x + sw, y - l),
        gras,
      );
    }

    // Gold light on the ridge.
    canvas.drawPath(
      _linie(size, (x) => boden(x, size)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFE0BF7E).withValues(alpha: .18 + .55 * tt),
    );

    // Roots under the ground line, like the logo.
    final rx = w * .5, ry = boden(rx, size) + 2;
    final wurzelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD4A85E).withValues(alpha: .18 + .5 * p),
          const Color(0x009A6D35),
        ],
      ).createShader(Rect.fromLTWH(0, ry, w, h - ry));
    _wurzel(
      canvas,
      wurzelPaint,
      Offset(rx, ry),
      math.pi / 2,
      h * .085 * (.55 + .45 * p),
      2.6,
      0,
    );

    // Shoe prints with a gold glow, a ripple when new.
    for (var i = 0; i < d.spuren.length; i++) {
      final alter = d.spuren[i];
      final t = i / math.max(1, ziel - 1);
      final a = weg(t, size);
      final b = weg(math.min(1, t + .02), size);
      final an = math.atan2(b.dy - a.dy, b.dx - a.dx) + math.pi / 2;
      final seite = i.isOdd ? 1.0 : -1.0;
      final sc = (1.5 - .55 * t) * _ease(alter / .25);
      final o =
          a +
          Offset(math.cos(an - math.pi / 2), math.sin(an - math.pi / 2)) *
              (seite * 5) +
          const Offset(0, 5);
      final welle = alter / 1.2;
      if (welle < 1) {
        canvas.drawOval(
          Rect.fromCenter(center: o, width: welle * 40, height: welle * 10),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFFF5DFAE)
                .withValues(alpha: (1 - welle) * .7),
        );
      }
      final neu = i == d.spuren.length - 1;
      final verblasst = 1 - math.min(.55, (d.spuren.length - 1 - i) * .03);
      final fuss = Paint()
        ..color = neu
            ? const Color(0xFFFFF0CD)
            : const Color(0xFFD4A85E).withValues(alpha: .85 * verblasst);
      canvas
        ..save()
        ..translate(o.dx, o.dy)
        ..rotate(an)
        ..scale(1, .55);
      if (neu) {
        canvas.drawCircle(
          Offset.zero,
          9 * sc,
          Paint()
            ..color = const Color(0x88F5D696)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: Offset(0, -2.4 * sc),
            width: 5.2 * sc,
            height: 7.2 * sc,
          ),
          fuss,
        )
        ..drawOval(
          Rect.fromCenter(
            center: Offset(0, 3.6 * sc),
            width: 4 * sc,
            height: 4.4 * sc,
          ),
          fuss,
        )
        ..restore();
    }

    // The sprout.
    if (trieb > 0) {
      final bx = w * .82, by = boden(bx, size), k = _ease(trieb);
      final hh = h * .065 * k;
      canvas.drawPath(
        Path()
          ..moveTo(bx, by)
          ..quadraticBezierTo(bx - 5, by - hh * .5, bx, by - hh),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFF9A6D35), Color(0xFFF5DFAE)],
          ).createShader(Rect.fromLTWH(bx - 6, by - hh, 12, hh + 1)),
      );
      void blatt(double dir, double f, double gr) {
        final l = 14 * k * gr;
        canvas
          ..save()
          ..translate(bx, by - hh * f)
          ..rotate(dir * .8 + math.sin(zeit * 1.5) * .06)
          ..drawPath(
            Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(dir * l / 2, -5 * k * gr, dir * l, 0)
              ..quadraticBezierTo(dir * l / 2, 4 * k * gr, 0, 0),
            Paint()
              ..shader = LinearGradient(
                colors: const [Color(0xFFD4A85E), Color(0xFFF5DFAE)],
              ).createShader(Rect.fromLTWH(math.min(0, dir * l), -5, l, 10)),
          )
          ..restore();
      }

      blatt(-1, .65, 1);
      blatt(1, .95, 1.1);
      canvas.drawCircle(
        Offset(bx, by - hh),
        10 * k,
        Paint()
          ..color = const Color(0xFFF5DFAE).withValues(alpha: .25 * k)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Sparks.
    for (final f in d.funken) {
      canvas.drawCircle(
        Offset(f.x, f.y),
        f.r * f.l,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = const Color(0xFFF5D696).withValues(alpha: f.l.clamp(0, 1)),
      );
    }

    // Vignette and a fine grain for a photographic feel.
    canvas.drawRect(
      himmel,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.1),
          radius: .95,
          colors: const [Color(0x00000000), Color(0x73000000)],
          stops: const [.45, 1],
        ).createShader(himmel),
    );
    canvas.drawPoints(
      PointMode.points,
      [for (final k in korn) Offset(k.dx * w, k.dy * h)],
      Paint()
        ..color = const Color(0x14F3E9D6)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MorgenMaler old) =>
      old.durch != durch || old.trieb != trieb || old.ziel != ziel;
}
