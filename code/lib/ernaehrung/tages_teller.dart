import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';

const tellerFarben = [Color(0xFFF5DFAE), Color(0xFF9DB37A), Color(0xFFD4A85E)];
const tellerNamen = ['Eiweiß', 'Gemüse', 'Energie'];

/// Idea B: one plate for the whole day, three thirds that fill in gold,
/// green and amber as meals are eaten.
class TagesTeller extends StatelessWidget {
  const TagesTeller({
    super.key,
    required this.werte,
    required this.gegessen,
    required this.geplant,
    this.size = 140,
  });

  /// Protein, vegetables, energy, each 0..1.
  final List<double> werte;
  final int gegessen, geplant;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, t, _) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TellerMaler([for (final w in werte) w * t]),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$gegessen von $geplant',
                style: const TextStyle(
                  fontSize: 12,
                  color: CoachStyle.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'gegessen',
                style: TextStyle(fontSize: 11, color: CoachStyle.inkSoft),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TellerMaler extends CustomPainter {
  _TellerMaler(this.werte);
  final List<double> werte;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 12;
    canvas.drawCircle(c, r - 16, Paint()..color = const Color(0xFF1A140E));
    canvas.drawCircle(
      c,
      r - 16,
      Paint()
        ..color = const Color(0xFF3A2E21)
        ..style = PaintingStyle.stroke,
    );
    final rect = Rect.fromCircle(center: c, radius: r);
    for (var k = 0; k < 3; k++) {
      final a0 = -math.pi / 2 + k * 2 * math.pi / 3 + 0.08;
      const span = 2 * math.pi / 3 - 0.16;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, a0, span, false, p..color = const Color(0xFF2A2118));
      final w = k < werte.length ? werte[k].clamp(0.0, 1.0) : 0.0;
      if (w > 0.02) {
        canvas.drawArc(rect, a0, span * w, false, p..color = tellerFarben[k]);
      }
    }
  }

  @override
  bool shouldRepaint(_TellerMaler old) => old.werte != werte;
}
