import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'training_data.dart';
import 'training_logik.dart';
import 'training_widgets.dart';

/// One exercise of today's session (ideas 1 and 5): last time and today's
/// target on top, the sets prefilled, a tick per set, the rest after each
/// tick, one more or one less set, and how it felt.
class UebungKarte extends StatelessWidget {
  const UebungKarte({
    super.key,
    required this.session,
    required this.i,
    required this.ziel,
    required this.onForm,
    required this.onVerlauf,
  });

  final HeuteSession session;
  final int i;
  final UebungZiel ziel;
  final VoidCallback? onForm;
  final VoidCallback onVerlauf;

  @override
  Widget build(BuildContext context) {
    final l = session.logs[i];
    final u = session.plan[i];
    final art = u.art;
    final warm = aufwaermSaetze(u, ziel);
    final zielText = ziel.saetze.isEmpty
        ? ''
        : satzText(art, ziel.saetze.first);
    return TKarte(
      key: ValueKey('uebung-$i'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(u.name, style: tTitel)),
              TLabel('${l.fertige.length}/${l.saetze.length} Sätze'),
            ],
          ),
          const SizedBox(height: 3),
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
          if (ziel.angepasst != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Vom Coach angepasst',
                style: tSoft.copyWith(color: CoachStyle.goldLight),
              ),
            ),
          if (u.notiz.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(u.notiz, style: tSoft.copyWith(fontSize: 11.5)),
            ),
          const SizedBox(height: 10),
          for (var k = 0; k < warm.length && k < l.aufwaermen.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 9),
                      child: Text('Satz ${k + 1}', style: tSoft),
                    ),
                  ),
                  if (art.wertEinheit != null) ...[
                    Expanded(
                      child: ZahlFeld(
                        key: ValueKey('wert-$i-$k'),
                        wert: l.saetze[k].wert,
                        einheit: art.wertEinheit,
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
                      onChanged: (v) => session.setWert(i, k, v, menge: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TTick(
                    key: ValueKey('satz-$i-$k'),
                    an: l.saetze[k].fertig,
                    onTap: () => session.abhaken(i, k),
                  ),
                ],
              ),
            ),
          if (session.pauseFuer == i)
            Container(
              key: ValueKey('pause-$i'),
              margin: const EdgeInsets.only(top: 2, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1F13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CoachStyle.goldEdge),
              ),
              child: Row(
                children: [
                  Text('Pause', style: tText.copyWith(fontSize: 12.5)),
                  const Spacer(),
                  Text(
                    mmss(session.pauseRest),
                    style: tTitel.copyWith(color: CoachStyle.goldLight),
                  ),
                  const Spacer(),
                  TLink('Weiter', onTap: session.pauseStopp),
                ],
              ),
            ),
          Row(
            children: [
              TLink(
                '+ Satz',
                key: ValueKey('satz-dazu-$i'),
                onTap: () => session.satzDazu(i),
              ),
              const SizedBox(width: 12),
              if (l.saetze.length > 1)
                TLink(
                  '– Satz',
                  key: ValueKey('satz-weg-$i'),
                  onTap: () => session.satzWeg(i),
                ),
              const SizedBox(width: 12),
              if (u.pause > 0)
                Text(
                  'Pause ${mmss(u.pause)}',
                  style: tSoft.copyWith(color: CoachStyle.inkSoft),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final f in const ['leicht', 'passt', 'schwer']) ...[
                Expanded(
                  child: TChip(
                    f,
                    key: ValueKey('gefuehl-$i-$f'),
                    an: l.gefuehl == f,
                    onTap: () => session.gefuehl(i, f),
                  ),
                ),
                if (f != 'schwer') const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
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
                fillColor: const Color(0xFF1A140E),
                hintText: widget.art.wertEinheit == null
                    ? 'z. B. 13'
                    : 'z. B. 85 × 6',
                hintStyle: const TextStyle(color: CoachStyle.inkSoft),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4A3B2A)),
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
