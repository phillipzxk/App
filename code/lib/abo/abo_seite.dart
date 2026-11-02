import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../konto/konto_ui.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'abo_daten.dart';
import 'abo_logik.dart';

/// Amber, the colour of the Abo screens (Phillip 2026-11-02: fits the rest,
/// only slightly stands out, clean).
abstract final class Bernstein {
  static const oben = Color(0xFF2C1D11);
  static const mitte = Color(0xFF1A120B);
  static const unten = Color(0xFF110C08);
  static const licht = Color(0xFFD98A4E);
  static const tief = Color(0xFF6E3A1C);
  static const gold = Color(0xFFF6D690);
  static const hell = Color(0xFFFFEAC0);
  static const amber = Color(0xFFE8894A);

  static const goldVerlauf = LinearGradient(
    colors: [Color(0xFFFFEAC0), Color(0xFFF4C46F), Color(0xFFE8894A)],
    stops: [0, .45, 1],
  );
}

/// The calm amber page with two slowly drifting lights.
class BernsteinHintergrund extends StatefulWidget {
  const BernsteinHintergrund({super.key, required this.child});
  final Widget child;

  @override
  State<BernsteinHintergrund> createState() => _BernsteinHintergrundState();
}

class _BernsteinHintergrundState extends State<BernsteinHintergrund>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  @override
  void initState() {
    super.initState();
    if (bewegungAn) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Bernstein.unten,
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Bernstein.oben, Bernstein.mitte, Bernstein.unten],
          stops: [0, .4, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(painter: _LichtFlecken(_c.value)),
            ),
          ),
          widget.child,
        ],
      ),
    ),
  );
}

class _LichtFlecken extends CustomPainter {
  _LichtFlecken(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    void fleck(Offset m, double r, Color c, double a) => canvas.drawCircle(
      m,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            c.withValues(alpha: a),
            c.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: m, radius: r)),
    );
    final e = Curves.easeInOut.transform(t);
    fleck(
      Offset(size.width * (.05 + .12 * e), 60 + 50 * e),
      230,
      Bernstein.licht,
      .26,
    );
    fleck(
      Offset(size.width * (1 - .1 * e), 330 + 60 * e),
      210,
      Bernstein.tief,
      .35,
    );
    fleck(
      Offset(size.width * (.3 + .1 * e), 700 - 40 * e),
      180,
      Bernstein.gold,
      .07,
    );
  }

  @override
  bool shouldRepaint(_LichtFlecken old) => old.t != t;
}

/// "Sieh, was gewachsen ist" (vault Umsetzung/Abo.md, Entwurf 7): the first
/// week as a growing tree with a sunrise, the 7 days, the numbers and what
/// the coach learned, then both prices side by side.
class AboSeite extends StatefulWidget {
  const AboSeite({
    super.key,
    required this.name,
    required this.bild,
    required this.text,
    required this.onKaufen,
    required this.onOhne,
    this.onZurueck,
  });

  final String name;
  final WochenBild bild;

  /// The coach's look back; null when it cannot be reached.
  final Future<String?> text;

  /// Buys the plan; true when it worked.
  final Future<bool> Function(AboPlan plan) onKaufen;
  final VoidCallback onOhne;

  /// Only when opened from the settings: a way back.
  final VoidCallback? onZurueck;

  @override
  State<AboSeite> createState() => _AboSeiteState();
}

class _AboSeiteState extends State<AboSeite> with TickerProviderStateMixin {
  late final AnimationController _auf = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  late final AnimationController _kreis = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );
  late final AnimationController _tipp = AnimationController(vsync: this);
  final _scroll = ScrollController();
  AboPlan _plan = AboPlan.jahr;
  bool _kauft = false;
  String? _fehler;
  String _text = '';

  @override
  void initState() {
    super.initState();
    if (bewegungAn) _kreis.repeat();
    widget.text.then((t) {
      if (!mounted) return;
      final s = (t ?? '').trim().isNotEmpty
          ? t!.trim()
          : wochenTextLokal(widget.name, widget.bild);
      setState(() => _text = s);
      _tipp.duration = Duration(milliseconds: 12 * s.length);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _tipp.forward();
      });
    });
  }

  @override
  void dispose() {
    _auf.dispose();
    _kreis.dispose();
    _tipp.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _kaufen() async {
    setState(() {
      _kauft = true;
      _fehler = null;
    });
    final ok = await widget.onKaufen(_plan);
    if (!mounted) return;
    setState(() {
      _kauft = false;
      if (!ok) _fehler = 'Das hat nicht geklappt. Versuch es gleich nochmal.';
    });
  }

  Animation<double> _ab(double von, [double dauer = .35]) => CurvedAnimation(
    parent: _auf,
    curve: Interval(von, math.min(1, von + dauer), curve: Curves.easeOutCubic),
  );

  Widget _rein(double von, Widget child) {
    final a = _ab(von);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BernsteinHintergrund(
    child: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              ListView(
                key: const ValueKey('abo-seite'),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 34),
                children: [
                  _rein(
                    0,
                    Column(
                      children: [
                        Text(
                          'DEINE ERSTE WOCHE',
                          style: Glas.tSoft.copyWith(
                            fontSize: 10.5,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        GoldText(
                          'Sieh, was gewachsen ist',
                          style: Glas.tBig.copyWith(fontSize: 25),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scroll,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(
                        0,
                        _scroll.hasClients ? _scroll.offset * .3 : 0,
                      ),
                      child: child,
                    ),
                    child: AspectRatio(
                      aspectRatio: 324 / 150,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_auf, _kreis]),
                        builder: (_, _) => CustomPaint(
                          key: const ValueKey('abo-baum'),
                          painter: _SonnenBaum(_auf.value, _kreis.value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Tage(punkte: widget.bild.punkte, anim: _auf),
                  const SizedBox(height: 14),
                  _rein(.3, _wochenKarte()),
                  const SizedBox(height: 16),
                  _rein(.45, _liste()),
                  const SizedBox(height: 18),
                  _rein(
                    .55,
                    _PreisFeld(
                      plan: _plan,
                      onPlan: (p) => setState(() => _plan = p),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _rein(
                    .6,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KontoKnopf(
                          key: const ValueKey('abo-kaufen'),
                          label: 'Weiter wachsen',
                          laedt: _kauft,
                          onTap: _kauft ? null : _kaufen,
                        ),
                        if (_fehler != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _fehler!,
                            style: Glas.tSoft.copyWith(color: Bernstein.amber),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${_plan.kurz}. Jederzeit kündbar, bezahlt wird '
                          'über Apple.',
                          textAlign: TextAlign.center,
                          style: Glas.tSoft.copyWith(fontSize: 11.5),
                        ),
                        TextButton(
                          key: const ValueKey('abo-ohne'),
                          onPressed: _kauft ? null : widget.onOhne,
                          child: Text(
                            'Ohne Abo weiter eintragen',
                            style: Glas.tSoft.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.onZurueck != null)
                Positioned(
                  left: 4,
                  top: 0,
                  child: IconButton(
                    key: const ValueKey('abo-zurueck'),
                    icon: const Icon(Icons.close, color: Glas.label),
                    onPressed: widget.onZurueck,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _wochenKarte() {
    final b = widget.bild;
    return GlasBox(
      key: const ValueKey('abo-woche'),
      radius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Ring(
                  zahl: b.checkIns,
                  anteil: b.checkIns / 7,
                  label: 'Check-ins',
                  anim: _ab(.25, .5),
                ),
                _Ring(
                  zahl: b.fokusTage,
                  anteil: b.fokusTage / 7,
                  label: 'Fokus-Tage',
                  anim: _ab(.3, .5),
                ),
                _Ring(
                  zahl: b.durchgezogen,
                  anteil: math.min(1, b.durchgezogen / 7),
                  label: 'durchgezogen',
                  anim: _ab(.35, .5),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00FFFFFF),
                  Color(0x24FFFFFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Affe(),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WAS ICH ÜBER DICH GELERNT HABE',
                        style: Glas.tSoft.copyWith(
                          fontSize: 9.5,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: _tipp,
                        builder: (_, _) {
                          final n = (_text.length * _tipp.value).round();
                          return ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 72),
                            child: Text(
                              key: const ValueKey('abo-text'),
                              _text.isEmpty ? '…' : _text.substring(0, n),
                              style: Glas.tText.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          );
                        },
                      ),
                      if (b.muster != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0x29F6D690), Color(0x1AF08A4B)],
                            ),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: const Color(0x4DF6D690)),
                          ),
                          child: Text(
                            'Muster: ${b.muster}',
                            style: Glas.tSoft.copyWith(
                              color: Bernstein.hell,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
            decoration: const BoxDecoration(
              color: Color(0x0AFFFFFF),
              border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
            ),
            child: Text(
              'Nächste Woche: dein erster Reality Check und ein neuer Fokus',
              style: Glas.tSoft.copyWith(color: Bernstein.hell, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liste() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Zwischen('Mit dem Abo wächst weiter'),
      const SizedBox(height: 8),
      GlasBox(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: [
            for (final (i, (icon, titel, unter)) in const [
              (
                Icons.chat_bubble_outline,
                'Dein Coach, jeden Tag',
                'Antwort auf jeden Check-in',
              ),
              (
                Icons.track_changes,
                'Fokus & Reality Check',
                'jede Woche neu ausgewertet',
              ),
              (
                Icons.photo_camera_outlined,
                'Teller-Foto & Form-Check',
                'der Coach schaut mit',
              ),
              (Icons.show_chart, 'Muster & Tagesplan', 'passt sich dir an'),
            ].indexed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : const Border(top: BorderSide(color: Color(0x12FFFFFF))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x33F6D690), Color(0x1FE8894A)],
                        ),
                        border: Border.all(color: const Color(0x38F6D690)),
                      ),
                      child: Icon(icon, size: 18, color: Bernstein.gold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titel,
                            style: Glas.tText.copyWith(fontSize: 13.5),
                          ),
                          Text(unter, style: Glas.tSoft.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _Zwischen extends StatelessWidget {
  const _Zwischen(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    Widget linie(bool links) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: links
                ? const [Color(0x00F6D690), Color(0x73F6D690)]
                : const [Color(0x73F6D690), Color(0x00F6D690)],
          ),
        ),
      ),
    );
    return Row(
      children: [
        linie(true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text.toUpperCase(),
            style: Glas.tSoft.copyWith(
              color: Bernstein.gold,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ),
        linie(false),
      ],
    );
  }
}

class _Affe extends StatelessWidget {
  const _Affe();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    padding: const EdgeInsets.all(1.5),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0x99F6D690),
      boxShadow: [BoxShadow(color: Color(0x59F6D690), blurRadius: 22)],
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/images/coach.jpg',
        fit: BoxFit.cover,
        semanticLabel: 'Dein Coach',
      ),
    ),
  );
}

/// The 7 days under the ground line, each with what stood out.
class _Tage extends StatelessWidget {
  const _Tage({required this.punkte, required this.anim});
  final List<WochenPunkt> punkte;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (i, p) in punkte.indexed)
        SizedBox(
          width: 42,
          child: Column(
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: anim,
                  curve: Interval(
                    .18 + i * .035,
                    .45 + i * .035,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: p.da
                      ? const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFF1CC),
                              Color(0xFFF6D690),
                              Color(0xFFE8964D),
                            ],
                            stops: [0, .45, 1],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1FF6D690),
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: Color(0x59F08A4B),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xE6140F0A),
                          border: Border.all(color: const Color(0x66D9C7A7)),
                        ),
                  child: Text(
                    p.tag,
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      color: p.da
                          ? CoachStyle.goldInk
                          : const Color(0x99D9C7A7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: anim,
                  curve: Interval(.3 + i * .03, .6),
                ),
                child: Text(
                  p.text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Glas.tSoft.copyWith(fontSize: 9, height: 1.15),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.zahl,
    required this.anteil,
    required this.label,
    required this.anim,
  });

  final int zahl;
  final double anteil;
  final String label;
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: anim,
    builder: (_, _) => Column(
      children: [
        SizedBox.square(
          dimension: 64,
          child: CustomPaint(
            painter: _RingFuell(anteil * anim.value),
            child: Center(
              child: Text(
                '${(zahl * anim.value).round()}',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 21,
                  color: Bernstein.gold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Glas.tSoft.copyWith(fontSize: 10.5)),
      ],
    ),
  );
}

class _RingFuell extends CustomPainter {
  _RingFuell(this.anteil);
  final double anteil;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(center: size.center(Offset.zero), radius: 27);
    canvas.drawArc(
      r,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0x1AFFFFFF),
    );
    if (anteil <= 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [Color(0xFFFFF1CC), Color(0xFFF6D690), Color(0xFFE58A45)],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(r);
    canvas.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * anteil,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0x33F6D690)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * anteil, false, p);
  }

  @override
  bool shouldRepaint(_RingFuell old) => old.anteil != anteil;
}

/// Both prices equally big in one field; a gold knob glides to the choice.
class _PreisFeld extends StatelessWidget {
  const _PreisFeld({required this.plan, required this.onPlan});
  final AboPlan plan;
  final ValueChanged<AboPlan> onPlan;

  @override
  Widget build(BuildContext context) => Container(
    height: 94,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0x0AFFFFFF),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0x1AFFFFFF)),
    ),
    child: Stack(
      children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutBack,
          alignment: plan == AboPlan.jahr
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .5,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFEAC0),
                    Color(0xFFF4C46F),
                    Color(0xFFE8894A),
                  ],
                  stops: [0, .45, 1],
                ),
                borderRadius: BorderRadius.circular(19),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59F08A4B),
                    blurRadius: 28,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (final p in AboPlan.values)
              Expanded(
                child: GestureDetector(
                  key: ValueKey('abo-plan-${p.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPlan(p),
                  child: Stack(
                    children: [
                      Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            color: p == plan ? CoachStyle.goldInk : Glas.text,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.label.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.preis,
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                  letterSpacing: -.3,
                                ),
                              ),
                              Text(
                                p.unter,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (p == AboPlan.jahr)
                        Positioned(
                          top: 3,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p == plan
                                  ? CoachStyle.goldInk
                                  : const Color(0x2EF6D690),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              '−50 %',
                              style: TextStyle(
                                fontFamily: 'Figtree',
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                color: Bernstein.gold,
                              ),
                            ),
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
  );
}

/// Sunrise behind a golden tree: rays turn slowly, leaves pop in and sway.
class _SonnenBaum extends CustomPainter {
  _SonnenBaum(this.t, this.kreis);

  /// 0..1 how far the scene has grown.
  final double t;

  /// 0..1 endless loop for the rays and the leaves.
  final double kreis;

  static const List<List<double>> _aeste = [
    [162.0, 124, 150, 116, 138, 110, 124, 100],
    [162.0, 118, 174, 110, 186, 104, 200, 96],
    [162.0, 106, 154, 96, 146, 88, 138, 76],
    [162.0, 102, 170, 92, 178, 84, 186, 72],
    [162.0, 96, 162, 86, 160, 76, 162, 64],
    [150.0, 114, 142, 112, 134, 114, 120, 116],
    [174.0, 112, 184, 110, 194, 112, 206, 116],
  ];

  static const List<List<double>> _blaetter = [
    [124.0, 100, -70],
    [200, 96, 70],
    [138, 76, -35],
    [186, 72, 35],
    [162, 64, 0],
    [120, 116, -95],
    [206, 116, 95],
    [132, 90, -55],
    [192, 86, 55],
    [150, 70, -15],
    [174, 68, 15],
    [144, 104, -80],
    [180, 102, 80],
    [156, 84, -25],
    [168, 82, 25],
    [112, 108, -85],
    [212, 106, 85],
    [128, 84, -50],
  ];

  double _ab(double von, double bis) =>
      Curves.easeOutCubic.transform(((t - von) / (bis - von)).clamp(0, 1));

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 324;
    canvas.save();
    canvas.scale(s);
    const boden = 148.0;
    const mx = 162.0;

    // Sunrise and slowly turning rays, only above the ground.
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(-60, -200, 384, boden));
    final strahl = _ab(.2, .7);
    if (strahl > 0) {
      canvas.save();
      canvas.translate(mx, boden);
      canvas.rotate(kreis * 2 * math.pi);
      final p = Paint()..color = Color.fromRGBO(246, 214, 144, .08 * strahl);
      for (var i = 0; i < 16; i++) {
        final a = i / 16 * 2 * math.pi;
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(math.cos(a) * 320, math.sin(a) * 320)
            ..lineTo(math.cos(a + .08) * 320, math.sin(a + .08) * 320)
            ..close(),
          p,
        );
      }
      canvas.restore();
    }
    final sonne = Offset(mx, boden + 52 - 104 * _ab(0, .8));
    canvas.drawCircle(
      sonne,
      86,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFFFF6DC),
            Color(0xFFF6D690),
            Color(0x59D9A24A),
            Color(0x00C9993F),
          ],
          stops: [0, .2, .55, 1],
        ).createShader(Rect.fromCircle(center: sonne, radius: 86)),
    );
    canvas.restore();

    canvas.drawLine(
      const Offset(-18, boden),
      const Offset(342, boden),
      Paint()
        ..color = const Color(0xB3F6D690)
        ..strokeWidth = 1 / s,
    );

    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF1CC), Color(0xFFF6D690), Color(0xFFE58A45)],
      ).createShader(const Rect.fromLTRB(0, 50, 324, 150));

    void wachse(Path p, double anteil, double breite) {
      if (anteil <= 0) return;
      for (final m in p.computeMetrics()) {
        canvas.drawPath(
          m.extractPath(0, m.length * anteil),
          gold..strokeWidth = breite,
        );
      }
    }

    wachse(
      Path()
        ..moveTo(mx, boden)
        ..cubicTo(mx, 128, 159, 112, mx, 92),
      _ab(.05, .3),
      4,
    );
    for (final (i, a) in _aeste.indexed) {
      wachse(
        Path()
          ..moveTo(a[0], a[1])
          ..cubicTo(a[2], a[3], a[4], a[5], a[6], a[7]),
        _ab(.18 + i * .025, .4 + i * .025),
        2,
      );
    }

    final blatt = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF1CC), Color(0xFFF6D690), Color(0xFFE58A45)],
      ).createShader(const Rect.fromLTRB(0, -20, 10, 0));
    for (final (i, b) in _blaetter.indexed) {
      final v = ((t - .3 - i * .018) / .2).clamp(0.0, 1.0);
      if (v <= 0) continue;
      final g = Curves.elasticOut.transform(v);
      canvas.save();
      canvas.translate(b[0], b[1]);
      canvas.rotate(
        (b[2] + 4 * math.sin(kreis * 2 * math.pi * 8 + i)) * math.pi / 180,
      );
      canvas.scale(g);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(-6, -6, -6, -16, 0, -20)
          ..cubicTo(6, -16, 6, -6, 0, 0)
          ..close(),
        blatt,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SonnenBaum old) => old.t != t || old.kreis != kreis;
}

/// After buying (Entwurf 7 "Danach mit Abo"): a gold ring draws itself, a
/// sprout grows, then "wir wachsen weiter" and the coming week.
class AboDanke extends StatefulWidget {
  const AboDanke({
    super.key,
    required this.name,
    required this.plan,
    required this.naechsteZahlung,
    required this.onWeiter,
  });

  final String name;
  final AboPlan plan;
  final DateTime? naechsteZahlung;
  final VoidCallback onWeiter;

  @override
  State<AboDanke> createState() => _AboDankeState();
}

class _AboDankeState extends State<AboDanke>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _rein(double von, Widget child) {
    final a = CurvedAnimation(
      parent: _c,
      curve: Interval(von, math.min(1, von + .3), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .1),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final z = widget.naechsteZahlung;
    final name = widget.name.trim();
    return BernsteinHintergrund(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              key: const ValueKey('abo-danke'),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, _) => CustomPaint(
                      size: const Size.square(160),
                      painter: _DankeRing(_c.value),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _rein(
                  .45,
                  Center(
                    child: GoldText(
                      name.isEmpty
                          ? 'Wir wachsen weiter.'
                          : '$name, wir wachsen weiter.',
                      style: Glas.tBig.copyWith(fontSize: 25),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _rein(
                  .52,
                  GlasBox(
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Affe(),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Ab morgen gehen wir an das, was ich in deiner Woche '
                            'gesehen habe. Den Plan bekommst du mit dem nächsten '
                            'Check-in.',
                            style: Glas.tText.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _rein(
                  .58,
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1FF6D690),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x66F6D690)),
                      ),
                      child: Text(
                        'Abo aktiv · ${widget.plan.label}'
                        '${z == null ? '' : ' · nächste Zahlung ${z.day}.${z.month}.${z.year}'}',
                        style: Glas.tSoft.copyWith(
                          color: Bernstein.gold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _rein(
                  .64,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Zwischen('Deine nächste Woche'),
                      const SizedBox(height: 8),
                      GlasBox(
                        radius: 20,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            for (final (i, (tag, text)) in const [
                              (
                                'Mo',
                                'Dein Coach plant mit dem, was er über dich weiß',
                              ),
                              ('Mi', 'Zwischen-Check zu deinem Fokus'),
                              (
                                'So',
                                'Dein erster Reality Check und ein neuer Fokus',
                              ),
                            ].indexed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  border: i == 0
                                      ? null
                                      : const Border(
                                          top: BorderSide(
                                            color: Color(0x12FFFFFF),
                                          ),
                                        ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 26,
                                      child: Text(
                                        tag,
                                        style: Glas.tLabel.copyWith(
                                          fontSize: 11.5,
                                          color: Bernstein.gold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Bernstein.gold.withValues(
                                          alpha: 1 - i * .3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x80F6D690),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: Glas.tText.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
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
                const SizedBox(height: 18),
                _rein(
                  .7,
                  KontoKnopf(
                    key: const ValueKey('abo-zu-heute'),
                    label: 'Zu Heute',
                    onTap: widget.onWeiter,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DankeRing extends CustomPainter {
  _DankeRing(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.center(Offset.zero);
    final glanz = .2 + .1 * math.sin(t * math.pi);
    canvas.drawCircle(
      m,
      72,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 244, 214, glanz),
            const Color(0x00C9993F),
          ],
        ).createShader(Rect.fromCircle(center: m, radius: 72)),
    );
    final ring = Curves.easeInOut.transform((t / .45).clamp(0, 1));
    canvas.drawArc(
      Rect.fromCircle(center: m, radius: 58),
      -math.pi / 2,
      2 * math.pi * ring,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFFFF1CC),
            Color(0xFFF6D690),
            Color(0xFFE58A45),
            Color(0xFFFFF1CC),
          ],
        ).createShader(Rect.fromCircle(center: m, radius: 58)),
    );
    final boden = m.dy + 22;
    canvas.drawLine(
      Offset(m.dx - 36, boden),
      Offset(m.dx + 36, boden),
      Paint()
        ..color = const Color(0xB3D9C7A7)
        ..strokeWidth = 1,
    );
    final tr = Curves.easeOut.transform(((t - .3) / .4).clamp(0, 1));
    if (tr > 0) {
      final p = Path()
        ..moveTo(m.dx, boden)
        ..lineTo(m.dx, boden - 38)
        ..moveTo(m.dx, boden - 24)
        ..quadraticBezierTo(m.dx - 10, boden - 32, m.dx - 20, boden - 29)
        ..moveTo(m.dx, boden - 32)
        ..quadraticBezierTo(m.dx + 11, boden - 43, m.dx + 21, boden - 39);
      for (final mt in p.computeMetrics()) {
        canvas.drawPath(
          mt.extractPath(0, mt.length * tr),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8
            ..strokeCap = StrokeCap.round
            ..color = Bernstein.gold,
        );
      }
    }
    // Sparks fly out once the ring is closed.
    final f = ((t - .42) / .4).clamp(0.0, 1.0);
    if (f > 0 && f < 1) {
      for (var k = 0; k < 16; k++) {
        final a = k / 16 * 2 * math.pi;
        final r = 58 + 46 * Curves.easeOut.transform(f);
        canvas.drawCircle(
          m + Offset(math.cos(a) * r, math.sin(a) * r - 20 * f),
          2.6 * (1 - f) + .6,
          Paint()..color = Color.fromRGBO(255, 240, 200, 1 - f),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DankeRing old) => old.t != t;
}
