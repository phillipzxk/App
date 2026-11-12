import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';

/// The glass look of the area pages (vault Umsetzung/Home-Schichten
/// "Glas-Wurzelwerk", area pages decided 2026-10-29): see-through light
/// layers on the dark page, a fine light edge, gold for what matters.
abstract final class Glas {
  static const radius = 24.0;

  // Since the Umbau (vault Umsetzung/Umbau.md, 2026-11-12): calm, even
  // glass without a gold frame, like the tiles on Heute.
  static const fill = LinearGradient(
    colors: [Color(0x0FFFF5E6), Color(0x0FFFF5E6)],
  );

  static const goldFill = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x24F5DFAE), Color(0x12F5DFAE)],
  );

  static const nightFill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x73464A8C), Color(0x990E0F22)],
  );

  static const edge = Color(0x0DFFF5E6);
  static const goldEdge = Color(0x33F5DFAE);
  static const nightEdge = Color(0x38AAB4FF);
  static const label = Color(0xFFE6C98F);
  static const soft = Color(0xFFCDBB98);
  static const text = Color(0xFFF7EEDD);

  static const shadow = <BoxShadow>[];

  static const goldShadow = <BoxShadow>[];

  static TextStyle tLabel = const TextStyle(
    fontFamily: 'Figtree',
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: label,
  );

  static TextStyle tText = const TextStyle(
    fontFamily: 'Figtree',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.3,
    letterSpacing: -0.2,
    color: text,
  );

  static TextStyle tSoft = const TextStyle(
    fontFamily: 'Figtree',
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.35,
    color: soft,
  );

  static TextStyle tBig = const TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: 1.05,
    letterSpacing: -0.6,
  );
}

enum GlasArt { normal, gold, nacht }

/// A pane of glass: light gradient, fine edge, soft shadow.
class GlasBox extends StatelessWidget {
  const GlasBox({
    super.key,
    required this.child,
    this.art = GlasArt.normal,
    this.padding = const EdgeInsets.all(14),
    this.radius = Glas.radius,
  });

  final Widget child;
  final GlasArt art;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final (fill, edge, shadow) = switch (art) {
      GlasArt.normal => (Glas.fill, Glas.edge, Glas.shadow),
      GlasArt.gold => (Glas.goldFill, Glas.goldEdge, Glas.goldShadow),
      GlasArt.nacht => (Glas.nightFill, Glas.nightEdge, Glas.shadow),
    };
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: edge),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

/// Round glass button with a gold line icon.
class GlasIcon extends StatelessWidget {
  const GlasIcon(this.icon, {super.key, this.size = 34, this.farbe});

  final IconData icon;
  final double size;
  final Color? farbe;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        center: Alignment(-0.3, -0.5),
        radius: 0.9,
        colors: [Color(0x40FFF0D2), Color(0x0DFFECC8), Color(0x730A0704)],
        stops: [0, 0.5, 1],
      ),
      border: Border.all(color: const Color(0x33FFEED7)),
    ),
    child: Icon(icon, size: size * .5, color: farbe ?? CoachStyle.goldLight),
  );
}

/// Text painted with the gold gradient.
class GoldSchrift extends StatelessWidget {
  const GoldSchrift(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) => CoachStyle.goldTextGradient.createShader(r),
    child: Text(
      text,
      textAlign: textAlign,
      style: style.copyWith(color: Colors.white),
    ),
  );
}

/// The area's score in a glass ring with a gold arc (value 0..10).
class WertRing extends StatelessWidget {
  const WertRing({super.key, required this.wert, this.size = 70});

  final int? wert;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size + 14,
    height: size + 14,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (wert ?? 0) / 10),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        painter: _RingPainter(t),
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.5),
                radius: 0.9,
                colors: [
                  Color(0x4DFFF0D2),
                  Color(0x0FFFECC8),
                  Color(0x8C0A0704),
                ],
                stops: [0, 0.45, 1],
              ),
              border: Border.all(color: const Color(0x33FFEED7)),
              boxShadow: Glas.shadow,
            ),
            alignment: Alignment.center,
            child: GoldSchrift(
              wert == null ? '–' : '${(t * 10).round()}',
              style: Glas.tBig.copyWith(fontSize: size * .4),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final r = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 2,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = CoachStyle.goldLight;
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * t, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

/// The dark page with slow gold light blobs behind the glass.
class GlasHintergrund extends StatefulWidget {
  const GlasHintergrund({super.key, required this.child});
  final Widget child;

  @override
  State<GlasHintergrund> createState() => _GlasHintergrundState();
}

class _GlasHintergrundState extends State<GlasHintergrund>
    with SingleTickerProviderStateMixin {
  // Endless motion is off in widget tests (they wait for all animations).
  late final bool _lebendig = !WidgetsBinding.instance.runtimeType
      .toString()
      .contains('Test');
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    if (_lebendig) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1B1611), Color(0xFF0F0C09)],
      ),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) =>
                CustomPaint(painter: _BlobPainter(_c.value)),
          ),
        ),
        widget.child,
      ],
    ),
  );
}

/// One soft gold light from the top right that drifts slowly (Umbau
/// 2026-11-12: gold only, no coloured lights).
class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w * (.8 - .12 * t), -h * .04);
    final r = w * (1.05 + .1 * t);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x38E9C98A), Color(0x00E9C98A)],
          stops: [0, .8],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
