import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'schritt_zaehler.dart';

/// The step task of the alarm (vault Umsetzung/Echter Wecker, "Schritte
/// echt zählen", Entwurf 1): every step sets a gold footprint on a path to
/// the sun, the sky gets lighter, at the goal the sun rises.
class SchrittWeg extends StatefulWidget {
  const SchrittWeg({
    super.key,
    required this.ziel,
    required this.onFertig,
    this.zaehler = const KeinZaehler(),
    this.wahl,
    this.clock = DateTime.now,
  });

  /// 20, 30 or 50 steps.
  final int ziel;

  /// Done: the steps and how long they took.
  final void Function(int schritte, Duration dauer) onFertig;
  final SchrittZaehler zaehler;

  /// The choice from the first time. Null: ask nothing, tap.
  final SchrittWahlStore? wahl;
  final DateTime Function() clock;

  @override
  State<SchrittWeg> createState() => _SchrittWegState();
}

enum _Modus { laedt, frage, zaehlen, tippen }

class _SchrittWegState extends State<SchrittWeg>
    with SingleTickerProviderStateMixin {
  _Modus _modus = _Modus.laedt;
  int _n = 0;
  DateTime? _start;
  StreamSubscription<int>? _abo;
  String? _hinweis;
  bool _fertig = false;
  late final AnimationController _sonne = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _waehle();
  }

  Future<void> _waehle() async {
    if (!widget.zaehler.moeglich || widget.wahl == null) {
      setState(() => _modus = _Modus.tippen);
      return;
    }
    final w = await widget.wahl!.zaehlenErlaubt();
    if (!mounted) return;
    if (w == null) {
      setState(() => _modus = _Modus.frage);
    } else {
      w ? _starteZaehlen() : setState(() => _modus = _Modus.tippen);
    }
  }

  Future<void> _antwort(bool zaehlen) async {
    await widget.wahl?.setze(zaehlen);
    if (!mounted) return;
    zaehlen ? _starteZaehlen() : setState(() => _modus = _Modus.tippen);
  }

  void _starteZaehlen() {
    setState(() {
      _modus = _Modus.zaehlen;
      _start = widget.clock();
    });
    _abo = widget.zaehler.zaehlen().listen(
      (n) => _setze(n),
      onError: (Object e) => _zuTippen(
        'Zählen klappt gerade nicht. Tipp einfach bei jedem Schritt.',
      ),
    );
  }

  void _zuTippen([String? hinweis]) {
    _abo?.cancel();
    _abo = null;
    if (!mounted) return;
    setState(() {
      _modus = _Modus.tippen;
      _hinweis = hinweis;
    });
  }

  void _tipp() {
    _start ??= widget.clock();
    _setze(_n + 1);
  }

  void _setze(int n) {
    if (_fertig || !mounted) return;
    setState(() => _n = math.min(n, widget.ziel));
    if (_n >= widget.ziel) _geschafft();
  }

  Future<void> _geschafft() async {
    _fertig = true;
    _abo?.cancel();
    _abo = null;
    final dauer = widget.clock().difference(_start ?? widget.clock());
    await _sonne.forward();
    if (mounted) widget.onFertig(widget.ziel, dauer);
  }

  @override
  void dispose() {
    _abo?.cancel();
    _sonne.dispose();
    super.dispose();
  }

  String get _satz {
    if (_fertig) return 'Geschafft. Der Wecker ist aus.';
    final rest = widget.ziel - _n;
    if (_n == 0) {
      return _modus == _Modus.zaehlen
          ? 'Steh auf. Das Handy kannst du in der Hand halten oder einstecken.'
          : 'Steh auf und tipp bei jedem Schritt.';
    }
    if (rest <= 3) return 'Noch $rest.';
    if (rest <= 10) return 'Noch $rest. Die Sonne kommt.';
    if (_n * 2 >= widget.ziel) return 'Mehr als die Hälfte.';
    return 'Gut, weiter so.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('schritt-weg'),
    body: AnimatedBuilder(
      animation: _sonne,
      builder: (_, child) => CustomPaint(
        painter: _WegMaler(
          n: _n,
          ziel: widget.ziel,
          auf: Curves.easeOut.transform(_sonne.value),
        ),
        child: child,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: switch (_modus) {
            _Modus.laedt => const SizedBox.expand(),
            _Modus.frage => _frage(),
            _ => _gehen(),
          },
        ),
      ),
    ),
  );

  Widget _frage() => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        key: const ValueKey('schritte-frage'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xB81E1812),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x4DF3D79A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk,
              color: CoachStyle.goldLight,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'Darf ich deine Schritte zählen?',
              style: tTitel.copyWith(fontSize: 21),
            ),
            const SizedBox(height: 8),
            const Text(
              'Damit der Wecker merkt, dass du wirklich aufgestanden bist. Ich '
              'zähle nur, solange diese Aufgabe offen ist, und speichere nur '
              'die Zahl.',
              style: tText,
            ),
            const SizedBox(height: 16),
            _GoldKnopf(
              key: const ValueKey('schritte-erlauben'),
              text: 'Erlauben',
              onTap: () => _antwort(true),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('schritte-tippen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CoachStyle.ink,
                  side: const BorderSide(color: Color(0x4DF3D79A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => _antwort(false),
                child: const Text('Lieber tippen'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Danach fragt das iPhone einmal nach „Bewegung und Fitness“.',
              style: tSoft.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _gehen() => Column(
    children: [
      const SizedBox(height: 40),
      GoldText(
        '$_n',
        key: const ValueKey('schritte-zahl'),
        style: tTitel.copyWith(
          fontSize: 72,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      Text('von ${widget.ziel} Schritten', style: tSoft),
      const Spacer(),
      Text(
        _hinweis ?? _satz,
        key: const ValueKey('schritte-satz'),
        textAlign: TextAlign.center,
        style: tText.copyWith(color: CoachStyle.ink),
      ),
      const SizedBox(height: 14),
      if (_modus == _Modus.tippen)
        _GoldKnopf(
          key: const ValueKey('schritte-tipp'),
          text: 'Schritt',
          onTap: _fertig ? null : _tipp,
        )
      else
        TextButton(
          key: const ValueKey('schritte-zu-tippen'),
          onPressed: _fertig ? null : _zuTippen,
          child: Text(
            'Zählt nicht? Dann tippen',
            style: tSoft.copyWith(color: CoachStyle.goldLight),
          ),
        ),
      const SizedBox(height: 8),
      Text(
        'Ist die Aufgabe nach 3 Minuten nicht erledigt, klingelt der Wecker '
        'noch einmal.',
        textAlign: TextAlign.center,
        style: tSoft.copyWith(fontSize: 12),
      ),
    ],
  );
}

class _GoldKnopf extends StatelessWidget {
  const _GoldKnopf({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: CoachStyle.gold,
        foregroundColor: CoachStyle.goldInk,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: const StadiumBorder(),
      ),
      onPressed: onTap,
      child: Text(text),
    ),
  );
}

/// Sky, sun and the path of footprints.
class _WegMaler extends CustomPainter {
  _WegMaler({required this.n, required this.ziel, required this.auf});
  final int n;
  final int ziel;

  /// The sunrise at the end, 0 to 1.
  final double auf;

  Offset _punkt(double t, Size s) => Offset(
    s.width * (.5 + .18 * math.sin(t * math.pi * 2.2) * (1 - t * .5)),
    s.height * (.86 - .62 * t),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final p = ziel == 0 ? 0.0 : n / ziel;
    final himmel = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      himmel,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF1B1530), const Color(0xFF3B5A8A), p)!,
            Color.lerp(const Color(0xFF4A2B3A), const Color(0xFFD99A68), p)!,
            Color.lerp(const Color(0xFF2A1A14), const Color(0xFF784628), p)!,
          ],
          stops: const [0, .62, 1],
        ).createShader(himmel),
    );
    // The sun: brighter with every step, rises at the end.
    final sonne = Offset(size.width / 2, size.height * (.30 + .22 * (1 - auf)));
    final r = size.width * .11;
    canvas.drawCircle(
      sonne,
      r * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFECBE).withValues(alpha: .35 + .5 * auf),
            const Color(0x00FFECBE),
          ],
        ).createShader(Rect.fromCircle(center: sonne, radius: r * 3)),
    );
    canvas.drawCircle(
      sonne,
      r * (.6 + .4 * p),
      Paint()..color = const Color(0xFFFFF0CD).withValues(alpha: .25 + .75 * p),
    );
    // The path as faint dots, then one footprint per step.
    final punkt = Paint()..color = const Color(0x2EEFE5D2);
    for (var i = 0; i < ziel; i++) {
      canvas.drawCircle(_punkt(i / math.max(1, ziel - 1), size), 2, punkt);
    }
    for (var i = 0; i < n; i++) {
      final t = i / math.max(1, ziel - 1);
      final a = _punkt(t, size);
      final b = _punkt(math.min(1, t + .01), size);
      final winkel = math.atan2(b.dy - a.dy, b.dx - a.dx) + math.pi / 2;
      final seite = i.isOdd ? 1.0 : -1.0;
      final neu = i == n - 1;
      final s = 1.6 * (1 - .35 * t);
      canvas
        ..save()
        ..translate(
          a.dx + seite * 7 * math.cos(winkel),
          a.dy + seite * 7 * math.sin(winkel),
        )
        ..rotate(winkel);
      final fuss = Paint()
        ..color = neu ? const Color(0xFFF6DC9C) : const Color(0xD9E0BF7E);
      if (neu) {
        canvas.drawCircle(
          Offset.zero,
          12 * s,
          Paint()
            ..color = const Color(0x55F6DC9C)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      canvas
        ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: 6.4 * s, height: 11 * s),
          fuss,
        )
        ..drawCircle(Offset(0, -7.6 * s), 2 * s, fuss)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_WegMaler old) =>
      old.n != n || old.auf != auf || old.ziel != ziel;
}
