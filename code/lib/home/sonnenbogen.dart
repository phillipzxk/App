import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../sleep/schlafzeiten.dart';
import '../ui/coach_style.dart';

/// One point of the day on the sun arc (see Umsetzung/Tages-Planer.md,
/// "Sonnenbogen"). [minute] counts from midnight and may pass 1440 for a
/// bedtime after midnight.
class BogenPunkt {
  const BogenPunkt({
    required this.id,
    required this.minute,
    required this.art,
    required this.titel,
    this.text,
    this.erledigt = false,
  });

  final String id;

  /// Done before its time, e.g. a supplement already taken.
  final bool erledigt;
  final int minute;

  /// Aufstehen, Foto, Termin, Training, Essen or Schlaf.
  final String art;
  final String titel;
  final String? text;
}

/// "Dein Tag" as a sun arc from getting up to bedtime. On opening the sun
/// rises and travels to now, points it passes spark. The sun can be dragged
/// to look ahead; on release it springs back to now. Below it a card counts
/// down to the next point.
class Sonnenbogen extends StatefulWidget {
  const Sonnenbogen({
    super.key,
    required this.punkte,
    required this.start,
    required this.ende,
    required this.jetzt,
    this.ohneZeit,
  });

  final List<BogenPunkt> punkte;

  /// Minutes after midnight where the arc starts (getting up) and ends
  /// (bedtime, may be above 1440).
  final int start;
  final int ende;

  /// Now, in minutes after midnight (with seconds as fraction).
  final double jetzt;

  /// Shown in the card when nothing with a time is left, e.g. "Push".
  final String? ohneZeit;

  @override
  State<Sonnenbogen> createState() => _SonnenbogenState();
}

class _Funke {
  _Funke(this.x, this.y, this.vx, this.vy);
  double x, y, vx, vy;
  double l = 1;
}

class _SonnenbogenState extends State<Sonnenbogen>
    with SingleTickerProviderStateMixin {
  // Ambient motion runs forever, so it is off in widget tests (they wait for
  // all animations to end).
  late final bool _lebendig = !WidgetsBinding.instance.runtimeType
      .toString()
      .contains('Test');
  late final Ticker _ticker = createTicker(_tick);
  final _bild = ValueNotifier<int>(0);
  final _karte = ValueNotifier<int>(0);
  final _rnd = math.Random(7);
  final _funken = <_Funke>[];
  final _an = <String>{};

  Duration _seit = Duration.zero;
  late double _sonne;
  double? _zieh;
  double? _zurueckVon;
  Duration _zurueckAb = Duration.zero;
  bool _intro = true;
  bool _gezogen = false;
  String? _wahl;
  Size _groesse = Size.zero;
  int _sekunde = -1;

  @override
  void initState() {
    super.initState();
    if (_lebendig) {
      _sonne = widget.start.toDouble();
      _ticker.start();
    } else {
      _intro = false;
      _sonne = _jetzt;
      for (final p in widget.punkte) {
        if (p.minute <= _sonne) _an.add(p.id);
      }
    }
  }

  @override
  void didUpdateWidget(Sonnenbogen old) {
    super.didUpdateWidget(old);
    final alt = {for (final p in old.punkte) p.id};
    for (final p in widget.punkte) {
      if (!alt.contains(p.id)) _spruehen(p.minute.toDouble(), 22);
    }
    _karte.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bild.dispose();
    _karte.dispose();
    super.dispose();
  }

  double get _jetzt => widget.jetzt + _seit.inMilliseconds / 60000;
  double get _von => widget.start.toDouble();
  double get _bis => math.max(widget.ende, widget.start + 60).toDouble();
  double _klemm(double m) => m.clamp(_von, _bis);

  void _tick(Duration d) {
    _seit = d;
    const auf = 1900.0, warten = 250.0;
    final ms = d.inMilliseconds.toDouble();
    if (_intro) {
      final k = ((ms - warten) / auf).clamp(0.0, 1.0);
      final e = 1 - math.pow(1 - k, 3).toDouble();
      _sonne = _von + (_klemm(_jetzt) - _von) * e;
      if (k >= 1) _intro = false;
    } else if (_zieh != null) {
      _sonne = _zieh!;
    } else if (_zurueckVon != null) {
      final k = ((d - _zurueckAb).inMilliseconds / 700).clamp(0.0, 1.0);
      final e = 1 - math.pow(1 - k, 3).toDouble();
      _sonne = _zurueckVon! + (_klemm(_jetzt) - _zurueckVon!) * e;
      if (k >= 1) {
        _zurueckVon = null;
        _karte.value++;
      }
    } else {
      _sonne = _klemm(_jetzt);
    }
    for (final p in widget.punkte) {
      final vorbei = p.minute <= _sonne;
      if (vorbei && !_an.contains(p.id)) {
        _an.add(p.id);
        if (_intro || _zieh != null) _spruehen(p.minute.toDouble(), 14);
      } else if (!vorbei) {
        _an.remove(p.id);
      }
    }
    for (final f in _funken) {
      f.x += f.vx;
      f.y += f.vy;
      f.vy += .05;
      f.l -= .022;
    }
    _funken.removeWhere((f) => f.l <= 0);
    _bild.value++;
    final s = (_jetzt * 60).floor();
    if (s != _sekunde || _zieh != null) {
      _sekunde = s;
      _karte.value++;
    }
  }

  // Geometry in a 360 x 270 box, scaled to the real width.
  static const _w = 360.0, _h = 270.0, _cx = 180.0, _cy = 228.0, _r = 158.0;
  double _winkel(double m) =>
      math.pi - ((m - _von) / (_bis - _von)).clamp(0.0, 1.0) * math.pi;
  Offset _pt(double m, [double r = _r]) {
    final a = _winkel(m);
    return Offset(_cx + r * math.cos(a), _cy - r * math.sin(a));
  }

  Offset _lokal(Offset o) {
    final s = _groesse.width / _w;
    return o / (s == 0 ? 1 : s);
  }

  double _minuteBei(Offset p) {
    var a = math.atan2(_cy - p.dy, p.dx - _cx);
    if (a < 0) a = p.dx < _cx ? math.pi : 0;
    return _klemm(_von + (1 - a / math.pi) * (_bis - _von));
  }

  void _spruehen(double minute, int n) {
    if (!_lebendig) return;
    final o = _pt(minute);
    for (var i = 0; i < n; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final v = .6 + _rnd.nextDouble() * 1.8;
      _funken.add(_Funke(o.dx, o.dy, math.cos(a) * v, math.sin(a) * v - .6));
    }
  }

  void _start(DragStartDetails d) {
    if (_intro) return;
    final p = _lokal(d.localPosition);
    if ((p - _pt(_sonne)).distance > 40) return;
    setState(() {
      _zieh = _sonne;
      _gezogen = true;
      _wahl = null;
    });
    _karte.value++;
  }

  void _update(DragUpdateDetails d) {
    if (_zieh == null) return;
    final m = _minuteBei(_lokal(d.localPosition));
    for (final p in widget.punkte) {
      if ((p.minute - _zieh!) * (p.minute - m) < 0) {
        _spruehen(p.minute.toDouble(), 14);
      }
    }
    _zieh = m;
    if (!_lebendig) _sonne = m;
    _karte.value++;
    _bild.value++;
  }

  void _ende([DragEndDetails? _]) {
    if (_zieh == null) return;
    setState(() {
      _zurueckVon = _zieh;
      _zurueckAb = _seit;
      _zieh = null;
      if (!_lebendig) {
        _zurueckVon = null;
        _sonne = _klemm(_jetzt);
      }
    });
    _karte.value++;
    _bild.value++;
  }

  void _tippen(TapUpDetails d) {
    final p = _lokal(d.localPosition);
    BogenPunkt? best;
    var bd = 24.0;
    for (final x in widget.punkte) {
      final dist = (p - _pt(x.minute.toDouble())).distance;
      if (dist < bd) {
        bd = dist;
        best = x;
      }
    }
    setState(() => _wahl = best == null || best.id == _wahl ? null : best.id);
    if (best != null) _spruehen(best.minute.toDouble(), 10);
    _karte.value++;
    _bild.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final breit = c.maxWidth;
            final hoch = breit * _h / _w;
            _groesse = Size(breit, hoch);
            return SizedBox(
              height: hoch,
              child: GestureDetector(
                key: const ValueKey('sonnenbogen'),
                behavior: HitTestBehavior.opaque,
                onPanStart: _start,
                onPanUpdate: _update,
                onPanEnd: _ende,
                onPanCancel: _ende,
                onTapUp: _tippen,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    colors: [
                      Color(0x00FFFFFF),
                      Colors.white,
                      Colors.white,
                      Color(0x00FFFFFF),
                    ],
                    stops: [0, .1, .9, 1],
                  ).createShader(r),
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FFFFFF), Colors.white],
                      stops: [0, .4],
                    ).createShader(r),
                    child: CustomPaint(
                      size: Size(breit, hoch),
                      painter: _Maler(this),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedOpacity(
          opacity: _gezogen ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          child: Text(
            'Sonne ziehen zum Vorspulen',
            textAlign: TextAlign.center,
            style: CoachStyle.body.copyWith(
              fontSize: 11.5,
              color: CoachStyle.inkSoft.withValues(alpha: .8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<int>(
          valueListenable: _karte,
          builder: (context, _, _) => _karteBauen(),
        ),
      ],
    );
  }

  List<BogenPunkt> get _sortiert => [...widget.punkte]..sort(_reihenfolge);

  Widget _karteBauen() {
    String gross;
    String klein = '';
    String t1;
    String? t2;
    var vorschau = false;
    final wahl = widget.punkte.where((p) => p.id == _wahl).firstOrNull;
    if (_zieh != null) {
      vorschau = true;
      final m = _zieh!;
      final davor = _sortiert.where((p) => p.minute <= m).lastOrNull;
      final danach = _sortiert.where((p) => p.minute > m).firstOrNull;
      gross = formatUhrzeit(m.round() % 1440);
      t1 = davor != null && m - davor.minute < 45
          ? '${davor.titel} ist dran'
          : 'Freie Zeit';
      t2 = danach == null
          ? 'Danach: Gute Nacht'
          : 'Danach ${formatUhrzeit(danach.minute % 1440)} ${danach.titel}';
    } else if (wahl != null) {
      gross = formatUhrzeit(wahl.minute % 1440);
      t1 = wahl.titel;
      final rest = wahl.minute - _jetzt;
      t2 = [
        if (wahl.text != null) wahl.text!,
        rest > 0 ? 'in ${_dauer(rest)}' : 'erledigt ✓',
      ].join(' · ');
    } else {
      final n = _sortiert.where((p) => p.minute > _jetzt).firstOrNull;
      if (n == null) {
        gross = formatUhrzeit(_jetzt.floor() % 1440);
        t1 = widget.ohneZeit != null
            ? 'Heute noch: ${widget.ohneZeit}'
            : 'Für heute ist alles geschafft';
        t2 = null;
      } else {
        final sek = ((n.minute - _jetzt) * 60).round().clamp(0, 86400);
        final h = sek ~/ 3600, m = sek % 3600 ~/ 60, s = sek % 60;
        gross = '$h:${m.toString().padLeft(2, '0')}';
        klein = ':${s.toString().padLeft(2, '0')}';
        t1 = 'bis ${n.titel} · ${formatUhrzeit(n.minute % 1440)}';
        t2 = n.text;
      }
    }
    return Container(
      key: const ValueKey('tag-naechstes'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: vorschau ? const Color(0xFF8E95B8) : CoachStyle.goldEdge,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241B12), Color(0xFF16110C)],
        ),
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 104),
            child: ShaderMask(
              shaderCallback: (r) => _gold.createShader(r),
              child: Text.rich(
                TextSpan(
                  text: gross,
                  children: [
                    TextSpan(text: klein, style: const TextStyle(fontSize: 15)),
                  ],
                ),
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t1, style: CoachStyle.cardTitle.copyWith(fontSize: 14.5)),
                if (t2 != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    t2,
                    style: CoachStyle.body.copyWith(
                      fontSize: 12.5,
                      color: CoachStyle.beigeLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dauer(double min) {
    final m = min.round();
    final h = m ~/ 60;
    return h > 0 ? '$h Std. ${m % 60} Min.' : '$m Min.';
  }
}

const _gold = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF5DFAE), Color(0xFFD4A85E), Color(0xFF9A6D35)],
);

Color _farbe(String art) => switch (art) {
  'Training' => const Color(0xFFF0C878),
  'Termin' => const Color(0xFFCDBB98),
  'Schlaf' => const Color(0xFF9AA1C8),
  _ => const Color(0xFFE0BF7E),
};

/// By time; at the same minute appointments come first, meals last.
int _reihenfolge(BogenPunkt a, BogenPunkt b) {
  final c = a.minute.compareTo(b.minute);
  if (c != 0) return c;
  const rang = ['Aufstehen', 'Termin', 'Training', 'Foto', 'Supplement'];
  int r(BogenPunkt p) {
    final i = rang.indexOf(p.art);
    return i < 0 ? rang.length : i;
  }

  return r(a).compareTo(r(b));
}

IconData _icon(String art) => switch (art) {
  'Aufstehen' => Icons.wb_twilight,
  'Foto' => Icons.photo_camera,
  'Termin' => Icons.event,
  'Training' => Icons.fitness_center,
  'Essen' => Icons.restaurant,
  'Supplement' => Icons.medication,
  _ => Icons.bedtime,
};

class _Maler extends CustomPainter {
  _Maler(this.s) : super(repaint: s._bild);

  final _SonnenbogenState s;

  static final _sterne = () {
    final r = math.Random(11);
    return [
      for (var i = 0; i < 34; i++)
        () {
          final a = r.nextDouble() * math.pi * .55;
          final rr = 40 + r.nextDouble() * 120;
          return (
            Offset(
              _SonnenbogenState._cx + rr * math.cos(a),
              _SonnenbogenState._cy - rr * math.sin(a) - 6,
            ),
            .5 + r.nextDouble() * 1.1,
            r.nextDouble() * 6,
          );
        }(),
    ];
  }();

  void _text(
    Canvas c,
    String t,
    Offset o, {
    double size = 10,
    Color color = const Color(0xFF6D604D),
    FontWeight weight = FontWeight.w400,
    String family = 'Figtree',
    double spacing = 0,
    TextAlign align = TextAlign.center,
    Shader? shader,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          fontFamily: family,
          letterSpacing: spacing,
          color: shader == null ? color : null,
          foreground: shader == null ? null : (Paint()..shader = shader),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.left => o.dx,
      TextAlign.right => o.dx - tp.width,
      _ => o.dx - tp.width / 2,
    };
    tp.paint(c, Offset(dx, o.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const w = _SonnenbogenState._w, h = _SonnenbogenState._h;
    const cx = _SonnenbogenState._cx, cy = _SonnenbogenState._cy;
    const r = _SonnenbogenState._r;
    canvas.save();
    canvas.scale(size.width / w);
    final t = s._seit.inMilliseconds / 1000;
    final f = ((s._sonne - s._von) / (s._bis - s._von)).clamp(0.0, 1.0);
    final nacht = ((f - .62) / .38).clamp(0.0, 1.0);
    final sonne = s._pt(s._sonne);
    const himmel = Rect.fromLTWH(0, 0, w, cy);

    // Sky from dawn to night, a halo around the sun, stars and moon.
    canvas.drawRect(
      himmel,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xD94A2510),
            Color(0xD92C2016),
            Color(0xD91C1712),
            Color(0xD9121730),
          ],
          stops: [0, .3, .72, 1],
        ).createShader(himmel),
    );
    canvas.drawRect(
      himmel,
      Paint()
        ..shader = ui.Gradient.radial(
          sonne,
          w * .55,
          [
            Color.lerp(
              const Color(0xFFF6C878),
              const Color(0xFF9AA1C8),
              nacht,
            )!.withValues(alpha: .5),
            const Color(0x553A2A18),
            const Color(0x00120F0B),
          ],
          [0, .35, 1],
        ),
    );
    for (final (o, rr, p) in _sterne) {
      final seite = o.dx > cx ? math.min(1.0, (o.dx - cx) / 150) : 0.0;
      final a = (.15 + .85 * seite) * (.5 + .5 * math.sin(t * 1.6 + p)) * .9;
      canvas.drawCircle(
        o,
        rr,
        Paint()..color = const Color(0xFFE9E6FF).withValues(alpha: a),
      );
    }
    final mond = s._pt(s._bis, r + 2) + const Offset(-14, -34);
    canvas.saveLayer(
      Rect.fromCircle(center: mond, radius: 12),
      Paint()..color = Colors.white.withValues(alpha: .55 + .45 * nacht),
    );
    canvas.drawCircle(mond, 9, Paint()..color = const Color(0xFFDFE2F5));
    canvas.drawCircle(
      mond + const Offset(4, -3),
      8,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
    // Arc: dotted rest, golden trail up to the sun, hour ticks.
    final bogen = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        math.pi,
        math.pi,
      );
    for (final m in bogen.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 8) {
        canvas.drawPath(
          m.extractPath(d, d + 2),
          Paint()
            ..color = const Color(0xFF4A3B2A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
      final spur = m.extractPath(0, m.length * f);
      final gold = Paint()
        ..shader = _gold.createShader(
          const Rect.fromLTWH(cx - r, cy - r, r * 2, r),
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        spur,
        Paint()
          ..color = const Color(0x88E0BF7E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(spur, gold..strokeWidth = 3.2);
    }
    final ersteStunde = (s._von / 60).ceil();
    for (var st = ersteStunde; st * 60 < s._bis; st++) {
      final m = st * 60.0;
      final a = s._pt(m, r - 7), b = s._pt(m, r - (st % 3 == 0 ? 14 : 10));
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFF5A4A36)
          ..strokeWidth = 1,
      );
      if (st % 3 == 0) _text(canvas, '${st % 24}', s._pt(m, r - 24), size: 9);
    }

    // Points of the day.
    for (final p in s._sortiert) {
      final o = s._pt(p.minute.toDouble());
      final vorbei = p.erledigt || p.minute <= s._sonne;
      final gewaehlt = p.id == s._wahl;
      final farbe = _farbe(p.art);
      final rad = switch (p.art) {
        'Training' => 8.0,
        'Essen' => 4.5,
        _ => 6.0,
      };
      if (gewaehlt) {
        canvas.drawCircle(
          o,
          rad + 6 + math.sin(t * 3) * 1.5,
          Paint()
            ..color = const Color(0xCCE0BF7E)
            ..style = PaintingStyle.stroke,
        );
      }
      if (vorbei) {
        canvas.drawCircle(
          o,
          rad + 3,
          Paint()
            ..color = farbe.withValues(alpha: .5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawCircle(
        o,
        rad,
        Paint()..color = vorbei ? farbe : const Color(0xFF120E0A),
      );
      canvas.drawCircle(
        o,
        rad,
        Paint()
          ..color = farbe
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      if (p.art == 'Training' || p.art == 'Termin' || gewaehlt) {
        final l = s._pt(p.minute.toDouble(), r + 17);
        _text(
          canvas,
          p.titel.length > 16 ? '${p.titel.substring(0, 15)}…' : p.titel,
          Offset(l.dx.clamp(4, w - 4), l.dy),
          size: 10.5,
          weight: FontWeight.w600,
          color: gewaehlt ? const Color(0xFFF0C878) : CoachStyle.ink,
          align: l.dx < 40
              ? TextAlign.left
              : l.dx > w - 40
              ? TextAlign.right
              : TextAlign.center,
        );
      }
    }

    // Ground, the sun's reflection and the golden ground line.
    const boden = Rect.fromLTWH(0, cy, w, h - cy);
    canvas.drawRect(
      boden,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A130C), Color(0x00120F0B)],
        ).createShader(boden),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sonne.dx, cy + (cy - sonne.dy) * .18 + 6),
        width: (26 + (1 - nacht) * 10) * 2,
        height: 10,
      ),
      Paint()
        ..color = const Color(0xFFF6CF83)
            .withValues(alpha: .35 * (1 - nacht) + .1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawLine(
      const Offset(0, cy),
      const Offset(w, cy),
      Paint()
        ..color = const Color(0x88E0BF7E)
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawLine(
      const Offset(0, cy),
      const Offset(w, cy),
      Paint()
        ..color = const Color(0xFFE0BF7E)
        ..strokeWidth = 1.2,
    );
    _text(
      canvas,
      formatUhrzeit(s._von.round() % 1440),
      Offset(cx - r, cy + 16),
      color: CoachStyle.inkSoft,
    );
    _text(
      canvas,
      formatUhrzeit(s._bis.round() % 1440),
      Offset(cx + r, cy + 16),
      color: CoachStyle.inkSoft,
    );

    // The sun with turning rays (only above the ground line).
    canvas.save();
    canvas.clipRect(himmel);
    for (var k = 0; k < 12; k++) {
      final a = k / 12 * math.pi * 2 + t * .25;
      final l = k.isOdd ? 16.0 : 24.0;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        sonne + d * 14,
        sonne + d * (14 + l),
        Paint()
          ..color = const Color(0xFFF6CF83).withValues(alpha: .5 * (1 - nacht))
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
    final halo = 34 + math.sin(t * 2) * 3;
    canvas.drawCircle(
      sonne,
      halo,
      Paint()
        ..shader = ui.Gradient.radial(
          sonne,
          halo,
          const [Color(0xD9FFF6DA), Color(0xD9F6CF83), Color(0x00E0BF7E)],
          const [0, .35, 1],
        ),
    );
    final kern = Color.lerp(
      const Color(0xFFFFF0C8),
      const Color(0xFFE3E6FA),
      nacht,
    )!;
    canvas.drawCircle(
      sonne,
      14,
      Paint()
        ..color = kern.withValues(alpha: .6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(sonne, s._zieh != null ? 12 : 10, Paint()..color = kern);
    canvas.restore();

    // Clock in the middle.
    final vorschau = s._zieh != null;
    _text(
      canvas,
      vorschau ? 'VORSCHAU' : 'JETZT',
      const Offset(cx, cy - 52),
      color: vorschau ? const Color(0xFF9AA1C8) : CoachStyle.inkSoft,
      family: 'Sora',
      spacing: 2,
    );
    _text(
      canvas,
      formatUhrzeit((vorschau ? s._zieh! : s._jetzt).floor() % 1440),
      const Offset(cx, cy - 22),
      size: 34,
      weight: FontWeight.w700,
      family: 'Sora',
      shader: _gold.createShader(
        const Rect.fromLTWH(cx - 60, cy - 44, 120, 44),
      ),
    );

    for (final p in s._funken) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        1.4 * p.l + .4,
        Paint()..color = const Color(0xFFFFE2A0).withValues(alpha: p.l),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Maler old) => true;
}

/// "Heute dran" on Heute (Umsetzung/Home-Schichten.md, 2026-10-25): one
/// small field, a sun arc with everything of today as small signs, evenly
/// spaced in their order. Done is gold, the next one pulses. Below one line
/// with the next point and a countdown. Tap opens Dein Tag.
class HeuteBogen extends StatefulWidget {
  const HeuteBogen({
    super.key,
    required this.punkte,
    required this.start,
    required this.ende,
    required this.jetzt,
    required this.onTap,
    this.ohneZeit,
  });

  final List<BogenPunkt> punkte;
  final int start;
  final int ende;
  final double jetzt;
  final VoidCallback onTap;
  final String? ohneZeit;

  @override
  State<HeuteBogen> createState() => _HeuteBogenState();
}

class _HeuteBogenState extends State<HeuteBogen>
    with SingleTickerProviderStateMixin {
  late final bool _lebendig = !WidgetsBinding.instance.runtimeType
      .toString()
      .contains('Test');
  late final Ticker _ticker = createTicker(_tick);
  final _bild = ValueNotifier<int>(0);
  final _zeile = ValueNotifier<int>(0);
  Duration _seit = Duration.zero;
  int _sekunde = -1;

  @override
  void initState() {
    super.initState();
    if (_lebendig) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bild.dispose();
    _zeile.dispose();
    super.dispose();
  }

  void _tick(Duration d) {
    _seit = d;
    _bild.value++;
    final s = (_jetzt * 60).floor();
    if (s != _sekunde) {
      _sekunde = s;
      _zeile.value++;
    }
  }

  double get _jetzt => widget.jetzt + _seit.inMilliseconds / 60000;

  /// 0..1 of the opening animation (1 in tests).
  double get _auf => _lebendig
      ? Curves.easeOutCubic.transform(
          ((_seit.inMilliseconds - 200) / 1500).clamp(0.0, 1.0),
        )
      : 1;

  List<BogenPunkt> get _sortiert => [...widget.punkte]..sort(_reihenfolge);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CoachStyle.goldEdge),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1F14), Color(0xFF15100B)],
              stops: [0, .7],
            ),
            boxShadow: CoachStyle.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      'HEUTE DRAN',
                      style: CoachStyle.goldLabel.copyWith(
                        fontFamily: 'Sora',
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: CoachStyle.gold,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '›',
                      style: TextStyle(color: CoachStyle.gold, fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, c) => CustomPaint(
                    size: Size(c.maxWidth, c.maxWidth * _HeuteMaler.h / 340),
                    painter: _HeuteMaler(this),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<int>(
                  valueListenable: _zeile,
                  builder: (context, _, _) => _naechstes(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _naechstes() {
    final liste = _sortiert;
    final i = liste.indexWhere((p) => !p.erledigt && p.minute > _jetzt);
    String gross, klein = '', t1;
    String? t2;
    if (i < 0) {
      gross = formatUhrzeit(_jetzt.floor() % 1440);
      t1 = widget.ohneZeit != null
          ? 'Heute noch: ${widget.ohneZeit}'
          : liste.isEmpty
          ? 'Tippe hier, um deinen Tag zu planen'
          : 'Für heute ist alles geschafft';
    } else {
      final n = liste[i];
      final sek = ((n.minute - _jetzt) * 60).round().clamp(0, 86400);
      gross = '${sek ~/ 3600}:${(sek % 3600 ~/ 60).toString().padLeft(2, '0')}';
      klein = ':${(sek % 60).toString().padLeft(2, '0')}';
      t1 = 'bis ${n.titel} · ${formatUhrzeit(n.minute % 1440)}';
      final danach = liste.skip(i + 1).where((p) => !p.erledigt).firstOrNull;
      if (danach != null) {
        t2 = 'Danach ${danach.titel} um ${formatUhrzeit(danach.minute % 1440)}';
      }
    }
    return Container(
      key: const ValueKey('heute-naechstes'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF120E0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoachStyle.line),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (r) => _gold.createShader(r),
            child: Text.rich(
              TextSpan(
                text: gross,
                children: [
                  TextSpan(text: klein, style: const TextStyle(fontSize: 13)),
                ],
              ),
              style: const TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 21,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoachStyle.cardTitle.copyWith(fontSize: 13.5),
                ),
                if (t2 != null)
                  Text(
                    t2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CoachStyle.body.copyWith(
                      fontSize: 12,
                      color: CoachStyle.beigeLabel,
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

class _HeuteMaler extends CustomPainter {
  _HeuteMaler(this.s) : super(repaint: s._bild);

  final _HeuteBogenState s;

  static const w = 340.0, h = 182.0, cx = 170.0, cy = 160.0, r = 128.0;

  // Points are evenly spaced in their order; the sun sits between its
  // neighbours by time.
  double _frac(List<BogenPunkt> l, double m) {
    if (l.isEmpty) {
      return ((m - s.widget.start) / (s.widget.ende - s.widget.start)).clamp(
        0.0,
        1.0,
      );
    }
    if (l.length == 1) return m <= l.first.minute ? .06 : .94;
    double pos;
    final k = l.indexWhere((p) => p.minute >= m);
    if (k == 0) {
      pos = 0;
    } else if (k < 0) {
      pos = l.length - 1.0;
    } else {
      final a = l[k - 1].minute, b = l[k].minute;
      pos = k - 1 + (b == a ? 0 : (m - a) / (b - a));
    }
    return .06 + .88 * pos / (l.length - 1);
  }

  Offset _pt(double f, [double rr = r]) {
    final a = math.pi - f * math.pi;
    return Offset(cx + rr * math.cos(a), cy - rr * math.sin(a));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / w);
    final t = s._seit.inMilliseconds / 1000;
    final auf = s._auf;
    final l = s._sortiert;
    final fJetzt = _frac(l, s._jetzt) * auf;
    final sonne = _pt(fJetzt);

    // Sky inside the arc, dawn on the left, night on the right.
    final himmel = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        math.pi,
        math.pi,
      )
      ..close();
    canvas.drawPath(
      himmel,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x8C5A2E14), Color(0x262C2016), Color(0xBF151B33)],
          stops: [0, .55, 1],
        ).createShader(const Rect.fromLTWH(cx - r, cy - r, r * 2, r)),
    );
    final rnd = math.Random(5);
    for (var i = 0; i < 16; i++) {
      final o = Offset(200 + rnd.nextDouble() * 90, 50 + rnd.nextDouble() * 90);
      final a = .2 + .5 * (.5 + .5 * math.sin(t * 1.6 + i));
      if ((o - const Offset(cx, cy)).distance < r - 14) {
        canvas.drawCircle(
          o,
          .6 + rnd.nextDouble() * .7,
          Paint()..color = const Color(0xFFE9E6FF).withValues(alpha: a),
        );
      }
    }

    // Arc: dotted, golden trail up to the sun.
    final bogen = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        math.pi,
        math.pi,
      );
    for (final m in bogen.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(
          m.extractPath(d, d + 2),
          Paint()
            ..color = const Color(0xFF4A3B2A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      final spur = m.extractPath(0, m.length * fJetzt);
      canvas.drawPath(
        spur,
        Paint()
          ..color = const Color(0x88E0BF7E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        spur,
        Paint()
          ..shader = _gold.createShader(
            const Rect.fromLTWH(cx - r, cy - r, r * 2, r),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawLine(
      const Offset(0, cy),
      const Offset(w, cy),
      Paint()
        ..color = const Color(0xFFC9A25C)
        ..strokeWidth = 1,
    );

    // The sun with turning rays.
    for (var k = 0; k < 10; k++) {
      final a = k / 10 * math.pi * 2 + t * .5;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        sonne + d * 12,
        sonne + d * (k.isOdd ? 19 : 24),
        Paint()
          ..color = const Color(0x99F6CF83)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      sonne,
      22,
      Paint()
        ..shader = ui.Gradient.radial(
          sonne,
          22,
          const [Color(0xFFFFF6DA), Color(0xCCF6CF83), Color(0x00E0BF7E)],
          const [0, .4, 1],
        ),
    );
    canvas.drawCircle(sonne, 7.5, Paint()..color = const Color(0xFFFFF0C8));

    // Signs of the day.
    final naechster = l
        .where((p) => !p.erledigt && p.minute > s._jetzt)
        .firstOrNull;
    for (final (i, p) in l.indexed) {
      // By position, so two points at the same minute sit side by side.
      final f = l.length == 1 ? .06 : .06 + .88 * i / (l.length - 1);
      final pop = ((auf - f) * 8).clamp(0.0, 1.0);
      if (pop <= 0) continue;
      final o = _pt(f);
      final vorbei = p.erledigt || p.minute <= s._jetzt;
      final farbe = _farbe(p.art);
      final gross = p.art == 'Training';
      final rad = (gross ? 12.5 : 10.5) * Curves.easeOutBack.transform(pop);
      if (p == naechster) {
        final k = (t % 1.6) / 1.6;
        canvas.drawCircle(
          o,
          rad + 4 + k * 8,
          Paint()
            ..color = const Color(0xFFE0BF7E).withValues(alpha: 1 - k)
            ..style = PaintingStyle.stroke,
        );
      }
      if (vorbei) {
        canvas.drawCircle(
          o,
          rad + 2,
          Paint()
            ..color = farbe.withValues(alpha: .45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawCircle(
        o,
        rad,
        Paint()..color = vorbei ? farbe : const Color(0xFF15100B),
      );
      canvas.drawCircle(
        o,
        rad,
        Paint()
          ..color = farbe
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final ic = _icon(p.art);
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(ic.codePoint),
          style: TextStyle(
            fontFamily: ic.fontFamily,
            package: ic.fontPackage,
            fontSize: rad * 1.15,
            color: vorbei ? const Color(0xFF1A140E) : farbe,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
      if (p.art == 'Termin' || gross || p == naechster) {
        final lp = _pt(f, r + 21);
        final name = p.titel.split(' ').first;
        final lt = TextPainter(
          text: TextSpan(
            text: name.length > 12 ? '${name.substring(0, 11)}…' : name,
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color:
                  (p == naechster
                          ? const Color(0xFFF0C878)
                          : CoachStyle.beigeLabel)
                      .withValues(alpha: pop),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (lp.dx - lt.width / 2).clamp(2.0, w - lt.width - 2);
        lt.paint(canvas, Offset(x, lp.dy - lt.height / 2));
      }
    }

    // Now in the middle.
    void mitte(String text, double y, TextStyle st) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: st),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, y - tp.height / 2));
    }

    mitte(
      'JETZT',
      cy - 50,
      const TextStyle(
        fontFamily: 'Sora',
        fontSize: 9.5,
        letterSpacing: 2,
        color: CoachStyle.inkSoft,
      ),
    );
    mitte(
      formatUhrzeit(s._jetzt.floor() % 1440),
      cy - 26,
      TextStyle(
        fontFamily: 'Sora',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        foreground: Paint()
          ..shader = _gold.createShader(
            const Rect.fromLTWH(cx - 50, cy - 44, 100, 36),
          ),
      ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeuteMaler old) => true;
}
