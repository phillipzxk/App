import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'glas.dart';

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

/// One of the four pages of an area (segmented bar + swipe).
class BSeite {
  const BSeite({
    required this.name,
    required this.coach,
    required this.kacheln,
  });

  final String name;
  final String coach;
  final List<BKachel> kacheln;
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
  });

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

  /// Plays the spring-in of the tiles; restarted on every part switch.
  late final AnimationController _ein = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  Unterbereich get t => widget.teile[_teil];

  @override
  void dispose() {
    _ein.dispose();
    _pages.dispose();
    super.dispose();
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
    widget.onWechsel?.call(widget.teile[i].id);
  }

  @override
  Widget build(BuildContext context) {
    final seiten = t.seiten;
    return Scaffold(
      backgroundColor: CoachStyle.night,
      body: GlasHintergrund(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
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
                          ),
                        ),
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          child: _SegmentLeiste(
                            key: ValueKey('seg-${t.id}'),
                            namen: [for (final s in seiten) s.name],
                            aktiv: _seite,
                            onTap: _zuSeite,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _coachKarte(seiten[_seite].coach),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      key: ValueKey('pages-${t.id}'),
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _seite = i),
                      children: [
                        for (final s in seiten)
                          _Bento(seite: s, ein: _ein, bereich: t.name),
                      ],
                    ),
                  ),
                  _Punkte(anzahl: seiten.length, aktiv: _seite),
                  SizedBox(height: 10 + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        color: const Color(0x12FFECC8),
        border: Border.all(color: const Color(0x29FFEECD)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeInOutCubic,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * aktiv / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: CoachStyle.goldGradient,
                  boxShadow: const [
                    BoxShadow(color: Color(0x66E0BF7E), blurRadius: 16),
                  ],
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
                          color: i == aktiv ? CoachStyle.goldInk : Glas.soft,
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
  const _Bento({required this.seite, required this.ein, required this.bereich});

  final BSeite seite;
  final Animation<double> ein;
  final String bereich;

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
          if (z != zeilen.first) const SizedBox(height: 10),
          z.length == 1 && z.first.groesse != KachelGroesse.halb
              ? _Einflug(ein: ein, nr: n++, child: KachelView(z.first, bereich))
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final k in z) ...[
                        if (k != z.first) const SizedBox(width: 10),
                        Expanded(
                          child: _Einflug(
                            ein: ein,
                            nr: n++,
                            child: KachelView(k, bereich),
                          ),
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
                  if (k.bild != null && k.groesse != KachelGroesse.halb)
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
                        GoldSchrift(
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
    final bloecke = [
      GlasBox(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CoachAvatar(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                feld.coach,
                style: Glas.tText.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      ...feld.inhalt(context),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF15110D),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1813), Color(0xFF0C0A08)],
          ),
        ),
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
                            height: 38,
                            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0x14FFECC8),
                              border: Border.all(
                                color: const Color(0x2EFFEECD),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chevron_left,
                                  color: CoachStyle.goldLight,
                                ),
                                Text(
                                  bereich,
                                  style: Glas.tLabel.copyWith(
                                    fontSize: 15,
                                    color: CoachStyle.goldLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            GlasIcon(feld.icon, size: 64),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bereich,
                                    style: Glas.tLabel.copyWith(fontSize: 12),
                                  ),
                                  Text(
                                    feld.titel,
                                    style: CoachStyle.title.copyWith(
                                      fontSize: 27,
                                      color: Glas.text,
                                      height: 1.05,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
