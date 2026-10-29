import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../checkin/checkin.dart';
import '../ui/coach_style.dart';
import 'mindset_data.dart';
import 'mindset_logik.dart';
import 'mindset_ui.dart';

/// The Lebensrad as a pentagon: gold = now, dashed = 3 months ago.
class _RadMaler extends CustomPainter {
  _RadMaler({
    required this.jetzt,
    this.vorher,
    required this.t,
    this.namen = true,
  });

  final Map<String, int> jetzt;
  final Map<String, int>? vorher;
  final double t;
  final bool namen;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2 + (namen ? 6 : 0));
    final r = math.min(s.width, s.height) / 2 - (namen ? 34 : 4);
    Offset pt(double v, int k) {
      final a = -math.pi / 2 + k * 2 * math.pi / 5;
      return c + Offset(math.cos(a), math.sin(a)) * r * v / 10;
    }

    Path poly(double Function(int k) v) {
      final p = Path()..moveTo(pt(v(0), 0).dx, pt(v(0), 0).dy);
      for (var k = 1; k < 5; k++) {
        p.lineTo(pt(v(k), k).dx, pt(v(k), k).dy);
      }
      return p..close();
    }

    final netz = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x21FFEECD);
    for (final x in [2.0, 4.0, 6.0, 8.0, 10.0]) {
      canvas.drawPath(poly((_) => x), netz);
    }
    if (vorher != null) {
      final p = poly((k) => (vorher![radBereiche[k]] ?? 0).toDouble());
      final strich = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0x99CDBB98);
      for (final m in p.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 8) {
          canvas.drawPath(m.extractPath(d, d + 4), strich);
        }
      }
    }
    final now = poly((k) => (jetzt[radBereiche[k]] ?? 0) * t);
    canvas.drawPath(now, Paint()..color = const Color(0x33E0BF7E));
    canvas.drawPath(
      now,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = CoachStyle.goldLight,
    );
    if (!namen) return;
    for (var k = 0; k < 5; k++) {
      final tp = TextPainter(
        text: TextSpan(
          text: radBereiche[k],
          style: Glas.tSoft.copyWith(fontSize: 11.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = pt(12.2, k);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadMaler o) => o.t != t || o.jetzt != jetzt;
}

class RadBild extends StatelessWidget {
  const RadBild({
    super.key,
    required this.jetzt,
    this.vorher,
    this.size = 280,
    this.namen = true,
  });

  final Map<String, int> jetzt;
  final Map<String, int>? vorher;
  final double size;
  final bool namen;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutBack,
    builder: (context, t, _) => SizedBox(
      width: size,
      height: size * (namen ? .95 : 1),
      child: CustomPaint(
        painter: _RadMaler(jetzt: jetzt, vorher: vorher, t: t, namen: namen),
      ),
    ),
  );
}

/// Dein Lebensrad: every 3 months each area 1..10, compared with last time.
class RadSeite extends StatefulWidget {
  const RadSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  State<RadSeite> createState() => _RadSeiteState();
}

class _RadSeiteState extends State<RadSeite> {
  MindsetUmfeld get u => widget.u;
  late final Map<String, int> _neu = {
    for (final b in radBereiche) b: u.stand.d.raeder.lastOrNull?.werte[b] ?? 5,
  };
  bool _ausfuellen = false;

  Future<void> _speichern() async {
    final d = u.stand.d;
    await u.stand.setze(
      d.copyWith(
        raeder: [
          ...d.raeder,
          Lebensrad(tag: dayKey(u.jetzt()), werte: {..._neu}),
        ],
      ),
    );
    if (mounted) setState(() => _ausfuellen = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final faellig = tageBisRad(d, u.jetzt()) == 0;
      final letztes = d.raeder.lastOrNull;
      final vorher = radVorher(d);
      if (_ausfuellen || letztes == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Block(
              art: GlasArt.gold,
              label: 'Wie zufrieden bist du gerade?',
              rechts: '1 bis 10',
              children: [
                Center(
                  child: RadBild(jetzt: _neu, vorher: letztes?.werte),
                ),
                for (final b in radBereiche)
                  Row(
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          b,
                          style: Glas.tText.copyWith(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          key: ValueKey('rad-$b'),
                          value: _neu[b]!.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: CoachStyle.goldLight,
                          inactiveColor: const Color(0x22FFECC8),
                          onChanged: (v) => setState(() => _neu[b] = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${_neu[b]}',
                          textAlign: TextAlign.right,
                          style: Glas.tLabel,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                GlasKnopf(
                  key: const ValueKey('rad-speichern'),
                  label: 'Lebensrad speichern',
                  onTap: _speichern,
                ),
              ],
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            children: [
              Center(
                child: RadBild(jetzt: letztes.werte, vorher: vorher?.werte),
              ),
              Text(
                vorher == null
                    ? 'gold = heute'
                    : 'gold = heute · gestrichelt = vor 3 Monaten',
                textAlign: TextAlign.center,
                style: Glas.tSoft,
              ),
            ],
          ),
          Block(
            children: [
              for (final b in radBereiche)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          b,
                          style: Glas.tText.copyWith(fontSize: 14),
                        ),
                      ),
                      GoldSchrift(
                        '${letztes.werte[b] ?? '–'}',
                        style: Glas.tBig.copyWith(fontSize: 18),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          _diff(letztes.werte[b], vorher?.werte[b]),
                          textAlign: TextAlign.right,
                          style: Glas.tSoft,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (faellig)
            GlasKnopf(
              key: const ValueKey('rad-neu'),
              label: 'Neues Lebensrad ausfüllen',
              onTap: () => setState(() => _ausfuellen = true),
            )
          else
            Text(
              'Das nächste kommt in ${tageBisRad(d, u.jetzt())} Tagen.',
              textAlign: TextAlign.center,
              style: Glas.tSoft,
            ),
        ],
      );
    },
  );

  static String _diff(int? a, int? b) {
    if (a == null || b == null) return '';
    final d = a - b;
    if (d == 0) return '±0';
    return d > 0 ? '+$d' : '−${-d}';
  }
}

/// One sentence about the Lebensrad for tile and coach line.
String? radSatz(MindsetDaten d) {
  final r = d.raeder.lastOrNull;
  if (r == null) return null;
  final v = radVorher(d);
  final tief = radBereiche.reduce(
    (a, b) => (r.werte[a] ?? 0) <= (r.werte[b] ?? 0) ? a : b,
  );
  if (v == null) return 'Am meisten zu holen ist gerade bei $tief.';
  final wachs = radBereiche.reduce(
    (a, b) =>
        (r.werte[a] ?? 0) - (v.werte[a] ?? 0) >=
            (r.werte[b] ?? 0) - (v.werte[b] ?? 0)
        ? a
        : b,
  );
  final plus = (r.werte[wachs] ?? 0) - (v.werte[wachs] ?? 0);
  return plus > 0
      ? '$wachs ist um $plus gewachsen. Am meisten zu holen ist gerade bei $tief.'
      : 'Am meisten zu holen ist gerade bei $tief.';
}

/// Brief an dich: write today, sealed, opens after 6 months.
class BriefSeite extends StatefulWidget {
  const BriefSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  State<BriefSeite> createState() => _BriefSeiteState();
}

class _BriefSeiteState extends State<BriefSeite> {
  MindsetUmfeld get u => widget.u;
  final _text = TextEditingController();
  bool _schreiben = false;

  @override
  void initState() {
    super.initState();
    _coachZuOffenen();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// An open letter gets the coach's look at what changed, once.
  Future<void> _coachZuOffenen() async {
    for (final b in offeneBriefe(u.stand.d, u.jetzt())) {
      if (b.satz != null) continue;
      final s = await u.coach.brief(
        u.profile,
        b,
        '${mindsetKontext(u.stand.d, u.jetzt())}\n${u.kontext}',
      );
      if (s == null) continue;
      final d = u.stand.d;
      await u.stand.setze(
        d.copyWith(
          briefe: [
            for (final x in d.briefe) identical(x, b) ? x.mitSatz(s) : x,
          ],
        ),
      );
    }
  }

  Future<void> _versiegeln() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    final heute = u.jetzt();
    final d = u.stand.d;
    await u.stand.setze(
      d.copyWith(
        briefe: [
          ...d.briefe,
          Brief(
            geschrieben: dayKey(heute),
            oeffnet: dayKey(sechsMonate(heute)),
            text: t,
          ),
        ],
      ),
    );
    _text.clear();
    if (!mounted) return;
    setState(() => _schreiben = false);
    hinweis(context, 'Versiegelt. In 6 Monaten öffnet er sich.');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final heute = u.jetzt();
      final naechster = naechsterBrief(d, heute);
      final offen = offeneBriefe(d, heute);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in offen.reversed)
            Block(
              art: GlasArt.gold,
              label: 'Dein Brief vom ${_datum(b.geschrieben)}',
              children: [
                Text(b.text, style: Glas.tText),
                if (b.satz != null) ...[
                  const SizedBox(height: 12),
                  CoachZeile(b.satz!),
                ],
              ],
            ),
          if (naechster != null && !_schreiben) ...[
            const SizedBox(height: 18),
            const Center(child: _Umschlag()),
            const SizedBox(height: 14),
            Center(
              child: GoldSchrift(
                '${naechster.tageBis(heute)} Tage',
                key: const ValueKey('brief-tage'),
                style: Glas.tBig.copyWith(fontSize: 40),
              ),
            ),
            Text(
              'Versiegelt am ${_datum(naechster.geschrieben)}. Öffnet am '
              '${_datum(naechster.oeffnet)}. Dann lege ich dir daneben, was '
              'sich seitdem verändert hat.',
              textAlign: TextAlign.center,
              style: Glas.tSoft,
            ),
          ],
          if (_schreiben || (naechster == null && offen.isEmpty))
            Block(
              label: 'Schreib dir, wer du in 6 Monaten sein willst',
              children: [
                GlasFeld(
                  key: const ValueKey('brief-feld'),
                  controller: _text,
                  hint: 'Lieber ich …',
                  zeilen: 6,
                ),
                const SizedBox(height: 10),
                GlasKnopf(
                  key: const ValueKey('brief-versiegeln'),
                  label: 'Versiegeln',
                  icon: Icons.lock_outline,
                  onTap: _versiegeln,
                ),
              ],
            )
          else ...[
            const SizedBox(height: 14),
            GlasKnopf(
              key: const ValueKey('brief-neu'),
              label: 'Noch einen Brief schreiben',
              ghost: true,
              onTap: () => setState(() => _schreiben = true),
            ),
          ],
        ],
      );
    },
  );
}

const _monate = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

String _datum(String tag) {
  final d = DateTime.parse(tag);
  return '${d.day}. ${_monate[d.month - 1]} ${d.year}';
}

class _Umschlag extends StatelessWidget {
  const _Umschlag();

  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    height: 112,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A2F22), Color(0xFF1E1812)],
      ),
      border: Border.all(color: const Color(0x55E0BF7E)),
      boxShadow: Glas.shadow,
    ),
    child: CustomPaint(
      painter: _KlappeMaler(),
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: CoachStyle.goldGradient,
            boxShadow: CoachStyle.goldGlow,
          ),
          child: const Icon(Icons.spa, size: 18, color: CoachStyle.goldInk),
        ),
      ),
    ),
  );
}

class _KlappeMaler extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width / 2, s.height * .55)
      ..lineTo(s.width, 0);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x66E0BF7E),
    );
  }

  @override
  bool shouldRepaint(_KlappeMaler o) => false;
}

/// Lebensziele: what everything else grows towards.
class ZieleSeite extends StatefulWidget {
  const ZieleSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  State<ZieleSeite> createState() => _ZieleSeiteState();
}

class _ZieleSeiteState extends State<ZieleSeite> {
  MindsetUmfeld get u => widget.u;
  final _text = TextEditingController();
  String _bereich = '';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFF1CF),
                    Color(0xAAE0BF7E),
                    Color(0x00E0BF7E),
                  ],
                  stops: [0, .35, 1],
                ),
              ),
            ),
          ),
          Block(
            children: [
              if (d.ziele.isEmpty)
                Text(
                  'Noch kein Lebensziel. Was willst du in deinem Leben '
                  'erreichen, ganz groß gedacht?',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                ),
              for (var i = 0; i < d.ziele.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: CoachStyle.goldGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(d.ziele[i].text, style: Glas.tText)),
                      if (d.ziele[i].bereich.isNotEmpty)
                        Text(d.ziele[i].bereich, style: Glas.tSoft),
                      IconButton(
                        key: ValueKey('ziel-weg-$i'),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Glas.soft,
                        ),
                        onPressed: () => u.stand.setze(
                          d.copyWith(
                            ziele: [
                              for (var j = 0; j < d.ziele.length; j++)
                                if (j != i) d.ziele[j],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Block(
            label: 'Lebensziel hinzufügen',
            children: [
              GlasFeld(
                key: const ValueKey('ziel-feld'),
                controller: _text,
                hint: 'z. B. Mit 40 in Topform',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in radBereiche)
                    GlasChip(
                      key: ValueKey('ziel-bereich-$b'),
                      label: b,
                      an: _bereich == b,
                      onTap: () =>
                          setState(() => _bereich = _bereich == b ? '' : b),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              GlasKnopf(
                key: const ValueKey('ziel-dazu'),
                label: 'Hinzufügen',
                onTap: () {
                  final t = _text.text.trim();
                  if (t.isEmpty) return;
                  u.stand.setze(
                    d.copyWith(
                      ziele: [
                        ...d.ziele,
                        Lebensziel(text: t, bereich: _bereich),
                      ],
                    ),
                  );
                  _text.clear();
                  setState(() => _bereich = '');
                },
              ),
            ],
          ),
        ],
      );
    },
  );
}
