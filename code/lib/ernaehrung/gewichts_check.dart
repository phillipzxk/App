import 'package:flutter/material.dart';

import '../feed/kcal.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../weight/weight.dart';
import '../weight/weight_chart.dart';
import 'ernaehrung_data.dart';
import 'ernaehrung_logik.dart';
import 'ernaehrung_stand.dart';

/// Idea 6: the weight did not move towards the goal for 3 weeks (or too
/// fast). The coach asks first, then shows its view and suggests a new
/// kcal target, to take over or leave, with undo.
class GewichtsCheckSeite extends StatefulWidget {
  const GewichtsCheckSeite({
    super.key,
    required this.umfeld,
    required this.weights,
    required this.kcal,
  });

  final EssenUmfeld umfeld;
  final List<WeightEntry> weights;

  /// Today's kcal target including earlier changes; null without data.
  final int? Function() kcal;

  @override
  State<GewichtsCheckSeite> createState() => _GewichtsCheckSeiteState();
}

class _GewichtsCheckSeiteState extends State<GewichtsCheckSeite> {
  bool _laedt = false;

  EssenUmfeld get u => widget.umfeld;
  int get _richtung => zielRichtung(u.profile.ziel);

  /// The open or latest check of the last 3 weeks.
  GewichtsCheck? get _check {
    if (u.d.gewicht.isEmpty) return null;
    final c = u.d.gewicht.last;
    return u.jetzt().difference(DateTime.parse(c.tag)).inDays < 21 ? c : null;
  }

  Future<void> _setze(GewichtsCheck c) => u.stand.setze(
    u.d.copyWith(
      gewicht: [
        for (final x in u.d.gewicht)
          if (x.tag != c.tag) x,
        c,
      ],
    ),
  );

  Future<void> _grund(String g, ({String lage, String text}) lage) async {
    final kcal = widget.kcal();
    if (kcal == null || _laedt) return;
    setState(() => _laedt = true);
    var c = GewichtsCheck(
      tag: u.heute,
      lage: lage.lage,
      kcalAlt: kcal,
      grund: g,
    );
    await _setze(c);
    final wochen = weeklyAverages(widget.weights);
    final verlauf = [
      for (final w in wochen.skip(wochen.length > 8 ? wochen.length - 8 : 0))
        '${w.monday.day}.${w.monday.month}.: ${formatKg(w.kg)} kg',
    ].join('\n');
    final r = await u.coach.gewicht(
      u.profile,
      verlauf,
      kcal,
      g,
      '${lage.text}\n${u.musterText()}',
    );
    c = c.copyWith(
      sicht:
          r?.sicht ??
          (lage.lage == 'zu schnell'
              ? 'Das geht schneller, als es deinem Ziel guttut. Etwas mehr '
                    'essen hilft dir, Kraft und Energie zu halten.'
              : 'Dein Gewicht steht, obwohl dein Ziel woanders hin will. Eine '
                    'kleine Änderung beim Essen bringt es wieder in Bewegung.'),
      vorschlag:
          r?.vorschlag ??
          (kcalVorschlagOhneCoach(kcal, lage.lage, _richtung) > kcal
              ? 'Am einfachsten: ein Snack extra am Tag.'
              : 'Am einfachsten: die Abendmahlzeit etwas kleiner.'),
      kcalNeu: r?.kcalNeu ?? kcalVorschlagOhneCoach(kcal, lage.lage, _richtung),
    );
    await _setze(c);
    if (mounted) setState(() => _laedt = false);
  }

  Future<void> _uebernehmen(GewichtsCheck c, bool ja) async {
    final diff = (c.kcalNeu ?? c.kcalAlt) - c.kcalAlt;
    final war = c.status == 'uebernommen';
    final neu = c.copyWith(status: ja ? 'uebernommen' : 'gelassen');
    var anpassung = u.d.kcalAnpassung;
    if (ja && !war) anpassung += diff;
    if (!ja && war) anpassung -= diff;
    await u.stand.setze(
      u.d.copyWith(
        kcalAnpassung: anpassung,
        gewicht: [
          for (final x in u.d.gewicht)
            if (x.tag != c.tag) x,
          neu,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => EssenSeite(
    umfeld: u,
    label: 'Ernährung · Gewicht',
    titel: 'Gewichts-Check',
    bau: (context) {
      final wochen = weeklyAverages(widget.weights);
      final c = _check;
      final lage =
          gewichtsLage(widget.weights, u.profile.ziel, u.d, u.jetzt()) ??
          (c == null ? null : (lage: c.lage, text: ''));
      final gruende = gewichtsGruende(lage?.lage ?? 'steht', _richtung);
      return [
        if (wochen.isNotEmpty)
          TKarte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TLabel(
                  'Wochenschnitt · ${wochen.length > 7 ? 7 : wochen.length} Wochen',
                ),
                const SizedBox(height: 8),
                WeightChart(
                  weeks: wochen.length > 7
                      ? wochen.sublist(wochen.length - 7)
                      : wochen,
                ),
              ],
            ),
          ),
        if (lage == null)
          TKarte(
            child: CoachZeile(
              text: wochen.length < 4
                  ? 'Trag ein paar Wochen dein Gewicht ein. Tut sich 3 Wochen '
                        'nichts in Richtung deines Ziels, melde ich mich hier.'
                  : 'Dein Gewicht läuft zu deinem Ziel. Ich melde mich, wenn '
                        'sich 3 Wochen nichts tut.',
            ),
          )
        else
          TKarte(
            key: const ValueKey('gewicht-check'),
            gold: c == null || c.status == 'offen',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CoachZeile(
                  text:
                      '${lage.text.isEmpty ? 'Dein Gewicht hat sich zuletzt nicht passend zu deinem Ziel bewegt.' : lage.text} '
                      'Was meinst du, woran es liegt?',
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final g in gruende)
                      TChip(
                        g,
                        key: ValueKey('gewicht-grund-$g'),
                        an: c?.grund == g,
                        onTap: c == null ? () => _grund(g, lage) : null,
                      ),
                  ],
                ),
                if (_laedt)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(color: CoachStyle.gold),
                    ),
                  ),
                if (c?.sicht != null) ...[
                  const SizedBox(height: 10),
                  CoachZeile(text: '${c!.sicht!} ${c.vorschlag ?? ''}'.trim()),
                  if (c.kcalNeu != null && c.kcalNeu != c.kcalAlt) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formatKcal(c.kcalAlt),
                          style: tTitel.copyWith(
                            fontSize: 18,
                            color: CoachStyle.inkSoft,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward,
                            color: CoachStyle.goldLight,
                            size: 20,
                          ),
                        ),
                        GoldZahl(formatKcal(c.kcalNeu!)),
                        const SizedBox(width: 6),
                        const Text('kcal', style: tSoft),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (c.status == 'offen')
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              key: const ValueKey('gewicht-uebernehmen'),
                              style: FilledButton.styleFrom(
                                backgroundColor: CoachStyle.goldLight,
                                foregroundColor: CoachStyle.goldInk,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => _uebernehmen(c, true),
                              child: const Text('Übernehmen'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TGhost(
                              'So lassen',
                              key: const ValueKey('gewicht-lassen'),
                              onTap: () => _uebernehmen(c, false),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.status == 'uebernommen'
                                  ? 'Übernommen. In 3 Wochen schauen wir wieder drauf.'
                                  : 'Bleibt bei ${formatKcal(c.kcalAlt)}.',
                              style: tSoft.copyWith(
                                color: c.status == 'uebernommen'
                                    ? CoachStyle.goldLight
                                    : null,
                              ),
                            ),
                          ),
                          TLink(
                            c.status == 'uebernommen'
                                ? 'Rückgängig'
                                : 'Doch ändern',
                            key: const ValueKey('gewicht-zurueck'),
                            onTap: () =>
                                _uebernehmen(c, c.status != 'uebernommen'),
                          ),
                        ],
                      ),
                  ],
                ],
              ],
            ),
          ),
        const Text(
          'Andersrum genauso: Geht es zu schnell für dein Ziel, sagt der Coach '
          'das auch. Gezählt wird nichts, du siehst nur dein Ziel.',
          style: tSoft,
        ),
      ];
    },
  );
}

/// A big number in the gold gradient.
class GoldZahl extends StatelessWidget {
  const GoldZahl(this.text, {super.key, this.size = 30});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) => CoachStyle.goldTextGradient.createShader(r),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: Colors.white,
        height: 1.1,
      ),
    ),
  );
}
