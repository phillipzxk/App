import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import 'ernaehrung_logik.dart';

/// Idea A (Phillip 2026-10-27): the expected energy over today with every
/// meal as a point on it. Dragging a point sideways moves the meal; the
/// curve follows live, the new time is saved when the finger lets go.
class EnergieKurve extends StatefulWidget {
  const EnergieKurve({
    super.key,
    required this.mahlzeiten,
    required this.start,
    required this.ende,
    required this.gegessen,
    required this.onVerschieben,
    this.training,
    this.trainingName,
    this.schlaf,
    this.onZiehen,
  });

  final List<MahlzeitSlot> mahlzeiten;
  final int start, ende;
  final int? training;
  final String? trainingName;
  final double? schlaf;
  final Set<String> gegessen;
  final void Function(String id, int minute) onVerschieben;

  /// The meals while dragging, for the coach line under the curve.
  final ValueChanged<List<MahlzeitSlot>>? onZiehen;

  @override
  State<EnergieKurve> createState() => _EnergieKurveState();
}

class _EnergieKurveState extends State<EnergieKurve> {
  String? _zieht;
  int? _minute;

  List<MahlzeitSlot> get _slots {
    final z = _zieht, m = _minute;
    if (z == null || m == null) return widget.mahlzeiten;
    return [
      for (final s in widget.mahlzeiten)
        s.id == z
            ? MahlzeitSlot(
                id: s.id,
                name: s.name,
                minute: m,
                snack: s.snack,
                tipp: s.tipp,
              )
            : s,
    ]..sort((a, b) => a.minute.compareTo(b.minute));
  }

  double _x(double minute, double w) =>
      12 + (minute - widget.start) / (widget.ende - widget.start) * (w - 24);

  int _minuteAus(double x, double w) =>
      (widget.start + (x - 12) / (w - 24) * (widget.ende - widget.start))
          .round();

  void _beginn(Offset p, double w) {
    String? best;
    var abstand = 28.0;
    for (final s in widget.mahlzeiten) {
      final d = (_x(s.minute.toDouble(), w) - p.dx).abs();
      if (d < abstand) {
        abstand = d;
        best = s.id;
      }
    }
    if (best != null) setState(() => _zieht = best);
  }

  void _bewegen(Offset p, double w) {
    final id = _zieht;
    if (id == null) return;
    final liste = widget.mahlzeiten;
    final i = liste.indexWhere((s) => s.id == id);
    final lo = i > 0 ? liste[i - 1].minute + 45 : widget.start;
    final hi = i + 1 < liste.length
        ? liste[i + 1].minute - 45
        : widget.ende - 30;
    var m = _minuteAus(p.dx, w);
    m = (m.clamp(lo, math.max(lo, hi)) / 15).round() * 15;
    if (m != _minute) {
      setState(() => _minute = m);
      widget.onZiehen?.call(_slots);
    }
  }

  void _ende() {
    final id = _zieht, m = _minute;
    setState(() {
      _zieht = null;
      _minute = null;
    });
    if (id != null && m != null) widget.onVerschieben(id, m);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return GestureDetector(
          key: const ValueKey('energie-kurve'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _beginn(d.localPosition, w),
          onHorizontalDragUpdate: (d) => _bewegen(d.localPosition, w),
          onHorizontalDragEnd: (_) => _ende(),
          onHorizontalDragCancel: _ende,
          child: CustomPaint(
            size: Size(w, 150),
            painter: _KurvenMaler(
              slots: _slots,
              start: widget.start,
              ende: widget.ende,
              training: widget.training,
              trainingName: widget.trainingName,
              schlaf: widget.schlaf,
              gegessen: widget.gegessen,
              zieht: _zieht,
              x: (m) => _x(m, w),
            ),
          ),
        );
      },
    );
  }
}

class _KurvenMaler extends CustomPainter {
  _KurvenMaler({
    required this.slots,
    required this.start,
    required this.ende,
    required this.training,
    required this.trainingName,
    required this.schlaf,
    required this.gegessen,
    required this.zieht,
    required this.x,
  });

  final List<MahlzeitSlot> slots;
  final int start, ende;
  final int? training;
  final String? trainingName;
  final double? schlaf;
  final Set<String> gegessen;
  final String? zieht;
  final double Function(double minute) x;

  static const _h = 120.0;

  double _e(double m) => energieBei(
    m,
    mahlzeiten: slots,
    start: start,
    ende: ende,
    training: training,
    schlaf: schlaf,
  );

  double _y(double e) => 10 + (1 - e) * (_h - 20);

  void _text(Canvas c, String t, Offset mitte, Color farbe) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(fontSize: 10, color: farbe, fontFamily: 'Figtree'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, mitte - Offset(tp.width / 2, 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = training;
    if (t != null) {
      final r = RRect.fromLTRBR(
        x(t.toDouble()),
        4,
        x(t + 70.0),
        _h,
        const Radius.circular(6),
      );
      canvas.drawRRect(r, Paint()..color = const Color(0x12FFFFFF));
      _text(
        canvas,
        trainingName ?? 'Training',
        Offset(x(t + 35.0), _h + 8),
        CoachStyle.goldLight,
      );
    }
    final pfad = Path();
    for (var m = start.toDouble(); m <= ende; m += 10) {
      final p = Offset(x(m), _y(_e(m)));
      m == start ? pfad.moveTo(p.dx, p.dy) : pfad.lineTo(p.dx, p.dy);
    }
    final flaeche = Path.from(pfad)
      ..lineTo(x(ende.toDouble()), _h)
      ..lineTo(x(start.toDouble()), _h)
      ..close();
    canvas.drawPath(
      flaeche,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x73E0BF7E), Color(0x00E0BF7E)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, _h)),
    );
    canvas.drawPath(
      pfad,
      Paint()
        ..color = const Color(0xFFF5DFAE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    for (final h in [8, 12, 16, 20]) {
      final m = h * 60.0 + (h * 60 < start ? 1440 : 0);
      if (m < start || m > ende) continue;
      if (t != null && (m - t - 35).abs() < 70) continue;
      _text(canvas, '$h', Offset(x(m), _h + 8), CoachStyle.inkSoft);
    }
    for (final s in slots) {
      final p = Offset(x(s.minute.toDouble()), _y(_e(s.minute + 3.0)));
      final r = (s.snack ? 6.0 : 8.0) + (s.id == zieht ? 3 : 0);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = gegessen.contains(s.id)
              ? CoachStyle.goldLight
              : const Color(0xFF1A140E),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = CoachStyle.goldLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_KurvenMaler old) => true;
}
