import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import 'health_logik.dart';

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

/// The glass fields under the coach card: only what the phone measured
/// new today.
class HealthFelderListe extends StatelessWidget {
  const HealthFelderListe({
    super.key,
    required this.felder,
    required this.onKnopf,
  });

  final List<HealthFeld> felder;
  final ValueChanged<HealthFeld> onKnopf;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('health-felder'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < felder.length; i++)
        _Einblenden(
          key: ValueKey('health-feld-${felder[i].id}'),
          verzoegerung: Duration(milliseconds: 250 * i),
          child: _Feld(feld: felder[i], onKnopf: onKnopf),
        ),
    ],
  );
}

class _Feld extends StatelessWidget {
  const _Feld({required this.feld, required this.onKnopf});

  final HealthFeld feld;
  final ValueChanged<HealthFeld> onKnopf;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
    constraints: const BoxConstraints(minHeight: 44),
    decoration: BoxDecoration(
      color: const Color(0x0FFFF0D7),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x38F3D79A)),
    ),
    child: Row(
      children: [
        const Icon(Icons.favorite, size: 13, color: Color(0xFFFF2D55)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            feld.text,
            style: const TextStyle(
              fontFamily: 'Figtree',
              fontSize: 13,
              color: CoachStyle.ink,
            ),
          ),
        ),
        if (feld.knopf)
          TextButton(
            key: ValueKey('health-knopf-${feld.id}'),
            onPressed: () => onKnopf(feld),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF3D79A),
              textStyle: const TextStyle(
                fontFamily: 'Figtree',
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            child: Text(feld.rechts),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              feld.rechts,
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 12,
                color: Color(0xFFF3D79A),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Slides up and fades in after [verzoegerung].
class _Einblenden extends StatefulWidget {
  const _Einblenden({
    super.key,
    required this.verzoegerung,
    required this.child,
  });

  final Duration verzoegerung;
  final Widget child;

  @override
  State<_Einblenden> createState() => _EinblendenState();
}

class _EinblendenState extends State<_Einblenden>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.verzoegerung, () {
      if (mounted) _a.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (context, child) {
      final v = Curves.easeOut.transform(_a.value);
      return Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      );
    },
    child: widget.child,
  );
}
