import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import 'bereichs_werte.dart';

/// Moving parts of "Heute" (decided with Phillip 2026-10-21): the sprout
/// with roots, the area switch with one big field, the grow-into-page
/// transition and the gold sparks.

const _goldColors = [Color(0xFFF5DFAE), Color(0xFFD4A85E), Color(0xFF9A6D35)];

/// Gold sparks flying out from the centre while [progress] runs 0 to 1.
class FunkenPainter extends CustomPainter {
  FunkenPainter(this.progress, {this.anzahl = 24, this.weite = 90});

  final double progress;
  final int anzahl;
  final double weite;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final c = size.center(Offset.zero);
    final rnd = math.Random(7);
    final e = Curves.easeOutCubic.transform(progress);
    for (var i = 0; i < anzahl; i++) {
      final w = rnd.nextDouble() * math.pi * 2;
      final d = weite * (0.45 + rnd.nextDouble() * 0.55) * e;
      final p = c + Offset(math.cos(w) * d, math.sin(w) * d);
      final a = (1 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        p,
        3.4 * (1 - progress * 0.7),
        Paint()
          ..color = const Color(0xFFF5DFAE).withValues(alpha: a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(FunkenPainter old) => old.progress != progress;
}

/// The logo sprout: the stem and leaves grow with the days in a row, the
/// roots grow with each "Heute geschafft" of the week.
class SprossPainter extends CustomPainter {
  SprossPainter({
    required this.trieb,
    required this.blaetter,
    required this.wurzel,
  });

  /// 0..1, height of the stem.
  final double trieb;

  /// 1..4, leaves along the stem (fractions grow in).
  final double blaetter;

  /// 0..7, how far the roots reach.
  final double wurzel;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gy = h * 0.36;
    final cx = w / 2;
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _goldColors,
      ).createShader(Offset.zero & size);

    // Roots below the ground line.
    final rootPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC9A25C), Color(0xFF6F5A40)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final len = h * (0.13 + 0.068 * wurzel);
    final main = Path()
      ..moveTo(cx, gy)
      ..lineTo(cx + 1.5, gy + len * 0.35)
      ..lineTo(cx - 1.5, gy + len * 0.7)
      ..lineTo(cx + 1, gy + len);
    canvas.drawPath(main, rootPaint..strokeWidth = 1.8);
    final seiten = 2 + (wurzel / 1.6).floor().clamp(0, 4);
    for (var j = 0; j < seiten; j++) {
      final sy = gy + len * (0.12 + 0.18 * j);
      if (sy > gy + len * 0.95) break;
      final side = j.isEven ? -1.0 : 1.0;
      final l = h * 0.2 * (1 - j * 0.12);
      final end = Offset(cx + side * l * 0.75, sy + l * 0.55);
      final p = Path()
        ..moveTo(cx, sy)
        ..quadraticBezierTo(cx + side * l * 0.3, sy + l * 0.1, end.dx, end.dy);
      canvas.drawPath(p, rootPaint..strokeWidth = 1.2);
      canvas.drawLine(
        Offset(cx + side * l * 0.45, sy + l * 0.22),
        Offset(cx + side * l * 0.5, sy + l * 0.5),
        rootPaint..strokeWidth = 0.8,
      );
    }

    // Ground line.
    canvas.drawLine(
      Offset(2, gy),
      Offset(w - 2, gy),
      Paint()
        ..color = const Color(0xFF8A6330)
        ..strokeWidth = 1.2,
    );

    // Stem and leaves.
    final top = gy - h * (0.12 + 0.2 * trieb);
    canvas.drawLine(
      Offset(cx, gy),
      Offset(cx, top),
      Paint()
        ..shader = gold.shader
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    void blatt(double y, double side, double l) {
      final p = Path()
        ..moveTo(cx, y)
        ..quadraticBezierTo(
          cx + side * l * 0.15,
          y - l * 1.05,
          cx + side * l,
          y - l,
        )
        ..quadraticBezierTo(cx + side * l * 0.95, y - l * 0.1, cx, y);
      canvas.drawPath(p, gold);
    }

    for (var i = 0; i < 4; i++) {
      final g = (blaetter - i).clamp(0.0, 1.0);
      if (g <= 0) continue;
      final f = [0.25, 0.5, 0.72, 0.92][i];
      blatt(gy - (gy - top) * f, i.isEven ? -1 : 1, h * 0.12 * g);
    }
  }

  @override
  bool shouldRepaint(SprossPainter old) =>
      old.trieb != trieb || old.blaetter != blaetter || old.wurzel != wurzel;
}

/// Box at the top right of "Heute": the sprout and the days in a row. Glows
/// and throws sparks when [jubelTick] goes up.
class SprossBox extends StatefulWidget {
  const SprossBox({
    super.key,
    required this.streak,
    required this.wurzeln,
    this.jubelTick = 0,
  });

  final int streak;
  final int wurzeln;
  final int jubelTick;

  @override
  State<SprossBox> createState() => _SprossBoxState();
}

class _SprossBoxState extends State<SprossBox>
    with SingleTickerProviderStateMixin {
  late final _jubel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didUpdateWidget(SprossBox old) {
    super.didUpdateWidget(old);
    if (widget.jubelTick > old.jubelTick) _jubel.forward(from: 0);
  }

  @override
  void dispose() {
    _jubel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.streak;
    final trieb = (s / 14).clamp(0.0, 1.0);
    final blaetter = (1 + s / 3).clamp(1.0, 4.0);
    return AnimatedBuilder(
      animation: _jubel,
      builder: (context, child) {
        final v = _jubel.value;
        final glow = v == 0 ? 0.0 : math.sin(v * math.pi);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1 + 0.08 * glow,
              child: Container(
                key: const ValueKey('spross'),
                width: 84,
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF17130E),
                  gradient: const RadialGradient(
                    center: Alignment(0, -0.3),
                    colors: [Color(0x2EE0BF7E), Color(0x00E0BF7E)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xFF3A3127),
                      const Color(0xFFE0BF7E),
                      glow,
                    )!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5DFAE)
                          .withValues(alpha: 0.55 * glow),
                      blurRadius: 40 * glow,
                      spreadRadius: 4 * glow,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: FunkenPainter(v, anzahl: 22, weite: 110),
                ),
              ),
            ),
          ],
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: widget.wurzeln.clamp(0, 7).toDouble()),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutBack,
            builder: (context, wurzel, _) => TweenAnimationBuilder<double>(
              tween: Tween(end: blaetter),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (context, b, _) => CustomPaint(
                size: const Size(66, 96),
                painter: SprossPainter(
                  trieb: trieb,
                  blaetter: b,
                  wurzel: wurzel,
                ),
              ),
            ),
          ),
          Text(
            '$s',
            key: const ValueKey('spross-tage'),
            style: CoachStyle.title.copyWith(
              fontSize: 18,
              height: 1.1,
              color: const Color(0xFFF5DFAE),
            ),
          ),
          Text(
            s == 1 ? 'TAG AM STÜCK' : 'TAGE AM STÜCK',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: CoachStyle.body.copyWith(
              fontSize: 8,
              letterSpacing: 0.2,
              color: CoachStyle.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

const _kurz = {
  Bereich.training: 'Training',
  Bereich.ernaehrung: 'Ernährung',
  Bereich.schlaf: 'Schlaf',
  Bereich.mindset: 'Mindset',
};

/// Switch with the four areas and one big field below it. Tapping the field
/// opens the area page; [onOpen] gets the field's place on screen.
class BereichsFeld extends StatefulWidget {
  const BereichsFeld({
    super.key,
    required this.checkIns,
    required this.today,
    required this.onOpen,
  });

  final List<CheckIn> checkIns;
  final DateTime today;
  final void Function(Bereich b, Rect von) onOpen;

  @override
  State<BereichsFeld> createState() => _BereichsFeldState();
}

class _BereichsFeldState extends State<BereichsFeld> {
  Bereich _b = Bereich.training;
  final _feld = GlobalKey();

  void _oeffnen() {
    final box = _feld.currentContext?.findRenderObject() as RenderBox?;
    final rect = box == null
        ? Rect.zero
        : box.localToGlobal(Offset.zero) & box.size;
    widget.onOpen(_b, rect);
  }

  @override
  Widget build(BuildContext context) {
    final i = Bereich.values.indexOf(_b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF17130E),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF2E261C)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  alignment: Alignment(-1 + 2 * i / 3, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.25,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: CoachStyle.goldGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final b in Bereich.values)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: b == _b,
                        child: GestureDetector(
                          key: ValueKey('schalter-${b.name}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _b = b),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              textAlign: TextAlign.center,
                              style: CoachStyle.body.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: b == _b
                                    ? CoachStyle.goldInk
                                    : CoachStyle.beigeLabel,
                              ),
                              child: Text(_kurz[b]!, maxLines: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          key: ValueKey('bereich-${_b.name}'),
          onTap: _oeffnen,
          child: Container(
            key: _feld,
            padding: const EdgeInsets.all(1.3),
            decoration: BoxDecoration(
              gradient: CoachStyle.goldEdgeGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: CoachStyle.nightShadow,
            ),
            child: Container(
              height: 250,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C2319), Color(0xFF1B1611)],
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: _FeldInhalt(
                  key: ValueKey(_b),
                  bereich: _b,
                  checkIns: widget.checkIns,
                  today: widget.today,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeldInhalt extends StatelessWidget {
  const _FeldInhalt({
    super.key,
    required this.bereich,
    required this.checkIns,
    required this.today,
  });

  final Bereich bereich;
  final List<CheckIn> checkIns;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final week = werteVerlauf(checkIns, bereich, today, 7);
    final heute = week.last;
    final gestern = week[5];
    final diff = heute != null && gestern != null ? heute - gestern : null;
    final (pfeil, farbe) = switch (diff) {
      null => ('', CoachStyle.inkSoft),
      0 => ('→', CoachStyle.beigeLabel),
      > 0 => ('↑', const Color(0xFF9FD18B)),
      _ => ('↓', const Color(0xFFE08A6A)),
    };
    final letzte = letzteBewertung(checkIns, bereich);
    final grund = heute == null
        ? 'Nach deinem nächsten Check-in bewertet der Coach diesen Bereich.'
        : (letzte?.gruende[bereich.name] ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${bereich.label.toUpperCase()} · HEUTE',
                style: CoachStyle.goldLabel.copyWith(
                  color: CoachStyle.goldLight,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_full,
              size: 15,
              color: CoachStyle.goldLight,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (heute ?? 0).toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                heute == null ? '–' : v.round().toString(),
                key: ValueKey('wert-${bereich.name}'),
                style: CoachStyle.title.copyWith(
                  fontSize: 64,
                  height: 1,
                  color: const Color(0xFFF5DFAE),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: heute == null ? '' : '/10  ',
                      style: TextStyle(color: CoachStyle.inkSoft),
                    ),
                    TextSpan(
                      text: heute == null ? '' : pfeil,
                      style: TextStyle(color: farbe),
                    ),
                  ],
                ),
                style: CoachStyle.title.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          grund,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: CoachStyle.body.copyWith(
            fontSize: 13.5,
            color: CoachStyle.beigeLabel,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 56,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            builder: (context, t, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Container(
                      height:
                          (week[i] == null ? 4 : 6 + week[i]! * 5.0) *
                          Curves.easeOutBack.transform(
                            ((t - i * 0.07) / 0.55).clamp(0.0, 1.0),
                          ),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: week[i] == null
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFF5DFAE), Color(0xFF9A6D35)],
                              ),
                        color: week[i] == null
                            ? CoachStyle.nightLineStrong
                            : null,
                        boxShadow: i == 6 && week[i] != null
                            ? const [
                                BoxShadow(
                                  color: Color(0x80E0BF7E),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The big field grows from [von] to the whole screen, then [onGross]
/// switches to the area page and the cover fades away.
Future<void> wachseZuSeite(
  BuildContext context, {
  required Rect von,
  required String titel,
  required VoidCallback onGross,
}) async {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null || von.isEmpty) {
    onGross();
    return;
  }
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Wachsen(
      von: von,
      titel: titel,
      onGross: onGross,
      onFertig: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _Wachsen extends StatefulWidget {
  const _Wachsen({
    required this.von,
    required this.titel,
    required this.onGross,
    required this.onFertig,
  });

  final Rect von;
  final String titel;
  final VoidCallback onGross;
  final VoidCallback onFertig;

  @override
  State<_Wachsen> createState() => _WachsenState();
}

class _WachsenState extends State<_Wachsen>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (_c.value >= 0.62 && !_umgeschaltet) {
        _umgeschaltet = true;
        widget.onGross();
      }
    });
    _c.forward().whenComplete(widget.onFertig);
  }

  bool _umgeschaltet = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final g = Curves.easeInOutCubic.transform(
            (_c.value / 0.62).clamp(0.0, 1.0),
          );
          final fade = ((_c.value - 0.62) / 0.38).clamp(0.0, 1.0);
          final r = Rect.lerp(widget.von, screen, g)!;
          return Stack(
            children: [
              Positioned.fromRect(
                rect: r,
                child: Opacity(
                  opacity: 1 - fade,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2C2319), Color(0xFF15110D)],
                      ),
                      borderRadius: BorderRadius.circular(24 * (1 - g)),
                      border: Border.all(
                        color: const Color(0xFF8A6330),
                        width: 1.3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: g,
                      child: Text(
                        widget.titel,
                        style: CoachStyle.title.copyWith(
                          fontSize: 26,
                          color: const Color(0xFFF5DFAE),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
