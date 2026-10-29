import 'dart:async';

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../checkin/checkin.dart';
import '../ui/coach_style.dart';
import 'mindset_data.dart';
import 'mindset_logik.dart';
import 'mindset_ui.dart';

/// Where the stones lie on the path, bottom to top (0..1 of the picture).
const _plaetze = [
  Offset(.17, .84),
  Offset(.53, .7),
  Offset(.3, .52),
  Offset(.6, .37),
  Offset(.4, .24),
  Offset(.7, .14),
];

/// The mountain path with the stones and the user's light on it.
class _BergMaler extends CustomPainter {
  _BergMaler({
    required this.steine,
    required this.erledigt,
    required this.auswahl,
    required this.klein,
  });

  final List<Stein> steine;
  final int erledigt;
  final String? auswahl;
  final bool klein;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    final hinten = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * .8)
      ..lineTo(w * .2, h * .66)
      ..lineTo(w * .34, h * .71)
      ..lineTo(w * .56, h * .32)
      ..lineTo(w * .7, h * .42)
      ..lineTo(w * .84, h * .12)
      ..lineTo(w, h * .36)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(hinten, Paint()..color = const Color(0xD92A2330));
    final vorne = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * .88)
      ..lineTo(w * .17, h * .8)
      ..lineTo(w * .4, h * .85)
      ..lineTo(w * .6, h * .6)
      ..lineTo(w * .8, h * .68)
      ..lineTo(w, h * .55)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(vorne, Paint()..color = const Color(0xE61C171D));
    // Gold summit.
    final gipfel = Path()
      ..moveTo(w * .84, h * .12)
      ..lineTo(w * .8, h * .19)
      ..lineTo(w * .83, h * .175)
      ..lineTo(w * .85, h * .2)
      ..lineTo(w * .87, h * .17)
      ..close();
    canvas.drawPath(
      gipfel,
      Paint()
        ..shader = CoachStyle.goldGradient.createShader(
          Rect.fromLTWH(w * .78, h * .1, w * .1, h * .1),
        ),
    );
    // Dashed path up.
    final pfad = Path()..moveTo(w * .1, h * .95);
    for (final x in _plaetze) {
      final ziel = p(x.dx, x.dy);
      pfad.quadraticBezierTo(
        ziel.dx - w * .12,
        ziel.dy + h * .06,
        ziel.dx,
        ziel.dy,
      );
    }
    pfad.quadraticBezierTo(w * .8, h * .14, w * .84, h * .14);
    final strich = Paint()
      ..color = CoachStyle.goldLight.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = klein ? 1.2 : 1.8;
    for (final m in pfad.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 4), strich);
      }
    }
    // Stones.
    final r = klein ? 7.0 : 17.0;
    for (var i = 0; i < steine.length && i < _plaetze.length; i++) {
      final c = p(_plaetze[i].dx, _plaetze[i].dy);
      final sel = steine[i].id == auswahl;
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 2.4, height: r * 1.7),
        Paint()..color = const Color(0xFF5A5260),
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 2.4, height: r * 1.7),
        Paint()
          ..color = sel ? CoachStyle.goldLight : const Color(0xFF8A7F8C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sel ? 2 : 1.1,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c - Offset(r * .35, r * .3),
          width: r * .9,
          height: r * .4,
        ),
        Paint()..color = const Color(0xFF7B7180),
      );
      if (!klein) {
        final tp = TextPainter(
          text: TextSpan(
            text: steine[i].titel,
            style: Glas.tSoft.copyWith(
              color: const Color(0xFFE8DCC4),
              fontSize: 12,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: w * .42);
        final links = c.dx > w * .55;
        tp.paint(
          canvas,
          Offset(
            links ? c.dx - r * 1.4 - tp.width - 4 : c.dx + r * 1.4 + 4,
            c.dy - tp.height / 2,
          ),
        );
      }
    }
    // The user's light: higher with every stone that rolled away.
    final stufe = erledigt.clamp(0, _plaetze.length);
    final ich = stufe == 0
        ? p(.1, .95)
        : p(_plaetze[stufe - 1].dx - .08, _plaetze[stufe - 1].dy + .05);
    canvas.drawCircle(
      ich,
      klein ? 9 : 18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            CoachStyle.goldLight.withValues(alpha: .55),
            CoachStyle.goldLight.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: ich, radius: klein ? 9 : 18)),
    );
    canvas.drawCircle(
      ich,
      klein ? 3.5 : 6,
      Paint()..color = CoachStyle.goldLight,
    );
  }

  @override
  bool shouldRepaint(_BergMaler o) =>
      o.steine != steine || o.erledigt != erledigt || o.auswahl != auswahl;
}

/// The small mountain for the tile.
class BergMini extends StatelessWidget {
  const BergMini({super.key, required this.daten});
  final MindsetDaten daten;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    height: 92,
    child: CustomPaint(
      painter: _BergMaler(
        steine: daten.offeneSteine,
        erledigt: daten.steine.length - daten.offeneSteine.length,
        auswahl: null,
        klein: true,
      ),
    ),
  );
}

/// Dein Berg: stones on the path, the 2-minute start, the Danach-Plan and
/// the excuse when a stone is left lying.
class BergSeite extends StatefulWidget {
  const BergSeite({super.key, required this.u, this.dauer = 120});

  final MindsetUmfeld u;

  /// Length of the 2-minute start in seconds.
  final int dauer;

  @override
  State<BergSeite> createState() => _BergSeiteState();
}

enum _Phase { bereit, laeuft, um, liegen }

class _BergSeiteState extends State<BergSeite> {
  MindsetUmfeld get u => widget.u;
  String? _auswahl;
  bool _neu = false;
  bool _laedt = false;
  _Phase _phase = _Phase.bereit;
  int _rest = 0;
  Timer? _uhr;
  String? _coachSatz;
  final _titel = TextEditingController();
  final _schritt = TextEditingController();

  @override
  void initState() {
    super.initState();
    u.stand.addListener(_neuBauen);
  }

  void _neuBauen() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    u.stand.removeListener(_neuBauen);
    _uhr?.cancel();
    _titel.dispose();
    _schritt.dispose();
    super.dispose();
  }

  Stein? get _stein {
    final offen = u.stand.d.offeneSteine;
    if (offen.isEmpty) return null;
    return offen.firstWhere((s) => s.id == _auswahl, orElse: () => offen.first);
  }

  void _waehle(String id) {
    if (_phase == _Phase.laeuft) return;
    setState(() {
      _auswahl = id;
      _neu = false;
      _phase = _Phase.bereit;
      _coachSatz = null;
    });
  }

  Future<void> _los(Stein s) async {
    _uhr?.cancel();
    setState(() {
      _phase = _Phase.laeuft;
      _rest = widget.dauer;
    });
    _uhr = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _rest--);
      if (_rest <= 0) {
        t.cancel();
        setState(() => _phase = _Phase.um);
      }
    });
    var neu = s.copyWith(starts: s.starts + 1);
    await u.stand.setze(u.stand.d.mitStein(neu));
    if (s.danach.isEmpty) {
      final plan = await u.coach.danach(
        u.profile,
        s.titel,
        '${mindsetKontext(u.stand.d, u.jetzt())}\n${u.kontext}',
      );
      final punkte = (plan != null && plan.isNotEmpty)
          ? plan.take(3).toList()
          : _danachSonst(s);
      final jetzt = u.stand.d.stein(s.id) ?? neu;
      await u.stand.setze(u.stand.d.mitStein(jetzt.copyWith(danach: punkte)));
    }
  }

  List<String> _danachSonst(Stein s) => [
    '2 Minuten: ${s.titel}, oder länger, wenn es läuft',
    '10 Minuten raus, ohne Handy',
    if (u.tagDanach.isNotEmpty)
      u.tagDanach.first
    else
      'Danach gehört dir der Rest',
  ];

  Future<void> _erledigt(Stein s) async {
    _uhr?.cancel();
    await u.stand.setze(
      u.stand.d.mitStein(s.copyWith(erledigt: dayKey(u.jetzt()))),
    );
    if (!mounted) return;
    setState(() {
      _phase = _Phase.bereit;
      _auswahl = null;
    });
    hinweis(context, 'Der Stein ist weg. Du bist ein Stück höher.');
  }

  Future<void> _ausrede(Stein s, String text) async {
    final d = u.stand.d;
    await u.stand.setze(
      d.copyWith(
        ausreden: [
          ...d.ausreden,
          Ausrede(zeit: u.jetzt(), text: text, stein: s.id),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _phase = _Phase.bereit);
    hinweis(context, 'Gemerkt. Ich zeige dir, wann sie wiederkommt.');
  }

  Future<void> _legen() async {
    final titel = _titel.text.trim();
    if (titel.isEmpty || _laedt) return;
    final eigen = _schritt.text.trim();
    setState(() => _laedt = true);
    final r = await u.coach.schritt(
      u.profile,
      titel,
      eigen.isEmpty ? null : eigen,
      mindsetKontext(u.stand.d, u.jetzt()),
    );
    final schritt =
        r?.schritt ??
        (eigen.isEmpty ? 'Nur 2 Minuten: das Erste dafür öffnen.' : eigen);
    final passt = eigen.isNotEmpty && (r?.passt ?? true);
    final stein = Stein(
      id: 'st${u.jetzt().microsecondsSinceEpoch}',
      titel: titel,
      schritt: schritt,
      eigener: passt,
      seit: dayKey(u.jetzt()),
    );
    await u.stand.setze(u.stand.d.mitStein(stein));
    if (!mounted) return;
    _titel.clear();
    _schritt.clear();
    setState(() {
      _laedt = false;
      _neu = false;
      _auswahl = stein.id;
      _coachSatz =
          r?.satz ??
          (passt
              ? 'Passt. Dein eigener Schritt zählt für deine Stufe.'
              : 'Liegt auf deinem Berg. Fang mit 2 Minuten an, mehr nicht.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = u.stand.d;
    final offen = d.offeneSteine;
    final s = _stein;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        GlasBox(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Glas.radius),
            child: AspectRatio(
              aspectRatio: 358 / 330,
              child: LayoutBuilder(
                builder: (context, c) => GestureDetector(
                  onTapUp: (e) {
                    for (
                      var i = 0;
                      i < offen.length && i < _plaetze.length;
                      i++
                    ) {
                      final p = Offset(
                        _plaetze[i].dx * c.maxWidth,
                        _plaetze[i].dy * c.maxHeight,
                      );
                      if ((p - e.localPosition).distance < 34) {
                        _waehle(offen[i].id);
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BergMaler(
                            steine: offen,
                            erledigt: d.steine.length - offen.length,
                            auswahl: s?.id,
                            klein: false,
                          ),
                        ),
                      ),
                      // Invisible tap targets for tests and screen readers.
                      for (
                        var i = 0;
                        i < offen.length && i < _plaetze.length;
                        i++
                      )
                        Positioned(
                          left: _plaetze[i].dx * c.maxWidth - 20,
                          top: _plaetze[i].dy * c.maxHeight - 14,
                          width: 40,
                          height: 28,
                          child: Semantics(
                            button: true,
                            label: offen[i].titel,
                            child: GestureDetector(
                              key: ValueKey('berg-stein-${offen[i].id}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _waehle(offen[i].id),
                            ),
                          ),
                        ),
                      if (offen.isEmpty)
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 16,
                          child: Text(
                            d.steine.isEmpty
                                ? 'Noch kein Stein. Leg alles drauf, wovor du '
                                      'dich gerade drückst.'
                                : 'Der Weg ist frei. Gerade liegt nichts mehr.',
                            style: Glas.tText,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_coachSatz != null)
          Block(art: GlasArt.gold, children: [CoachZeile(_coachSatz!)]),
        if (_neu) _neuBlock() else if (s != null) ..._steinBloecke(s),
        if (!_neu) ...[
          const SizedBox(height: 12),
          GlasKnopf(
            key: const ValueKey('berg-neu'),
            label: 'Neuer Stein',
            icon: Icons.add,
            ghost: true,
            onTap: () => setState(() {
              _neu = true;
              _coachSatz = null;
            }),
          ),
        ],
      ],
    );
  }

  Widget _neuBlock() => Block(
    art: GlasArt.gold,
    label: 'Neuer Stein · wovor drückst du dich?',
    children: [
      GlasFeld(
        key: const ValueKey('stein-titel'),
        controller: _titel,
        hint: 'z. B. Steuererklärung',
      ),
      const SizedBox(height: 12),
      Text('Dein erster kleiner Schritt?', style: Glas.tLabel),
      const SizedBox(height: 6),
      GlasFeld(
        key: const ValueKey('stein-schritt'),
        controller: _schritt,
        hint: 'Erst du, dann ergänze ich',
      ),
      const SizedBox(height: 6),
      Text(
        'Schlägst du ihn selbst vor und er passt, steigt deine '
        'Selbstständig-Stufe.',
        style: Glas.tSoft,
      ),
      const SizedBox(height: 12),
      GlasKnopf(
        key: const ValueKey('stein-legen'),
        label: _laedt ? 'Einen Moment …' : 'Auf den Berg legen',
        onTap: _laedt ? null : _legen,
      ),
    ],
  );

  List<Widget> _steinBloecke(Stein s) {
    final min = (_rest ~/ 60).toString();
    final sek = (_rest % 60).toString().padLeft(2, '0');
    return [
      Block(
        art: GlasArt.gold,
        label: 'Stein ${seitText(s.seit, u.jetzt())}',
        children: [
          Text(
            s.titel,
            style: CoachStyle.title.copyWith(fontSize: 21, color: Glas.text),
          ),
          const SizedBox(height: 8),
          Text('Dein 2-Minuten-Schritt', style: Glas.tLabel),
          Text(
            s.schritt,
            style: Glas.tText.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (_phase == _Phase.laeuft) ...[
            Center(
              child: GoldSchrift(
                '$min:$sek',
                key: const ValueKey('stein-timer'),
                style: Glas.tBig.copyWith(fontSize: 44),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1 - _rest / widget.dauer,
                minHeight: 5,
                backgroundColor: const Color(0x1AFFECC8),
                color: CoachStyle.goldLight,
              ),
            ),
            const SizedBox(height: 12),
            GlasKnopf(
              key: const ValueKey('stein-erledigt'),
              label: 'Erledigt',
              onTap: () => _erledigt(s),
            ),
          ],
          if (_phase == _Phase.um) ...[
            Text(
              '2 Minuten geschafft. Weitermachen oder für heute aufhören?',
              style: Glas.tText,
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('stein-erledigt'),
              label: 'Erledigt, Stein weg',
              onTap: () => _erledigt(s),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GlasKnopf(
                    key: const ValueKey('stein-weiter'),
                    label: 'Weitermachen',
                    ghost: true,
                    onTap: () => setState(() => _phase = _Phase.bereit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlasKnopf(
                    key: const ValueKey('stein-aufhoeren'),
                    label: 'Für heute gut',
                    ghost: true,
                    onTap: () => setState(() => _phase = _Phase.bereit),
                  ),
                ),
              ],
            ),
          ],
          if (_phase == _Phase.bereit) ...[
            GlasKnopf(
              key: const ValueKey('stein-los'),
              label: 'Jetzt anfangen',
              icon: Icons.play_arrow_rounded,
              onTap: () => _los(s),
            ),
            const SizedBox(height: 8),
            GlasKnopf(
              key: const ValueKey('stein-liegen'),
              label: 'Heute liegen lassen',
              ghost: true,
              onTap: () => setState(() => _phase = _Phase.liegen),
            ),
          ],
          if (_phase == _Phase.liegen) ...[
            Text('Okay. Was hält dich ab?', style: Glas.tText),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in ausredenWahl)
                  GlasChip(
                    key: ValueKey('ausrede-$a'),
                    label: a,
                    an: false,
                    onTap: () => _ausrede(s, a),
                  ),
              ],
            ),
          ],
        ],
      ),
      if (s.danach.isNotEmpty)
        Block(
          key: const ValueKey('danach-plan'),
          label: 'Danach-Plan',
          children: [
            for (var i = 0; i < s.danach.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: i == 0 ? CoachStyle.goldGradient : null,
                        border: i == 0
                            ? null
                            : Border.all(color: const Color(0x44FFEECD)),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: Glas.tLabel.copyWith(
                          color: i == 0 ? CoachStyle.goldInk : Glas.label,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.danach[i], style: Glas.tText)),
                  ],
                ),
              ),
          ],
        )
      else
        Block(
          label: 'Danach-Plan',
          children: [
            Text(
              'Sobald du anfängst, sage ich dir, was direkt danach kommt. So '
              'entsteht keine Lücke.',
              style: Glas.tSoft.copyWith(fontSize: 13.5),
            ),
          ],
        ),
    ];
  }
}
