import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../konto/konto_ui.dart' show bewegungAn;
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../ui/umbau.dart';
import 'glas.dart';
import 'koerper_bilder.dart';
import 'koerper_szene.dart';

/// How big a tile is in the bento grid of an area page.
enum KachelGroesse {
  /// Whole width, tall (main tile of a page).
  hoch,

  /// Whole width, medium.
  mittel,

  /// Whole width, only as high as its content.
  schmal,

  /// Half the width (two side by side).
  halb,
}

/// The full page a tile grows into: header plus blocks.
class Feld {
  const Feld({
    required this.titel,
    required this.icon,
    required this.coach,
    required this.inhalt,
  });

  final String titel;
  final IconData icon;

  /// One coach sentence at the top of the page.
  final String coach;

  /// The blocks of the page. Built when the page opens, so it shows the
  /// latest data.
  final List<Widget> Function(BuildContext context) inhalt;
}

/// One tile of an area page.
class BKachel {
  const BKachel({
    required this.id,
    required this.titel,
    required this.icon,
    this.groesse = KachelGroesse.halb,
    this.wert,
    this.text,
    this.unter,
    this.hot,
    this.gold = false,
    this.nacht = false,
    this.bild,
    this.knopf,
    this.onKnopf,
    this.feld,
    this.seite,
  });

  final String id;
  final String titel;
  final IconData icon;
  final KachelGroesse groesse;

  /// Big gold value, e.g. "4/5".
  final String? wert;

  /// Light text instead of (or under) the value.
  final String? text;
  final String? unter;

  /// Small gold badge top right.
  final String? hot;
  final bool gold;
  final bool nacht;

  /// A small picture or chart (top right or under the text).
  final Widget? bild;

  /// Optional small button in the tile.
  final String? knopf;
  final VoidCallback? onKnopf;

  /// What opens on tap: a page in the glass look ...
  final Feld? feld;

  /// ... or an existing page of the app.
  final WidgetBuilder? seite;
}

/// One number of the strip under a picture; a tap opens tile [ziel].
class BZahl {
  const BZahl(this.wert, this.label, {this.ziel});
  final String wert, label;
  final String? ziel;
}

/// A page drawn as one picture (draft "Körper als Bilder" 3b,
/// 2026-11-07): coach line, picture, three numbers, one main button.
/// Every part points at one of the page's tiles, so nothing is lost:
/// the tiles are no longer shown, only opened.
class BBild {
  const BBild({
    required this.bau,
    required this.zahlen,
    required this.knopf,
    this.knopf2,
  });

  /// The picture on its 302 x 270 board; [v] plays 0 to 1 once, [t]
  /// runs in seconds (both stay still without motion).
  final Widget Function(BildTipp tipp, double v, double t) bau;
  final List<BZahl> zahlen;

  /// Label and tile of the main button.
  final (String, String) knopf;

  /// Icon and tile of the small round button next to it.
  final (IconData, String)? knopf2;
}

/// The one thing that counts right now, on the light tile of a page in
/// the new structure.
class BJetzt {
  const BJetzt({
    required this.titel,
    required this.text,
    this.ring,
    this.mitte = '',
    this.unter = '',
    this.knopf,
    this.fertig = false,
  });

  final String titel, text;

  /// How full the ring is, 0..1; null leaves it empty.
  final double? ring;

  /// Short value and tiny label inside the ring.
  final String mitte, unter;

  /// Label and tile of the one button.
  final (String, String)? knopf;

  /// Done for today: the tile cheers and gold sparks fly once.
  final bool fertig;
}

/// "Deine Serie": how often in a row it worked.
class BSerie {
  const BSerie({
    required this.zahl,
    required this.einheit,
    required this.text,
    this.rekord = 0,
  });
  final int zahl, rekord;
  final String einheit, text;
}

/// "Nächstes Ziel": a small goal within reach.
class BNaechstes {
  const BNaechstes({
    required this.titel,
    required this.anteil,
    required this.text,
  });
  final String titel, text;
  final double anteil;
}

/// One row of the calm "Mehr" list; a tap opens tile [ziel].
class BMehr {
  const BMehr(this.titel, {this.wert, this.ziel});
  final String titel;
  final String? wert, ziel;
}

/// The new structure of a picture page (vault Umsetzung/Schlaf und Mindset
/// Aufbau, Phillip "passt" 2026-11-13), top to bottom: coach line with the
/// user's reason, "Jetzt dran", streak and next goal, the picture, "Diese
/// Woche geschafft", "Mehr".
class BAufbau {
  const BAufbau({
    required this.jetzt,
    this.dafuer,
    this.serie,
    this.naechstes,
    this.geschafft = const [],
    this.mehr = const [],
  });

  /// The user's own goal or reason, shown in gold under the coach line.
  final String? dafuer;
  final BJetzt jetzt;
  final BSerie? serie;
  final BNaechstes? naechstes;

  /// What worked this week: text and day.
  final List<(String, String)> geschafft;
  final List<BMehr> mehr;
}

/// One of the four pages of an area (segmented bar + swipe).
class BSeite {
  const BSeite({
    required this.name,
    required this.coach,
    required this.kacheln,
    this.zeigt,
    this.bild,
    this.aufbau,
  });

  /// The new structure around the picture; without it the picture page
  /// keeps its old order.
  final BAufbau? aufbau;

  final String name;
  final String coach;
  final List<BKachel> kacheln;

  /// Drawn as one picture instead of the tiles.
  final BBild? bild;

  /// The one tile that matters today: the coach's face flies over to it
  /// and the tile lights up.
  final String? zeigt;
}

/// A part of an area with its own four pages (Körper: Training,
/// Ernährung, Schlaf & Routine).
class Unterbereich {
  const Unterbereich({
    required this.id,
    required this.name,
    required this.icon,
    required this.sub,
    required this.seiten,
    this.wert,
    this.woche = const [],
    this.szene,
    this.szeneDaten = const SzeneDaten(),
  });

  /// The living picture on top instead of the ring (Körper parts).
  final SzeneArt? szene;
  final SzeneDaten szeneDaten;

  final String id;
  final String name;
  final IconData icon;
  final int? wert;
  final List<int?> woche;

  /// Line under the area name while this part is picked.
  final String sub;
  final List<BSeite> seiten;
}

/// An area page in the Mindset draft 7 pattern (decided 2026-10-29): score
/// ring, glass segmented bar with gliding knob, one coach line per page,
/// bento of glass tiles; a tile grows into its own page.
class BereichSeite extends StatefulWidget {
  const BereichSeite({
    super.key,
    required this.name,
    required this.wert,
    required this.teile,
    this.start = 0,
    this.zurueck = 'Heute',
    this.verlauf,
    this.frag,
    this.onWechsel,
  });

  final String name;
  final int? wert;

  /// The parts; an area without parts has exactly one.
  final List<Unterbereich> teile;
  final int start;
  final String zurueck;

  /// Opens behind the score ring.
  final Feld? verlauf;

  /// Opens behind the coach card ("Frag den Coach").
  final Feld Function(Unterbereich teil)? frag;
  final ValueChanged<String>? onWechsel;

  @override
  State<BereichSeite> createState() => _BereichSeiteState();
}

class _BereichSeiteState extends State<BereichSeite>
    with TickerProviderStateMixin {
  late int _teil = widget.start.clamp(0, widget.teile.length - 1);
  int _seite = 0;
  late PageController _pages = PageController();
  final _ringKey = GlobalKey();
  final _coachKey = GlobalKey();
  final _avatarKey = GlobalKey();
  final _stackKey = GlobalKey();
  final _zielKey = GlobalKey();

  /// The coach's face flying from the scene down to his speech bubble at
  /// today's tile (draft "Körper, lebendig").
  late final AnimationController _flug = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  )..addListener(_flugTick);
  Rect? _flugVon, _flugNach;

  /// The face sits in its bubble (at once without motion).
  bool _da = true;

  /// Plays the spring-in of the tiles; restarted on every part switch.
  late final AnimationController _ein = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  Unterbereich get t => widget.teile[_teil];

  @override
  void initState() {
    super.initState();
    _starteFlug();
  }

  @override
  void dispose() {
    _ein.dispose();
    _flug.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Starts the flight for the shown page, if it has a tile to point at.
  /// Off in widget tests, like all extra motion.
  void _starteFlug() {
    _flugVon = null;
    _flugNach = null;
    _flug.value = 0;
    _da = !bewegungAn || t.szene == null;
    if (_da) return;
    _flug.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _da = true;
        _flugVon = null;
        _flugNach = null;
      });
    });
  }

  /// Once the tiles have sprung in, measure where the face flies.
  void _flugTick() {
    if (_flug.value < .45 || _flugNach != null) return;
    Rect? rect(GlobalKey k) {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      final bezug = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || bezug == null || !box.hasSize) return null;
      final o = box.localToGlobal(Offset.zero, ancestor: bezug);
      return o & box.size;
    }

    final von = rect(_avatarKey), ziel = rect(_zielKey);
    if (von == null || ziel == null) {
      _flug.stop();
      setState(() => _da = true);
      return;
    }
    setState(() {
      _flugVon = von;
      _flugNach = ziel;
    });
  }

  void _zuSeite(int i) {
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  void _zuTeil(int i) {
    if (i == _teil) return;
    setState(() {
      _teil = i;
      _seite = 0;
      _pages.dispose();
      _pages = PageController();
    });
    _ein.forward(from: 0.25);
    _starteFlug();
    widget.onWechsel?.call(widget.teile[i].id);
  }

  @override
  Widget build(BuildContext context) {
    if (t.seiten.first.bild != null) return _bildLayout(context);
    final seiten = t.seiten;
    final szene = t.szene != null;
    final seiteJetzt = seiten[_seite];
    final pages = PageView(
      key: ValueKey('pages-${t.id}'),
      controller: _pages,
      onPageChanged: (i) {
        setState(() => _seite = i);
        _starteFlug();
      },
      children: [
        for (final (i, s) in seiten.indexed)
          _Bento(
            seite: s,
            ein: _ein,
            bereich: t.name,
            blase: !szene
                ? null
                : _CoachBlase(
                    key: const ValueKey('bereich-coach'),
                    text: s.coach,
                    platzKey: i == _seite ? _zielKey : null,
                    gesicht: i != _seite || _da,
                    onTap: widget.frag == null
                        ? null
                        : () => oeffneFeld(
                            context,
                            _coachKey,
                            widget.frag!(t),
                            t.name,
                          ),
                    rahmenKey: i == _seite ? _coachKey : null,
                  ),
            hervor: i == _seite && _da && s.zeigt != null,
          ),
      ],
    );
    final zurueck = InkWell(
      key: const ValueKey('bereich-zurueck'),
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).maybePop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '‹ ${widget.zurueck}',
          style: Glas.tLabel.copyWith(
            fontSize: 15,
            color: CoachStyle.goldLight,
          ),
        ),
      ),
    );
    final segment = AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      child: _SegmentLeiste(
        key: ValueKey('seg-${t.id}'),
        namen: [for (final s in seiten) s.name],
        aktiv: _seite,
        onTap: _zuSeite,
      ),
    );
    final Widget inhalt;
    if (!szene) {
      inhalt = SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: zurueck),
                  _kopf(),
                  if (widget.teile.length > 1) ...[
                    const SizedBox(height: 12),
                    _TeilLeiste(
                      teile: widget.teile,
                      aktiv: _teil,
                      onTap: _zuTeil,
                    ),
                  ],
                  const SizedBox(height: 12),
                  segment,
                  const SizedBox(height: 12),
                  _coachKarte(seiteJetzt.coach),
                ],
              ),
            ),
            Expanded(child: pages),
            _Punkte(anzahl: seiten.length, aktiv: _seite),
            SizedBox(height: 10 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      );
    } else {
      final oben = MediaQuery.paddingOf(context).top;
      inhalt = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The big living scene with back, name, value and the parts.
          SizedBox(
            height: 262 + oben,
            child: Stack(
              children: [
                Positioned.fill(
                  child: KoerperSzene(
                    key: ValueKey('szene-${t.id}'),
                    rahmenKey: _ringKey,
                    art: t.szene!,
                    titel: t.name,
                    sub: t.sub,
                    wert: t.wert,
                    daten: t.szeneDaten,
                    gross: true,
                    obenFrei: oben + 34,
                    ueber: widget.name,
                    onTap: widget.verlauf == null
                        ? null
                        : () => oeffneFeld(
                            context,
                            _ringKey,
                            widget.verlauf!,
                            widget.name,
                          ),
                  ),
                ),
                Positioned(left: 16, top: oben + 4, child: zurueck),
                // Where the coach sits before he flies down.
                Positioned(
                  left: 16,
                  top: oben + 122,
                  child: Opacity(
                    opacity: _da ? 0 : 1,
                    child: CoachAvatar(key: _avatarKey, size: 50),
                  ),
                ),
                if (widget.teile.length > 1)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 8,
                    child: _TeilPillen(
                      teile: widget.teile,
                      aktiv: _teil,
                      onTap: _zuTeil,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: segment,
          ),
          Expanded(child: pages),
          _Punkte(anzahl: seiten.length, aktiv: _seite),
          SizedBox(height: 10 + MediaQuery.paddingOf(context).bottom),
        ],
      );
    }
    return Scaffold(
      backgroundColor: CoachStyle.night,
      body: Stack(
        key: _stackKey,
        children: [
          Positioned.fill(
            child: GlasHintergrund(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: inhalt,
                ),
              ),
            ),
          ),
          if (_flugVon != null && _flugNach != null && !_da)
            AnimatedBuilder(
              animation: _flug,
              builder: (context, _) {
                final v = Curves.easeInOutCubic.transform(
                  ((_flug.value - .45) / .55).clamp(0.0, 1.0),
                );
                final r = Rect.lerp(_flugVon, _flugNach, v)!;
                // A small arc upwards on the way.
                final hoch = math.sin(v * math.pi) * 46;
                return Positioned(
                  left: r.left,
                  top: r.top - hoch,
                  width: r.width,
                  height: r.height,
                  child: IgnorePointer(
                    child: Container(
                      key: const ValueKey('coach-fliegt'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x66E0BF7E),
                            blurRadius: 10 + 12 * v,
                          ),
                        ],
                      ),
                      child: CoachAvatar(size: r.width),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Körper as pictures (draft 3b): back and parts on top, the part's
  /// name with its ring, the gold page bar, then one picture per page.
  Widget _bildLayout(BuildContext context) {
    final seiten = t.seiten;
    // Pages in the new structure get the lighter look of the sub pages
    // ("3 klar"; Phillip 2026-11-14: "mehr den helleren modernen Stil").
    if (seiten.any((s) => s.aufbau != null)) {
      return Scaffold(
        backgroundColor: const Color(0xFF231B14),
        body: KlarHintergrund(child: _bildInhalt(context)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C09),
      // Dark brown with a soft gold light from the top (draft "Bereiche
      // als Bilder" 3, Phillip "ins Braun" 2026-11-07).
      // Since the Umbau (2026-11-12): espresso brown with one gold light
      // from the top right, like Heute.
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: Umbau.seite),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.6, -1.15),
              radius: 1.15,
              colors: [Color(0x38E9C98A), Color(0x00E9C98A)],
              stops: [0, .75],
            ),
          ),
          child: _bildInhalt(context),
        ),
      ),
    );
  }

  Widget _bildInhalt(BuildContext context) {
    final seiten = t.seiten;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      key: const ValueKey('bereich-zurueck'),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x1FFFECD2),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 22,
                          color: Umbau.gold,
                        ),
                      ),
                    ),
                    if (widget.teile.length > 1) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TeilPillen(
                          teile: widget.teile,
                          aktiv: _teil,
                          onTap: _zuTeil,
                        ),
                      ),
                    ],
                    // One part only: where you came from, small
                    // (draft "Bereiche als Bilder" 3).
                    if (widget.teile.length == 1) ...[
                      const SizedBox(width: 10),
                      Text(
                        widget.zurueck,
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Umbau.text,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (widget.teile.length == 1 ? 'Bereich' : widget.name)
                                .toUpperCase(),
                            style: Umbau.label.copyWith(
                              color: const Color(0xFFF1E6D2),
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              t.name,
                              key: ValueKey('titel-${t.id}'),
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontWeight: FontWeight.w700,
                                fontSize: 27,
                                height: 1.15,
                                letterSpacing: -0.6,
                                color: Umbau.text,
                              ),
                            ),
                          ),
                          // The score big in gold, counting up.
                          GestureDetector(
                            key: const ValueKey('bereich-ring'),
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.verlauf == null
                                ? null
                                : () => oeffneFeld(
                                    context,
                                    _ringKey,
                                    widget.verlauf!,
                                    widget.name,
                                  ),
                            child: KeyedSubtree(
                              key: _ringKey,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ZaehlZahl(
                                    key: ValueKey('ring-${t.id}'),
                                    wert: (t.wert ?? 0).toDouble(),
                                    leer: t.wert == null ? '–' : null,
                                    style: const TextStyle(
                                      fontFamily: 'Sora',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 60,
                                      height: 1.05,
                                      letterSpacing: -2.4,
                                      color: Colors.white,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        _trend(t),
                                        style: const TextStyle(
                                          fontFamily: 'Figtree',
                                          fontSize: 12,
                                          height: 1.3,
                                          color: Color(0xFFE6D9C2),
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
                    ),
                    if (t.woche.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WochenBalken(
                          key: ValueKey('woche-${t.id}'),
                          woche: t.woche,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  child: _SegmentLeiste(
                    key: ValueKey('seg-${t.id}'),
                    namen: [for (final s in seiten) s.name],
                    aktiv: _seite,
                    onTap: _zuSeite,
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  key: ValueKey('pages-${t.id}'),
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _seite = i),
                  children: [
                    for (final (i, s) in seiten.indexed)
                      _BildSeiteView(
                        key: ValueKey('bild-${t.id}-$i'),
                        seite: s,
                        bereich: t.name,
                        sichtbar: i == _seite,
                        coachKey: i == _seite ? _coachKey : null,
                        onCoach: widget.frag == null
                            ? null
                            : () => oeffneFeld(
                                context,
                                _coachKey,
                                widget.frag!(t),
                                t.name,
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "+1 zu gestern", "wie gestern" or nothing before two ratings.
  static String _trend(Unterbereich t) {
    final w = t.woche;
    if (w.length < 2 || w.last == null || w[w.length - 2] == null) return '';
    final d = w.last! - w[w.length - 2]!;
    return d == 0 ? 'wie gestern' : '${d > 0 ? '+' : '−'}${d.abs()} zu gestern';
  }

  Widget _kopf() => Row(
    children: [
      GestureDetector(
        key: const ValueKey('bereich-ring'),
        onTap: widget.verlauf == null
            ? null
            : () => oeffneFeld(context, _ringKey, widget.verlauf!, widget.name),
        child: KeyedSubtree(
          key: _ringKey,
          child: WertRing(wert: widget.wert),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: CoachStyle.title.copyWith(
                fontSize: 30,
                color: Glas.text,
                letterSpacing: -0.6,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                t.sub,
                key: ValueKey('sub-${t.id}'),
                style: Glas.tSoft.copyWith(
                  fontSize: 13,
                  color: CoachStyle.goldLight,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _coachKarte(String text) => GestureDetector(
    key: const ValueKey('bereich-coach'),
    onTap: widget.frag == null
        ? null
        : () => oeffneFeld(context, _coachKey, widget.frag!(t), t.name),
    child: KeyedSubtree(
      key: _coachKey,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlasBox(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CoachAvatar(size: 34),
                const SizedBox(width: 11),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, .15),
                          end: Offset.zero,
                        ).animate(a),
                        child: c,
                      ),
                    ),
                    child: Text(
                      text,
                      key: ValueKey(text),
                      style: Glas.tText.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.38,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.frag != null)
            Positioned(
              right: 12,
              bottom: -9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  gradient: CoachStyle.goldGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Frag mich',
                  style: TextStyle(
                    fontFamily: 'Figtree',
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    color: CoachStyle.goldInk,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Training · Ernährung · Schlaf & Routine: each with icon, score and the
/// last 7 days; the picked one has a gold frame that glides along.
class _TeilLeiste extends StatelessWidget {
  const _TeilLeiste({
    required this.teile,
    required this.aktiv,
    required this.onTap,
  });

  final List<Unterbereich> teile;
  final int aktiv;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = teile.length;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0x0DFFECC8),
        border: Border.all(color: const Color(0x24FFEECD)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 560),
              curve: const Cubic(.34, 1.3, .5, 1),
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * aktiv / (n - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x33FFE8BE), Color(0x0FE0BF7E)],
                    ),
                    border: Border.all(color: Glas.goldEdge),
                    boxShadow: const [
                      BoxShadow(color: Color(0x40E0BF7E), blurRadius: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: GestureDetector(
                    key: ValueKey('teil-${teile[i].id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: _TeilKnopf(teil: teile[i], an: i == aktiv),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeilKnopf extends StatelessWidget {
  const _TeilKnopf({required this.teil, required this.an});
  final Unterbereich teil;
  final bool an;

  @override
  Widget build(BuildContext context) {
    final w = teil.woche;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: an ? 1 : .55,
                child: Icon(teil.icon, size: 18, color: CoachStyle.goldLight),
              ),
              const Spacer(),
              an
                  ? GoldSchrift(
                      teil.wert?.toString() ?? '–',
                      style: Glas.tBig.copyWith(fontSize: 24, height: 1),
                    )
                  : Text(
                      teil.wert?.toString() ?? '–',
                      style: Glas.tBig.copyWith(
                        fontSize: 24,
                        height: 1,
                        color: const Color(0xFF9C8B6C),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            teil.name,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Glas.tLabel.copyWith(
              fontSize: 11.5,
              letterSpacing: -.2,
              color: an ? Glas.text : Glas.soft,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var k = 0; k < 7; k++) ...[
                  if (k > 0) const SizedBox(width: 2),
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: k < w.length && w[k] != null
                          ? (w[k]!.clamp(1, 10)) / 10
                          : .12,
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: an ? CoachStyle.goldGradient : null,
                          color: an ? null : const Color(0x33FFECC8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass bar with a gold knob that stretches over to the new page.
class _SegmentLeiste extends StatelessWidget {
  const _SegmentLeiste({
    super.key,
    required this.namen,
    required this.aktiv,
    required this.onTap,
  });

  final List<String> namen;
  final int aktiv;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = namen.length;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0x17FFF0DC),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * aktiv / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: Umbau.grad,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: GestureDetector(
                    key: ValueKey('seite-${namen[i]}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: i == aktiv
                              ? Umbau.tinte
                              : const Color(0xFFDCCBB0),
                        ),
                        child: Text(namen[i], maxLines: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Punkte extends StatelessWidget {
  const _Punkte({required this.anzahl, required this.aktiv});
  final int anzahl, aktiv;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < anzahl; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: const Cubic(.34, 1.45, .5, 1),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == aktiv ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: i == aktiv ? CoachStyle.goldGradient : null,
            color: i == aktiv ? null : const Color(0x33FFECC8),
          ),
        ),
    ],
  );
}

/// The tiles of one page: whole-width tiles alone, half tiles in pairs.
class _Bento extends StatelessWidget {
  const _Bento({
    required this.seite,
    required this.ein,
    required this.bereich,
    this.blase,
    this.hervor = false,
  });

  final BSeite seite;
  final Animation<double> ein;
  final String bereich;

  /// The coach's speech bubble, right above the tile he points at.
  final Widget? blase;

  /// The coach has arrived: that tile glows.
  final bool hervor;

  Widget _kachel(BKachel k) {
    if (k.id != seite.zeigt) return KachelView(k, bereich);
    return _Leuchten(an: hervor, child: KachelView(k, bereich));
  }

  @override
  Widget build(BuildContext context) {
    final zeilen = <List<BKachel>>[];
    for (final k in seite.kacheln) {
      if (k.groesse == KachelGroesse.halb &&
          zeilen.isNotEmpty &&
          zeilen.last.length == 1 &&
          zeilen.last.first.groesse == KachelGroesse.halb) {
        zeilen.last.add(k);
      } else {
        zeilen.add([k]);
      }
    }
    var n = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        for (final z in zeilen) ...[
          if (blase != null &&
              (seite.zeigt == null
                  ? z == zeilen.first
                  : z.any((k) => k.id == seite.zeigt))) ...[
            if (z != zeilen.first) const SizedBox(height: 14),
            blase!,
            const SizedBox(height: 8),
          ] else if (z != zeilen.first)
            const SizedBox(height: 10),
          z.length == 1 && z.first.groesse != KachelGroesse.halb
              ? _Einflug(ein: ein, nr: n++, child: _kachel(z.first))
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final k in z) ...[
                        if (k != z.first) const SizedBox(width: 10),
                        Expanded(
                          child: _Einflug(ein: ein, nr: n++, child: _kachel(k)),
                        ),
                      ],
                      if (z.length == 1) ...[
                        const SizedBox(width: 10),
                        const Expanded(child: SizedBox()),
                      ],
                    ],
                  ),
                ),
        ],
      ],
    );
  }
}

/// A tile value: a number at the start ("82", "3/4", "1,5 l") counts up
/// from 0 when the tile appears; other text shows as it is.
class _ZaehltHoch extends StatelessWidget {
  const _ZaehltHoch(this.text, {required this.style});
  final String text;
  final TextStyle style;

  static final _zahl = RegExp(r'^(\d+)(,\d+)?');

  @override
  Widget build(BuildContext context) {
    final m = _zahl.firstMatch(text);
    if (m == null) return GoldSchrift(text, style: style);
    final komma = m.group(2) != null;
    final ziel = double.parse(m.group(0)!.replaceAll(',', '.'));
    final rest = text.substring(m.end);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ziel),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final zahl = v >= ziel
            ? m.group(0)!
            : komma
            ? v.toStringAsFixed(m.group(2)!.length - 1).replaceAll('.', ',')
            : '${v.round()}';
        return GoldSchrift('$zahl$rest', style: style);
      },
    );
  }
}

/// The tile the coach points at: a gold glow fades in around it.
class _Leuchten extends StatelessWidget {
  const _Leuchten({required this.an, required this.child});
  final bool an;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Glas.radius),
      border: Border.all(
        color: an ? const Color(0xD9E0BF7E) : const Color(0x00E0BF7E),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: an ? const Color(0x40E0BF7E) : const Color(0x00E0BF7E),
          blurRadius: 26,
        ),
      ],
    ),
    child: child,
  );
}

/// A tile springs in out of a small gold light, one after another.
class _Einflug extends StatelessWidget {
  const _Einflug({required this.ein, required this.nr, required this.child});
  final Animation<double> ein;
  final int nr;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (0.2 + nr * 0.09).clamp(0.0, 0.8);
    final a = CurvedAnimation(
      parent: ein,
      curve: Interval(
        start,
        (start + 0.4).clamp(0, 1),
        curve: const Cubic(.3, 1.25, .5, 1),
      ),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, c) {
        final v = a.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.6 + 0.4 * v, child: c),
        );
      },
      child: child,
    );
  }
}

/// One glass tile; tap grows it into its page.
class KachelView extends StatefulWidget {
  const KachelView(this.k, this.bereich, {super.key});
  final BKachel k;
  final String bereich;

  @override
  State<KachelView> createState() => _KachelViewState();
}

class _KachelViewState extends State<KachelView> {
  final _key = GlobalKey();
  bool _gedrueckt = false;

  BKachel get k => widget.k;

  void _auf() {
    if (k.feld != null) {
      oeffneFeld(context, _key, k.feld!, widget.bereich);
    } else if (k.seite != null) {
      oeffneSeite(context, _key, k.seite!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minH = switch (k.groesse) {
      KachelGroesse.hoch => 196.0,
      KachelGroesse.mittel => 150.0,
      KachelGroesse.halb => 166.0,
      KachelGroesse.schmal => 0.0,
    };
    final art = k.nacht
        ? GlasArt.nacht
        : (k.gold ? GlasArt.gold : GlasArt.normal);
    return GestureDetector(
      key: ValueKey('kachel-${k.id}'),
      onTapDown: (_) => setState(() => _gedrueckt = true),
      onTapCancel: () => setState(() => _gedrueckt = false),
      onTapUp: (_) => setState(() => _gedrueckt = false),
      onTap: _auf,
      child: AnimatedScale(
        scale: _gedrueckt ? .965 : 1,
        duration: const Duration(milliseconds: 160),
        child: KeyedSubtree(
          key: _key,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: GlasBox(
              art: art,
              child: Stack(
                children: [
                  if (k.bild != null &&
                      (k.groesse == KachelGroesse.hoch ||
                          k.groesse == KachelGroesse.mittel))
                    Positioned(right: 0, bottom: 0, child: k.bild!)
                  else if (k.bild != null && k.groesse != KachelGroesse.halb)
                    Positioned(right: 0, top: 30, child: k.bild!),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GlasIcon(k.icon),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              k.titel,
                              maxLines: 2,
                              style: Glas.tLabel.copyWith(
                                color: k.nacht
                                    ? const Color(0xFFB9C0EE)
                                    : Glas.label,
                              ),
                            ),
                          ),
                          if (k.hot != null) _Hot(k.hot!),
                        ],
                      ),
                      SizedBox(height: minH > 0 ? 18 : 10),
                      if (k.bild != null &&
                          k.groesse == KachelGroesse.halb) ...[
                        k.bild!,
                        const SizedBox(height: 8),
                      ],
                      if (k.wert != null)
                        _ZaehltHoch(
                          k.wert!,
                          style: Glas.tBig.copyWith(
                            fontSize: k.groesse == KachelGroesse.hoch ? 38 : 30,
                          ),
                        ),
                      if (k.text != null)
                        Padding(
                          padding: EdgeInsets.only(top: k.wert == null ? 0 : 4),
                          child: Text(k.text!, style: Glas.tText),
                        ),
                      if (k.unter != null && k.unter!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            k.unter!,
                            style: Glas.tSoft.copyWith(
                              color: k.nacht ? const Color(0xFFB9C0EE) : null,
                            ),
                          ),
                        ),
                      if (k.knopf != null) ...[
                        const SizedBox(height: 10),
                        _KleinKnopf(k.knopf!, k.onKnopf ?? _auf),
                      ],
                    ],
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

class _Hot extends StatelessWidget {
  const _Hot(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      gradient: CoachStyle.goldGradient,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Figtree',
        fontWeight: FontWeight.w600,
        fontSize: 10.5,
        color: CoachStyle.goldInk,
      ),
    ),
  );
}

class _KleinKnopf extends StatelessWidget {
  const _KleinKnopf(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4DE0BF7E),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: CoachStyle.goldInk,
        ),
      ),
    ),
  );
}

Rect? _rectVon(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The tile grows into the page: the page is cut out of the tile's shape
/// and opens up to the whole screen.
Future<void> oeffneFeld(
  BuildContext context,
  GlobalKey von,
  Feld feld,
  String bereich,
) => Navigator.of(context).push(
  _WachsRoute(
    von: _rectVon(von),
    builder: (_) => FeldSeite(feld: feld, bereich: bereich),
  ),
);

/// Same growth for an existing page of the app.
Future<void> oeffneSeite(
  BuildContext context,
  GlobalKey von,
  WidgetBuilder seite,
) =>
    Navigator.of(context).push(_WachsRoute(von: _rectVon(von), builder: seite));

class _WachsRoute extends PageRouteBuilder<void> {
  _WachsRoute({required this.von, required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 620),
        reverseTransitionDuration: const Duration(milliseconds: 480),
        opaque: true,
        barrierColor: const Color(0x9E070605),
        pageBuilder: (context, a, b) => builder(context),
      );

  final Rect? von;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final a = CurvedAnimation(
      parent: animation,
      curve: const Cubic(.32, .72, 0, 1),
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, c) {
        final size = MediaQuery.sizeOf(context);
        final voll = Offset.zero & size;
        final start = von ?? voll.deflate(40);
        final r = Rect.lerp(start, voll, a.value)!;
        final radius = 24 + (38 - 24) * a.value;
        return ClipRRect(
          clipper: _RechteckClipper(r, radius),
          child: Opacity(opacity: (a.value * 2.2).clamp(0.0, 1.0), child: c),
        );
      },
      child: child,
    );
  }
}

class _RechteckClipper extends CustomClipper<RRect> {
  _RechteckClipper(this.r, this.radius);
  final Rect r;
  final double radius;

  @override
  RRect getClip(Size size) =>
      RRect.fromRectAndRadius(r, Radius.circular(radius));

  @override
  bool shouldReclip(_RechteckClipper old) => old.r != r || old.radius != radius;
}

/// The page of one tile: back pill, icon, title, coach line, blocks that
/// build up one after another.
class FeldSeite extends StatelessWidget {
  const FeldSeite({super.key, required this.feld, required this.bereich});

  final Feld feld;
  final String bereich;

  @override
  Widget build(BuildContext context) {
    final bloecke = [CoachBlase(text: feld.coach), ...feld.inhalt(context)];
    return Scaffold(
      backgroundColor: const Color(0xFF231B14),
      body: KlarHintergrund(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          key: const ValueKey('feld-zurueck'),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.fromLTRB(6, 0, 13, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Klar.glas,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chevron_left,
                                  size: 20,
                                  color: Umbau.hell,
                                ),
                                Text(
                                  bereich,
                                  style: Glas.tLabel.copyWith(
                                    fontSize: 13,
                                    color: Umbau.hell,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            feld.titel,
                            style: CoachStyle.title.copyWith(
                              fontSize: 26,
                              color: Umbau.text,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0, 0.04],
                      ).createShader(r),
                      blendMode: BlendMode.dstIn,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          40 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          for (var i = 0; i < bloecke.length; i++)
                            _Aufbau(
                              nr: i,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: bloecke[i],
                              ),
                            ),
                        ],
                      ),
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

/// Blocks rise one after another when a page opens.
class _Aufbau extends StatefulWidget {
  const _Aufbau({required this.nr, required this.child});
  final int nr;
  final Widget child;

  @override
  State<_Aufbau> createState() => _AufbauState();
}

class _AufbauState extends State<_Aufbau> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 700 + 110 * widget.nr.clamp(0, 6)),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = 700 + 110 * widget.nr.clamp(0, 6);
    final start = (300 + 110 * widget.nr.clamp(0, 6)) / total;
    final a = CurvedAnimation(
      parent: _c,
      curve: Interval(
        start.clamp(0.0, 0.9),
        1,
        curve: const Cubic(.22, 1.15, .36, 1),
      ),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, c) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 34 * (1 - a.value)),
          child: c,
        ),
      ),
      child: widget.child,
    );
  }
}

/// The coach speaks right at the tile that matters (draft "Körper,
/// lebendig"): a gold-edged bubble with his face at its end. The face
/// flies in from the scene first; [gesicht] false keeps its place empty.
class _CoachBlase extends StatelessWidget {
  const _CoachBlase({
    super.key,
    required this.text,
    required this.gesicht,
    this.platzKey,
    this.rahmenKey,
    this.onTap,
  });

  final String text;
  final bool gesicht;
  final GlobalKey? platzKey, rahmenKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: KeyedSubtree(
      key: rahmenKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A2117), Color(0xFF17120D)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(5),
                ),
                border: Border.all(color: const Color(0x8CE0BF7E)),
                boxShadow: Glas.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    child: Text(
                      text,
                      key: ValueKey(text),
                      style: Glas.tText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.36,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Frag mich ›',
                      style: Glas.tLabel.copyWith(
                        fontSize: 11.5,
                        color: CoachStyle.goldLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          KeyedSubtree(
            key: platzKey,
            child: AnimatedOpacity(
              opacity: gesicht ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x55E0BF7E), blurRadius: 16),
                  ],
                ),
                child: const CoachAvatar(size: 46),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Training · Ernährung · Schlaf as small glass pills at the bottom of the
/// scene; the picked one is gold.
class _TeilPillen extends StatelessWidget {
  const _TeilPillen({
    required this.teile,
    required this.aktiv,
    required this.onTap,
  });

  final List<Unterbereich> teile;
  final int aktiv;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < teile.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            key: ValueKey('teil-${teile[i].id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: i == aktiv ? Umbau.grad : null,
                color: i == aktiv ? null : const Color(0x17FFF0DC),
              ),
              child: Row(
                children: [
                  Icon(
                    teile[i].icon,
                    size: 15,
                    color: i == aktiv ? CoachStyle.goldInk : Glas.label,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      teile[i].name.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Glas.tLabel.copyWith(
                        fontSize: 12,
                        color: i == aktiv ? CoachStyle.goldInk : Glas.soft,
                      ),
                    ),
                  ),
                  if (teile[i].wert != null)
                    Text(
                      '${teile[i].wert}',
                      style: Glas.tLabel.copyWith(
                        fontSize: 12,
                        fontFamily: 'Sora',
                        color: i == aktiv ? CoachStyle.goldInk : Glas.label,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

/// One picture page: coach line, the picture, three numbers and the
/// buttons. The picture plays in once each time the page shows.
class _BildSeiteView extends StatefulWidget {
  const _BildSeiteView({
    super.key,
    required this.seite,
    required this.bereich,
    required this.sichtbar,
    this.coachKey,
    this.onCoach,
  });

  final BSeite seite;
  final String bereich;
  final bool sichtbar;
  final GlobalKey? coachKey;
  final VoidCallback? onCoach;

  @override
  State<_BildSeiteView> createState() => _BildSeiteViewState();
}

class _BildSeiteViewState extends State<_BildSeiteView>
    with TickerProviderStateMixin {
  late final AnimationController _ein = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final AnimationController _zeit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  BBild get b => widget.seite.bild!;

  @override
  void initState() {
    super.initState();
    if (!bewegungAn) {
      _ein.value = 1;
      return;
    }
    if (widget.sichtbar) _ein.forward();
    _zeit.repeat();
  }

  @override
  void didUpdateWidget(_BildSeiteView old) {
    super.didUpdateWidget(old);
    if (bewegungAn && widget.sichtbar && !old.sichtbar) {
      _ein.forward(from: 0);
    }
    final fertig = widget.seite.aufbau?.jetzt.fertig ?? false;
    final vorher = old.seite.aufbau?.jetzt.fertig ?? false;
    if (fertig && !vorher && widget.sichtbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = _heldKey.currentContext?.findRenderObject();
        if (!mounted || box is! RenderBox || !box.attached) return;
        funkenBei(context, box.localToGlobal(box.size.center(Offset.zero)));
      });
    }
  }

  final _heldKey = GlobalKey();

  @override
  void dispose() {
    _ein.dispose();
    _zeit.dispose();
    super.dispose();
  }

  BKachel? _kachel(String id) {
    for (final k in widget.seite.kacheln) {
      if (k.id == id) return k;
    }
    return null;
  }

  Widget _tipp(String id, Widget child, {String art = 'kachel'}) {
    final k = _kachel(id);
    if (k == null) return child;
    return _Ziel(
      key: ValueKey('$art-$id'),
      k: k,
      bereich: widget.bereich,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.seite;
    if (s.aufbau case final a?) return _aufbau(a);
    final (label, ziel) = b.knopf;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _coachZeile(),
        const SizedBox(height: 12),
        _bildKachel(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Umbau.glas,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Glas.edge),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (final (i, z) in b.zahlen.indexed) ...[
                  if (i > 0)
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      indent: 4,
                      endIndent: 4,
                      color: Glas.edge,
                    ),
                  Expanded(child: _tippZahl(z, i == 0)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _tipp(
                ziel,
                art: 'knopf',
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: Umbau.grad,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Umbau.tinte,
                    ),
                  ),
                ),
              ),
            ),
            if (b.knopf2 case (final icon, final id)) ...[
              const SizedBox(width: 8),
              _tipp(
                id,
                art: 'knopf',
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x17FFF0DC),
                  ),
                  child: Icon(icon, size: 20, color: Glas.text),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _coachZeile() {
    final s = widget.seite;
    return GestureDetector(
      key: widget.sichtbar ? const ValueKey('bereich-coach') : null,
      onTap: widget.onCoach,
      child: KeyedSubtree(
        key: widget.coachKey,
        child: Row(
          children: [
            // The coach stands free, like on Heute (Umbau 2026-11-12).
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: Umbau.grad,
              ),
              child: const ClipOval(
                child: Image(
                  image: AssetImage('assets/images/coach.jpg'),
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.coach,
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      fontSize: 14.5,
                      height: 1.4,
                      color: Color(0xFFF1E6D2),
                    ),
                  ),
                  if (s.aufbau?.dafuer case final d?) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Dafür: $d',
                      key: const ValueKey('dafuer'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.35,
                        color: Glas.label,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bildKachel() => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: DecoratedBox(
      // A calm glass tile like on Heute (Umbau 2026-11-12).
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: widget.seite.aufbau != null ? Klar.glas : Umbau.glas,
        border: widget.seite.aufbau != null
            ? null
            : Border.all(color: Glas.edge),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.2),
            radius: .75,
            colors: [Color(0x17C9A25C), Color(0x00C9A25C)],
          ),
        ),
        child: AspectRatio(
          aspectRatio: bildBreite / bildHoehe,
          child: FittedBox(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ein, _zeit]),
              builder: (context, _) =>
                  b.bau(_tipp, _ein.value, _zeit.value * 60),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _glas({Key? key, required Widget child}) => Container(
    key: key,
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(
      color: Klar.glas,
      borderRadius: BorderRadius.circular(26),
    ),
    child: child,
  );

  /// The new structure: one thing first, motivation next, the rest calm.
  Widget _aufbau(BAufbau a) {
    final j = a.jetzt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _coachZeile(),
        const SizedBox(height: 12),
        RingKachel(
          key: const ValueKey('jetzt-dran'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          j.fertig ? 'GESCHAFFT' : 'JETZT DRAN',
                          style: Umbau.label.copyWith(color: Umbau.tinteWeich),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          j.titel,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            height: 1.15,
                            letterSpacing: -.3,
                            color: Umbau.tinte,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          j.text,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 13.5,
                            height: 1.4,
                            color: Umbau.tinteWeich,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  KeyedSubtree(
                    key: _heldKey,
                    child: FuellRing(
                      wert: j.fertig ? 1 : j.ring ?? 0,
                      size: 84,
                      dunkel: true,
                      child: j.fertig
                          ? const Icon(
                              Icons.check_rounded,
                              size: 34,
                              color: Umbau.tinte,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  j.mitte,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 19,
                                    height: 1.1,
                                    color: Umbau.tinte,
                                  ),
                                ),
                                if (j.unter.isNotEmpty)
                                  Text(
                                    j.unter.toUpperCase(),
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontFamily: 'Sora',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 7,
                                      letterSpacing: .8,
                                      color: Umbau.tinteWeich,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              if (j.knopf case (final label, final ziel)) ...[
                const SizedBox(height: 16),
                _tipp(
                  ziel,
                  art: 'knopf',
                  DunkelKnopf(label: label, onPressed: null),
                ),
              ],
            ],
          ),
        ),
        if (a.serie != null || a.naechstes != null) ...[
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (a.serie case final x?) Expanded(child: _serie(x)),
                if (a.serie != null && a.naechstes != null)
                  const SizedBox(width: 12),
                if (a.naechstes case final x?) Expanded(child: _naechstes(x)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _bildKachel(),
        const SizedBox(height: 12),
        _glas(
          key: const ValueKey('geschafft'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('DIESE WOCHE GESCHAFFT', style: Umbau.label),
              const SizedBox(height: 6),
              if (a.geschafft.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Noch nichts diese Woche. Der erste Haken kommt mit '
                    'deinem nächsten Eintrag.',
                    style: Glas.tSoft.copyWith(fontSize: 13),
                  ),
                ),
              for (final (i, g) in a.geschafft.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(top: BorderSide(color: Umbau.linie)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: Umbau.grad,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Umbau.tinte,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g.$1,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Glas.tText.copyWith(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(g.$2, style: Glas.tSoft.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (a.mehr.isNotEmpty) ...[
          const SizedBox(height: 12),
          _glas(
            key: const ValueKey('mehr'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('MEHR', style: Umbau.label),
                const SizedBox(height: 4),
                for (final (i, m) in a.mehr.indexed) _mehrZeile(m, i == 0),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _mehrZeile(BMehr m, bool erste) {
    final zeile = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: erste
            ? null
            : const Border(top: BorderSide(color: Umbau.linie)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              m.titel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Glas.tText.copyWith(fontSize: 14),
            ),
          ),
          if (m.wert ?? (m.ziel == null ? '–' : null) case final w?) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Text(
                w,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Glas.tSoft.copyWith(fontSize: 12.5),
              ),
            ),
          ],
          if (m.ziel != null) ...[
            const SizedBox(width: 6),
            Text('›', style: Glas.tSoft.copyWith(fontSize: 15)),
          ],
        ],
      ),
    );
    return m.ziel == null ? zeile : _tipp(m.ziel!, art: 'mehr', zeile);
  }

  Widget _serie(BSerie x) => _glas(
    key: const ValueKey('serie'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('DEINE SERIE', style: Umbau.label)),
            SizedBox(
              width: 30,
              height: 40,
              child: AnimatedBuilder(
                animation: _ein,
                builder: (context, _) => CustomPaint(
                  painter: _TriebMaler(
                    math.min(x.zahl, 6),
                    Curves.easeOutCubic.transform(_ein.value),
                  ),
                ),
              ),
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ZaehltHoch(
                '${x.zahl}',
                style: Glas.tBig.copyWith(fontSize: 30, height: 1),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    x.einheit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Glas.tText.copyWith(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(x.text, style: Glas.tSoft.copyWith(fontSize: 12.5, height: 1.35)),
        if (x.rekord > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Rekord ${x.rekord}',
            style: Glas.tSoft.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Glas.label,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _naechstes(BNaechstes x) => _glas(
    key: const ValueKey('naechstes-ziel'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NÄCHSTES ZIEL', style: Umbau.label),
        const SizedBox(height: 10),
        Text(
          x.titel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
            height: 1.2,
            color: Glas.text,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 5,
            child: AnimatedBuilder(
              animation: _ein,
              builder: (context, _) => Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0x24FFF5E6)),
                  ),
                  FractionallySizedBox(
                    widthFactor:
                        x.anteil.clamp(0.0, 1.0) *
                        Curves.easeOutCubic.transform(_ein.value),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(gradient: Umbau.grad),
                      child: SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(x.text, style: Glas.tSoft.copyWith(fontSize: 12.5, height: 1.35)),
      ],
    ),
  );

  Widget _tippZahl(BZahl z, bool erste) {
    final inhalt = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: erste
                ? _ZaehltHoch(
                    z.wert,
                    style: Glas.tBig.copyWith(fontSize: 18, height: 1.2),
                  )
                : Text(
                    z.wert,
                    maxLines: 1,
                    style: Glas.tBig.copyWith(
                      fontSize: 18,
                      height: 1.2,
                      color: Glas.text,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          z.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Glas.tSoft.copyWith(fontSize: 11),
        ),
      ],
    );
    return z.ziel == null ? inhalt : _tipp(z.ziel!, art: 'zahl', inhalt);
  }
}

/// The small sprout of "Deine Serie": one leaf per day, six at most.
class _TriebMaler extends CustomPainter {
  _TriebMaler(this.blaetter, this.v);
  final int blaetter;
  final double v;

  @override
  void paint(Canvas c, Size s) {
    final gold = Paint()
      ..shader = Umbau.grad.createShader(Offset.zero & s)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final x = s.width / 2;
    final hoehe = (s.height - 4) * (.35 + .65 * math.max(blaetter, 1) / 6) * v;
    c.drawLine(Offset(x, s.height), Offset(x, s.height - hoehe), gold);
    final blatt = Paint()..shader = Umbau.grad.createShader(Offset.zero & s);
    for (var i = 0; i < blaetter; i++) {
      final y = s.height - 6 - i * (s.height - 12) / 6;
      if (s.height - y > hoehe) break;
      final links = i.isEven;
      final p = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + (links ? -12 : 12),
          y - 2,
          x + (links ? -11 : 11),
          y - 11,
        )
        ..quadraticBezierTo(x + (links ? -2 : 2), y - 9, x, y);
      c.drawPath(p, blatt);
    }
  }

  @override
  bool shouldRepaint(_TriebMaler old) => old.blaetter != blaetter || old.v != v;
}

/// A part of a picture page that opens a tile's page, grown from itself.
class _Ziel extends StatefulWidget {
  const _Ziel({
    super.key,
    required this.k,
    required this.bereich,
    required this.child,
  });

  final BKachel k;
  final String bereich;
  final Widget child;

  @override
  State<_Ziel> createState() => _ZielState();
}

class _ZielState extends State<_Ziel> {
  final _g = GlobalKey();
  bool _gedrueckt = false;

  void _auf() {
    final k = widget.k;
    if (k.onKnopf != null) {
      k.onKnopf!();
    } else if (k.feld != null) {
      oeffneFeld(context, _g, k.feld!, widget.bereich);
    } else if (k.seite != null) {
      oeffneSeite(context, _g, k.seite!);
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _gedrueckt = true),
    onTapCancel: () => setState(() => _gedrueckt = false),
    onTapUp: (_) => setState(() => _gedrueckt = false),
    onTap: _auf,
    child: AnimatedScale(
      scale: _gedrueckt ? .97 : 1,
      duration: const Duration(milliseconds: 150),
      child: KeyedSubtree(key: _g, child: widget.child),
    ),
  );
}

/// The last seven days as slim bars, today in gold (Umbau 2026-11-12).
class _WochenBalken extends StatelessWidget {
  const _WochenBalken({super.key, required this.woche});
  final List<int?> woche;

  @override
  Widget build(BuildContext context) {
    final n = woche.length;
    final heute = DateTime.now().weekday;
    const tage = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 52,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: bewegungAn ? 0 : 1, end: 1),
                      duration: Duration(milliseconds: 900 + i * 70),
                      curve: Interval(
                        i * 70 / (900 + i * 70),
                        1,
                        curve: Curves.easeOutBack,
                      ),
                      builder: (context, v, _) => Container(
                        width: 11,
                        height: math.max(
                          0,
                          (4 + 48 * (woche[i] ?? 0) / 10) * v,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: i == n - 1 && woche[i] != null
                              ? Umbau.grad
                              : null,
                          color: i == n - 1 && woche[i] != null
                              ? null
                              : const Color(0x33FFECD2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tage[(heute - 1 - (n - 1 - i)) % 7],
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600,
                    fontSize: 8.5,
                    color: i == n - 1 ? Colors.white : const Color(0xFFCDBB9D),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
