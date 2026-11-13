import 'dart:async';

import 'package:flutter/material.dart';

/// The measured values fall as small gold seeds into the coach card, once
/// a day (vault Umsetzung/Apple Health.md, Entwurf 2 "Coach und Heute").
/// Lies over the coach card and lets every tap through.
class SamenRegen extends StatefulWidget {
  const SamenRegen({super.key, required this.samen, this.onFertig});

  final List<String> samen;
  final VoidCallback? onFertig;

  @override
  State<SamenRegen> createState() => _SamenRegenState();
}

class _SamenRegenState extends State<SamenRegen>
    with SingleTickerProviderStateMixin {
  static const _fall = 1600;
  static const _abstand = 350;

  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: _fall + _abstand * (widget.samen.length - 1).clamp(0, 9),
    ),
  );

  @override
  void initState() {
    super.initState();
    unawaited(
      _a.forward().then((_) {
        if (mounted) widget.onFertig?.call();
      }),
    );
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, c) => AnimatedBuilder(
        animation: _a,
        builder: (context, _) {
          final ms = _a.value * _a.duration!.inMilliseconds;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < widget.samen.length; i++)
                _samen(i, ((ms - i * _abstand) / _fall).clamp(0.0, 1.0), c),
            ],
          );
        },
      ),
    ),
  );

  Widget _samen(int i, double t, BoxConstraints c) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final n = widget.samen.length;
    final x = c.maxWidth * (.08 + .7 * (n == 1 ? .4 : i / (n - 1)));
    final kurve = Curves.easeIn.transform(t);
    final deckkraft = t < .25 ? t / .25 : 1 - (t - .25) / .75;
    return Positioned(
      left: x,
      top: -40 + 120 * kurve,
      child: Opacity(
        opacity: deckkraft.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 1 - .4 * kurve,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xF0241C13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x73F3D79A)),
            ),
            child: Text(
              widget.samen[i],
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 12,
                color: Color(0xFFF3D79A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
