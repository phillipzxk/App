import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../konto/konto_ui.dart';
import '../ui/coach_style.dart';

/// The small counter top right on Heute during the free week (vault
/// Umsetzung/Abo.md): a ring of 7 parts, today's sprout in the middle.
/// Shortly after opening and on every tap the coach explains day 7.
class AboZaehler extends StatefulWidget {
  const AboZaehler({super.key, required this.tag});

  /// Day of the free week, 1 to 7.
  final int tag;

  @override
  State<AboZaehler> createState() => _AboZaehlerState();
}

class _AboZaehlerState extends State<AboZaehler>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  final _link = LayerLink();
  OverlayEntry? _blase;
  Timer? _zu;

  @override
  void initState() {
    super.initState();
    if (bewegungAn) {
      _zu = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) _zeige(dauer: const Duration(seconds: 4));
      });
    }
  }

  @override
  void dispose() {
    _zu?.cancel();
    _blase?.remove();
    _c.dispose();
    super.dispose();
  }

  void _zeige({Duration dauer = const Duration(seconds: 5)}) {
    _blase?.remove();
    _zu?.cancel();
    final e = OverlayEntry(
      builder: (_) => Positioned(
        width: 230,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: GestureDetector(
            onTap: _weg,
            child: const _Blase(
              text:
                  '7 Tage ist alles offen. Am 7. Tag zeige ich dir, was in '
                  'deiner ersten Woche gewachsen ist.',
            ),
          ),
        ),
      ),
    );
    _blase = e;
    Overlay.of(context).insert(e);
    _zu = Timer(dauer, _weg);
  }

  void _weg() {
    _zu?.cancel();
    _blase?.remove();
    _blase = null;
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _link,
    child: Semantics(
      button: true,
      label: 'Gratis-Woche, Tag ${widget.tag} von 7',
      child: GestureDetector(
        key: const ValueKey('abo-zaehler'),
        onTap: () => _blase == null ? _zeige() : _weg(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 11, 4),
          decoration: BoxDecoration(
            color: const Color(0x12FFF0D7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x4DF3D79A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(
                  size: const Size.square(32),
                  painter: _RingMaler(widget.tag, _c.value),
                ),
              ),
              const SizedBox(width: 7),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Tag\n'),
                    TextSpan(
                      text: '${widget.tag} von 7',
                      style: const TextStyle(
                        color: Glas.label,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                style: Glas.tSoft.copyWith(fontSize: 10.5, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Blase extends StatelessWidget {
  const _Blase({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutBack,
    builder: (_, v, child) => Opacity(
      opacity: v.clamp(0, 1),
      child: Transform.scale(
        scale: .94 + .06 * v,
        alignment: Alignment.topRight,
        child: child,
      ),
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Container(
        key: const ValueKey('abo-blase'),
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        decoration: BoxDecoration(
          color: const Color(0xF7241C13),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0x80F3D79A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          text,
          style: Glas.tSoft.copyWith(
            color: Glas.text,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ),
    ),
  );
}

class _RingMaler extends CustomPainter {
  _RingMaler(this.tag, this.t);
  final int tag;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 3;
    for (var i = 0; i < 7; i++) {
      final a0 = -math.pi / 2 + i * 2 * math.pi / 7 + .12;
      final an = i < tag && t * 7 > i;
      final offen = i == tag;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a0,
        2 * math.pi / 7 - .24,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = an
              ? const Color(0xFFF6D690)
              : offen && tag == 6
              ? const Color(0x80F6D690)
              : const Color(0x40D9C7A7),
      );
    }
    // Ground line and a sprout that grows with the days.
    final boden = c.dy + 7;
    canvas.drawLine(
      Offset(c.dx - 6, boden),
      Offset(c.dx + 6, boden),
      Paint()
        ..color = const Color(0x80D9C7A7)
        ..strokeWidth = 1,
    );
    final h = (3 + tag * 1.3) * Curves.easeOut.transform(t);
    final s = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF6D690);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, boden)
        ..lineTo(c.dx, boden - h)
        ..moveTo(c.dx, boden - h * .55)
        ..quadraticBezierTo(c.dx - 2, boden - h * .7, c.dx - 5, boden - h * .62)
        ..moveTo(c.dx, boden - h * .8)
        ..quadraticBezierTo(c.dx + 2, boden - h, c.dx + 5, boden - h * .95),
      s,
    );
  }

  @override
  bool shouldRepaint(_RingMaler old) => old.t != t || old.tag != tag;
}

/// Day 6 under the coach card: "Morgen: Deine erste Woche geht auf."
class MorgenKarte extends StatefulWidget {
  const MorgenKarte({super.key});

  @override
  State<MorgenKarte> createState() => _MorgenKarteState();
}

class _MorgenKarteState extends State<MorgenKarte>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
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
  Widget build(BuildContext context) => GlasBox(
    key: const ValueKey('abo-morgen'),
    art: GlasArt.gold,
    radius: 20,
    padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
    child: Row(
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            size: const Size(48, 44),
            painter: _SamenMaler(_c.value),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MORGEN',
                style: Glas.tSoft.copyWith(fontSize: 10, letterSpacing: 1.8),
              ),
              const SizedBox(height: 2),
              Text(
                'Deine erste Woche geht auf.',
                style: Glas.tText.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SamenMaler extends CustomPainter {
  _SamenMaler(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final m = Offset(size.width / 2, size.height * .62);
    canvas.drawCircle(
      m,
      12 + 8 * t,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF2D0).withValues(alpha: .5 + .4 * t),
            const Color(0x00F6D690),
          ],
        ).createShader(Rect.fromCircle(center: m, radius: 20)),
    );
    final boden = size.height * .5;
    canvas.drawLine(
      Offset(2, boden),
      Offset(size.width - 2, boden),
      Paint()
        ..color = const Color(0x80D9C7A7)
        ..strokeWidth = 1,
    );
    canvas.drawOval(
      Rect.fromCenter(center: m.translate(0, 3), width: 9, height: 13),
      Paint()..color = const Color(0xFFE7C47C),
    );
    canvas.drawPath(
      Path()
        ..moveTo(m.dx, boden)
        ..quadraticBezierTo(m.dx - 2, boden - 7, m.dx - 7, boden - 9)
        ..moveTo(m.dx, boden)
        ..quadraticBezierTo(m.dx + 2, boden - 9, m.dx + 8, boden - 11),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF6D690).withValues(alpha: .2 + .8 * t),
    );
  }

  @override
  bool shouldRepaint(_SamenMaler old) => old.t != t;
}

/// Without Abo under the grey coach card: a calm way back to the coach.
class CoachEinschaltenFeld extends StatelessWidget {
  const CoachEinschaltenFeld({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('coach-einschalten'),
    onTap: onTap,
    child: GlasBox(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Coach wieder einschalten',
              style: Glas.tText.copyWith(fontSize: 14),
            ),
          ),
          Text(
            'ab 5 € im Monat ›',
            style: Glas.tSoft.copyWith(
              color: CoachStyle.goldLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}
