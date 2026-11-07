import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../ui/coach_style.dart';

/// Endless motion is off in widget tests (they wait for all animations).
bool get bewegungAn =>
    bewegungErzwingen ||
    !WidgetsBinding.instance.runtimeType.toString().contains('Test');

/// Turns the motion on in a test (for screenshots and the flight test).
@visibleForTesting
bool bewegungErzwingen = false;

/// The calm page of the account screens (Entwurf 2, 2026-11-01): warm dark
/// gradient and one slowly breathing light instead of many blobs.
class KontoHintergrund extends StatefulWidget {
  const KontoHintergrund({super.key, required this.child, this.lichtY = .28});

  final Widget child;

  /// Height of the light, 0 = top, 1 = bottom.
  final double lichtY;

  @override
  State<KontoHintergrund> createState() => _KontoHintergrundState();
}

class _KontoHintergrundState extends State<KontoHintergrund>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (bewegungAn) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0C0906),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1),
          radius: 1.3,
          colors: [Color(0xFF2A1F13), Color(0xFF140F0A), Color(0xFF0C0906)],
          stops: [0, .55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) =>
                  CustomPaint(painter: _LichtMaler(widget.lichtY, _c.value)),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LichtMaler extends CustomPainter {
  _LichtMaler(this.y, this.t);
  final double y;
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final mitte = Offset(s.width / 2, s.height * y);
    final r = 170.0 * (1 + .12 * t);
    c.drawCircle(
      mitte,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(240, 200, 120, .26 - .06 * t),
            const Color(0x00F0C878),
          ],
        ).createShader(Rect.fromCircle(center: mitte, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_LichtMaler o) => o.t != t || o.y != y;
}

/// The Groundset logo building itself: ground, roots, sprout, leaves. With
/// [leuchten] the roots light up afterwards ("Gesichert").
class WachsendesLogo extends StatefulWidget {
  const WachsendesLogo({super.key, this.size = 150, this.leuchten = false});

  final double size;
  final bool leuchten;

  @override
  State<WachsendesLogo> createState() => _WachsendesLogoState();
}

class _WachsendesLogoState extends State<WachsendesLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.leuchten ? 2600 : 2000),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _LogoMaler(
          _c.value * (widget.leuchten ? 2600 / 2000 : 1),
          widget.leuchten,
        ),
      ),
    ),
  );
}

class _LogoMaler extends CustomPainter {
  _LogoMaler(this.t, this.leuchten);

  /// 0..1 builds the logo, beyond 1 the roots light up.
  final double t;
  final bool leuchten;

  static double _teil(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    const boden = Color(0xFFE8DCC6);
    final licht = leuchten ? _teil(t, 1.0, 1.3) : 0.0;
    final wurzelFarbe = Color.lerp(boden, const Color(0xFFF8E2A8), licht)!;

    // Ground line grows from the middle.
    final g = Curves.easeOut.transform(_teil(t, 0, .25));
    if (g > 0) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          50 - 32 * g,
          59,
          50 + 32 * g,
          65,
          const Radius.circular(3),
        ),
        Paint()..color = boden,
      );
    }

    // Roots, drawn down one after the other.
    final wurzeln = [
      (const Offset(50, 62), const Offset(50, 78), .15, .4),
      (const Offset(50, 68), const Offset(40, 80), .25, .5),
      (const Offset(50, 68), const Offset(60, 80), .25, .5),
      (const Offset(50, 74), const Offset(44, 84), .35, .58),
      (const Offset(50, 74), const Offset(56, 84), .35, .58),
    ];
    final strich = Paint()
      ..color = wurzelFarbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    if (licht > 0) {
      final glanz = Paint()
        ..color = const Color(0xFFF0C878).withValues(alpha: .7 * licht)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (final (a, b, _, _) in wurzeln) {
        canvas.drawLine(a, b, glanz);
      }
    }
    for (final (a, b, von, bis) in wurzeln) {
      final p = Curves.easeOut.transform(_teil(t, von, bis));
      if (p > 0) canvas.drawLine(a, Offset.lerp(a, b, p)!, strich);
    }

    // Sprout grows up.
    final s = Curves.easeOut.transform(_teil(t, .45, .7));
    if (s > 0) {
      canvas.drawLine(
        const Offset(50, 60),
        Offset(50, 60 - 30 * s),
        Paint()
          ..color = const Color(0xFFD9B06A)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    // Leaves open.
    void blatt(Path p, Offset anker, double k, Color farbe) {
      if (k <= 0) return;
      canvas
        ..save()
        ..translate(anker.dx, anker.dy)
        ..scale(k)
        ..translate(-anker.dx, -anker.dy)
        ..drawPath(p, Paint()..color = farbe)
        ..restore();
    }

    blatt(
      Path()
        ..moveTo(50, 44)
        ..cubicTo(38, 44, 32, 36, 32, 28)
        ..cubicTo(42, 28, 50, 34, 50, 44)
        ..close(),
      const Offset(50, 44),
      Curves.elasticOut.transform(_teil(t, .65, .95)),
      const Color(0xFFE0BF7E),
    );
    blatt(
      Path()
        ..moveTo(50, 38)
        ..cubicTo(62, 38, 69, 30, 69, 21)
        ..cubicTo(58, 21, 50, 28, 50, 38)
        ..close(),
      const Offset(50, 38),
      Curves.elasticOut.transform(_teil(t, .75, 1)),
      const Color(0xFFE8C888),
    );
  }

  @override
  bool shouldRepaint(_LogoMaler o) => o.t != t;
}

/// "GROUNDSET" wide-spaced, SET in gold.
class KontoWortmarke extends StatelessWidget {
  const KontoWortmarke({super.key});

  @override
  Widget build(BuildContext context) => const Text.rich(
    TextSpan(
      children: [
        TextSpan(text: 'GROUND'),
        TextSpan(
          text: 'SET',
          style: TextStyle(color: Color(0xFFE0BF7E)),
        ),
      ],
    ),
    style: TextStyle(
      fontFamily: 'Sora',
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: 5,
      color: Color(0xFFE8DCC6),
    ),
  );
}

enum KnopfArt { gold, glas, linie }

/// A big button of the account screens; the gold one gets a passing shine.
class KontoKnopf extends StatefulWidget {
  const KontoKnopf({
    super.key,
    required this.label,
    required this.onTap,
    this.art = KnopfArt.gold,
    this.icon,
    this.laedt = false,
  });

  final String label;
  final VoidCallback? onTap;
  final KnopfArt art;
  final Widget? icon;
  final bool laedt;

  @override
  State<KontoKnopf> createState() => _KontoKnopfState();
}

class _KontoKnopfState extends State<KontoKnopf>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.art == KnopfArt.gold && bewegungAn) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final an = widget.onTap != null;
    final (deko, farbe) = switch (widget.art) {
      KnopfArt.gold => (
        BoxDecoration(
          gradient: an ? CoachStyle.goldGradient : null,
          color: an ? null : const Color(0xFF241E17),
          borderRadius: BorderRadius.circular(18),
          boxShadow: an
              ? const [
                  BoxShadow(
                    color: Color(0x59E0AA5A),
                    blurRadius: 26,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        an ? CoachStyle.goldInk : Glas.soft,
      ),
      KnopfArt.glas => (
        BoxDecoration(
          gradient: Glas.fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Glas.edge),
        ),
        Glas.text,
      ),
      KnopfArt.linie => (
        BoxDecoration(
          color: const Color(0x0DE0BF7E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x8CE0BF7E)),
        ),
        const Color(0xFFF3DCA6),
      ),
    };
    return Semantics(
      button: true,
      enabled: an,
      label: widget.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.laedt ? null : widget.onTap,
          child: Container(
            height: 54,
            decoration: deko,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.art == KnopfArt.gold && an)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) =>
                          CustomPaint(painter: _GlanzMaler(_c.value)),
                    ),
                  ),
                if (widget.laedt)
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: farbe,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: farbe,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlanzMaler extends CustomPainter {
  _GlanzMaler(this.t);
  final double t;

  @override
  void paint(Canvas c, Size s) {
    // Passes in the first 40 % of the loop, then rests.
    final p = (t / .4).clamp(0.0, 1.0);
    if (p <= 0 || p >= 1) return;
    final x = -s.width * .6 + s.width * 1.9 * p;
    final r = Rect.fromLTWH(x, 0, s.width * .4, s.height);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00FFFFFF), Color(0x80FFFFFF), Color(0x00FFFFFF)],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_GlanzMaler o) => o.t != t;
}

/// Fades and slides a part in, at [start] (0..1) of the screen's entrance.
class Auftritt extends StatelessWidget {
  const Auftritt({
    super.key,
    required this.anim,
    required this.start,
    required this.child,
  });

  final Animation<double> anim;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(
      parent: anim,
      curve: Interval(
        start,
        math.min(1, start + .35),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .12),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }
}

/// Small round gold-edged coach face with a sentence.
class KontoCoach extends StatelessWidget {
  const KontoCoach({super.key, required this.text, required this.avatar});

  final String text;
  final Widget avatar;

  @override
  Widget build(BuildContext context) => GlasBox(
    radius: 20,
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: Glas.tText.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    ),
  );
}
