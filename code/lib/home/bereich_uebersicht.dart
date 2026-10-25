import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';

/// One of the four fixed tiles of an area (vault Umsetzung/Home-Schichten:
/// fixed per area, decided 2026-10-25).
class Kachel {
  const Kachel({
    required this.titel,
    required this.wert,
    this.unter = '',
    this.breit = false,
    this.verlauf,
    this.balken,
    this.tage,
    this.key,
  });

  final String titel;
  final String wert;
  final String unter;
  final bool breit;

  /// Line over the last days (null = no score that day).
  final List<int?>? verlauf;

  /// Bars, e.g. hours slept per night.
  final List<double>? balken;

  /// Week dots Mo..So: true = done, false = planned, null = nothing.
  final List<bool?>? tage;
  final Key? key;
}

/// What the big area view shows.
class BereichDaten {
  const BereichDaten({
    required this.bereich,
    required this.name,
    required this.icon,
    required this.kacheln,
    this.wert,
    this.diff,
    this.grund,
    this.haupt,
    this.onHaupt,
  });

  final Bereich bereich;
  final String name;
  final IconData icon;
  final int? wert;
  final int? diff;

  /// The coach's one sentence for this area today.
  final String? grund;
  final List<Kachel> kacheln;

  /// Optional main button, e.g. "Wie war dein Training?".
  final String? haupt;
  final VoidCallback? onHaupt;
}

/// The area over the whole screen after it burst open from its root:
/// score, the coach's sentence, the 4 tiles and "Alles zu …". Everything
/// springs in one after another.
class BereichUebersicht extends StatefulWidget {
  const BereichUebersicht({
    super.key,
    required this.daten,
    required this.onAlles,
  });

  final BereichDaten daten;

  /// Opens the full area page (all that was on the old area tab).
  final VoidCallback onAlles;

  @override
  State<BereichUebersicht> createState() => _BereichUebersichtState();
}

class _BereichUebersichtState extends State<BereichUebersicht>
    with SingleTickerProviderStateMixin {
  late final _rein = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void dispose() {
    _rein.dispose();
    super.dispose();
  }

  Widget _stufe(int i, Widget child) {
    final start = (0.1 + i * 0.07).clamp(0.0, 0.6);
    final a = CurvedAnimation(
      parent: _rein,
      curve: Interval(start, start + 0.4, curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, child) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - a.value)),
          child: Transform.scale(scale: .94 + .06 * a.value, child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.daten;
    var i = 0;
    final kacheln = d.kacheln;
    final reihen = <Widget>[];
    for (var k = 0; k < kacheln.length;) {
      final a = kacheln[k];
      if (a.breit || k + 1 >= kacheln.length || kacheln[k + 1].breit) {
        reihen.add(_stufe(++i, _KachelView(a, _rein, widget.onAlles)));
        k++;
      } else {
        reihen.add(
          _stufe(
            ++i,
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _KachelView(a, _rein, widget.onAlles)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KachelView(kacheln[k + 1], _rein, widget.onAlles),
                  ),
                ],
              ),
            ),
          ),
        );
        k += 2;
      }
    }
    final (pfeil, farbe) = switch (d.diff) {
      null => ('', CoachStyle.inkSoft),
      0 => ('– wie gestern', CoachStyle.inkSoft),
      > 0 => ('↑ +${d.diff} seit gestern', const Color(0xFF9BCB8A)),
      _ => ('↓ ${d.diff} seit gestern', const Color(0xFFE39A7E)),
    };
    return Scaffold(
      backgroundColor: CoachStyle.night,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF221A12), Color(0xFF130F0B), Color(0xFF0E0B08)],
            stops: [0, .55, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1.2),
              radius: 1.1,
              colors: [Color(0x38D6AA5E), Color(0x00D6AA5E)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: NightScope(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                    children: [
                      _stufe(
                        0,
                        Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: Alignment(-.3, -.4),
                                  colors: [
                                    Color(0xFF3A2D1F),
                                    Color(0xFF18120D),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x59F0C878),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              foregroundDecoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFB8894A),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: ShaderMask(
                                  shaderCallback: (r) =>
                                      CoachStyle.goldGradient.createShader(r),
                                  child: Icon(
                                    d.icon,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BEREICH',
                                    style: CoachStyle.goldLabel.copyWith(
                                      fontFamily: 'Sora',
                                      letterSpacing: 2,
                                      color: CoachStyle.gold,
                                    ),
                                  ),
                                  Text(
                                    d.name,
                                    style: CoachStyle.title.copyWith(
                                      fontSize: 25,
                                      color: const Color(0xFFF5DFAE),
                                    ),
                                  ),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.end,
                                    spacing: 6,
                                    children: [
                                      _Zaehler(
                                        wert: d.wert,
                                        rein: _rein,
                                        key: ValueKey(
                                          'uebersicht-wert-${d.bereich.name}',
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Text(
                                          pfeil,
                                          style: CoachStyle.body.copyWith(
                                            fontSize: 13,
                                            color: farbe,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('uebersicht-zu'),
                              tooltip: 'Schließen',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: CoachStyle.goldLight,
                              ),
                              style: IconButton.styleFrom(
                                side: const BorderSide(
                                  color: CoachStyle.goldEdge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (d.grund != null && d.grund!.trim().isNotEmpty) ...[
                        _stufe(1, _CoachSatz(d.grund!.trim(), _rein)),
                        const SizedBox(height: 12),
                      ],
                      for (final r in reihen) ...[
                        r,
                        const SizedBox(height: 10),
                      ],
                      _stufe(
                        ++i,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (d.haupt != null) ...[
                              FilledButton(
                                key: ValueKey('haupt-${d.bereich.name}'),
                                onPressed: d.onHaupt,
                                style: FilledButton.styleFrom(
                                  backgroundColor: CoachStyle.goldLight,
                                  foregroundColor: const Color(0xFF1A140E),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  d.haupt!,
                                  style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            OutlinedButton(
                              key: ValueKey('alles-${d.bereich.name}'),
                              onPressed: widget.onAlles,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CoachStyle.goldLight,
                                side: const BorderSide(
                                  color: CoachStyle.goldEdge,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Alles zu ${d.name} ›',
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Score counting up from 0.
class _Zaehler extends StatelessWidget {
  const _Zaehler({super.key, required this.wert, required this.rein});
  final int? wert;
  final Animation<double> rein;

  @override
  Widget build(BuildContext context) {
    final w = wert;
    final a = CurvedAnimation(
      parent: rein,
      curve: const Interval(.15, .7, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, _) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: w == null ? '–' : '${(w * a.value).round()}',
              style: CoachStyle.title.copyWith(
                fontSize: 20,
                color: CoachStyle.ink,
              ),
            ),
            if (w != null)
              TextSpan(
                text: '/10',
                style: CoachStyle.body.copyWith(
                  fontSize: 13,
                  color: CoachStyle.beigeLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The coach's sentence, typing itself word by word.
class _CoachSatz extends StatelessWidget {
  const _CoachSatz(this.text, this.rein);
  final String text;
  final Animation<double> rein;

  @override
  Widget build(BuildContext context) {
    final worte = text.split(' ');
    final a = CurvedAnimation(parent: rein, curve: const Interval(.2, .85));
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFEFE3C8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoachAvatar(size: 28),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COACH',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A5A2C),
                  ),
                ),
                const SizedBox(height: 2),
                // The full text keeps the size; the typed part shows on top.
                Stack(
                  children: [
                    Opacity(opacity: 0, child: Text(text, style: _stil)),
                    AnimatedBuilder(
                      animation: a,
                      builder: (context, _) {
                        final n = a.value >= 1
                            ? worte.length
                            : (a.value * worte.length).ceil();
                        return Text(worte.take(n).join(' '), style: _stil);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _stil = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 13.5,
    height: 1.4,
    color: Color(0xFF1A140E),
  );
}

class _KachelView extends StatelessWidget {
  const _KachelView(this.k, this.rein, this.onTap);
  final Kachel k;
  final Animation<double> rein;

  /// Tapping a tile opens the full area page.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: k.key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _inhalt(),
    );
  }

  Widget _inhalt() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2319), Color(0xFF1D1712)],
        ),
        border: Border.all(color: const Color(0xFF4A3B2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            k.titel.toUpperCase(),
            style: CoachStyle.goldLabel.copyWith(
              fontFamily: 'Sora',
              fontSize: 9.5,
              letterSpacing: 1.4,
              color: CoachStyle.gold,
            ),
          ),
          const SizedBox(height: 6),
          if (k.wert.isNotEmpty)
            Text(
              k.wert,
              style: CoachStyle.title.copyWith(
                fontSize: k.wert.length > 14 ? 17 : 24,
                height: 1.15,
                color: const Color(0xFFF5DFAE),
              ),
            ),
          if (k.unter.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              k.unter,
              style: CoachStyle.body.copyWith(
                fontSize: 12.5,
                height: 1.35,
                color: CoachStyle.beigeLabel,
              ),
            ),
          ],
          if (k.tage != null) ...[
            const SizedBox(height: 10),
            _Woche(k.tage!, rein),
          ],
          if (k.verlauf != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: rein,
                builder: (context, _) => CustomPaint(
                  painter: _Linie(
                    k.verlauf!,
                    Curves.easeInOutCubic.transform(
                      ((rein.value - .3) / .6).clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (k.balken != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: rein,
                builder: (context, _) => CustomPaint(
                  painter: _Balken(
                    k.balken!,
                    Curves.easeOutBack.transform(
                      ((rein.value - .3) / .5).clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Woche extends StatelessWidget {
  const _Woche(this.tage, this.rein);
  final List<bool?> tage;
  final Animation<double> rein;

  static const _namen = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            children: [
              AnimatedBuilder(
                animation: rein,
                builder: (context, child) => Transform.scale(
                  scale: Curves.easeOutBack.transform(
                    ((rein.value - .35 - i * .04) / .3).clamp(0.0, 1.0),
                  ),
                  child: child,
                ),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: tage[i] == true ? CoachStyle.goldGradient : null,
                    border: Border.all(
                      color: tage[i] == false
                          ? CoachStyle.goldLight
                          : const Color(0xFF4A3B2A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _namen[i],
                style: CoachStyle.body.copyWith(
                  fontSize: 10,
                  color: CoachStyle.inkSoft,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Linie extends CustomPainter {
  _Linie(this.werte, this.t);
  final List<int?> werte;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[];
    final n = werte.length;
    for (var i = 0; i < n; i++) {
      final w = werte[i];
      if (w == null) continue;
      pts.add(
        Offset(
          6 + i * (size.width - 12) / math.max(1, n - 1),
          size.height - 6 - (w - 1) / 9 * (size.height - 12),
        ),
      );
    }
    if (pts.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Noch keine Werte',
          style: CoachStyle.body.copyWith(
            fontSize: 12,
            color: CoachStyle.inkSoft,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, size.height / 2 - tp.height / 2));
      return;
    }
    final avg =
        werte.whereType<int>().reduce((a, b) => a + b) /
        werte.whereType<int>().length;
    final ay = size.height - 6 - (avg - 1) / 9 * (size.height - 12);
    final dash = Paint()
      ..color = CoachStyle.goldEdge
      ..strokeWidth = 1;
    for (double x = 6; x < size.width - 6; x += 9) {
      canvas.drawLine(Offset(x, ay), Offset(x + 4, ay), dash);
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = CoachStyle.goldGradient.createShader(bounds),
    );
    canvas.restore();
    if (t >= 1) {
      canvas.drawCircle(
        pts.last,
        4.5,
        Paint()..color = const Color(0xFFF5DFAE),
      );
    }
  }

  @override
  bool shouldRepaint(_Linie old) => old.t != t || old.werte != werte;
}

class _Balken extends CustomPainter {
  _Balken(this.werte, this.t);
  final List<double> werte;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (werte.isEmpty) return;
    final n = werte.length;
    const gap = 8.0;
    final bw = (size.width - gap * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      final h = (werte[i] / 10).clamp(0.05, 1.0) * size.height * t;
      final r = Rect.fromLTWH(i * (bw + gap), size.height - h, bw, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(5)),
        Paint()
          ..shader = werte[i] < 6
              ? const LinearGradient(
                  colors: [Color(0xFF9A6D35), Color(0xFF7A5428)],
                ).createShader(r)
              : CoachStyle.goldGradient.createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(_Balken old) => old.t != t || old.werte != werte;
}
