import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../checkin/checkin.dart';
import '../ui/coach_style.dart';
import 'mindset_data.dart';
import 'mindset_logik.dart';
import 'mindset_ui.dart';

/// A gold ring that fills to [anteil] (0..1) with a text in the middle.
class GoldRing extends StatelessWidget {
  const GoldRing({
    super.key,
    required this.anteil,
    required this.text,
    this.size = 140,
    this.dicke = 11,
  });

  final double anteil;
  final String text;
  final double size;
  final double dicke;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: anteil.clamp(0, 1)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        painter: _RingMaler(t, dicke),
        child: Center(
          child: GoldSchrift(
            text,
            style: Glas.tBig.copyWith(fontSize: size * .2),
          ),
        ),
      ),
    ),
  );
}

class _RingMaler extends CustomPainter {
  _RingMaler(this.t, this.dicke);
  final double t;
  final double dicke;

  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromCircle(
      center: s.center(Offset.zero),
      radius: s.width / 2 - dicke / 2,
    );
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dicke
        ..color = const Color(0x1AFFECC8),
    );
    if (t <= 0) return;
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dicke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [Color(0xFFF5DFAE), Color(0xFF9A6D35), Color(0xFFF5DFAE)],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_RingMaler o) => o.t != t;
}

/// Wort gehalten: up to 3 promises a day, ticked in the evening; the week
/// as a ring and the last 6 weeks as bars.
class WortSeite extends StatefulWidget {
  const WortSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  State<WortSeite> createState() => _WortSeiteState();
}

class _WortSeiteState extends State<WortSeite> {
  final _neu = TextEditingController();
  MindsetUmfeld get u => widget.u;

  @override
  void dispose() {
    _neu.dispose();
    super.dispose();
  }

  Future<void> _dazu() async {
    final t = _neu.text.trim();
    final heute = dayKey(u.jetzt());
    final d = u.stand.d;
    if (t.isEmpty || d.vorsaetzeAm(heute).length >= 3) return;
    _neu.clear();
    await u.stand.setze(
      d.copyWith(
        vorsaetze: [
          ...d.vorsaetze,
          Vorsatz(tag: heute, text: t),
        ],
      ),
    );
  }

  Future<void> _umschalten(Vorsatz v) async {
    final d = u.stand.d;
    await u.stand.setze(
      d.copyWith(
        vorsaetze: [
          for (final x in d.vorsaetze)
            identical(x, v)
                ? Vorsatz(tag: x.tag, text: x.text, gehalten: !x.gehalten)
                : x,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final heute = u.jetzt();
      final w = wortWoche(d, heute);
      final heuteV = d.vorsaetzeAm(dayKey(heute));
      final verlauf = wortVerlauf(d, heute);
      final da = [for (final v in verlauf) ?v];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            children: [
              Center(
                child: GoldRing(
                  key: const ValueKey('wort-ring'),
                  anteil: w.vorgenommen == 0 ? 0 : w.gehalten / w.vorgenommen,
                  text: '${w.gehalten}/${w.vorgenommen}',
                ),
              ),
              const SizedBox(height: 6),
              Center(child: Text('diese Woche gehalten', style: Glas.tSoft)),
            ],
          ),
          Block(
            label: 'Heute vorgenommen · höchstens 3',
            rechts: 'abends abhaken',
            children: [
              for (var i = 0; i < heuteV.length; i++)
                HakenZeile(
                  key: ValueKey('vorsatz-$i'),
                  an: heuteV[i].gehalten,
                  onTap: () => _umschalten(heuteV[i]),
                  titel: heuteV[i].text,
                  rechts: heuteV[i].gehalten ? 'gehalten' : 'offen',
                ),
              if (heuteV.length < 3) ...[
                if (heuteV.isNotEmpty) const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GlasFeld(
                        key: const ValueKey('vorsatz-feld'),
                        controller: _neu,
                        hint: 'Was nimmst du dir heute vor?',
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: GlasKnopf(
                        key: const ValueKey('vorsatz-dazu'),
                        label: 'Dazu',
                        onTap: _dazu,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          Block(
            label: 'Die letzten 6 Wochen',
            children: [
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < verlauf.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: (verlauf[i] ?? 0) / 100,
                                ),
                                duration: Duration(milliseconds: 600 + i * 80),
                                curve: Curves.easeOutCubic,
                                builder: (context, t, _) => Container(
                                  height: 4 + 80 * t,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: i == verlauf.length - 1
                                        ? CoachStyle.goldGradient
                                        : null,
                                    color: i == verlauf.length - 1
                                        ? null
                                        : const Color(0x33FFECC8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                i == verlauf.length - 1
                                    ? 'jetzt'
                                    : '-${verlauf.length - 1 - i}',
                                style: Glas.tSoft.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              CoachZeile(
                da.length < 2
                    ? 'Nach zwei Wochen zeige ich dir, ob du dein Wort öfter '
                          'hältst.'
                    : 'Von ${da.first} auf ${da.last} Prozent seit '
                          '${da.length} Wochen.',
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Selbstständig: the level, how it works, and the user's own steps.
class StufeSeite extends StatelessWidget {
  const StufeSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final s = selbststaendig(d);
      final eigene = [
        for (final x in d.steine.reversed)
          if (x.eigener) x,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            art: GlasArt.gold,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GoldSchrift(
                    'Stufe ${s.stufe}',
                    style: Glas.tBig.copyWith(fontSize: 28),
                  ),
                  const Spacer(),
                  Text('von 5', style: Glas.tSoft),
                ],
              ),
              const SizedBox(height: 10),
              StufenStriche(stufe: s.stufe, hoch: 10),
              const SizedBox(height: 8),
              Text(
                s.stufe >= 5
                    ? 'Höchste Stufe. Du brauchst mich kaum noch.'
                    : 'Noch ${s.bisNaechste} eigene Schritte bis Stufe '
                          '${s.stufe + 1}',
                style: Glas.tSoft,
              ),
            ],
          ),
          Block(
            children: [
              Text(
                'Bevor ich helfe, frage ich dich nach deinem ersten Schritt. '
                'Je öfter dein eigener passt, desto höher die Stufe. So '
                'brauchst du mich immer weniger.',
                style: Glas.tText.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Block(
            label: 'Deine eigenen Schritte',
            children: [
              if (eigene.isEmpty)
                Text(
                  'Noch keiner. Leg einen Stein auf deinen Berg und schlag den '
                  'ersten Schritt selbst vor.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                ),
              for (final x in eigene.take(12))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(x.titel, style: Glas.tText),
                            Text(x.schritt, style: Glas.tSoft),
                          ],
                        ),
                      ),
                      const DuMarke(),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}

/// Small "DU" tag.
class DuMarke extends StatelessWidget {
  const DuMarke({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: CoachStyle.goldLight.withValues(alpha: .6)),
    ),
    child: Text(
      'DU',
      style: Glas.tLabel.copyWith(fontSize: 10.5, letterSpacing: 1),
    ),
  );
}

/// Five little bars, the first [stufe] gold.
class StufenStriche extends StatelessWidget {
  const StufenStriche({super.key, required this.stufe, this.hoch = 6});
  final int stufe;
  final double hoch;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 5; i++)
        Expanded(
          child: Container(
            height: hoch,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(hoch),
              gradient: i < stufe ? CoachStyle.goldGradient : null,
              color: i < stufe ? null : const Color(0x1FFFECC8),
            ),
          ),
        ),
    ],
  );
}

/// Ausreden-Spiegel: which excuse comes back and when, and a plan against
/// the most frequent one.
class AusredenSeite extends StatefulWidget {
  const AusredenSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  State<AusredenSeite> createState() => _AusredenSeiteState();
}

class _AusredenSeiteState extends State<AusredenSeite> {
  MindsetUmfeld get u => widget.u;
  bool _laedt = false;

  @override
  void initState() {
    super.initState();
    _holePlan();
  }

  /// From 3 excuses on, the coach makes a plan against the top one.
  Future<void> _holePlan() async {
    final d = u.stand.d;
    final l = ausredenListe(d);
    if (l.isEmpty || l.first.n < 3) return;
    final top = l.first;
    if (d.ausredenPlan?.ausrede == top.text) return;
    setState(() => _laedt = true);
    final plan = await u.coach.ausredenPlan(
      u.profile,
      top.text,
      '${mindsetKontext(d, u.jetzt())}\n${u.kontext}',
    );
    if (!mounted) return;
    setState(() => _laedt = false);
    if (plan == null) return;
    await u.stand.setze(
      u.stand.d.copyWith(
        ausredenPlan: (ausrede: top.text, plan: plan, uebernommen: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final l = ausredenListe(d);
      final max = l.isEmpty ? 1 : l.first.n;
      final p = d.ausredenPlan;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            children: [
              if (l.isEmpty)
                Text(
                  'Noch keine Ausrede. Lässt du einen Stein liegen, tippst du '
                  'an, was dich abhält. Hier siehst du dann, welche wiederkommt.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                ),
              for (final a in l)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('„${a.text}“', style: Glas.tText),
                                if (a.wann != null)
                                  Text(a.wann!, style: Glas.tSoft),
                              ],
                            ),
                          ),
                          GoldSchrift(
                            '${a.n}',
                            style: Glas.tBig.copyWith(fontSize: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: a.n / max,
                          minHeight: 4,
                          backgroundColor: const Color(0x14FFECC8),
                          color: CoachStyle.goldLight,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (p != null && l.isNotEmpty && p.ausrede == l.first.text)
            Block(
              key: const ValueKey('ausreden-plan'),
              art: GlasArt.gold,
              children: [
                CoachZeile('Plan gegen „${p.ausrede}“: ${p.plan}'),
                const SizedBox(height: 12),
                GlasKnopf(
                  key: const ValueKey('plan-uebernehmen'),
                  label: p.uebernommen ? 'Übernommen' : 'Plan übernehmen',
                  ghost: p.uebernommen,
                  onTap: p.uebernommen
                      ? null
                      : () async {
                          await u.stand.setze(
                            u.stand.d.copyWith(
                              ausredenPlan: (
                                ausrede: p.ausrede,
                                plan: p.plan,
                                uebernommen: true,
                              ),
                            ),
                          );
                          if (context.mounted) {
                            hinweis(
                              context,
                              'Übernommen. Ich erinnere dich daran, wenn sie '
                              'wiederkommt.',
                            );
                          }
                        },
                ),
              ],
            )
          else if (_laedt)
            Block(
              children: [
                Text('Ich schaue, was dagegen hilft …', style: Glas.tSoft),
              ],
            )
          else if (l.isNotEmpty && l.first.n < 3)
            Block(
              children: [
                Text(
                  'Ab der dritten gleichen Ausrede mache ich dir einen Plan '
                  'dagegen.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                ),
              ],
            ),
        ],
      );
    },
  );
}
