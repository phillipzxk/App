import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import 'weight.dart';

/// Line of the weekly averages, oldest week on the left.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.weeks});

  final List<WeekAverage> weeks;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: CustomPaint(painter: _ChartPainter(weeks), size: Size.infinite),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.weeks);

  final List<WeekAverage> weeks;

  @override
  void paint(Canvas canvas, Size size) {
    if (weeks.isEmpty) return;
    final values = [for (final w in weeks) w.kg];
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    // Keep at least 2 kg of range so small swings don't look dramatic.
    if (hi - lo < 2) {
      final mid = (hi + lo) / 2;
      lo = mid - 1;
      hi = mid + 1;
    }
    const pad = 10.0;
    Offset point(int i) {
      final x = weeks.length == 1
          ? size.width / 2
          : pad + (size.width - 2 * pad) * i / (weeks.length - 1);
      final y = pad + (size.height - 2 * pad) * (hi - values[i]) / (hi - lo);
      return Offset(x, y);
    }

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (final y in [pad, size.height / 2, size.height - pad]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final line = Paint()
      ..color = CoachStyle.gold
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < weeks.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = CoachStyle.gold;
    for (var i = 0; i < weeks.length; i++) {
      canvas.drawCircle(point(i), i == weeks.length - 1 ? 5 : 3, dot);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.weeks != weeks;
}
