import 'package:flutter/material.dart';

import '../ui/coach_style.dart';

/// One bar per night, oldest on the left; nights without an entry stay
/// empty. The dashed line marks 8 hours.
class SleepChart extends StatelessWidget {
  const SleepChart({super.key, required this.nights});

  final List<double?> nights;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: CustomPaint(painter: _BarPainter(nights), size: Size.infinite),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.nights);

  final List<double?> nights;

  static const _max = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (nights.isEmpty) return;
    double y(double h) => size.height * (1 - h / _max);

    final guide = Paint()
      ..color = CoachStyle.inkSoft.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y(8)), Offset(x + 4, y(8)), guide);
    }

    final slot = size.width / nights.length;
    final width = slot * 0.6;
    for (var i = 0; i < nights.length; i++) {
      final h = nights[i];
      final left = slot * i + (slot - width) / 2;
      final paint = Paint()
        ..color = h == null
            ? CoachStyle.bar.withValues(alpha: 0.5)
            : i == nights.length - 1
            ? CoachStyle.gold
            : CoachStyle.bar;
      final top = h == null ? size.height - 4 : y(h.clamp(0, _max));
      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          top,
          left + width,
          size.height,
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.nights != nights;
}
