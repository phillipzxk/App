import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../checkin/checkin.dart';
import '../ui/coach_style.dart';
import 'mindset_data.dart';
import 'mindset_logik.dart';
import 'mindset_ui.dart';

/// The breathing circle (in 5 s, out 5 s).
class Atemkreis extends StatefulWidget {
  const Atemkreis({super.key, this.size = 200, this.text});
  final double size;
  final String? text;

  @override
  State<Atemkreis> createState() => _AtemkreisState();
}

class _AtemkreisState extends State<Atemkreis>
    with SingleTickerProviderStateMixin {
  // Endless motion is off in widget tests (they wait for all animations).
  late final bool _lebendig = !WidgetsBinding.instance.runtimeType
      .toString()
      .contains('Test');
  late final _a = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
    value: .3,
  );

  @override
  void initState() {
    super.initState();
    if (_lebendig) _a.repeat(reverse: true);
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (context, _) {
      final t = Curves.easeInOutSine.transform(_a.value);
      final r = widget.size * (.55 + .45 * t);
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Container(
            width: r,
            height: r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0x66F5DFAE),
                  const Color(0x22E0BF7E),
                  CoachStyle.goldLight.withValues(alpha: 0),
                ],
                stops: const [0, .6, 1],
              ),
              border: Border.all(color: const Color(0x55F5DFAE)),
            ),
            child: widget.text == null
                ? null
                : Text(widget.text!, style: Glas.tText.copyWith(fontSize: 16)),
          ),
        ),
      );
    },
  );
}

/// Three minutes only breathing; everything else is locked until the
/// time is up.
class RuheModus extends StatefulWidget {
  const RuheModus({super.key, this.dauer = 180, required this.onFertig});
  final int dauer;
  final Future<void> Function() onFertig;

  @override
  State<RuheModus> createState() => _RuheModusState();
}

class _RuheModusState extends State<RuheModus> {
  late int _rest = widget.dauer;
  Timer? _uhr;
  bool get _fertig => _rest <= 0;

  @override
  void initState() {
    super.initState();
    _uhr = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _rest--);
      if (_fertig) {
        t.cancel();
        widget.onFertig();
      }
    });
  }

  @override
  void dispose() {
    _uhr?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gelaufen = widget.dauer - _rest;
    final atem = (gelaufen ~/ 5).isEven ? 'einatmen' : 'ausatmen';
    return PopScope(
      canPop: _fertig,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0907),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Atemkreis(size: 240, text: _fertig ? 'Gut gemacht' : atem),
                const SizedBox(height: 28),
                GoldSchrift(
                  '${math.max(0, _rest) ~/ 60}:'
                  '${(math.max(0, _rest) % 60).toString().padLeft(2, '0')}',
                  key: const ValueKey('ruhe-zeit'),
                  style: Glas.tBig.copyWith(fontSize: 44),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _fertig ? Icons.lock_open : Icons.lock_outline,
                      size: 14,
                      color: Glas.soft,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _fertig
                            ? 'Drei Minuten nur für dich.'
                            : 'Alles andere ist gesperrt, bis die Zeit um ist',
                        style: Glas.tSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                if (_fertig)
                  SizedBox(
                    width: 220,
                    child: GlasKnopf(
                      key: const ValueKey('ruhe-fertig'),
                      label: 'Zurück',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  )
                else
                  TextButton(
                    key: const ValueKey('ruhe-abbrechen'),
                    onPressed: () {
                      _uhr?.cancel();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Abbrechen',
                      style: Glas.tSoft.copyWith(fontSize: 13),
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

/// Opens the 3 minutes and saves the run when it reaches the end.
Future<void> starteRuhe(
  BuildContext context,
  MindsetUmfeld u, {
  int dauer = 180,
}) => Navigator.of(context).push(
  PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (_, _, _) => RuheModus(
      dauer: dauer,
      onFertig: () async {
        final d = u.stand.d;
        await u.stand.setze(d.copyWith(ruhe: [...d.ruhe, u.jetzt()]));
      },
    ),
    transitionsBuilder: (_, a, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 1.06, end: 1.0).animate(a),
        child: child,
      ),
    ),
  ),
);

class RuheSeite extends StatelessWidget {
  const RuheSeite({super.key, required this.u, this.dauer = 180});
  final MindsetUmfeld u;
  final int dauer;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final w = ruheWoche(u.stand.d, u.jetzt());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              key: const ValueKey('ruhe-start'),
              onTap: () => starteRuhe(context, u, dauer: dauer),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Atemkreis(size: 210),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.self_improvement,
                        size: 34,
                        color: CoachStyle.goldLight,
                      ),
                      const SizedBox(height: 4),
                      Text('Starten', style: Glas.tText.copyWith(fontSize: 17)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Danach ist für 3 Minuten alles gesperrt. Nur atmen.',
            textAlign: TextAlign.center,
            style: Glas.tSoft,
          ),
          Block(
            label: 'Diese Woche',
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      w.n == 0
                          ? 'Noch keine Ruhe genommen'
                          : '${w.n} Mal Ruhe genommen',
                      style: Glas.tText,
                    ),
                  ),
                  if (w.wann != null) Text(w.wann!, style: Glas.tSoft),
                ],
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Deine Werte (rated honestly once a week), calm habits to tick off and
/// the user's own practice.
class WerteSeite extends StatefulWidget {
  const WerteSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  State<WerteSeite> createState() => _WerteSeiteState();
}

class _WerteSeiteState extends State<WerteSeite> {
  MindsetUmfeld get u => widget.u;
  final _name = TextEditingController();
  final _wie = TextEditingController();
  final _gName = TextEditingController();
  final _gWann = TextEditingController();
  late final _praxis = TextEditingController(text: u.stand.d.praxis);

  @override
  void dispose() {
    for (final c in [_name, _wie, _gName, _gWann, _praxis]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final woche = wocheVon(u.jetzt());
      final heute = dayKey(u.jetzt());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            label: 'Wie gut hast du diese Woche danach gelebt?',
            children: [
              for (var i = 0; i < d.werte.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.werte[i].name, style: Glas.tText),
                            if (d.werte[i].wie.isNotEmpty)
                              Text(d.werte[i].wie, style: Glas.tSoft),
                          ],
                        ),
                      ),
                      for (var n = 1; n <= 5; n++)
                        _Note(
                          key: ValueKey('wert-$i-$n'),
                          n: n,
                          an: n <= (d.werte[i].noten[woche] ?? 0),
                          onTap: () => u.stand.setze(
                            d.copyWith(
                              werte: [
                                for (var j = 0; j < d.werte.length; j++)
                                  j == i
                                      ? d.werte[j].mitNote(woche, n)
                                      : d.werte[j],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (d.werte.length < 5) ...[
                const SizedBox(height: 6),
                GlasFeld(
                  key: const ValueKey('wert-name'),
                  controller: _name,
                  hint: 'Ein Wert, z. B. Ruhig bleiben',
                ),
                const SizedBox(height: 8),
                GlasFeld(
                  key: const ValueKey('wert-wie'),
                  controller: _wie,
                  hint: 'Woran man es merkt (optional)',
                ),
                const SizedBox(height: 8),
                GlasKnopf(
                  key: const ValueKey('wert-dazu'),
                  label: 'Wert dazu',
                  ghost: true,
                  onTap: () {
                    final n = _name.text.trim();
                    if (n.isEmpty) return;
                    u.stand.setze(
                      d.copyWith(
                        werte: [
                          ...d.werte,
                          Wert(name: n, wie: _wie.text.trim()),
                        ],
                      ),
                    );
                    _name.clear();
                    _wie.clear();
                  },
                ),
              ],
            ],
          ),
          Block(
            label: 'Ruhe im Alltag',
            children: [
              for (var i = 0; i < d.gewohnheiten.length; i++)
                HakenZeile(
                  key: ValueKey('gewohnheit-$i'),
                  an: d.gewohnheiten[i].tage.contains(heute),
                  onTap: () => u.stand.setze(
                    d.copyWith(
                      gewohnheiten: [
                        for (var j = 0; j < d.gewohnheiten.length; j++)
                          j == i
                              ? d.gewohnheiten[j].umschalten(heute)
                              : d.gewohnheiten[j],
                      ],
                    ),
                  ),
                  titel: d.gewohnheiten[i].name,
                  unter: d.gewohnheiten[i].wann,
                  rechts: d.gewohnheiten[i].tage.contains(heute)
                      ? 'heute'
                      : 'offen',
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GlasFeld(
                      key: const ValueKey('gewohnheit-name'),
                      controller: _gName,
                      hint: 'z. B. Lesen',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: GlasFeld(
                      key: const ValueKey('gewohnheit-wann'),
                      controller: _gWann,
                      hint: 'wann',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GlasKnopf(
                key: const ValueKey('gewohnheit-dazu'),
                label: 'Dazu',
                ghost: true,
                onTap: () {
                  final n = _gName.text.trim();
                  if (n.isEmpty) return;
                  u.stand.setze(
                    d.copyWith(
                      gewohnheiten: [
                        ...d.gewohnheiten,
                        RuheGewohnheit(name: n, wann: _gWann.text.trim()),
                      ],
                    ),
                  );
                  _gName.clear();
                  _gWann.clear();
                },
              ),
            ],
          ),
          Block(
            label: 'Deine Praxis',
            children: [
              Text(
                'Was dir Halt gibt, Glaube, Gebet oder Stille. Du legst fest, '
                'was es ist, ich erinnere nur.',
                style: Glas.tSoft.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 8),
              GlasFeld(
                key: const ValueKey('praxis-feld'),
                controller: _praxis,
                hint: 'Deine Praxis in deinen Worten',
                zeilen: 2,
                onChanged: (t) =>
                    u.stand.setze(u.stand.d.copyWith(praxis: t.trim())),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _Note extends StatelessWidget {
  const _Note({
    super.key,
    required this.n,
    required this.an,
    required this.onTap,
  });
  final int n;
  final bool an;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(left: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: an ? CoachStyle.goldGradient : null,
        color: an ? null : const Color(0x12FFECC8),
      ),
      child: Text(
        '$n',
        style: Glas.tLabel.copyWith(
          fontSize: 12,
          color: an ? CoachStyle.goldInk : Glas.soft,
        ),
      ),
    ),
  );
}

/// Sorgen abgeben: write freely, the coach sorts it into what the user can
/// change and what is not up to them; changeable things can become stones.
class SorgenSeite extends StatefulWidget {
  const SorgenSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  State<SorgenSeite> createState() => _SorgenSeiteState();
}

class _SorgenSeiteState extends State<SorgenSeite> {
  MindsetUmfeld get u => widget.u;
  final _text = TextEditingController();
  bool _laedt = false;
  List<Sorge>? _neu;
  String? _satz;
  bool _fehler = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _abgeben() async {
    final t = _text.text.trim();
    if (t.isEmpty || _laedt) return;
    setState(() {
      _laedt = true;
      _fehler = false;
    });
    final r = await u.coach.sorgen(
      u.profile,
      t,
      mindsetKontext(u.stand.d, u.jetzt()),
    );
    if (!mounted) return;
    if (r == null || r.sorgen.isEmpty) {
      setState(() {
        _laedt = false;
        _fehler = true;
      });
      return;
    }
    final tag = dayKey(u.jetzt());
    final sorgen = [
      for (final s in r.sorgen)
        Sorge(tag: tag, text: s.text, aendern: s.aendern, nicht: s.nicht),
    ];
    await u.stand.setze(
      u.stand.d.copyWith(sorgen: [...u.stand.d.sorgen, ...sorgen]),
    );
    _text.clear();
    setState(() {
      _laedt = false;
      _neu = sorgen;
      _satz =
          r.satz ?? 'Beides darf da sein. Kümmere dich nur um die linke Seite.';
    });
  }

  Future<void> _alsStein(Sorge s) async {
    final d = u.stand.d;
    if (d.steine.any((x) => x.titel == s.aendern && x.erledigt == null)) return;
    await u.stand.setze(
      d.mitStein(
        Stein(
          id: 'st${u.jetzt().microsecondsSinceEpoch}',
          titel: s.aendern,
          schritt: 'Nur 2 Minuten: damit anfangen.',
          seit: dayKey(u.jetzt()),
        ),
      ),
    );
    if (mounted) hinweis(context, 'Liegt jetzt als Stein auf deinem Berg.');
  }

  @override
  Widget build(BuildContext context) {
    final alt = [
      for (final s in u.stand.d.sorgen.reversed)
        if (_neu == null || !_neu!.contains(s)) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Block(
          label: 'Raus damit, ohne Ordnung',
          children: [
            GlasFeld(
              key: const ValueKey('sorgen-feld'),
              controller: _text,
              hint: 'Was bedrückt dich gerade?',
              zeilen: 4,
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('sorgen-abgeben'),
              label: _laedt ? 'Ich sortiere …' : 'Abgeben',
              onTap: _laedt ? null : _abgeben,
            ),
            if (_fehler) ...[
              const SizedBox(height: 8),
              Text(
                'Ich bin gerade nicht erreichbar. Dein Text bleibt stehen, '
                'versuch es gleich nochmal.',
                style: Glas.tSoft,
              ),
            ],
          ],
        ),
        if (_neu != null) ...[
          for (var i = 0; i < _neu!.length; i++)
            _SorgeKarte(
              key: ValueKey('sorge-$i'),
              sorge: _neu![i],
              onStein: () => _alsStein(_neu![i]),
              steinKey: ValueKey('sorge-stein-$i'),
            ),
          Block(art: GlasArt.gold, children: [CoachZeile(_satz!)]),
        ],
        if (alt.isNotEmpty)
          Block(
            label: 'Schon abgegeben',
            children: [
              for (final s in alt.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text('„${s.text}“', style: Glas.tSoft),
                ),
            ],
          ),
      ],
    );
  }
}

class _SorgeKarte extends StatelessWidget {
  const _SorgeKarte({
    super.key,
    required this.sorge,
    required this.onStein,
    required this.steinKey,
  });
  final Sorge sorge;
  final VoidCallback onStein;
  final Key steinKey;

  @override
  Widget build(BuildContext context) => Block(
    children: [
      Text('„${sorge.text}“', style: Glas.tText),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kannst du ändern', style: Glas.tLabel),
                const SizedBox(height: 4),
                Text(sorge.aendern, style: Glas.tText.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                GestureDetector(
                  key: steinKey,
                  onTap: onStein,
                  child: Text(
                    'Als Stein auf den Berg ›',
                    style: Glas.tLabel.copyWith(color: CoachStyle.goldLight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liegt nicht bei dir',
                  style: Glas.tLabel.copyWith(color: Glas.soft),
                ),
                const SizedBox(height: 4),
                Text(sorge.nicht, style: Glas.tSoft.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

/// The evening question: one per night, the answers form the Leitsatz.
class AbendFrageSeite extends StatefulWidget {
  const AbendFrageSeite({super.key, required this.u});
  final MindsetUmfeld u;

  @override
  State<AbendFrageSeite> createState() => _AbendFrageSeiteState();
}

class _AbendFrageSeiteState extends State<AbendFrageSeite> {
  MindsetUmfeld get u => widget.u;
  final _text = TextEditingController();
  bool _laedt = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _guteNacht() async {
    final t = _text.text.trim();
    if (t.isEmpty || _laedt) return;
    setState(() => _laedt = true);
    final d = u.stand.d;
    final antwort = Abendantwort(
      tag: dayKey(u.jetzt()),
      frage: abendFrage(d, u.jetzt()),
      antwort: t,
    );
    final alle = [...d.abend, antwort];
    await u.stand.setze(d.copyWith(abend: alle));
    final satz = await u.coach.leitsatz(u.profile, alle);
    if (satz != null) {
      await u.stand.setze(u.stand.d.copyWith(leitsatz: satz));
    }
    if (mounted) setState(() => _laedt = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final heute = abendHeute(d, u.jetzt());
      final n = d.abend.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            '„${abendFrage(d, u.jetzt())}“',
            textAlign: TextAlign.center,
            style: CoachStyle.title.copyWith(
              fontSize: 22,
              height: 1.3,
              color: Glas.text,
            ),
          ),
          if (heute == null) ...[
            const SizedBox(height: 14),
            GlasFeld(
              key: const ValueKey('abend-feld'),
              controller: _text,
              hint: 'Ehrlich, in ein paar Sätzen',
              zeilen: 3,
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('abend-gute-nacht'),
              label: _laedt ? 'Einen Moment …' : 'Gute Nacht',
              icon: Icons.nightlight_round,
              onTap: _laedt ? null : _guteNacht,
            ),
          ] else
            Block(
              art: GlasArt.nacht,
              children: [
                Text(heute.antwort, style: Glas.tText),
                const SizedBox(height: 6),
                Text(
                  'Schlaf gut${u.profile.name.trim().isEmpty ? '' : ', ${u.profile.name.trim()}'}.',
                  style: Glas.tSoft.copyWith(color: const Color(0xFFB9C0EE)),
                ),
              ],
            ),
          Block(
            key: const ValueKey('leitsatz'),
            art: GlasArt.nacht,
            label: d.leitsatz == null
                ? 'Dein Leitsatz wächst'
                : 'Dein Leitsatz · aus $n Antworten',
            children: [
              if (d.leitsatz != null)
                Text(
                  '„${d.leitsatz}“',
                  style: Glas.tText.copyWith(fontSize: 18, height: 1.35),
                )
              else
                Text(
                  n == 0
                      ? 'Aus deinen Antworten forme ich deinen Leitsatz. Nach '
                            'jeder Antwort wird er ein Stück klarer.'
                      : 'Aus $n Antworten bisher. Nach jeder Antwort wird er '
                            'ein Stück klarer.',
                  style: Glas.tSoft,
                ),
            ],
          ),
        ],
      );
    },
  );
}
