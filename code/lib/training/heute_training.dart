import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../ui/umbau.dart';
import 'training_data.dart';
import 'training_logik.dart';
import 'training_widgets.dart';

/// One exercise of today's session (ideas 1 and 5): last time and today's
/// target on top, the sets prefilled, a tick per set, the rest after each
/// tick, one more or one less set, and how it felt. Since "3 klar"
/// (2026-11-13): big gold number, small bars of the last times, hairline
/// rows, and the set that is next lies on a light gold row.
class UebungKarte extends StatelessWidget {
  const UebungKarte({
    super.key,
    required this.session,
    required this.i,
    required this.ziel,
    required this.onForm,
    required this.onVerlauf,
    this.verlauf = const [],
  });

  final HeuteSession session;
  final int i;
  final UebungZiel ziel;
  final VoidCallback? onForm;
  final VoidCallback onVerlauf;

  /// The best value of the last times, oldest first (for the small bars).
  final List<double> verlauf;

  static const _linie = BorderSide(color: Umbau.linie);

  @override
  Widget build(BuildContext context) {
    final l = session.logs[i];
    final u = session.plan[i];
    final art = u.art;
    final warm = aufwaermSaetze(u, ziel);
    final zielText = ziel.saetze.isEmpty
        ? ''
        : satzText(art, ziel.saetze.first);
    final jetzt = l.saetze.indexWhere((x) => !x.fertig);
    return TKarte(
      key: ValueKey('uebung-$i'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GoldMaske(
                child: Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 34,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name, style: tTitel.copyWith(fontSize: 18)),
                    const SizedBox(height: 1),
                    Text.rich(
                      TextSpan(
                        style: tSoft,
                        children: [
                          TextSpan(
                            text: ziel.letztes == null
                                ? 'Erstes Mal · '
                                : 'Letztes Mal ${satzText(art, ziel.letztes!)} · ',
                          ),
                          TextSpan(
                            text: 'Ziel heute $zielText',
                            style: const TextStyle(
                              color: CoachStyle.goldLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (verlauf.length > 1) ...[
                const SizedBox(width: 10),
                _Balken(verlauf),
              ],
            ],
          ),
          if (ziel.angepasst != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Vom Coach angepasst',
                style: tSoft.copyWith(color: CoachStyle.goldLight),
              ),
            ),
          if (u.notiz.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(u.notiz, style: tSoft.copyWith(fontSize: 11.5)),
            ),
          const SizedBox(height: 10),
          for (var k = 0; k < warm.length && k < l.aufwaermen.length; k++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(border: Border(top: _linie)),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      'Aufw.',
                      style: tSoft.copyWith(color: CoachStyle.nightMuted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      satzText(art, warm[k]),
                      style: tSoft.copyWith(color: CoachStyle.inkSoft),
                    ),
                  ),
                  TTick(
                    key: ValueKey('aufw-$i-$k'),
                    an: l.aufwaermen[k],
                    onTap: () => session.aufwaermen(i, k),
                  ),
                ],
              ),
            ),
          for (var k = 0; k < l.saetze.length; k++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.symmetric(vertical: k == jetzt ? 4 : 0),
              padding: k == jetzt
                  ? const EdgeInsets.fromLTRB(14, 8, 8, 8)
                  : const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                gradient: k == jetzt ? Klar.held : null,
                borderRadius: BorderRadius.circular(k == jetzt ? 22 : 0),
                border: k == jetzt || k == jetzt + 1 && jetzt >= 0
                    ? null
                    : const Border(top: _linie),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 46,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Text(
                        'Satz ${k + 1}',
                        style: tSoft.copyWith(
                          color: k == jetzt ? Umbau.tinteWeich : null,
                        ),
                      ),
                    ),
                  ),
                  if (art.wertEinheit != null) ...[
                    Expanded(
                      child: ZahlFeld(
                        key: ValueKey('wert-$i-$k'),
                        wert: l.saetze[k].wert,
                        einheit: art.wertEinheit,
                        hell: k == jetzt,
                        onChanged: (v) => session.setWert(i, k, v),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: ZahlFeld(
                      key: ValueKey('menge-$i-$k'),
                      wert: l.saetze[k].menge,
                      einheit: art == UebungArt.koerpergewicht
                          ? 'Wdh · Körpergewicht'
                          : art.mengeEinheit,
                      dezimal: art == UebungArt.strecke,
                      hell: k == jetzt,
                      onChanged: (v) => session.setWert(i, k, v, menge: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TTick(
                    key: ValueKey('satz-$i-$k'),
                    an: l.saetze[k].fertig,
                    hell: k == jetzt,
                    funken: true,
                    onTap: () => session.abhaken(i, k),
                  ),
                ],
              ),
            ),
          if (session.pauseFuer == i)
            Container(
              key: ValueKey('pause-$i'),
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(
                color: const Color(0x1AE2BD7A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  FuellRing(
                    wert: u.pause > 0 ? session.pauseRest / u.pause : 0,
                    size: 22,
                    dicke: 3,
                  ),
                  const SizedBox(width: 10),
                  Text('Pause', style: tText.copyWith(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    mmss(session.pauseRest),
                    style: tTitel.copyWith(color: CoachStyle.goldLight),
                  ),
                  const Spacer(),
                  if (jetzt >= 0) Text('dann Satz ${jetzt + 1}', style: tSoft),
                  const SizedBox(width: 6),
                  TLink('Weiter', onTap: session.pauseStopp),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TChip(
                '+ Satz',
                key: ValueKey('satz-dazu-$i'),
                an: false,
                klein: true,
                onTap: () => session.satzDazu(i),
              ),
              if (l.saetze.length > 1)
                TChip(
                  '– Satz',
                  key: ValueKey('satz-weg-$i'),
                  an: false,
                  klein: true,
                  onTap: () => session.satzWeg(i),
                ),
              if (u.pause > 0) KlarPille('Pause ${mmss(u.pause)}'),
              if (onForm != null)
                TChip(
                  'Form filmen',
                  key: ValueKey('form-$i'),
                  an: false,
                  klein: true,
                  onTap: onForm,
                ),
              TChip(
                'Verlauf ›',
                key: ValueKey('verlauf-$i'),
                an: false,
                klein: true,
                onTap: onVerlauf,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Klar.glas,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                for (final f in const ['leicht', 'passt', 'schwer'])
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('gefuehl-$i-$f'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => session.gefuehl(i, f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          gradient: l.gefuehl == f ? Umbau.grad : null,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          f,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: l.gefuehl == f ? Umbau.tinte : Umbau.weich,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small gold bars: how the exercise went the last times.
class _Balken extends StatelessWidget {
  const _Balken(this.werte);
  final List<double> werte;

  @override
  Widget build(BuildContext context) {
    final w = werte.length > 5 ? werte.sublist(werte.length - 5) : werte;
    final hoch = w.reduce((a, b) => a > b ? a : b);
    final tief = w.reduce((a, b) => a < b ? a : b);
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var k = 0; k < w.length; k++)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Opacity(
                opacity: k == w.length - 1 ? 1 : .45,
                child: Container(
                  width: 5,
                  height: hoch == tief
                      ? 24
                      : 12 + 22 * (w[k] - tief) / (hoch - tief),
                  decoration: BoxDecoration(
                    gradient: Umbau.grad,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// After "Überspringen" (idea 3): why it is skipped, then the coach's
/// answer and "Rückgängig".
class SkipKarte extends StatelessWidget {
  const SkipKarte({
    super.key,
    required this.name,
    this.grund,
    this.text,
    required this.onGrund,
    required this.onZurueck,
  });

  final String name;
  final String? grund;
  final String? text;
  final ValueChanged<String>? onGrund;
  final VoidCallback onZurueck;

  static const gruende = [
    'Müde',
    'Keine Zeit',
    'Krank',
    'Termin',
    'Etwas anderes',
  ];

  @override
  Widget build(BuildContext context) => TKarte(
    key: const ValueKey('skip-karte'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TLabel('$name überspringen'),
        const SizedBox(height: 6),
        if (text == null) ...[
          Text('Warum fällt es heute aus?', style: tText),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final g in gruende)
                TChip(
                  g,
                  key: ValueKey('grund-$g'),
                  an: g == grund,
                  onTap: onGrund == null ? null : () => onGrund!(g),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TGhost('Doch trainieren', onTap: onZurueck),
        ] else ...[
          Text('Grund: $grund', style: tSoft),
          const SizedBox(height: 8),
          CoachZeile(
            text: text!,
            unten: TLink(
              'Rückgängig',
              key: const ValueKey('skip-zurueck'),
              onTap: onZurueck,
            ),
          ),
        ],
      ],
    ),
  );
}

/// "Training fertig": the record with the growing sprout (idea 2), or
/// what was saved.
class FertigKarte extends StatelessWidget {
  const FertigKarte({super.key, required this.einheit, required this.rekorde});

  final TrainingEinheit einheit;
  final Map<String, (SatzWert neu, SatzWert? alt, UebungArt art)> rekorde;

  @override
  Widget build(BuildContext context) {
    final saetze = einheit.uebungen.fold<int>(
      0,
      (a, u) => a + u.fertige.length,
    );
    final erster = rekorde.entries.firstOrNull;
    return TKarte(
      key: const ValueKey('fertig-karte'),
      gold: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            if (erster != null) ...[
              const RekordSpross(key: ValueKey('rekord-spross')),
              const TLabel('Neuer Rekord'),
              const SizedBox(height: 4),
              GoldText(
                '${erster.key} ${satzText(erster.value.$3, erster.value.$1)}',
                style: tTitel.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (erster.value.$2 != null)
                Text(
                  'vorher ${satzText(erster.value.$3, erster.value.$2!)}',
                  style: tSoft,
                ),
              for (final r in rekorde.entries.skip(1))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Auch neu: ${r.key} ${satzText(r.value.$3, r.value.$1)}',
                    style: tSoft.copyWith(color: CoachStyle.goldLight),
                  ),
                ),
            ] else ...[
              const TLabel('Gespeichert'),
              const SizedBox(height: 4),
              GoldText(
                '${einheit.name} geschafft',
                style: tTitel.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Kein neuer Rekord heute, aber $saetze ${saetze == 1 ? 'Satz' : 'Sätze'} durch.',
                style: tSoft,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Idea 6: the user suggests the next target first, the coach confirms.
class VorschlagFeld extends StatefulWidget {
  const VorschlagFeld({
    super.key,
    required this.uebung,
    required this.art,
    required this.vorbelegt,
    required this.gespeichert,
    required this.onSenden,
  });

  final String uebung;
  final UebungArt art;

  /// What the app would suggest, as starting text.
  final String vorbelegt;

  /// Already saved own target, if any.
  final SatzWert? gespeichert;

  /// Sends the text; returns the coach's answer to show.
  final Future<String?> Function(String text) onSenden;

  @override
  State<VorschlagFeld> createState() => _VorschlagFeldState();
}

class _VorschlagFeldState extends State<VorschlagFeld> {
  late final _c = TextEditingController(text: widget.vorbelegt);
  bool _laedt = false;
  String? _antwort;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _senden() async {
    if (_c.text.trim().isEmpty || _laedt) return;
    setState(() => _laedt = true);
    final a = await widget.onSenden(_c.text.trim());
    if (!mounted) return;
    setState(() {
      _laedt = false;
      _antwort = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gespeichert;
    return TKarte(
      key: ValueKey('vorschlag-${widget.uebung}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TLabel('Dein Vorschlag fürs nächste Mal'),
          const SizedBox(height: 6),
          Text(
            'Was traust du dir bei ${widget.uebung} nächstes Mal zu?',
            style: tSoft,
          ),
          const SizedBox(height: 8),
          if (_antwort == null && g == null) ...[
            TextField(
              key: ValueKey('vorschlag-feld-${widget.uebung}'),
              controller: _c,
              style: tText.copyWith(fontWeight: FontWeight.w600),
              cursorColor: CoachStyle.goldLight,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0x14FFF5E6),
                hintText: widget.art.wertEinheit == null
                    ? 'z. B. 13'
                    : 'z. B. 85 × 6',
                hintStyle: const TextStyle(color: CoachStyle.inkSoft),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CoachStyle.goldLight),
                ),
              ),
              onSubmitted: (_) => _senden(),
            ),
            const SizedBox(height: 8),
            _laedt
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(color: CoachStyle.gold),
                    ),
                  )
                : TGhost(
                    'Vorschlagen',
                    key: ValueKey('vorschlag-senden-${widget.uebung}'),
                    onTap: _senden,
                  ),
          ] else
            CoachZeile(
              text:
                  _antwort ??
                  'Eingetragen: ${satzText(widget.art, g!)} fürs nächste Mal.',
            ),
        ],
      ),
    );
  }
}
