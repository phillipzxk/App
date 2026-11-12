import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../konto/konto_ui.dart' show bewegungAn;

/// The look of the "Umbau" (vault Umsetzung/Umbau.md, draft 9 confirmed by
/// Phillip 2026-11-12): espresso brown, calm round glass tiles without
/// frames, gold as the only colour, one light gold tile as the eye-catcher
/// and a living background of fine roots.
abstract final class Umbau {
  /// Dark brown text on the light gold tile.
  static const tinte = Color(0xFF2A1D0D);
  static const tinteWeich = Color(0x9E2A1D0D);
  static const text = Color(0xFFF6ECDB);
  static const weich = Color(0xFFB3A188);
  static const hell = Color(0xFFD8C6A8);
  static const gold = Color(0xFFF5DFAE);
  static const linie = Color(0x1CFFECD2);
  static const glas = Color(0x0FFFF5E6);
  static const radius = 30.0;

  static const grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8E6BC), Color(0xFFC8974D)],
  );

  /// The light gold tile ("Heute dran", "Dein Schnitt").
  static const held = LinearGradient(
    begin: Alignment(-1, -.6),
    end: Alignment(1, .6),
    colors: [Color(0xFFF6E3B8), Color(0xFFD7A45C)],
  );

  static const seite = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B1611), Color(0xFF0F0C09)],
  );

  static const label = TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w600,
    fontSize: 9.5,
    letterSpacing: 1.5,
    color: weich,
  );

  static const zahl = TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w700,
    fontSize: 31,
    height: 1,
    letterSpacing: -.6,
    color: Colors.white,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const titel = TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w600,
    fontSize: 14.5,
    height: 1.25,
    color: text,
  );

  static const klein = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 11.5,
    height: 1.3,
    color: Color(0xFFCDBB9D),
  );
}

/// Paints its child with the gold gradient (for big numbers and names).
class GoldMaske extends StatelessWidget {
  const GoldMaske({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) => Umbau.grad.createShader(r),
    child: child,
  );
}

/// A number that counts up once when it appears (still in tests).
class ZaehlZahl extends StatelessWidget {
  const ZaehlZahl({
    super.key,
    required this.wert,
    required this.style,
    this.stellen = 0,
    this.gold = true,
    this.textKey,
    this.leer,
  });

  /// Key for the number's text (tests look for it).
  final Key? textKey;

  /// Shown instead of a number while there is none yet.
  final String? leer;

  final double wert;
  final TextStyle style;
  final int stellen;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    if (leer case final l?) {
      final t = Text(l, key: textKey, style: style);
      return gold ? GoldMaske(child: t) : t;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: bewegungAn ? 0 : wert, end: wert),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final t = Text(
          v.toStringAsFixed(stellen).replaceAll('.', ','),
          key: textKey,
          style: style,
        );
        return gold ? GoldMaske(child: t) : t;
      },
    );
  }
}

/// A calm round glass tile. It springs in when it appears, leans towards
/// the finger and gives its centre on screen when tapped. [hell] makes the
/// one light gold tile.
class GlasKachel extends StatefulWidget {
  const GlasKachel({
    super.key,
    required this.child,
    this.onTap,
    this.hell = false,
    this.platz = 0,
    this.padding = const EdgeInsets.all(18),
    this.radius = Umbau.radius,
  });

  final Widget child;
  final void Function(Offset mitte)? onTap;
  final bool hell;

  /// Place in the row of tiles: later ones spring in a little later.
  final int platz;
  final EdgeInsets padding;
  final double radius;

  @override
  State<GlasKachel> createState() => _GlasKachelState();
}

class _GlasKachelState extends State<GlasKachel> {
  Offset _kipp = Offset.zero;
  bool _druck = false;

  void _zeig(PointerEvent e, {bool? druck}) {
    final b = context.findRenderObject() as RenderBox?;
    if (b == null || !b.hasSize) return;
    final l = b.globalToLocal(e.position);
    setState(() {
      _druck = druck ?? _druck;
      _kipp = Offset(
        (l.dx / b.size.width - .5).clamp(-.5, .5),
        (l.dy / b.size.height - .5).clamp(-.5, .5),
      );
    });
  }

  void _los() => setState(() {
    _druck = false;
    _kipp = Offset.zero;
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.radius);
    final innen = Padding(padding: widget.padding, child: widget.child);
    Widget k = ClipRRect(
      borderRadius: r,
      child: widget.hell
          ? DecoratedBox(
              decoration: const BoxDecoration(gradient: Umbau.held),
              child: innen,
            )
          : BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Umbau.glas,
                  borderRadius: r,
                  border: Border.all(color: const Color(0x0DFFF5E6)),
                ),
                child: innen,
              ),
            ),
    );
    k = TweenAnimationBuilder<Offset>(
      tween: Tween(begin: Offset.zero, end: _kipp),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: k,
      builder: (context, o, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0012)
          ..rotateX(-o.dy * .22)
          ..rotateY(o.dx * .22),
        child: AnimatedScale(
          scale: _druck ? .975 : 1,
          duration: const Duration(milliseconds: 180),
          child: child,
        ),
      ),
    );
    k = MouseRegion(
      onHover: _zeig,
      onExit: (_) => _los(),
      child: Listener(
        onPointerDown: (e) => _zeig(e, druck: true),
        onPointerMove: _zeig,
        onPointerUp: (_) => _los(),
        onPointerCancel: (_) => _los(),
        child: k,
      ),
    );
    if (widget.onTap case final tap?) {
      k = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final b = context.findRenderObject() as RenderBox?;
          tap(
            b == null
                ? Offset.zero
                : b.localToGlobal(b.size.center(Offset.zero)),
          );
        },
        child: k,
      );
    }
    return Einflug(platz: widget.platz, child: k);
  }
}

/// Lets its child spring in from a little below, once.
class Einflug extends StatelessWidget {
  const Einflug({super.key, required this.child, this.platz = 0});
  final Widget child;
  final int platz;

  @override
  Widget build(BuildContext context) {
    if (!bewegungAn) return child;
    final warte = 120.0 + platz * 80;
    final ganz = warte + 800;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: ganz.round()),
      curve: Interval(warte / ganz, 1, curve: Curves.easeOutBack),
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - v)),
          child: Transform.scale(scale: .96 + .04 * v, child: child),
        ),
      ),
    );
  }
}

class _Wurzel {
  _Wurzel(this.p, this.tiefe);
  final List<Offset> p;
  final int tiefe;
}

/// The fine roots of the background, the same on every device.
List<_Wurzel> _baueNetz() {
  final r = <_Wurzel>[];
  var sd = 11;
  double rnd() {
    sd = (sd * 16807) % 2147483647;
    return sd / 2147483647;
  }

  void ast(double x, double y, double w, int len, int tiefe) {
    final p = [Offset(x, y)];
    for (var i = 0; i < len; i++) {
      w += (rnd() - .5) * .55;
      w *= .96;
      x += math.sin(w) * 16;
      y -= math.cos(w) * 16;
      p.add(Offset(x, y));
      if (tiefe < 2 && i > 3 && rnd() < .17) {
        ast(
          x,
          y,
          w + (rnd() < .5 ? -1 : 1) * (.6 + rnd() * .5),
          ((len - i) * .7).floor() + 4,
          tiefe + 1,
        );
      }
    }
    r.add(_Wurzel(p, tiefe));
  }

  const winkel = [-.55, -.25, 0.0, .25, .55];
  for (var i = 0; i < winkel.length; i++) {
    ast((i - 2) * 12, 0, winkel[i], 36, 0);
  }
  return r;
}

/// The living background "Wurzelnetz" (Phillip's pick 2026-11-12): on the
/// espresso page fine gold roots grow up from the bottom, small lights run
/// along them, and every touch sends a soft wave through them. With
/// [still] the roots fade out (on Fundament the real roots take over).
class Wurzelnetz extends StatefulWidget {
  const Wurzelnetz({super.key, required this.child, this.still = false});
  final Widget child;
  final bool still;

  /// Sends a wave through the background from [global] (a point on screen).
  static void welle(BuildContext context, Offset global) =>
      context.findAncestorStateOfType<_WurzelnetzState>()?._welle(global);

  @override
  State<Wurzelnetz> createState() => _WurzelnetzState();
}

class _WurzelnetzState extends State<Wurzelnetz>
    with SingleTickerProviderStateMixin {
  static final _netz = _baueNetz();
  late final Ticker _ticker = createTicker((d) {
    _zeit.value = d.inMicroseconds / 1e6;
  });
  final _zeit = ValueNotifier<double>(0);
  final _wellen = <(Offset, double)>[];
  double _start = 0;

  @override
  void initState() {
    super.initState();
    if (bewegungAn) _ticker.start();
  }

  @override
  void didUpdateWidget(Wurzelnetz old) {
    super.didUpdateWidget(old);
    // Back on Heute the roots grow in again.
    if (old.still && !widget.still) _start = _zeit.value;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _zeit.dispose();
    super.dispose();
  }

  void _welle(Offset global) {
    if (!bewegungAn) return;
    final b = context.findRenderObject() as RenderBox?;
    if (b == null || !b.hasSize) return;
    _wellen
      ..removeWhere((w) => _zeit.value - w.$2 > 1.4)
      ..add((b.globalToLocal(global), _zeit.value));
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: Umbau.seite),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-.1, -1.25),
              radius: 1.05,
              colors: [Color(0x4DE9C98A), Color(0x00E9C98A)],
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: widget.still ? 0 : 1,
          duration: const Duration(milliseconds: 800),
          child: RepaintBoundary(child: CustomPaint(painter: _NetzMaler(this))),
        ),
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => _welle(e.position),
          child: widget.child,
        ),
      ],
    ),
  );
}

class _NetzMaler extends CustomPainter {
  _NetzMaler(this.s) : super(repaint: s._zeit);
  final _WurzelnetzState s;

  @override
  void paint(Canvas canvas, Size size) {
    final t = s._zeit.value;
    final g = bewegungAn ? ((t - s._start) / 3.2).clamp(0.0, 1.0) : 1.0;
    final wuchs = 1 - (1 - g) * (1 - g);
    final wellen = [
      for (final w in s._wellen)
        if (t - w.$2 < 1.4) w,
    ];
    final fuss = Offset(size.width / 2, size.height + 20);

    Offset ort(Offset p) {
      var o = fuss + p;
      for (final w in wellen) {
        final a = (t - w.$2) / 1.4;
        final d = o - w.$1;
        final l = d.distance == 0 ? 1.0 : d.distance;
        final k = math.exp(-math.pow((l - a * 430) / 46, 2)) * 24 * (1 - a);
        o += d / l * k;
      }
      return o;
    }

    final linie = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final punkt = Paint()..color = const Color(0xE6FFF0C8);
    final schein = Paint()
      ..color = const Color(0x80FFE2A0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (var i = 0; i < _WurzelnetzState._netz.length; i++) {
      final w = _WurzelnetzState._netz[i];
      final n = w.p.length - 1;
      final bis = wuchs * n;
      if (bis < 1) continue;
      final path = Path();
      final ende = math.min(n, bis.floor());
      for (var k = 0; k <= ende; k++) {
        final o = ort(w.p[k]);
        if (k == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      linie
        ..color = Color.fromRGBO(232, 201, 138, .34 - w.tiefe * .08)
        ..strokeWidth = 1.6 - w.tiefe * .45;
      canvas.drawPath(path, linie);
      // A small light runs up each bigger root.
      if (!bewegungAn || w.tiefe > 1) continue;
      final q = ((t * .16 + i * .37) % 1) * n;
      if (q >= bis) continue;
      final k = q.floor();
      final o = ort(Offset.lerp(w.p[k], w.p[math.min(n, k + 1)], q - k)!);
      canvas
        ..drawCircle(o, 5, schein)
        ..drawCircle(o, 2.2, punkt);
    }
  }

  @override
  bool shouldRepaint(_NetzMaler old) => false;
}

/// A small light flies in an arc from [von] to [nach] (points on screen),
/// e.g. from "Heute geschafft" into the Fundament tile.
void fliegeLicht(
  BuildContext context,
  Offset von,
  Offset nach, {
  VoidCallback? onDa,
}) {
  if (!bewegungAn) {
    onDa?.call();
    return;
  }
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late final OverlayEntry e;
  final mitte = Offset.lerp(von, nach, .5)! + const Offset(70, -30);
  e = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: const Cubic(.5, 0, .3, 1),
        onEnd: () {
          e.remove();
          onDa?.call();
        },
        builder: (context, v, _) {
          final u = 1 - v;
          final p = von * (u * u) + mitte * (2 * u * v) + nach * (v * v);
          final gr = 14 * (1 + math.sin(v * math.pi) * .5);
          return Stack(
            children: [
              Positioned(
                left: p.dx - gr / 2,
                top: p.dy - gr / 2,
                width: gr,
                height: gr,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFE9B8),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xCCFFD98A),
                        blurRadius: 14,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
  overlay.insert(e);
}

/// Gold sparks burst once from [ort] (a point on screen).
void funkenBei(BuildContext context, Offset ort) {
  if (!bewegungAn) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late final OverlayEntry e;
  e = OverlayEntry(
    builder: (_) => Positioned(
      left: ort.dx - 90,
      top: ort.dy - 90,
      width: 180,
      height: 180,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          onEnd: e.remove,
          builder: (context, v, _) => CustomPaint(painter: _FunkenMaler(v)),
        ),
      ),
    ),
  );
  overlay.insert(e);
}

class _FunkenMaler extends CustomPainter {
  _FunkenMaler(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0 || v >= 1) return;
    final c = size.center(Offset.zero);
    final rnd = math.Random(3);
    final e = Curves.easeOutCubic.transform(v);
    final p = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    for (var i = 0; i < 22; i++) {
      final w = rnd.nextDouble() * math.pi * 2;
      final d = 80 * (.4 + rnd.nextDouble() * .6) * e;
      p.color = Color.fromRGBO(255, 233, 184, 1 - v);
      canvas.drawCircle(
        c + Offset(math.cos(w) * d, math.sin(w) * d + 30 * v * v),
        3.2 * (1 - v * .7),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_FunkenMaler old) => old.v != v;
}
