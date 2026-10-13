import 'package:flutter/material.dart';

import 'coach_style.dart';

/// The Groundset symbol "Wurzeln und Trieb": roots below a ground line
/// that nobody sees, a golden sprout above it.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 48, this.ground = CoachStyle.dark});

  final double size;

  /// Colour of the ground line and the roots (light on dark backgrounds).
  final Color ground;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LogoPainter(ground)),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.ground);

  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on the 100 x 100 grid of the approved SVG.
    canvas.scale(size.width / 100);
    final roots = Paint()
      ..color = ground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawLine(const Offset(50, 62), const Offset(50, 78), roots)
      ..drawLine(const Offset(50, 68), const Offset(40, 80), roots)
      ..drawLine(const Offset(50, 68), const Offset(60, 80), roots)
      ..drawLine(const Offset(50, 74), const Offset(44, 84), roots)
      ..drawLine(const Offset(50, 74), const Offset(56, 84), roots);

    final stem = Paint()
      ..color = CoachStyle.gold
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(50, 60), const Offset(50, 30), stem);

    final leaf = Paint()..color = CoachStyle.gold;
    canvas
      ..drawPath(
        Path()
          ..moveTo(50, 44)
          ..cubicTo(38, 44, 32, 36, 32, 28)
          ..cubicTo(42, 28, 50, 34, 50, 44)
          ..close(),
        leaf,
      )
      ..drawPath(
        Path()
          ..moveTo(50, 38)
          ..cubicTo(62, 38, 69, 30, 69, 21)
          ..cubicTo(58, 21, 50, 28, 50, 38)
          ..close(),
        leaf,
      )
      ..drawRRect(
        RRect.fromLTRBR(18, 59, 82, 65, const Radius.circular(3)),
        Paint()..color = ground,
      );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.ground != ground;
}

/// "GROUNDSET" in wide-spaced capitals, SET in gold.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 11});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: const [
        TextSpan(text: 'GROUND'),
        TextSpan(
          text: 'SET',
          style: TextStyle(color: CoachStyle.gold),
        ),
      ],
      style: TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        letterSpacing: fontSize * 0.4,
        color: CoachStyle.dark,
      ),
    ),
  );
}
