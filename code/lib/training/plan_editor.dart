import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../bereiche/glas.dart';
import '../home/feed_widgets.dart';
import '../ui/coach_style.dart';
import 'training_data.dart';
import 'training_widgets.dart';

typedef PlanErgebnis = ({
  TrainingPlan plan,
  List<String> sportarten,
  Schwerpunkt? schwerpunkt,
});

/// The plan, set once (Entwurf 2, view 4): sports and focus (idea 8), per
/// weekday a name with time and the exercises, each with its settings.
/// Users write the exercise names themselves, there is no database.
class TrainingPlanEditor extends StatefulWidget {
  const TrainingPlanEditor({
    super.key,
    required this.plan,
    this.sportarten = const [],
    this.schwerpunkt,
    this.onFertig,
    this.startTag,
  });

  /// The day shown first under the week strip (0 = Monday), today if null.
  final int? startTag;

  /// Saves the plan before the page closes, when it is opened straight
  /// from a tile ("Plan anlegen") instead of from the Training page.
  final Future<void> Function(PlanErgebnis ergebnis)? onFertig;

  final TrainingPlan plan;
  final List<String> sportarten;
  final Schwerpunkt? schwerpunkt;

  @override
  State<TrainingPlanEditor> createState() => _TrainingPlanEditorState();
}

class _TrainingPlanEditorState extends State<TrainingPlanEditor> {
  late final _namen = [
    for (final t in widget.plan.tage) TextEditingController(text: dayName(t)),
  ];
  late final _uebungen = [
    for (var i = 0; i < 7; i++) [...widget.plan.uebungenAm(i)],
  ];
  late final _sportarten = [...widget.sportarten];
  late Schwerpunkt? _schwerpunkt = widget.schwerpunkt;
  (int, int)? _offen;

  /// The day shown under the week strip: today when the page opens.
  late int _tag = widget.startTag ?? DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();
    for (final c in _namen) {
      c.addListener(() => setState(() {}));
    }
  }

  /// Training on this day: a name that is not a rest day, or exercises.
  bool _trainiert(int i) {
    final n = _namen[i].text.trim().toLowerCase();
    final ruhe =
        n.isEmpty ||
        n.startsWith('ruhe') ||
        n.startsWith('frei') ||
        n.startsWith('pause');
    return !ruhe || _uebungen[i].isNotEmpty;
  }

  @override
  void dispose() {
    for (final c in _namen) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _speichern() async {
    final r = _ergebnis();
    final fertig = widget.onFertig;
    if (fertig != null) await fertig(r);
    if (mounted) Navigator.of(context).pop<PlanErgebnis>(r);
  }

  PlanErgebnis _ergebnis() => (
    plan: TrainingPlan.aus(
      [for (final c in _namen) c.text],
      [
        for (final d in _uebungen)
          [
            for (final u in d)
              if (u.name.trim().isNotEmpty) u.copyWith(name: u.name.trim()),
          ],
      ],
    ),
    sportarten: _sportarten,
    schwerpunkt: _schwerpunkt,
  );

  Future<void> _eigeneSportart() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CoachStyle.cardBright,
        title: const Text('Eigene Sportart', style: tTitel),
        content: EditorField(
          key: const ValueKey('eigene-sportart'),
          controller: c,
          hint: 'z. B. Calisthenics',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(c.text.trim()),
            child: const Text(
              'Dazu',
              style: TextStyle(color: CoachStyle.goldLight),
            ),
          ),
        ],
      ),
    );
    c.dispose();
    if (name != null && name.isNotEmpty && !_sportarten.contains(name)) {
      setState(() => _sportarten.add(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final alle = [
      ...sportartenAuswahl,
      for (final s in _sportarten)
        if (!sportartenAuswahl.contains(s)) s,
    ];
    return EditorPage(
      title: 'Dein Trainingsplan',
      intro:
          'Einmal festlegen, dann läuft alles von selbst weiter. Tippe einen '
          'Tag an, gib ihm einen Namen, gern mit Uhrzeit wie „Push 17:30“, '
          'und trag die Übungen ein. Lass einen Tag leer, wenn er frei ist.',
      glas: true,
      onSave: _speichern,
      children: [
        GlasBox(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TLabel('Deine Sportarten'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in alle)
                    TChip(
                      s,
                      key: ValueKey('sportart-$s'),
                      an: _sportarten.contains(s),
                      onTap: () => setState(
                        () => _sportarten.contains(s)
                            ? _sportarten.remove(s)
                            : _sportarten.add(s),
                      ),
                    ),
                  TChip(
                    '+ Eigene',
                    key: const ValueKey('sportart-eigene'),
                    an: false,
                    onTap: _eigeneSportart,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const TLabel('Dein Schwerpunkt'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in Schwerpunkt.values)
                    TChip(
                      s.label,
                      key: ValueKey('plan-schwerpunkt-${s.name}'),
                      an: s == _schwerpunkt,
                      onTap: () => setState(() => _schwerpunkt = s),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              CoachZeile(
                text: _sportarten.length > 1
                    ? '${_sportarten.join(' und ')}${_schwerpunkt == null ? '' : ' mit Schwerpunkt ${_schwerpunkt!.label}'}: '
                          'Ich achte darauf, dass sich das nicht ausbremst, und '
                          'zeige dir die Balance in der Woche.'
                    : 'Wählst du mehr als eine Sportart, zeige ich dir in der '
                          'Woche die Balance zwischen Kraft und Ausdauer.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const TLabel('Deine Woche'),
        const SizedBox(height: 8),
        _wochenLeiste(),
        const SizedBox(height: 12),
        _tagKarte(_tag),
      ],
    );
  }

  /// Mo to So: training days glow gold, the chosen day is framed.
  Widget _wochenLeiste() => Row(
    children: [
      for (var i = 0; i < 7; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: _TagKnopf(
            key: ValueKey('plan-wochentag-$i'),
            kurz: wochentage[i].substring(0, 2),
            training: _trainiert(i),
            gewaehlt: i == _tag,
            onTap: () => setState(() {
              _tag = i;
              _offen = null;
            }),
          ),
        ),
      ],
    ],
  );

  Widget _tagKarte(int i) => GlasBox(
    key: ValueKey('plan-tag-edit-$i'),
    art: _trainiert(i) ? GlasArt.gold : GlasArt.normal,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(wochentage[i], style: Glas.tLabel),
        const SizedBox(height: 8),
        EditorField(
          key: ValueKey('plan-name-$i'),
          controller: _namen[i],
          label: 'Name',
          hint: i == 0 ? 'z. B. Push 17:30' : (i == 1 ? 'z. B. Ruhe' : null),
        ),
        const SizedBox(height: 8),
        for (var j = 0; j < _uebungen[i].length; j++) ...[
          _zeile(i, j),
          if (_offen == (i, j))
            UebungOptionen(
              key: ValueKey('uebung-optionen-$i-$j'),
              uebung: _uebungen[i][j],
              onChanged: (u) => setState(() => _uebungen[i][j] = u),
              onEntfernen: () => setState(() {
                _uebungen[i].removeAt(j);
                _offen = null;
              }),
            ),
          const SizedBox(height: 6),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TLink(
            '+ Übung',
            key: ValueKey('plan-add-$i'),
            onTap: () => setState(() {
              _uebungen[i].add(const PlanUebung(name: ''));
              _offen = (i, _uebungen[i].length - 1);
            }),
          ),
        ),
      ],
    ),
  );

  Widget _zeile(int i, int j) {
    final u = _uebungen[i][j];
    final offen = _offen == (i, j);
    return InkWell(
      key: ValueKey('plan-uebung-$i-$j'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _offen = offen ? null : (i, j)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0x14FFECDC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: offen ? Glas.goldEdge : Glas.edge),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Glas.goldEdge),
              ),
              child: Text(
                '${j + 1}',
                style: Glas.tLabel.copyWith(fontSize: 11),
              ),
            ),
            Expanded(
              child: Text(
                u.name.isEmpty ? 'Neue Übung' : u.name,
                style: Glas.tText.copyWith(
                  fontSize: 14,
                  color: u.name.isEmpty ? Glas.soft : Glas.text,
                ),
              ),
            ),
            Flexible(
              child: Text(
                offen ? u.kurz : '${u.kurz} ›',
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: Glas.tSoft.copyWith(fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The settings of one exercise ("schlau denken", Phillip 2026-10-26).
class UebungOptionen extends StatefulWidget {
  const UebungOptionen({
    super.key,
    required this.uebung,
    required this.onChanged,
    required this.onEntfernen,
  });

  final PlanUebung uebung;
  final ValueChanged<PlanUebung> onChanged;
  final VoidCallback onEntfernen;

  @override
  State<UebungOptionen> createState() => _UebungOptionenState();
}

class _UebungOptionenState extends State<UebungOptionen> {
  late final _name = TextEditingController(text: widget.uebung.name);
  late final _notiz = TextEditingController(text: widget.uebung.notiz);

  PlanUebung get u => widget.uebung;
  void _neu(PlanUebung x) => widget.onChanged(x);

  @override
  void dispose() {
    _name.dispose();
    _notiz.dispose();
    super.dispose();
  }

  Widget _reihe(String titel, Widget inhalt) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(titel, style: tSoft),
          ),
        ),
        Expanded(child: inhalt),
      ],
    ),
  );

  Widget _chips<T>(
    List<T> werte,
    T an,
    String Function(T) text,
    void Function(T) wahl,
    String key,
  ) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      for (final w in werte)
        TChip(
          text(w),
          key: ValueKey('$key-${text(w)}'),
          klein: true,
          an: w == an,
          onTap: () => wahl(w),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final art = u.art;
    final erklaerung = switch (u.steigerung) {
      Steigerung.coach =>
        u.modus == WdhModus.bereich
            ? 'Schaffst du in allen Sätzen ${u.wdhBis} Wdh, kommt mehr Gewicht '
                  'und du startest wieder bei ${u.wdhVon}.'
            : 'Der Coach schlägt den nächsten Schritt aus deinen Werten und '
                  'deinem Gefühl vor.',
      Steigerung.selbst =>
        'Du legst nach jedem Training dein nächstes Ziel selbst fest.',
      _ =>
        'Erhöht sich automatisch, wenn alle Sätze geschafft sind und es '
            'sich nicht schwer angefühlt hat.',
    };
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF120D09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoachStyle.goldEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditorField(
            key: const ValueKey('uebung-name'),
            controller: _name,
            label: 'Übung',
            hint: 'z. B. Bankdrücken',
          ).withListener((t) => _neu(u.copyWith(name: t))),
          const SizedBox(height: 10),
          _reihe(
            'Art',
            _chips(UebungArt.values, art, (a) => a.label, (a) {
              _neu(
                u.copyWith(
                  art: a,
                  saetze: a == UebungArt.strecke
                      ? 1
                      : (u.saetze < 1 ? 3 : null),
                  wdhVon: a == UebungArt.zeit
                      ? 30
                      : (a == UebungArt.strecke ? 0 : 8),
                  wdhBis: a == UebungArt.zeit
                      ? 30
                      : (a == UebungArt.strecke ? 0 : 8),
                  modus: WdhModus.fest,
                  wertLeeren: a.wertEinheit == null,
                  pause: a == UebungArt.strecke
                      ? 0
                      : (u.pause == 0 ? 90 : null),
                  aufwaermen: a.wertEinheit == null || a == UebungArt.strecke
                      ? 0
                      : null,
                  jederSatz: const [],
                ),
              );
            }, 'art'),
          ),
          if (art != UebungArt.strecke)
            _reihe(
              'Sätze',
              Align(
                alignment: Alignment.centerLeft,
                child: TStepper(
                  key: const ValueKey('uebung-saetze'),
                  wert: u.saetze,
                  min: 1,
                  max: 10,
                  onChanged: (n) => _neu(
                    u.copyWith(
                      saetze: n,
                      jederSatz: u.jederSatz.isEmpty
                          ? null
                          : [
                              for (var k = 0; k < n; k++)
                                k < u.jederSatz.length
                                    ? u.jederSatz[k]
                                    : u.jederSatz.last,
                            ],
                    ),
                  ),
                ),
              ),
            ),
          if (art == UebungArt.strecke) ...[
            _reihe(
              'Strecke',
              SizedBox(
                width: 100,
                child: ZahlFeld(
                  key: const ValueKey('uebung-wert'),
                  wert: u.wert,
                  einheit: 'km',
                  onChanged: (v) =>
                      _neu(u.copyWith(wert: v, wertLeeren: v == null)),
                ),
              ),
            ),
            _reihe(
              'Zeit (frei)',
              SizedBox(
                width: 100,
                child: ZahlFeld(
                  key: const ValueKey('uebung-von'),
                  wert: u.wdhVon == 0 ? null : u.wdhVon.toDouble(),
                  einheit: 'min',
                  dezimal: false,
                  onChanged: (v) => _neu(
                    u.copyWith(
                      wdhVon: v?.round() ?? 0,
                      wdhBis: v?.round() ?? 0,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (art == UebungArt.zeit)
            _reihe(
              'Dauer pro Satz',
              SizedBox(
                width: 100,
                child: ZahlFeld(
                  key: const ValueKey('uebung-von'),
                  wert: u.wdhVon.toDouble(),
                  einheit: 'Sekunden',
                  dezimal: false,
                  onChanged: (v) => _neu(
                    u.copyWith(
                      wdhVon: v?.round() ?? 30,
                      wdhBis: v?.round() ?? 30,
                    ),
                  ),
                ),
              ),
            )
          else if (!u.jederSatz.isNotEmpty)
            _reihe(
              'Wieder­holungen',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _chips(
                    WdhModus.values,
                    u.modus,
                    (m) => m.label,
                    (m) => _neu(
                      u.copyWith(
                        modus: m,
                        wdhBis: m == WdhModus.bereich && u.wdhBis <= u.wdhVon
                            ? u.wdhVon + 2
                            : (m == WdhModus.fest ? u.wdhVon : null),
                      ),
                    ),
                    'modus',
                  ),
                  const SizedBox(height: 6),
                  if (u.modus == WdhModus.rir)
                    Text(
                      'So viele, wie sauber gehen. 1 bis 2 hast du noch im Tank.',
                      style: tSoft.copyWith(color: CoachStyle.inkSoft),
                    )
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: ZahlFeld(
                            key: const ValueKey('uebung-von'),
                            wert: u.wdhVon.toDouble(),
                            dezimal: false,
                            onChanged: (v) {
                              final n = v?.round() ?? u.wdhVon;
                              _neu(
                                u.copyWith(
                                  wdhVon: n,
                                  wdhBis: u.modus == WdhModus.fest ? n : null,
                                ),
                              );
                            },
                          ),
                        ),
                        if (u.modus == WdhModus.bereich) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('bis', style: tSoft),
                          ),
                          SizedBox(
                            width: 64,
                            child: ZahlFeld(
                              key: const ValueKey('uebung-bis'),
                              wert: u.wdhBis.toDouble(),
                              dezimal: false,
                              onChanged: (v) => _neu(
                                u.copyWith(wdhBis: v?.round() ?? u.wdhBis),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          if ((art == UebungArt.gewicht || art == UebungArt.zusatzgewicht) &&
              u.jederSatz.isEmpty)
            _reihe(
              art == UebungArt.gewicht ? 'Startgewicht' : 'Zusatz',
              SizedBox(
                width: 100,
                child: ZahlFeld(
                  key: const ValueKey('uebung-wert'),
                  wert: u.wert,
                  einheit: 'kg',
                  onChanged: (v) =>
                      _neu(u.copyWith(wert: v, wertLeeren: v == null)),
                ),
              ),
            ),
          if (art != UebungArt.strecke)
            _reihe(
              'Pause',
              _chips(
                const [60, 90, 120, 180],
                u.pause,
                (p) => '$p s',
                (p) => _neu(u.copyWith(pause: p)),
                'pause',
              ),
            ),
          if (art == UebungArt.gewicht || art == UebungArt.zusatzgewicht)
            _reihe(
              'Aufwärmsätze',
              Align(
                alignment: Alignment.centerLeft,
                child: TStepper(
                  key: const ValueKey('uebung-aufw'),
                  wert: u.aufwaermen,
                  min: 0,
                  max: 3,
                  onChanged: (n) => _neu(u.copyWith(aufwaermen: n)),
                ),
              ),
            ),
          if (art != UebungArt.strecke)
            _reihe(
              'Steigern',
              _chips(
                Steigerung.values,
                u.steigerung,
                (s) => s.label,
                (s) => _neu(u.copyWith(steigerung: s)),
                'steig',
              ),
            ),
          if (art != UebungArt.strecke && art != UebungArt.zeit)
            _reihe(
              'Jeder Satz anders',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TChip(
                    u.jederSatz.isEmpty ? 'Aus' : 'An',
                    key: const ValueKey('uebung-jeder'),
                    klein: true,
                    an: u.jederSatz.isNotEmpty,
                    onTap: () => _neu(
                      u.copyWith(
                        jederSatz: u.jederSatz.isNotEmpty
                            ? const []
                            : [
                                for (var k = 0; k < u.saetze; k++)
                                  SatzWert(
                                    u.hatWert ? u.wert : null,
                                    u.wdhVon.toDouble(),
                                  ),
                              ],
                      ),
                    ),
                  ),
                  for (var k = 0; k < u.jederSatz.length; k++)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text('Satz ${k + 1}', style: tSoft),
                          ),
                          if (u.hatWert) ...[
                            Expanded(
                              child: ZahlFeld(
                                key: ValueKey('jeder-wert-$k'),
                                wert: u.jederSatz[k].wert,
                                einheit: 'kg',
                                onChanged: (v) => _neu(
                                  u.copyWith(
                                    jederSatz: [
                                      for (
                                        var x = 0;
                                        x < u.jederSatz.length;
                                        x++
                                      )
                                        x == k
                                            ? SatzWert(v, u.jederSatz[x].menge)
                                            : u.jederSatz[x],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: ZahlFeld(
                              key: ValueKey('jeder-menge-$k'),
                              wert: u.jederSatz[k].menge,
                              einheit: 'Wdh',
                              dezimal: false,
                              onChanged: (v) => _neu(
                                u.copyWith(
                                  jederSatz: [
                                    for (var x = 0; x < u.jederSatz.length; x++)
                                      x == k
                                          ? SatzWert(u.jederSatz[x].wert, v)
                                          : u.jederSatz[x],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          EditorField(
            key: const ValueKey('uebung-notiz'),
            controller: _notiz,
            label: 'Notiz',
            hint: 'z. B. Bank auf Stufe 3, enger Griff',
          ).withListener((t) => _neu(u.copyWith(notiz: t))),
          const SizedBox(height: 8),
          if (art != UebungArt.strecke)
            Text(
              erklaerung,
              style: tSoft.copyWith(fontSize: 11.5, color: CoachStyle.inkSoft),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TLink(
              'Übung entfernen',
              key: const ValueKey('uebung-entfernen'),
              soft: true,
              onTap: widget.onEntfernen,
            ),
          ),
        ],
      ),
    );
  }
}

extension on EditorField {
  /// Reports every change of the text.
  Widget withListener(ValueChanged<String> onChanged) =>
      _Mithoerer(controller: controller, onChanged: onChanged, child: this);
}

class _Mithoerer extends StatefulWidget {
  const _Mithoerer({
    required this.controller,
    required this.onChanged,
    required this.child,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Widget child;

  @override
  State<_Mithoerer> createState() => _MithoererState();
}

class _MithoererState extends State<_Mithoerer> {
  late String _alt = widget.controller.text;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_hoer);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_hoer);
    super.dispose();
  }

  void _hoer() {
    if (widget.controller.text == _alt) return;
    _alt = widget.controller.text;
    widget.onChanged(_alt);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One day in the week strip.
class _TagKnopf extends StatelessWidget {
  const _TagKnopf({
    super.key,
    required this.kurz,
    required this.training,
    required this.gewaehlt,
    required this.onTap,
  });

  final String kurz;
  final bool training;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: training ? Glas.goldFill : Glas.fill,
        border: Border.all(
          color: gewaehlt
              ? CoachStyle.goldLight
              : (training ? Glas.goldEdge : Glas.edge),
          width: gewaehlt ? 1.6 : 1,
        ),
        boxShadow: training
            ? const [BoxShadow(color: Color(0x40E0BF7E), blurRadius: 12)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kurz,
            style: Glas.tText.copyWith(
              fontSize: 13,
              color: training ? Glas.text : Glas.soft,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: training ? CoachStyle.goldGradient : null,
              color: training ? null : const Color(0x33FFECDC),
            ),
          ),
        ],
      ),
    ),
  );
}
