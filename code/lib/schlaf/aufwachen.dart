import 'dart:async';

import 'package:flutter/material.dart';

import '../ernaehrung/ernaehrung_coach.dart' show fotoAufnahme;
import '../sleep/schlafzeiten.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'schlaf_data.dart';
import 'schlaf_logik.dart';
import 'schlaf_widgets.dart';

/// The alarm as it rings: a warm sunrise, the time, and the task that
/// switches it off. Rings for real only in the phone version; here it is
/// opened from "Wecker testen".
class WeckerKlingelt extends StatefulWidget {
  const WeckerKlingelt({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  @override
  State<WeckerKlingelt> createState() => _WeckerKlingeltState();
}

class _WeckerKlingeltState extends State<WeckerKlingelt> {
  bool _geschlummert = false;
  int _schritte = 0;
  String? _fehler;

  SchlafUmfeld get u => widget.umfeld;

  void _aus() => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => AufwachSeite(umfeld: u)),
  );

  Future<void> _aufgabe() async {
    switch (u.d.wecker.aufgabe) {
      case 'foto':
        final bild = await fotoAufnahme();
        if (!mounted) return;
        if (bild == null) {
          setState(
            () =>
                _fehler = 'Kein Foto. Geh ans Fenster und versuch es nochmal.',
          );
          return;
        }
        _aus();
      case 'schritte':
        setState(() => _schritte++);
        if (_schritte >= 30) _aus();
      default:
        _aus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = u.d.wecker;
    final text = switch (w.aufgabe) {
      'foto' =>
        'Zum Ausschalten: Geh ans Fenster und mach ein Foto vom Himmel.',
      'schritte' => 'Zum Ausschalten: 30 Schritte gehen.',
      _ => 'Zum Ausschalten: Sag kurz, wie du aufgewacht bist.',
    };
    final knopf = switch (w.aufgabe) {
      'foto' => 'Himmel fotografieren',
      'schritte' =>
        _schritte == 0 ? 'Los gehen' : 'Schritt ${_schritte + 1} von 30',
      _ => 'Aufwach-Himmel',
    };
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B2A1C), Color(0xFFB87A3E), Color(0xFFF2B860)],
            stops: [0, .7, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    germanWeekday(u.jetzt()),
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      color: Color(0xFF2A1A0C),
                    ),
                  ),
                  Text(
                    formatUhrzeit(u.aufstehen),
                    key: const ValueKey('wecker-zeit'),
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 64,
                      color: CoachStyle.goldInk,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .5, end: 1),
                    duration: const Duration(seconds: 3),
                    curve: Curves.easeOut,
                    builder: (_, s, _) => Transform.scale(
                      scale: s,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFFFE9B8),
                              Color(0xFFF2B860),
                              Color(0xFFE0954A),
                            ],
                            stops: [0, .6, 1],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x66F2B860),
                              blurRadius: 50,
                              spreadRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Guten Morgen${u.profile.name.isEmpty ? '' : ', ${u.profile.name}'}.',
                    style: tTitel.copyWith(color: CoachStyle.goldInk),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: tText.copyWith(color: const Color(0xFF2A1A0C)),
                  ),
                  if (_fehler != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _fehler!,
                        textAlign: TextAlign.center,
                        style: tSoft.copyWith(color: const Color(0xFF2A1A0C)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 280,
                    child: FilledButton(
                      key: const ValueKey('wecker-aufgabe'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CoachStyle.goldInk,
                        foregroundColor: const Color(0xFFF5DFAE),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _aufgabe,
                      child: Text(knopf),
                    ),
                  ),
                  if (w.schlummern) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 280,
                      child: OutlinedButton(
                        key: const ValueKey('wecker-schlummern'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CoachStyle.goldInk,
                          side: const BorderSide(color: Color(0x551A140E)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _geschlummert
                            ? null
                            : () => setState(() => _geschlummert = true),
                        child: Text(
                          _geschlummert
                              ? 'Schlummern schon genutzt'
                              : 'Noch 5 Minuten (einmal)',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Vorschau: Der echte Wecker kommt mit der Handy-Version.',
                    style: tSoft.copyWith(
                      color: const Color(0xAA1A140E),
                      fontSize: 11,
                    ),
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

String germanWeekday(DateTime d) => const [
  'MONTAG',
  'DIENSTAG',
  'MITTWOCH',
  'DONNERSTAG',
  'FREITAG',
  'SAMSTAG',
  'SONNTAG',
][d.weekday - 1];

/// After waking: the Aufwach-Himmel, what was at night, then the score,
/// the coach's line for today and the sunlight step.
class AufwachSeite extends StatefulWidget {
  const AufwachSeite({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  @override
  State<AufwachSeite> createState() => _AufwachSeiteState();
}

class _AufwachSeiteState extends State<AufwachSeite> {
  SchlafUmfeld get u => widget.umfeld;
  late final Morgen? _alt = u.d.morgenAm(u.heute);
  late int _himmel = _alt?.himmel ?? 60;
  late final Set<String> _tags = {...?_alt?.tags};
  double? _stundenEigen;
  late bool _fertig = _alt != null;
  bool _laedt = false;

  Journal? get _gestern => u.d.journalAm(SchlafDaten.gestern(u.jetzt()));

  double get _stunden =>
      _stundenEigen ??
      geschlafen(
        guteNacht: _gestern?.guteNacht,
        bettPlan: u.bett,
        aufstehen: u.aufstehen,
        heute: u.jetzt(),
        tags: _tags.toList(),
      ) ??
      u.zeiten.stunden;

  Future<void> _speichern() async {
    final g = _gestern?.guteNacht;
    int? abw;
    if (g != null && u.bett != null) {
      var m = g.hour * 60 + g.minute - u.bett!;
      if (m > 720) m -= 1440;
      if (m < -720) m += 1440;
      abw = m;
    }
    final s = schlafwert(
      stunden: _stunden,
      brauch: u.zeiten.stunden,
      himmel: _himmel,
      tags: _tags.toList(),
      abweichung: abw,
    );
    final m = Morgen(
      tag: u.heute,
      himmel: _himmel,
      tags: [
        for (final t in aufwachTags)
          if (_tags.contains(t)) t,
      ],
      stunden: _stunden,
      wert: s.wert,
      teile: s.teile,
    );
    setState(() {
      _fertig = true;
      _laedt = true;
    });
    await u.stand.setze(u.d.mitMorgen(m));
    await u.onMorgen(_stunden);
    final satz = await u.coach.morgen(u.profile, u.kontext());
    await u.stand.setze(
      u.d.mitMorgen(
        m.copyWith(
          satz: satz ?? morgenSatzOhneCoach(s.wert, training: u.trainingName),
        ),
      ),
    );
    if (mounted) setState(() => _laedt = false);
  }

  Future<void> _stundenAendern() async {
    var h = _stunden;
    final neu = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF1A140E),
      builder: (context) => StatefulBuilder(
        builder: (context, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TLabel('Wie lange hast du geschlafen?'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const ValueKey('stunden-minus'),
                      onPressed: () => set(() => h = (h - .25).clamp(1, 14)),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: CoachStyle.goldLight,
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text(
                        formatDauer(h),
                        textAlign: TextAlign.center,
                        style: tTitel.copyWith(fontSize: 22),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('stunden-plus'),
                      onPressed: () => set(() => h = (h + .25).clamp(1, 14)),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: CoachStyle.goldLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                MainButton(
                  key: const ValueKey('stunden-ok'),
                  label: 'Passt',
                  onPressed: () => Navigator.of(context).pop(h),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (neu != null) setState(() => _stundenEigen = neu);
  }

  @override
  Widget build(BuildContext context) => SchlafSeite(
    umfeld: u,
    phase: HimmelPhase.morgen,
    label:
        '${germanWeekday(u.jetzt())} · ${formatUhrzeit(u.jetzt().hour * 60 + u.jetzt().minute)}',
    titel: _fertig ? 'Deine Nacht' : 'Wie bist du aufgewacht?',
    bau: (context) => _fertig ? _ergebnis() : _eingabe(),
  );

  List<Widget> _eingabe() => [
    TKarte(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: himmelFarbe(_himmel),
            ),
            child: Text(
              himmelWort(_himmel),
              key: const ValueKey('himmel-wort'),
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: _himmel > 55 ? CoachStyle.goldInk : CoachStyle.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 14,
              activeTrackColor: const Color(0xFFF2B860),
              inactiveTrackColor: const Color(0xFF4B4A48),
              thumbColor: const Color(0xFFF5DFAE),
              overlayColor: const Color(0x22F5DFAE),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
            ),
            child: Slider(
              key: const ValueKey('himmel-regler'),
              value: _himmel.toDouble(),
              min: 0,
              max: 100,
              onChanged: (v) => setState(() => _himmel = v.round()),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('wie im Nebel', style: tSoft),
              Text('wie die Sonne', style: tSoft),
            ],
          ),
        ],
      ),
    ),
    const TLabel('Was war heute Nacht?'),
    const SizedBox(height: 8),
    Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final t in aufwachTags)
          TChip(
            t,
            key: ValueKey('nacht-$t'),
            an: _tags.contains(t),
            onTap: () => setState(
              () => _tags.contains(t) ? _tags.remove(t) : _tags.add(t),
            ),
          ),
      ],
    ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: Text(
            'Geschlafen: etwa ${formatDauer(_stunden)}'
            '${_stundenEigen == null ? (_gestern?.guteNacht != null ? ', ab deinem Gute Nacht' : ', aus deinen Zeiten') : ''}',
            style: tSoft,
          ),
        ),
        TLink(
          'Ändern',
          key: const ValueKey('stunden-aendern'),
          onTap: _stundenAendern,
        ),
      ],
    ),
    const SizedBox(height: 14),
    MainButton(
      key: const ValueKey('aufwachen-fertig'),
      label: 'Fertig',
      onPressed: _speichern,
    ),
  ];

  List<Widget> _ergebnis() {
    final m = u.d.morgenAm(u.heute);
    if (m == null) return const [];
    return [
      TKarte(
        key: const ValueKey('schlafwert-karte'),
        gold: true,
        child: Column(
          children: [
            SchlafMond(
              fuell: (m.wert / 100 + .05).clamp(0, 1).toDouble(),
              size: 140,
              child: Text(
                '${m.wert}',
                key: const ValueKey('schlafwert'),
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 40,
                  color: Color(0xFFF5DFAE),
                  shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Schlafwert von 100', style: tSoft),
            const SizedBox(height: 10),
            if (m.satz != null)
              CoachZeile(text: m.satz!)
            else if (_laedt)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: CoachStyle.gold),
              ),
            const SizedBox(height: 6),
            for (final t in teilNamen.entries)
              TeilZeile(
                name: t.value,
                wert: m.teile[t.key] ?? 0,
                text: teilText(t.key, m),
              ),
          ],
        ),
      ),
      SonnenlichtKarte(umfeld: u),
      if (nochDunkel(u.jetzt(), u.aufstehen)) DunkelKarte(umfeld: u),
      TLink(
        'Nochmal eintragen',
        soft: true,
        onTap: () => setState(() => _fertig = false),
      ),
    ];
  }
}

Color himmelFarbe(int v) {
  final t = v / 100;
  const a = [
    Color(0xFF262422),
    Color(0xFF5A5650),
    Color(0xFFB9A076),
    Color(0xFFF2B860),
  ];
  final i = (t * 3).floor().clamp(0, 2);
  return Color.lerp(a[i], a[i + 1], t * 3 - i)!;
}

/// "Jetzt: Sonnenlicht": 5 minutes outside, with a timer.
class SonnenlichtKarte extends StatefulWidget {
  const SonnenlichtKarte({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  @override
  State<SonnenlichtKarte> createState() => _SonnenlichtKarteState();
}

class _SonnenlichtKarteState extends State<SonnenlichtKarte> {
  int _rest = 300;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    if (_t != null || _rest == 0) return;
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _rest--);
      if (_rest <= 0) {
        t.cancel();
        _t = null;
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => TKarte(
    key: const ValueKey('sonnenlicht'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TLabel('Jetzt: Sonnenlicht'),
        const SizedBox(height: 4),
        const Text(
          '5 Minuten raus oder ans offene Fenster. Licht am Morgen stellt deine '
          'innere Uhr, du wirst wacher und schläfst abends leichter ein.',
          style: tText,
        ),
        const SizedBox(height: 8),
        Text(
          '${_rest ~/ 60}:${(_rest % 60).toString().padLeft(2, '0')}',
          key: const ValueKey('sonnenlicht-timer'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            fontSize: 42,
            color: Color(0xFFF5DFAE),
          ),
        ),
        const SizedBox(height: 6),
        MainButton(
          key: const ValueKey('sonnenlicht-start'),
          label: _rest == 0
              ? 'Geschafft'
              : (_t != null ? 'Läuft … draußen?' : 'Draußen, Start'),
          onPressed: _t != null || _rest == 0 ? null : _start,
        ),
        const SizedBox(height: 6),
        const Text(
          'Auch bei Wolken ist es draußen viel heller als drinnen. Nicht direkt '
          'in die Sonne schauen.',
          textAlign: TextAlign.center,
          style: tSoft,
        ),
      ],
    ),
  );
}

/// Winter: still dark at getting up. The Licht-Modus on the phone and the
/// daylight lamp.
class DunkelKarte extends StatelessWidget {
  const DunkelKarte({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  @override
  Widget build(BuildContext context) {
    final u = umfeld;
    final auf = sonnenaufgang(u.jetzt());
    return TKarte(
      key: const ValueKey('dunkel-karte'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TLabel('Noch dunkel draußen?'),
          const SizedBox(height: 4),
          Text(
            'Die Sonne geht heute erst gegen ${formatUhrzeit(auf)} auf. Bis dahin hilft dir:',
            style: tText,
          ),
          const SizedBox(height: 8),
          _Wahl(
            key: const ValueKey('licht-modus'),
            icon: Icons.light_mode,
            titel: 'Licht-Modus am Handy',
            text: 'Bildschirm 3 Minuten hell, kaltes Tageslicht-Weiß. Macht wacher.',
            onTap: () => zeigeSchlafSeite(context, const LichtModusSeite()),
          ),
          const SizedBox(height: 8),
          _Wahl(
            key: const ValueKey('lampe'),
            icon: Icons.wb_incandescent_outlined,
            titel: 'Ich hab eine Tageslichtlampe',
            text: u.d.lampe
                ? 'Timer 20 Minuten, zum Beispiel beim Frühstück. Kommt jeden dunklen Morgen.'
                : 'Die wirkt richtig. Die App startet dann jeden dunklen Morgen den Timer.',
            an: u.d.lampe,
            onTap: () => u.stand.setze(u.d.copyWith(lampe: !u.d.lampe)),
          ),
          if (u.d.lampe) ...[
            const SizedBox(height: 8),
            TLink(
              'Lampen-Timer starten ›',
              key: const ValueKey('lampe-timer'),
              onTap: () =>
                  zeigeSchlafSeite(context, const LichtModusSeite(lampe: true)),
            ),
          ],
          const SizedBox(height: 8),
          const CoachZeile(
            text:
                'Sobald es hell ist: 5 Minuten raus, zum Beispiel auf dem Weg.',
          ),
        ],
      ),
    );
  }
}

class _Wahl extends StatelessWidget {
  const _Wahl({
    super.key,
    required this.icon,
    required this.titel,
    required this.text,
    required this.onTap,
    this.an = false,
  });

  final IconData icon;
  final String titel, text;
  final VoidCallback onTap;
  final bool an;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF1A140E),
        border: Border.all(
          color: an ? CoachStyle.goldLight : const Color(0xFF3A2E21),
          width: an ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: an ? CoachStyle.goldGradient : null,
              color: an ? null : const Color(0xFF2A1F13),
            ),
            child: Icon(
              icon,
              size: 18,
              color: an ? CoachStyle.goldInk : CoachStyle.goldLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titel, style: tTitel.copyWith(fontSize: 13.5)),
                Text(text, style: tSoft),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The Licht-Modus: the whole screen bright daylight white with a timer.
/// Honest: it wakes up, it does not replace daylight.
class LichtModusSeite extends StatefulWidget {
  const LichtModusSeite({super.key, this.lampe = false});

  /// Timer for the daylight lamp (20 minutes) instead of the screen light.
  final bool lampe;

  @override
  State<LichtModusSeite> createState() => _LichtModusSeiteState();
}

class _LichtModusSeiteState extends State<LichtModusSeite> {
  late int _rest = widget.lampe ? 20 * 60 : 180;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _rest = (_rest - 1).clamp(0, 99999));
      if (_rest == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hell = !widget.lampe;
    final ink = hell ? const Color(0xFF1A140E) : const Color(0xFFF5DFAE);
    return Scaffold(
      backgroundColor: hell ? const Color(0xFFF4F8FF) : CoachStyle.night,
      body: GestureDetector(
        key: const ValueKey('licht-ende'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.lampe ? 'TAGESLICHTLAMPE' : 'LICHT-MODUS',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      color: hell
                          ? const Color(0xFF5B6B80)
                          : CoachStyle.beigeLabel,
                    ),
                  ),
                  Text(
                    '${_rest ~/ 60}:${(_rest % 60).toString().padLeft(2, '0')}',
                    key: const ValueKey('licht-timer'),
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 60,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lampe
                        ? 'Lampe etwa auf Augenhöhe, seitlich vor dir. Nebenbei frühstücken oder lesen.'
                        : 'Handy auf Augenhöhe, etwa 30 cm weg, Helligkeit ganz hoch. Nicht reinstarren, '
                              'einfach daneben frühstücken oder lesen.',
                    textAlign: TextAlign.center,
                    style: tText.copyWith(
                      color: hell ? const Color(0xFF3A4250) : CoachStyle.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hell)
                    const Text(
                      'Macht wacher, ersetzt aber kein Tageslicht. Raus, sobald es hell ist.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 12,
                        color: Color(0xFF6B7484),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    _rest == 0
                        ? 'Geschafft. Tippen zum Beenden'
                        : 'Tippen zum Beenden',
                    style: TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 12,
                      color: hell
                          ? const Color(0xFF6B7484)
                          : CoachStyle.inkSoft,
                    ),
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
