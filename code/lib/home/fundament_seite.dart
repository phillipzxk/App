import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../ui/logo.dart';
import 'feed_widgets.dart';
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
  });

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
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PageHeader(
              label: 'Deine ${bereiche.length} Bereiche',
              title: 'Fundament',
              trailing: null,
            ),
          ),
          if (s != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              child: Row(
                children: [
                  Text('SCHNITT HEUTE', style: _klein),
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: s),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => GoldText(
                      komma(v),
                      key: const ValueKey('fundament-schnitt'),
                      style: CoachStyle.title.copyWith(fontSize: 24),
                    ),
                  ),
                  if (t != null && t != 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${t > 0 ? '+' : '−'}${komma(t.abs())} zu gestern',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t > 0
                            ? const Color(0xFF9BCB8A)
                            : const Color(0xFFE39A7E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Wachsen(
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

  static final _klein = CoachStyle.goldLabel.copyWith(
    fontFamily: 'Sora',
    fontSize: 10,
    letterSpacing: 1.8,
    color: CoachStyle.beigeLabel,
  );
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

/// Small card at the end of Heute that leads to the Fundament page.
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
    final schwach = fundamentSchwach(bereiche);
    final satz = [
      if (s != null) 'Schnitt ${komma(s)}',
      if (schwach != null) '${schwach.name} braucht dich',
    ].join(' · ');
    return HeuteFeld(
      key: const ValueKey('fundament-vorschau'),
      onTap: (_) => onTap(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CoachStyle.goldEdge),
              color: const Color(0xFF17110B),
            ),
            child: const Center(
              child: LogoMark(size: 36, ground: CoachStyle.cream),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEIN FUNDAMENT',
                  style: CoachStyle.goldLabel.copyWith(
                    fontFamily: 'Sora',
                    fontSize: 9.5,
                    letterSpacing: 1.6,
                    color: CoachStyle.goldLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  satz.isEmpty ? 'Alle Bereiche im Blick' : satz,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: CoachStyle.cream,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final b in bereiche)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: CoachStyle.nightLineStrong),
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: '${b.name.split(' ').first} ',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CoachStyle.beigeLabel,
                            ),
                            children: [
                              TextSpan(
                                text: b.wert?.toString() ?? '–',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: CoachStyle.goldLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: CoachStyle.gold),
        ],
      ),
    );
  }
}

/// The slim glass bar at the bottom: two symbols, a gold drop glides to the
/// open page and only there the name shows.
class GlasLeiste extends StatelessWidget {
  const GlasLeiste({super.key, required this.seite, required this.onWahl});
  final int seite;
  final ValueChanged<int> onWahl;

  static const _namen = ['Heute', 'Fundament'];
  static const _icons = [Icons.wb_sunny_outlined, Icons.spa_outlined];

  static const _text = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: CoachStyle.goldInk,
  );

  @override
  Widget build(BuildContext context) {
    // Widths are known up front so the gold drop can glide between them.
    final scaler = MediaQuery.textScalerOf(context);
    double breite(int i) {
      if (i != seite) return 52;
      final tp = TextPainter(
        text: TextSpan(text: _namen[i], style: _text),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      return 52 + 7 + tp.width.ceilToDouble() + 1;
    }

    final w0 = breite(0), w1 = breite(1);
    const kurve = Curves.easeOutBack;
    const zeit = Duration(milliseconds: 450);
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0x9E221910),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0x59C9A25C)),
          ),
          child: AnimatedContainer(
            duration: zeit,
            curve: Curves.easeOutCubic,
            width: w0 + w1,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: zeit,
                  curve: kurve,
                  left: seite == 0 ? 0 : w0,
                  width: seite == 0 ? w0 : w1,
                  top: 0,
                  bottom: 0,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: CoachStyle.goldGradient,
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x59F0D49A),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: zeit,
                  curve: Curves.easeOutCubic,
                  left: 0,
                  width: w0,
                  top: 0,
                  bottom: 0,
                  child: _knopf(0),
                ),
                AnimatedPositioned(
                  duration: zeit,
                  curve: Curves.easeOutCubic,
                  left: w0,
                  width: w1,
                  top: 0,
                  bottom: 0,
                  child: _knopf(1),
                ),
              ],
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
      child: GestureDetector(
        key: ValueKey('leiste-${i == 0 ? 'heute' : 'fundament'}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onWahl(i),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icons[i],
              size: 20,
              color: an ? CoachStyle.goldInk : CoachStyle.beigeLabel,
            ),
            if (an)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Text(
                    _namen[i],
                    style: _text,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
