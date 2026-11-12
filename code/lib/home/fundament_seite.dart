import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../konto/konto_ui.dart' show bewegungAn;
import '../ui/coach_widgets.dart';
import '../ui/umbau.dart';
import 'today_tab.dart';
import 'wurzelwerk.dart';

/// "Heute und Fundament" (vault Umsetzung/Heute und Fundament.md, draft 6
/// approved by Phillip 2026-11-08 "Sehr gut"): the app has two pages,
/// switched by a slim glass bar at the bottom. Heute keeps the fields on
/// top, Fundament holds the real root system with all areas.

/// Mean of today's area scores, null before the first rating.
double? fundamentSchnitt(List<WurzelBereich> b) {
  final w = [for (final x in b) ?x.wert];
  if (w.isEmpty) return null;
  return w.reduce((a, c) => a + c) / w.length;
}

/// Mean change to yesterday over the areas that know it.
double? fundamentTrend(List<WurzelBereich> b) {
  final d = [for (final x in b) ?x.diff];
  if (d.isEmpty) return null;
  return d.reduce((a, c) => a + c) / d.length;
}

/// The area the coach points at: lowest score, if it is 5 or less.
WurzelBereich? fundamentSchwach(List<WurzelBereich> b) {
  WurzelBereich? s;
  for (final x in b) {
    final w = x.wert;
    if (w == null || w > 5) continue;
    if (s == null || w < s.wert!) s = x;
  }
  return s;
}

String komma(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// The second page: header with the mean score, below the root system that
/// grows in from the top each time the page opens.
class FundamentSeite extends StatelessWidget {
  const FundamentSeite({
    super.key,
    required this.bereiche,
    required this.onOpen,
    this.streak = 0,
    this.wurzeln = 0,
    this.jubelTick = 0,
    this.lebensziele,
    this.name = '',
    this.onKonto,
  });

  /// The round button top right, like on Heute.
  final String name;
  final VoidCallback? onKonto;

  final List<WurzelBereich> bereiche;
  final Future<void> Function(String id, Offset mitte) onOpen;
  final int streak;
  final int wurzeln;
  final int jubelTick;
  final Widget? lebensziele;

  @override
  Widget build(BuildContext context) {
    final s = fundamentSchnitt(bereiche);
    final t = fundamentTrend(bereiche);
    return NightScope(
      child: ListView(
        key: const ValueKey('fundament-seite'),
        padding: const EdgeInsets.only(top: 14, bottom: 120),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'DEINE ${bereiche.length} BEREICHE',
                          style: Umbau.label.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.6,
                            color: Umbau.hell,
                          ),
                        ),
                      ),
                      if (onKonto != null)
                        KontoKnopfKlein(
                          initiale: name.isEmpty ? '' : name[0].toUpperCase(),
                          onTap: onKonto!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fundament',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    height: 1.15,
                    letterSpacing: -.6,
                    color: Umbau.text,
                  ),
                ),
                const SizedBox(height: 16),
                // The same light gold tile as "Heute dran" on Heute.
                GlasKachel(
                  hell: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DEIN SCHNITT',
                            style: Umbau.label.copyWith(
                              color: Umbau.tinteWeich,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ZaehlZahl(
                            wert: s ?? 0,
                            leer: s == null ? '–' : null,
                            stellen: 1,
                            gold: false,
                            textKey: const ValueKey('fundament-schnitt'),
                            style: Umbau.zahl.copyWith(
                              fontSize: 40,
                              color: Umbau.tinte,
                            ),
                          ),
                          if (t != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              trendText(t),
                              style: Umbau.klein.copyWith(
                                color: Umbau.tinteWeich,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            for (final b in bereiche)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 13),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        b.wert?.toString() ?? '–',
                                        style: const TextStyle(
                                          fontFamily: 'Sora',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 21,
                                          height: 1.1,
                                          color: Umbau.tinte,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        kurzName(b.name),
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.fade,
                                        style: const TextStyle(
                                          fontFamily: 'Sora',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 9,
                                          color: Umbau.tinteWeich,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wachsen(
            dauer: const Duration(milliseconds: 2600),
            child: Wurzelwerk(
              bereiche: bereiche,
              onOpen: onOpen,
              streak: streak,
              wurzeln: wurzeln,
              jubelTick: jubelTick,
              gross: true,
              lebensziele: lebensziele,
            ),
          ),
        ],
      ),
    );
  }
}

/// "+0,5 zu gestern", "−1,0 zu gestern" or "wie gestern".
String trendText(double t) =>
    t == 0 ? 'wie gestern' : '${t > 0 ? '+' : '−'}${komma(t.abs())} zu gestern';

/// Short area name under a number or a bar: "Fokus", "Ausstr.".
String kurzName(String name) {
  final w = name.split(' ').first;
  return w.length > 7 ? '${w.substring(0, 6)}.' : w;
}

/// Lets its child grow in from the top: a soft edge with a line of light
/// moves down once when the page opens.
class Wachsen extends StatefulWidget {
  const Wachsen({
    super.key,
    required this.child,
    this.dauer = const Duration(milliseconds: 2400),
  });
  final Widget child;
  final Duration dauer;

  @override
  State<Wachsen> createState() => _WachsenState();
}

class _WachsenState extends State<Wachsen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.dauer)
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = Curves.easeInOutCubic.transform(_c.value);
        if (_c.isCompleted) return child!;
        final m = v * 1.06;
        return Stack(
          children: [
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
                stops: [0, (m - .05).clamp(0.0, 1.0), m.clamp(0.0, 1.0)],
              ).createShader(r),
              child: child,
            ),
            // The line of light at the growing edge.
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      Positioned(
                        left: c.maxWidth * .08,
                        right: c.maxWidth * .08,
                        top: (m - .03) * c.maxHeight,
                        height: 3,
                        child: Opacity(
                          opacity: (1 - v).clamp(0.0, 1.0),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                radius: 3,
                                colors: [Color(0xF2FFE4AA), Color(0x00FFE4AA)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Wide tile at the end of Heute that leads to the Fundament page: the
/// mean score counts up, beside it one gold bar per area.
class FundamentVorschau extends StatelessWidget {
  const FundamentVorschau({
    super.key,
    required this.bereiche,
    required this.onTap,
  });
  final List<WurzelBereich> bereiche;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = fundamentSchnitt(bereiche);
    final t = fundamentTrend(bereiche);
    final schwach = fundamentSchwach(bereiche);
    final unter = [
      if (t != null) trendText(t),
      if (schwach != null) '${schwach.name} braucht dich',
    ].join(' · ');
    return GlasKachel(
      key: const ValueKey('fundament-vorschau'),
      platz: 6,
      onTap: (_) => onTap(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('DEIN FUNDAMENT', style: Umbau.label),
                const SizedBox(height: 6),
                ZaehlZahl(
                  wert: s ?? 0,
                  leer: s == null ? '–' : null,
                  stellen: 1,
                  style: Umbau.zahl,
                ),
                const SizedBox(height: 4),
                Text(
                  unter.isEmpty ? 'Alle Bereiche im Blick' : unter,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Umbau.klein,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          for (final (i, b) in bereiche.indexed)
            Padding(
              padding: const EdgeInsets.only(left: 13),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: bewegungAn ? 0 : 1, end: 1),
                        duration: Duration(milliseconds: 1700 + i * 90),
                        curve: Interval(
                          (700 + i * 90) / (1700 + i * 90),
                          1,
                          curve: Curves.easeOutBack,
                        ),
                        builder: (context, v, _) => Container(
                          width: 8,
                          height: math.max(
                            0,
                            (4 + 44 * (b.wert ?? 0) / 10) * v,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: b.wert == null ? null : Umbau.grad,
                            color: b.wert == null
                                ? const Color(0x29FFECD2)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    kurzName(b.name),
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                      color: Color(0xFFCDBB9D),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The glass pill at the bottom: "Heute | Fundament", a gold knob glides
/// to the open page.
class GlasLeiste extends StatelessWidget {
  const GlasLeiste({super.key, required this.seite, required this.onWahl});
  final int seite;
  final ValueChanged<int> onWahl;

  static const _namen = ['Heute', 'Fundament'];
  static const _b = 98.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x17FFF5E6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: SizedBox(
              width: _b * 2,
              height: 42,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: Duration(milliseconds: bewegungAn ? 550 : 0),
                    curve: Curves.easeOutBack,
                    left: seite * _b,
                    width: _b,
                    top: 0,
                    bottom: 0,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: Umbau.grad,
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                    ),
                  ),
                  Row(children: [_knopf(0), _knopf(1)]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _knopf(int i) {
    final an = i == seite;
    return Semantics(
      button: true,
      selected: an,
      label: _namen[i],
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('leiste-${i == 0 ? 'heute' : 'fundament'}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onWahl(i),
        child: SizedBox(
          width: _b,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontFamily: 'Figtree',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: an ? Umbau.tinte : const Color(0xFFDCCBB0),
              ),
              child: Text(_namen[i], maxLines: 1, softWrap: false),
            ),
          ),
        ),
      ),
    );
  }
}
