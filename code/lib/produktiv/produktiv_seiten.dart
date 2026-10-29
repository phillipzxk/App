import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../checkin/checkin.dart';
import '../mindset/dranbleiben.dart' show GoldRing;
import '../mindset/mindset_ui.dart';
import '../sleep/schlafzeiten.dart' show formatUhrzeit;
import '../ui/coach_style.dart';
import 'produktiv_data.dart';
import 'produktiv_logik.dart';

/// The Produktivität data in memory; every change is saved right away.
class ProduktivStand extends ChangeNotifier {
  ProduktivStand(this._speichern);

  final Future<void> Function(ProduktivDaten d) _speichern;
  ProduktivDaten _d = const ProduktivDaten();
  ProduktivDaten get d => _d;

  void laden(ProduktivDaten d) {
    _d = d;
    notifyListeners();
  }

  Future<void> setze(ProduktivDaten d) async {
    _d = d;
    notifyListeners();
    await _speichern(d);
  }
}

/// What every Produktivität page needs.
class ProduktivUmfeld {
  const ProduktivUmfeld({
    required this.stand,
    required this.jetzt,
    this.energieJetzt,
    this.aufstehen,
    this.tag = const [],
  });

  final ProduktivStand stand;
  final DateTime Function() jetzt;

  /// Today's forecast energy right now (0..1), if known.
  final double? energieJetzt;

  /// Today's wake time in minutes, from the sleep times.
  final int? aufstehen;

  /// Today's plan as lines ("12:30 Mittagessen").
  final List<String> tag;

  String get heute => dayKey(jetzt());
}

/// Seven dots, gold where kept.
class SiebenPunkte extends StatelessWidget {
  const SiebenPunkte({super.key, required this.an, required this.heute});
  final List<bool?> an;
  final DateTime heute;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 7; i++)
        Expanded(
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: an[i] == true ? CoachStyle.goldGradient : null,
                  color: an[i] == true
                      ? null
                      : an[i] == false
                      ? const Color(0x1FFFECC8)
                      : const Color(0x0AFFECC8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                wochentageKurz[heute.subtract(Duration(days: 6 - i)).weekday -
                    1],
                style: Glas.tSoft.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
    ],
  );
}

// ------------------------------------------------------------- Fokus heute

class FokusHeuteSeite extends StatefulWidget {
  const FokusHeuteSeite({super.key, required this.u});
  final ProduktivUmfeld u;

  @override
  State<FokusHeuteSeite> createState() => _FokusHeuteSeiteState();
}

class _FokusHeuteSeiteState extends State<FokusHeuteSeite> {
  final _text = TextEditingController();
  bool _aendern = false;
  ProduktivUmfeld get u => widget.u;

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
      final f = d.fokusAm(u.heute);
      final sieben = fokus7(d, u.jetzt());
      final geschafft = sieben.where((x) => x == true).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (f == null || _aendern)
            Block(
              art: GlasArt.gold,
              label: 'Die eine Sache heute',
              children: [
                GlasFeld(
                  key: const ValueKey('fokus-feld'),
                  controller: _text,
                  hint: 'Was zählt heute wirklich?',
                ),
                const SizedBox(height: 10),
                GlasKnopf(
                  key: const ValueKey('fokus-setzen'),
                  label: 'Festlegen',
                  onTap: () {
                    final t = _text.text.trim();
                    if (t.isEmpty) return;
                    u.stand.setze(
                      d.mitFokus(
                        TagesFokus(tag: u.heute, text: t, gesetzt: u.jetzt()),
                      ),
                    );
                    _text.clear();
                    setState(() => _aendern = false);
                  },
                ),
              ],
            )
          else
            Block(
              art: GlasArt.gold,
              label: 'Die eine Sache heute',
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  style: CoachStyle.title.copyWith(
                    fontSize: 22,
                    height: 1.25,
                    color: f.erledigt ? Glas.soft : Glas.text,
                    decoration: f.erledigt
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: CoachStyle.goldLight,
                  ),
                  child: Text(f.text, key: const ValueKey('fokus-text')),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gesetzt um ${formatUhrzeit(f.gesetzt.hour * 60 + f.gesetzt.minute)}',
                  style: Glas.tSoft,
                ),
                const SizedBox(height: 12),
                GlasKnopf(
                  key: const ValueKey('fokus-erledigt'),
                  label: f.erledigt ? 'Geschafft' : 'Erledigt',
                  ghost: f.erledigt,
                  icon: f.erledigt ? Icons.check : null,
                  onTap: () => u.stand.setze(d.mitFokus(f.umschalten())),
                ),
                if (!f.erledigt) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      key: const ValueKey('fokus-aendern'),
                      onPressed: () {
                        _text.text = f.text;
                        setState(() => _aendern = true);
                      },
                      child: Text('Ändern', style: Glas.tSoft),
                    ),
                  ),
                ],
              ],
            ),
          if (u.tag.isNotEmpty)
            Block(
              label: 'Der Rest steht in Dein Tag',
              children: [
                for (final z in u.tag)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(z, style: Glas.tText.copyWith(fontSize: 14)),
                  ),
              ],
            ),
          Block(
            label: 'Die letzten 7 Tage',
            children: [
              SiebenPunkte(an: sieben, heute: u.jetzt()),
              const SizedBox(height: 8),
              Text(
                '$geschafft von 7 Tagen die eine Sache geschafft',
                style: Glas.tSoft,
              ),
            ],
          ),
        ],
      );
    },
  );
}

// ------------------------------------------------------------ Focus timer

/// Full-screen countdown with a gold ring. With [gesperrt] it can only be
/// left when the time is up (Fokus-Knopf).
class FokusTimer extends StatefulWidget {
  const FokusTimer({
    super.key,
    required this.titel,
    required this.minuten,
    required this.onEnde,
    this.gesperrt = false,
    this.sekundeLaenge = const Duration(seconds: 1),
  });

  final String titel;
  final int minuten;
  final bool gesperrt;

  /// Called with the minutes done when the timer ends or is stopped.
  final Future<void> Function(int geschafft) onEnde;
  final Duration sekundeLaenge;

  @override
  State<FokusTimer> createState() => _FokusTimerState();
}

class _FokusTimerState extends State<FokusTimer> {
  late final int _gesamt = widget.minuten * 60;
  late int _rest = _gesamt;
  Timer? _uhr;
  bool _gespeichert = false;
  bool get _fertig => _rest <= 0;

  @override
  void initState() {
    super.initState();
    _uhr = Timer.periodic(widget.sekundeLaenge, (t) {
      if (!mounted) return t.cancel();
      setState(() => _rest--);
      if (_fertig) {
        t.cancel();
        _speichern();
      }
    });
  }

  Future<void> _speichern() async {
    if (_gespeichert) return;
    _gespeichert = true;
    await widget.onEnde(((_gesamt - math.max(0, _rest)) / 60).round());
  }

  @override
  void dispose() {
    _uhr?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = math.max(0, _rest);
    final zeit = '${r ~/ 60}:${(r % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: _fertig || !widget.gesperrt,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0907),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.titel, style: Glas.tLabel.copyWith(fontSize: 15)),
                  const SizedBox(height: 24),
                  GoldRing(
                    key: const ValueKey('timer-ring'),
                    anteil: 1 - r / _gesamt,
                    text: _fertig ? 'Fertig' : zeit,
                    size: 250,
                    dicke: 12,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.gesperrt && !_fertig
                            ? Icons.lock_outline
                            : Icons.do_not_disturb_on_outlined,
                        size: 14,
                        color: Glas.soft,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _fertig
                              ? 'Gut gemacht.'
                              : widget.gesperrt
                              ? 'Geht erst weg, wenn die Zeit um ist'
                              : 'Apps sperren kommt mit der Handy-Version',
                          style: Glas.tSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_fertig)
                    SizedBox(
                      width: 220,
                      child: GlasKnopf(
                        key: const ValueKey('timer-fertig'),
                        label: 'Zurück',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    )
                  else if (!widget.gesperrt)
                    TextButton(
                      key: const ValueKey('timer-stopp'),
                      onPressed: () async {
                        _uhr?.cancel();
                        await _speichern();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text('Beenden', style: Glas.tSoft),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> starteFokus(
  BuildContext context,
  ProduktivUmfeld u, {
  required int minuten,
  bool knopf = false,
}) {
  final start = u.jetzt();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, _, _) => FokusTimer(
        titel: knopf ? 'Fokus-Knopf' : 'Fokus-Block',
        minuten: minuten,
        gesperrt: knopf,
        onEnde: (g) async {
          final d = u.stand.d;
          await u.stand.setze(
            d.copyWith(
              laeufe: [
                ...d.laeufe,
                FokusLauf(
                  start: start,
                  minuten: minuten,
                  geschafft: g,
                  knopf: knopf,
                ),
              ],
            ),
          );
        },
      ),
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween(
            begin: .94,
            end: 1.0,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
  );
}

class _Wahl extends StatelessWidget {
  const _Wahl({
    required this.optionen,
    required this.an,
    required this.onTap,
    this.markiert,
    this.prefix = 'wahl',
  });

  final List<int> optionen;
  final int an;
  final int? markiert;
  final ValueChanged<int> onTap;
  final String prefix;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final m in optionen)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              key: ValueKey('$prefix-$m'),
              onTap: () => onTap(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: m == an ? CoachStyle.goldGradient : null,
                  color: m == an ? null : const Color(0x12FFECC8),
                ),
                child: Column(
                  children: [
                    Text(
                      '$m Min',
                      style: Glas.tLabel.copyWith(
                        color: m == an ? CoachStyle.goldInk : Glas.text,
                      ),
                    ),
                    if (m == markiert)
                      Text(
                        'Coach',
                        style: Glas.tSoft.copyWith(
                          fontSize: 10,
                          color: m == an ? CoachStyle.goldInk : Glas.soft,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class BlockSeite extends StatefulWidget {
  const BlockSeite({super.key, required this.u});
  final ProduktivUmfeld u;

  @override
  State<BlockSeite> createState() => _BlockSeiteState();
}

class _BlockSeiteState extends State<BlockSeite> {
  ProduktivUmfeld get u => widget.u;
  late final int _vorschlag = blockVorschlag(u.energieJetzt);
  late int _laenge = _vorschlag;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final woche = fokusWoche(u.stand.d, u.jetzt());
      final summe = woche.fold(0, (a, b) => a + b);
      final max = math.max(25, woche.reduce(math.max));
      final heuteIdx = u.jetzt().weekday - 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            art: GlasArt.gold,
            children: [
              Center(
                child: GoldSchrift(
                  '$_laenge:00',
                  style: Glas.tBig.copyWith(fontSize: 48),
                ),
              ),
              Text(
                u.energieJetzt == null
                    ? 'Wähl die Länge. Mit deiner Energie-Kurve schlage ich sie vor.'
                    : 'Länge vom Coach nach deiner Energie gerade',
                textAlign: TextAlign.center,
                style: Glas.tSoft,
              ),
              const SizedBox(height: 12),
              _Wahl(
                optionen: const [25, 50, 75],
                an: _laenge,
                markiert: u.energieJetzt == null ? null : _vorschlag,
                prefix: 'block',
                onTap: (m) => setState(() => _laenge = m),
              ),
              const SizedBox(height: 14),
              GlasKnopf(
                key: const ValueKey('block-start'),
                label: 'Block starten',
                icon: Icons.play_arrow_rounded,
                onTap: () => starteFokus(context, u, minuten: _laenge),
              ),
            ],
          ),
          Block(
            label: 'Apps sperren',
            children: [
              Text(
                'Während des Blocks werden ablenkende Apps gesperrt. Das kommt '
                'mit der Handy-Version, hier läuft schon der Timer.',
                style: Glas.tSoft.copyWith(fontSize: 13.5),
              ),
            ],
          ),
          Block(
            label: 'Diese Woche',
            rechts: stundenText(summe),
            children: [
              SizedBox(
                height: 96,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 4 + 66 * woche[i] / max,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: i == heuteIdx
                                      ? CoachStyle.goldGradient
                                      : null,
                                  color: i == heuteIdx
                                      ? null
                                      : const Color(0x33FFECC8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                wochentageKurz[i],
                                style: Glas.tSoft.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
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

// ------------------------------------------------------------------ Handy

class SpiegelSeite extends StatefulWidget {
  const SpiegelSeite({super.key, required this.u});
  final ProduktivUmfeld u;

  @override
  State<SpiegelSeite> createState() => _SpiegelSeiteState();
}

class _SpiegelSeiteState extends State<SpiegelSeite> {
  ProduktivUmfeld get u => widget.u;
  final _std = TextEditingController();
  final _min = TextEditingController();

  @override
  void dispose() {
    _std.dispose();
    _min.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final heute = d.bildschirm[u.heute];
      final gestern =
          d.bildschirm[dayKey(u.jetzt().subtract(const Duration(days: 1)))];
      final stunde = drangStunde(d);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            art: GlasArt.gold,
            label: 'Bildschirmzeit heute',
            children: [
              if (heute != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GoldSchrift(
                      stundenText(heute),
                      key: const ValueKey('spiegel-heute'),
                      style: Glas.tBig.copyWith(fontSize: 38),
                    ),
                    const Spacer(),
                    if (gestern != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'gestern ${stundenText(gestern)}',
                            style: Glas.tSoft,
                          ),
                          Text(
                            '${heute <= gestern ? '−' : '+'}${(heute - gestern).abs()} Min',
                            style: Glas.tLabel,
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Bis zur Handy-Version trägst du sie aus den Einstellungen '
                'deines Handys ein. Danach liest die App sie selbst.',
                style: Glas.tSoft.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GlasFeld(
                      key: const ValueKey('spiegel-std'),
                      controller: _std,
                      hint: 'Std',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlasFeld(
                      key: const ValueKey('spiegel-min'),
                      controller: _min,
                      hint: 'Min',
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 96,
                    child: GlasKnopf(
                      key: const ValueKey('spiegel-speichern'),
                      label: 'Speichern',
                      onTap: () {
                        final s = int.tryParse(_std.text.trim()) ?? 0;
                        final m = int.tryParse(_min.text.trim()) ?? 0;
                        if (s <= 0 && m <= 0) return;
                        u.stand.setze(
                          d.copyWith(
                            bildschirm: {...d.bildschirm, u.heute: s * 60 + m},
                          ),
                        );
                        _std.clear();
                        _min.clear();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          Block(
            label: 'Wann die Unruhe kommt',
            children: [
              if (stunde == null)
                Text(
                  'Tipp ein paar Tage den Drang-Knopf, wenn du zum Handy '
                  'greifen willst. Dann sehe ich, wann es dich packt.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                )
              else ...[
                Text(stunde, style: Glas.tText.copyWith(fontSize: 17)),
                Text('aus ${d.drang.length} Mal Drang', style: Glas.tSoft),
                const SizedBox(height: 10),
                const CoachZeile(
                  'Leg in diese Stunde 10 Minuten raus gehen statt Couch. Dann '
                  'greifst du weniger zum Handy.',
                ),
              ],
            ],
          ),
        ],
      );
    },
  );
}

class DrangSeite extends StatefulWidget {
  const DrangSeite({super.key, required this.u});
  final ProduktivUmfeld u;

  @override
  State<DrangSeite> createState() => _DrangSeiteState();
}

class _DrangSeiteState extends State<DrangSeite> {
  ProduktivUmfeld get u => widget.u;
  DateTime? _letzter;

  Future<void> _tippen() async {
    final z = u.jetzt();
    final d = u.stand.d;
    await u.stand.setze(
      d.copyWith(
        drang: [
          ...d.drang,
          Drang(zeit: z),
        ],
      ),
    );
    setState(() => _letzter = z);
  }

  Future<void> _grund(String g) async {
    final d = u.stand.d;
    await u.stand.setze(
      d.copyWith(
        drang: [
          for (final x in d.drang)
            x.zeit == _letzter ? Drang(zeit: x.zeit, grund: g) : x,
        ],
      ),
    );
    setState(() => _letzter = null);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final heute = drangAm(d, u.heute);
      final m = drangMuster(d);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: DrangKnopf(n: heute.length, onTap: _tippen, gross: true),
          ),
          const SizedBox(height: 12),
          Text(
            'Kurz tippen, wenn du zum Handy greifen willst. Mehr nicht.',
            textAlign: TextAlign.center,
            style: Glas.tSoft,
          ),
          if (_letzter != null)
            Block(
              label: 'Was war es? (optional)',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in drangGruende)
                      GlasChip(
                        key: ValueKey('drang-grund-$g'),
                        label: g,
                        an: false,
                        onTap: () => _grund(g),
                      ),
                  ],
                ),
              ],
            ),
          Block(
            label: 'Heute getippt',
            children: [
              if (heute.isEmpty) Text('Noch nichts.', style: Glas.tSoft),
              for (final x in heute.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          formatUhrzeit(x.zeit.hour * 60 + x.zeit.minute),
                          style: Glas.tSoft,
                        ),
                      ),
                      Text(
                        x.grund ?? 'Drang',
                        style: Glas.tText.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (m.wann != null || m.grund != null)
            Block(
              art: GlasArt.gold,
              children: [
                CoachZeile(
                  [
                    if (m.wann != null) 'Der Drang kommt ${m.wann}.',
                    if (m.grund == 'Aufgabe unklar')
                      'Meist, wenn eine Aufgabe unklar ist. Schreib vor dem '
                          'Start den ersten Schritt auf.'
                    else if (m.grund == 'Müde')
                      'Meist, wenn du müde bist. Dann lieber 5 Minuten raus '
                          'als aufs Handy.'
                    else if (m.grund == 'Langeweile')
                      'Meist aus Langeweile. Leg dir für diese Momente eine '
                          'kleine Aufgabe bereit.'
                    else if (m.grund != null)
                      'Meist aus Gewohnheit. Leg das Handy in einen anderen Raum.',
                  ].join(' '),
                ),
              ],
            ),
        ],
      );
    },
  );
}

/// The round Drang button, tappable right in the tile.
class DrangKnopf extends StatefulWidget {
  const DrangKnopf({
    super.key,
    required this.n,
    required this.onTap,
    this.gross = false,
  });
  final int n;
  final VoidCallback onTap;
  final bool gross;

  @override
  State<DrangKnopf> createState() => _DrangKnopfState();
}

class _DrangKnopfState extends State<DrangKnopf> {
  bool _gedrueckt = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.gross ? 170.0 : 74.0;
    return GestureDetector(
      key: ValueKey(widget.gross ? 'drang-knopf' : 'drang-mini'),
      onTapDown: (_) => setState(() => _gedrueckt = true),
      onTapCancel: () => setState(() => _gedrueckt = false),
      onTap: () {
        setState(() => _gedrueckt = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _gedrueckt ? .9 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: s,
          height: s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-.3, -.4),
              colors: [Color(0x66F5DFAE), Color(0x22E0BF7E), Color(0x330A0704)],
              stops: [0, .55, 1],
            ),
            border: Border.all(color: const Color(0x88E0BF7E), width: 1.4),
            boxShadow: CoachStyle.goldGlow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.gross ? 'Drang gerade' : 'Drang',
                style: Glas.tText.copyWith(fontSize: widget.gross ? 18 : 13),
              ),
              if (widget.gross) Text('${widget.n}× heute', style: Glas.tSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class HandyfreiSeite extends StatefulWidget {
  const HandyfreiSeite({super.key, required this.u});
  final ProduktivUmfeld u;

  @override
  State<HandyfreiSeite> createState() => _HandyfreiSeiteState();
}

class _HandyfreiSeiteState extends State<HandyfreiSeite> {
  ProduktivUmfeld get u => widget.u;
  int _knopf = 30;
  final _eigen = TextEditingController();

  @override
  void dispose() {
    _eigen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final sieben = letzte7(d.handyfreiTage, u.jetzt());
      final heute = d.handyfreiTage.contains(u.heute);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            label: 'Handyfrei nach dem Aufstehen',
            children: [
              Text(
                handyfreiText(u.aufstehen, d.handyfreiMinuten),
                style: CoachStyle.title.copyWith(
                  fontSize: 24,
                  color: CoachStyle.goldLight,
                ),
              ),
              Text(
                u.aufstehen == null
                    ? 'Trag deine Aufstehzeit bei Schlaf ein, dann steht hier '
                          'die Uhrzeit.'
                    : 'aus deinen Schlafzeiten',
                style: Glas.tSoft,
              ),
              const SizedBox(height: 10),
              _Wahl(
                optionen: const [30, 45, 60],
                an: d.handyfreiMinuten,
                prefix: 'frei',
                onTap: (m) => u.stand.setze(d.copyWith(handyfreiMinuten: m)),
              ),
              const SizedBox(height: 12),
              HakenZeile(
                key: const ValueKey('frei-heute'),
                an: heute,
                onTap: () => u.stand.setze(
                  d.copyWith(
                    handyfreiTage: heute
                        ? [
                            for (final t in d.handyfreiTage)
                              if (t != u.heute) t,
                          ]
                        : [...d.handyfreiTage, u.heute],
                  ),
                ),
                titel: 'Heute gehalten',
              ),
              const SizedBox(height: 8),
              SiebenPunkte(an: sieben, heute: u.jetzt()),
              const SizedBox(height: 6),
              Text(
                '${sieben.where((x) => x).length} von 7 Morgen gehalten',
                style: Glas.tSoft,
              ),
            ],
          ),
          Block(
            art: GlasArt.gold,
            label: 'Fokus-Knopf',
            children: [
              Text(
                'Einmal gedrückt, geht er erst wieder weg, wenn die Zeit um ist.',
                style: Glas.tSoft,
              ),
              const SizedBox(height: 10),
              _Wahl(
                optionen: const [30, 45],
                an: _knopf,
                prefix: 'knopf',
                onTap: (m) => setState(() {
                  _knopf = m;
                  _eigen.clear();
                }),
              ),
              const SizedBox(height: 8),
              GlasFeld(
                key: const ValueKey('knopf-eigen'),
                controller: _eigen,
                hint: 'Eigene Zeit in Minuten',
              ),
              const SizedBox(height: 12),
              GlasKnopf(
                key: const ValueKey('knopf-start'),
                label: 'Fokus-Knopf drücken',
                icon: Icons.lock_outline,
                onTap: () {
                  final e = int.tryParse(_eigen.text.trim());
                  final m = (e != null && e > 0) ? e.clamp(1, 240) : _knopf;
                  starteFokus(context, u, minuten: m, knopf: true);
                },
              ),
            ],
          ),
        ],
      );
    },
  );
}

String handyfreiText(int? aufstehen, int minuten) {
  if (aufstehen == null) return '$minuten Minuten';
  return '${formatUhrzeit(aufstehen)} – ${formatUhrzeit(aufstehen + minuten)}';
}

// ---------------------------------------------------------- Gewohnheiten

/// The chain: anchor -> new habit.
class Kette extends StatelessWidget {
  const Kette({
    super.key,
    required this.anker,
    required this.neu,
    this.klein = false,
  });
  final String anker;
  final String neu;
  final bool klein;

  @override
  Widget build(BuildContext context) {
    Widget glied(String t, bool gold) => Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: klein ? 7 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: gold ? CoachStyle.goldGradient : null,
        color: gold ? null : const Color(0x14FFECC8),
        border: gold ? null : Border.all(color: const Color(0x33FFEECD)),
      ),
      child: Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Glas.tLabel.copyWith(
          fontSize: klein ? 12 : 14,
          color: gold ? CoachStyle.goldInk : Glas.text,
        ),
      ),
    );
    return Row(
      children: [
        Flexible(child: glied(anker, false)),
        Container(
          width: 22,
          height: 2,
          decoration: const BoxDecoration(gradient: CoachStyle.goldGradient),
        ),
        Flexible(child: glied(neu, true)),
      ],
    );
  }
}

/// 21 dots, the first [n] gold.
class EinundzwanzigPunkte extends StatelessWidget {
  const EinundzwanzigPunkte({super.key, required this.n, this.klein = false});
  final int n;
  final bool klein;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: klein ? 4 : 6,
    runSpacing: klein ? 4 : 6,
    children: [
      for (var i = 0; i < 21; i++)
        Container(
          width: klein ? 8 : 12,
          height: klein ? 8 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: i < n ? CoachStyle.goldGradient : null,
            color: i < n ? null : const Color(0x1FFFECC8),
          ),
        ),
    ],
  );
}

class AndockSeite extends StatelessWidget {
  const AndockSeite({super.key, required this.u});
  final ProduktivUmfeld u;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final a = aktiverAndock(d);
      if (a == null) {
        return Block(
          children: [
            Text(
              'Gerade wird keine neue Gewohnheit aufgebaut. Dock eine an etwas '
              'an, das du sowieso jeden Tag machst.',
              style: Glas.tSoft.copyWith(fontSize: 13.5),
            ),
          ],
        );
      }
      final heute = a.tage.contains(u.heute);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            art: GlasArt.gold,
            children: [
              Kette(anker: a.anker, neu: a.neu),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Text('Hält seit', style: Glas.tLabel)),
                  Text('${a.tage.length} von 21 Tagen', style: Glas.tSoft),
                ],
              ),
              const SizedBox(height: 8),
              EinundzwanzigPunkte(n: a.tage.length),
              const SizedBox(height: 10),
              HakenZeile(
                key: const ValueKey('andock-heute'),
                an: heute,
                onTap: () => u.stand.setze(
                  d.copyWith(
                    andocken: [
                      for (final x in d.andocken)
                        identical(x, a) ? x.umschalten(u.heute) : x,
                    ],
                  ),
                ),
                titel: 'Heute gemacht',
              ),
              const SizedBox(height: 6),
              Text(
                'Nach 21 Tagen läuft sie von allein, dann kommt die nächste '
                'dran.',
                style: Glas.tSoft,
              ),
            ],
          ),
          Block(
            label: 'Passt zum Danach-Plan aus Mindset',
            children: [
              Text(
                'Eine neue Gewohnheit hängt immer an etwas, das du sowieso '
                'machst. So musst du nicht dran denken.',
                style: Glas.tText.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class NeuAndockSeite extends StatefulWidget {
  const NeuAndockSeite({super.key, required this.u});
  final ProduktivUmfeld u;

  @override
  State<NeuAndockSeite> createState() => _NeuAndockSeiteState();
}

class _NeuAndockSeiteState extends State<NeuAndockSeite> {
  ProduktivUmfeld get u => widget.u;
  final _wenn = TextEditingController();
  final _dann = TextEditingController();

  @override
  void dispose() {
    _wenn.dispose();
    _dann.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final aktiv = aktiverAndock(d);
      if (aktiv != null) {
        return Block(
          children: [
            CoachZeile(
              'Erst muss „${aktiv.neu}“ von allein laufen. Noch '
              '${21 - aktiv.tage.length} Tage, dann kommt die nächste dran.',
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            art: GlasArt.gold,
            children: [
              Text('Wenn ich …', style: Glas.tLabel),
              const SizedBox(height: 6),
              GlasFeld(
                key: const ValueKey('andock-wenn'),
                controller: _wenn,
                hint: 'z. B. die Zähne geputzt habe',
              ),
              const SizedBox(height: 12),
              Text('… dann', style: Glas.tLabel),
              const SizedBox(height: 6),
              GlasFeld(
                key: const ValueKey('andock-dann'),
                controller: _dann,
                hint: 'z. B. lege ich das Handy in die Küche',
              ),
              const SizedBox(height: 12),
              GlasKnopf(
                key: const ValueKey('andock-speichern'),
                label: 'Andocken',
                onTap: () {
                  final w = _wenn.text.trim();
                  final n = _dann.text.trim();
                  if (w.isEmpty || n.isEmpty) return;
                  u.stand.setze(
                    d.copyWith(
                      andocken: [
                        ...d.andocken,
                        Andock(anker: w, neu: n, start: u.heute),
                      ],
                    ),
                  );
                  _wenn.clear();
                  _dann.clear();
                  hinweis(context, 'Angedockt. Hak sie jeden Tag kurz ab.');
                },
              ),
            ],
          ),
          Block(
            label: 'Deine Anker',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in anker)
                    GlasChip(
                      key: ValueKey('anker-$a'),
                      label: a,
                      an: _wenn.text == a,
                      onTap: () => setState(() => _wenn.text = a),
                    ),
                ],
              ),
            ],
          ),
        ],
      );
    },
  );
}

class LaeuftSeite extends StatelessWidget {
  const LaeuftSeite({super.key, required this.u});
  final ProduktivUmfeld u;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final l = laufende(u.stand.d);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Block(
            children: [
              if (l.isEmpty)
                Text(
                  'Noch keine. Nach 21 Tagen landet eine Gewohnheit hier.',
                  style: Glas.tSoft.copyWith(fontSize: 13.5),
                ),
              for (final a in l)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.neu, style: Glas.tText),
                            Text(a.anker, style: Glas.tSoft),
                          ],
                        ),
                      ),
                      Text('${a.tage.length} Tage', style: Glas.tLabel),
                    ],
                  ),
                ),
            ],
          ),
          if (l.isNotEmpty)
            Block(
              art: GlasArt.gold,
              children: [
                CoachZeile(
                  '${l.length == 1 ? 'Eine läuft' : '${l.length} laufen'} '
                  'schon ohne mich. Genau so soll es sein.',
                ),
              ],
            ),
        ],
      );
    },
  );
}

// --------------------------------------------------------------- Verlauf

/// 30-day line with a dashed average.
class Linie30 extends StatelessWidget {
  const Linie30({super.key, required this.werte, this.hoehe = 140});
  final List<int?> werte;
  final double hoehe;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: hoehe,
    width: double.infinity,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(painter: _LinieMaler(werte, t)),
    ),
  );
}

class _LinieMaler extends CustomPainter {
  _LinieMaler(this.werte, this.t);
  final List<int?> werte;
  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    final da = [
      for (var i = 0; i < werte.length; i++)
        if (werte[i] != null) (i, werte[i]!),
    ];
    if (da.isEmpty) return;
    Offset p(int i, num v) => Offset(
      s.width * i / math.max(1, werte.length - 1),
      s.height - 6 - (s.height - 12) * (v - 1) / 9,
    );
    final schnitt = da.map((x) => x.$2).reduce((a, b) => a + b) / da.length;
    final y = p(0, schnitt).dy;
    final strich = Paint()
      ..color = const Color(0x66CDBB98)
      ..strokeWidth = 1;
    for (var x = 0.0; x < s.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), strich);
    }
    final path = Path();
    for (var k = 0; k < da.length; k++) {
      final o = p(da[k].$1, da[k].$2);
      k == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, s.width * t, s.height));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = CoachStyle.goldLight,
    );
    for (final x in da) {
      canvas.drawCircle(
        p(x.$1, x.$2),
        2.6,
        Paint()..color = CoachStyle.goldLight,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LinieMaler o) => o.t != t || o.werte != werte;
}
