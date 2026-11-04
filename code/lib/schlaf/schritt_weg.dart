import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../konto/konto_ui.dart' show bewegungAn;
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'morgen_szene.dart';
import 'schritt_zaehler.dart';

/// The step task of the alarm (vault Umsetzung/Echter Wecker, "Schritte
/// echt zählen", Entwurf 3): a morning scene in the app colours, every step
/// sets a shoe print on the hill and pulls the sun higher, a gold ring
/// fills around the count, at the goal the sun breaks through.
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

class _SchrittWegState extends State<SchrittWeg> with TickerProviderStateMixin {
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

  /// The footprints walking on the question card.
  late final AnimationController _fuesse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (bewegungAn) _fuesse.repeat();
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
    _fuesse.dispose();
    super.dispose();
  }

  String get _satz {
    if (_fertig) return 'Geschafft. Der Wecker ist aus.';
    final rest = widget.ziel - _n;
    if (_n == 0) {
      return _modus == _Modus.zaehlen
          ? 'Steh auf. Handy in die Hand oder in die Tasche.'
          : 'Steh auf und tipp bei jedem Schritt.';
    }
    if (rest <= 3) return 'Noch $rest.';
    if (rest <= 10) return 'Noch $rest. Die Sonne kommt.';
    if (_n * 3 >= widget.ziel) return 'Ein Drittel geschafft. Weiter so.';
    return 'Gut, du bist auf den Beinen.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('schritt-weg'),
    backgroundColor: CoachStyle.page,
    body: AnimatedBuilder(
      animation: _sonne,
      builder: (_, child) => MorgenSzene(
        schritte: _n,
        ziel: widget.ziel,
        durch: Curves.easeOut.transform(_sonne.value),
        trieb: Curves.easeOut.transform(
          ((_sonne.value - .3) / .7).clamp(0.0, 1.0),
        ),
        child: child,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
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
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - t)),
            child: child,
          ),
        ),
        child: _Glas(
          key: const ValueKey('schritte-frage'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _fuesse,
                  builder: (_, _) =>
                      CustomPaint(painter: _GehendeFuesse(_fuesse.value)),
                ),
              ),
              const SizedBox(height: 10),
              GoldText(
                'Darf ich deine Schritte zählen?',
                style: tTitel.copyWith(fontSize: 21, height: 1.22),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dann merkt der Wecker, dass du wirklich aufgestanden bist. '
                'Ich zähle nur, solange die Aufgabe offen ist, und speichere '
                'nur die Zahl.',
                style: tText,
              ),
              const SizedBox(height: 16),
              GoldKnopf(
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
                    side: const BorderSide(color: Color(0x47F3D79A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: tTitel.copyWith(fontSize: 14.5),
                  ),
                  onPressed: () => _antwort(false),
                  child: const Text('Lieber tippen'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Danach fragt das iPhone einmal nach „Bewegung und Fitness“.',
                style: tSoft.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _gehen() => Column(
    children: [
      const SizedBox(height: 34),
      _Ring(n: _n, ziel: widget.ziel),
      const Spacer(),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .3),
              end: Offset.zero,
            ).animate(a),
            child: c,
          ),
        ),
        child: Text(
          _hinweis ?? _satz,
          key: ValueKey(_hinweis ?? _satz),
          textAlign: TextAlign.center,
          style: tTitel.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (_modus == _Modus.tippen)
        GoldKnopf(
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
        'Nicht erledigt nach 3 Minuten? Dann klingelt er noch einmal.',
        textAlign: TextAlign.center,
        style: tSoft.copyWith(fontSize: 11.5),
      ),
    ],
  );
}

/// The count in a gold ring that fills with every step; the number hops.
class _Ring extends StatelessWidget {
  const _Ring({required this.n, required this.ziel});
  final int n;
  final int ziel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    height: 160,
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: ziel == 0 ? 0 : n / ziel),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (_, wert, child) =>
          CustomPaint(painter: _RingMaler(wert), child: child),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(n),
              tween: Tween(begin: n == 0 ? 1 : 1.18, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: GoldText(
                '$n',
                key: const ValueKey('schritte-zahl'),
                style: tTitel.copyWith(
                  fontSize: 58,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'von $ziel',
              style: tSoft.copyWith(color: const Color(0xB8EFE5D2)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RingMaler extends CustomPainter {
  _RingMaler(this.wert);
  final double wert;

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    canvas
      ..drawCircle(m, r, Paint()..color = const Color(0x590C090E))
      ..drawCircle(
        m,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0x24EFE5D2),
      );
    if (wert <= 0) return;
    final bogen = Rect.fromCircle(center: m, radius: r);
    canvas.drawArc(
      bogen,
      -math.pi / 2,
      math.pi * 2 * wert.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [Color(0xFFC99A52), Color(0xFFFFF0C8), Color(0xFFC99A52)],
        ).createShader(bogen),
    );
  }

  @override
  bool shouldRepaint(_RingMaler old) => old.wert != wert;
}

/// Six gold footprints that appear one after another, like walking.
class _GehendeFuesse extends CustomPainter {
  _GehendeFuesse(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 6; i++) {
      final phase = (t - i * .125) % 1;
      final a = phase < .12
          ? phase / .12
          : phase < .7
          ? 1 - (phase - .12) / .58 * .2
          : math.max(0, .8 - (phase - .7) / .3 * .8);
      if (a <= 0) continue;
      final o = Offset(10 + i * 26, i.isOdd ? 10 : 26);
      final s = .7 + .3 * math.min(1, phase / .12);
      final fuss = Paint()
        ..color = CoachStyle.goldLight.withValues(alpha: a.toDouble());
      canvas
        ..save()
        ..translate(o.dx, o.dy)
        ..rotate(math.pi / 2)
        ..scale(s)
        ..drawOval(
          Rect.fromCenter(center: const Offset(0, -2.5), width: 7, height: 9),
          fuss,
        )
        ..drawOval(
          Rect.fromCenter(center: const Offset(0, 5), width: 5.4, height: 5.6),
          fuss,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_GehendeFuesse old) => old.t != t;
}

/// A glass card in the app colours.
class _Glas extends StatelessWidget {
  const _Glas({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0x9918130E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x47F3D79A)),
        ),
        child: child,
      ),
    ),
  );
}

/// The main gold button with a soft shine running over it.
class GoldKnopf extends StatefulWidget {
  const GoldKnopf({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  State<GoldKnopf> createState() => _GoldKnopfState();
}

class _GoldKnopfState extends State<GoldKnopf>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glanz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void initState() {
    super.initState();
    if (bewegungAn) _glanz.repeat();
  }

  @override
  void dispose() {
    _glanz.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.onTap == null
                ? const [Color(0xFF8A7A5E), Color(0xFF6E5F46)]
                : const [
                    Color(0xFFF6DC9C),
                    Color(0xFFE0BF7E),
                    Color(0xFFB8904C),
                  ],
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _glanz,
            builder: (_, child) {
              final x = _glanz.value < .6
                  ? -1.4
                  : -1.4 + (_glanz.value - .6) / .4 * 2.8;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(x - .4, -.3),
                    end: Alignment(x + .4, .3),
                    colors: const [
                      Color(0x00FFFFFF),
                      Color(0x80FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                  ),
                ),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: Text(
                  widget.text,
                  style: tTitel.copyWith(
                    fontSize: 14.5,
                    color: CoachStyle.goldInk,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
