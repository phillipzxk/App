import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import 'coach_style.dart';
import 'coach_widgets.dart';

/// The coach is happy with you: his laughing face hops in from below,
/// gold sparks burst, one short line, then he is gone again (draft
/// "Körper, lebendig", idea 3, 2026-11-07).
void coachFreut(BuildContext context, String text) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Freude(text: text, fertig: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _Freude extends StatefulWidget {
  const _Freude({required this.text, required this.fertig});
  final String text;
  final VoidCallback fertig;

  @override
  State<_Freude> createState() => _FreudeState();
}

class _FreudeState extends State<_Freude> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward().whenComplete(() => widget.fertig());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: 16,
    right: 16,
    bottom: 26 + MediaQuery.paddingOf(context).bottom,
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          // In (0-.15), hop (.15-.35), stay, out (.85-1).
          final ein = Curves.easeOutBack.transform((v / .15).clamp(0.0, 1.0));
          final aus = ((v - .85) / .15).clamp(0.0, 1.0);
          final hops = v > .15 && v < .35
              ? math.sin((v - .15) / .2 * math.pi * 2).abs() * 14
              : 0.0;
          return Opacity(
            opacity: (1 - aus).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - ein) * 80 + aus * 30),
              child: Row(
                key: const ValueKey('coach-freut'),
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _Funken(v)),
                        ),
                        Transform.translate(
                          offset: Offset(0, -hops),
                          child: Transform.rotate(
                            angle: hops / 14 * -.12,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x88E0BF7E),
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                              child: const CoachAvatar(size: 62, lacht: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2A2117), Color(0xFF1A140E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x8CE0BF7E)),
                        boxShadow: Glas.shadow,
                      ),
                      child: Text(
                        widget.text,
                        style: Glas.tText.copyWith(
                          fontSize: 14,
                          color: CoachStyle.goldLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Gold sparks bursting out from behind the face.
class _Funken extends CustomPainter {
  _Funken(this.v);
  final double v;

  @override
  void paint(Canvas c, Size s) {
    final t = ((v - .1) / .4).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return;
    final m = s.center(Offset.zero);
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + i * .37;
      final d = 20 + 46 * Curves.easeOut.transform(t) * (.7 + (i % 3) * .15);
      c.drawCircle(
        m + Offset(math.cos(a) * d, math.sin(a) * d - 10 * t),
        2.4 * (1 - t) + .6,
        Paint()
          ..color = Color.fromRGBO(245, 223, 174, 1 - t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_Funken old) => old.v != v;
}
