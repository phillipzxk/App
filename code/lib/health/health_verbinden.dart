import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'health_dienst.dart';

/// The 7 roots, one per kind of data (vault Umsetzung/Apple Health.md).
const healthWurzeln = [
  'Schlaf',
  'Puls',
  'HRV',
  'Trainings',
  'Gewicht',
  'Schritte',
  'Tageslicht',
];

/// "Lass dein Handy mitreden": a heartbeat runs from the Apple Health heart
/// down a gold stem below the ground, then the 7 roots light up one by one.
/// Then Apple's own question comes.
class HealthVerbindenSeite extends StatefulWidget {
  const HealthVerbindenSeite({
    super.key,
    required this.dienst,
    this.onVerbunden,
  });

  final HealthDienst dienst;
  final VoidCallback? onVerbunden;

  @override
  State<HealthVerbindenSeite> createState() => _HealthVerbindenSeiteState();
}

enum _Stand { offen, laeuft, verbunden, fehler }

class _HealthVerbindenSeiteState extends State<HealthVerbindenSeite>
    with TickerProviderStateMixin {
  late final AnimationController _herz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  late final AnimationController _fluss = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  _Stand _stand = _Stand.offen;

  @override
  void initState() {
    super.initState();
    widget.dienst.verbunden().then((v) {
      if (v && mounted) {
        _fluss.value = 1;
        setState(() => _stand = _Stand.verbunden);
      }
    });
  }

  @override
  void dispose() {
    _herz.dispose();
    _fluss.dispose();
    super.dispose();
  }

  Future<void> _verbinden() async {
    setState(() => _stand = _Stand.laeuft);
    _fluss.value = 0;
    final anim = _fluss.forward();
    final ok = await widget.dienst.verbinden();
    await anim;
    if (!mounted) return;
    if (ok) {
      setState(() => _stand = _Stand.verbunden);
      widget.onVerbunden?.call();
    } else {
      _fluss.value = 0;
      setState(() => _stand = _Stand.fehler);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (knopf, text) = switch (_stand) {
      _Stand.offen => (
        'Mit Apple Health verbinden',
        'Dein iPhone und deine Uhr messen jede Nacht mit. Verbunden fließt das '
            'in deine Wurzeln. Groundset liest nur und schreibt nichts.',
      ),
      _Stand.laeuft => (
        'Verbinden …',
        'Gleich fragt dich Apple, was Groundset lesen darf. Du kannst jede '
            'Art einzeln an- oder ausschalten.',
      ),
      _Stand.verbunden => (
        'Fertig',
        'Verbunden. Ab jetzt fließen deine Werte in den Schlafwert und zu '
            'deinem Coach. Ändern kannst du das jederzeit in der Health-App '
            'unter Teilen, Apps, Groundset.',
      ),
      _Stand.fehler => (
        'Nochmal versuchen',
        'Das hat nicht geklappt. Auf diesem Gerät gibt es Apple Health '
            'vielleicht nicht, zum Beispiel auf manchen iPads.',
      ),
    };
    return Scaffold(
      backgroundColor: const Color(0xFF0A0806),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.3,
            colors: [Color(0xFF1C1838), Color(0xFF0F0C1C), Color(0xFF0A0806)],
            stops: [0, .55, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const ValueKey('health-zurueck'),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: CoachStyle.goldLight,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Text(
                  'SCHLAF & ENERGIE',
                  style: tSoft.copyWith(letterSpacing: 2, fontSize: 10.5),
                ),
                const SizedBox(height: 2),
                GoldText(
                  'Lass dein Handy mitreden',
                  style: tTitel.copyWith(fontSize: 25),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(text, key: ValueKey(_stand), style: tText),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_herz, _fluss]),
                    builder: (context, _) => CustomPaint(
                      key: const ValueKey('health-wurzeln'),
                      painter: _WurzelMaler(_herz.value, _fluss.value),
                      size: Size.infinite,
                    ),
                  ),
                ),
                MainButton(
                  key: const ValueKey('health-verbinden'),
                  label: knopf,
                  onPressed: switch (_stand) {
                    _Stand.laeuft => null,
                    _Stand.verbunden => () => Navigator.of(context).maybePop(),
                    _ => _verbinden,
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WurzelMaler extends CustomPainter {
  _WurzelMaler(this.herz, this.fluss);

  /// 0..1 heart beat loop.
  final double herz;

  /// 0..1: stem (to .38), then the roots one after the other.
  final double fluss;

  static const _gold1 = Color(0xFFF3D79A);
  static const _gold2 = Color(0xFFC9993F);

  @override
  void paint(Canvas canvas, Size size) {
    final mx = size.width / 2;
    final herzY = size.height * .1;
    final boden = size.height * .36;
    final stamm = (fluss / .38).clamp(0.0, 1.0);

    // Heart with a soft pulse.
    final puls = math.sin(herz * math.pi * 2) * .5 + .5;
    canvas.drawCircle(
      Offset(mx, herzY),
      26 + puls * 8,
      Paint()..color = const Color(0x1FFF2D55),
    );
    final h = Path()
      ..moveTo(mx, herzY + 14)
      ..cubicTo(mx - 4, herzY + 10, mx - 17, herzY + 2, mx - 16, herzY - 7)
      ..cubicTo(mx - 15, herzY - 15, mx - 4, herzY - 16, mx, herzY - 8)
      ..cubicTo(mx + 4, herzY - 16, mx + 15, herzY - 15, mx + 16, herzY - 7)
      ..cubicTo(mx + 17, herzY + 2, mx + 4, herzY + 10, mx, herzY + 14)
      ..close();
    canvas.drawPath(h, Paint()..color = const Color(0xFFFF2D55));

    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..shader = ui.Gradient.linear(
        Offset(0, herzY),
        Offset(0, size.height),
        const [_gold1, _gold2],
      );

    // Stem from the heart to the ground.
    final stammOben = herzY + 22;
    if (stamm > 0) {
      canvas.drawLine(
        Offset(mx, stammOben),
        Offset(mx, stammOben + (boden - stammOben) * stamm),
        gold,
      );
      if (stamm < 1) {
        canvas.drawCircle(
          Offset(mx, stammOben + (boden - stammOben) * stamm),
          5,
          Paint()..color = const Color(0xFFFF2D55),
        );
      }
    }

    // Ground line and the small sprout.
    canvas.drawLine(
      Offset(size.width * .08, boden),
      Offset(size.width * .92, boden),
      Paint()
        ..color = const Color(0x80D9C7A7)
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(mx, boden)
        ..quadraticBezierTo(mx - 4, boden - 18, mx - 14, boden - 24)
        ..moveTo(mx, boden)
        ..quadraticBezierTo(mx + 4, boden - 20, mx + 16, boden - 26),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _gold2,
    );

    // The 7 roots.
    final n = healthWurzeln.length;
    for (var i = 0; i < n; i++) {
      final seite = (i - (n - 1) / 2) / ((n - 1) / 2); // -1..1
      final ex = mx + seite * size.width * .38;
      final ey =
          boden + (size.height - boden) * (.62 + .26 * (1 - seite.abs()));
      final p = Path()
        ..moveTo(mx, boden + 2)
        ..cubicTo(
          mx + seite * 20,
          boden + (ey - boden) * .4,
          ex - seite * 30,
          ey - 50,
          ex,
          ey,
        );
      final an = ((fluss - .38) / .62 * n - i).clamp(0.0, 1.0);
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0x40D9C7A7),
      );
      if (an > 0) {
        for (final m in p.computeMetrics()) {
          canvas.drawPath(
            m.extractPath(0, m.length * an),
            gold..strokeWidth = 2.4,
          );
        }
      }
      canvas.drawCircle(
        Offset(ex, ey),
        an >= 1 ? 5 : 3,
        Paint()..color = an >= 1 ? _gold1 : const Color(0x59D9C7A7),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: healthWurzeln[i],
          style: TextStyle(
            fontFamily: 'Figtree',
            fontSize: 11,
            color: Color.fromRGBO(233, 223, 207, an >= 1 ? .95 : .35),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(ex - tp.width / 2, ey + 8));
    }
  }

  @override
  bool shouldRepaint(_WurzelMaler old) =>
      old.herz != herz || old.fluss != fluss;
}
