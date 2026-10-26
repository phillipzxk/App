import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'training_data.dart';
import 'training_logik.dart';
import 'training_widgets.dart';

/// Idea 9: one exercise and one set at a time, big numbers with −/+,
/// then the rest ring with the next set. Everything goes into the same
/// session as the normal view.
class TrainingsModus extends StatefulWidget {
  const TrainingsModus({super.key, required this.session, this.onForm});

  final HeuteSession session;

  /// Films the current exercise (idea 10).
  final void Function(int i)? onForm;

  @override
  State<TrainingsModus> createState() => _TrainingsModusState();
}

class _TrainingsModusState extends State<TrainingsModus> {
  late int _ex = _ersteOffene();
  int _satz = 0;
  bool _pause = false;

  HeuteSession get s => widget.session;

  int _ersteOffene() {
    for (var i = 0; i < widget.session.logs.length; i++) {
      final l = widget.session.logs[i];
      if (l.fertige.length < l.saetze.length) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    final l = s.logs.isEmpty ? null : s.logs[_ex];
    if (l != null) {
      _satz = l.saetze
          .indexWhere((x) => !x.fertig)
          .clamp(0, l.saetze.length - 1);
    }
    s.addListener(_neu);
  }

  @override
  void dispose() {
    s.removeListener(_neu);
    super.dispose();
  }

  void _neu() {
    if (!mounted) return;
    setState(() {
      if (_pause && s.pauseFuer == null) _pause = false;
    });
  }

  void _geschafft() {
    final l = s.logs[_ex];
    if (!l.saetze[_satz].fertig) s.abhaken(_ex, _satz);
    if (_satz + 1 < l.saetze.length) {
      _satz++;
    } else {
      _ex++;
      _satz = 0;
    }
    setState(() => _pause = s.pauseFuer != null && _ex < s.logs.length);
  }

  void _aendern(bool menge, double d) {
    final v = menge
        ? s.logs[_ex].saetze[_satz].menge
        : s.logs[_ex].saetze[_satz].wert;
    final neu = ((v ?? 0) + d).clamp(0, 9999).toDouble();
    s.setWert(_ex, _satz, neu, menge: menge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachStyle.night,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: CoachStyle.nightGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _ex >= s.logs.length
                    ? _ende()
                    : (_pause ? _pausen() : _satzSeite()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kopf(String links) => Row(
    children: [
      TLabel(links),
      const Spacer(),
      TLink(
        'Schließen',
        key: const ValueKey('modus-zu'),
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );

  Widget _ende() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const TLabel('Alle Übungen durch'),
      const SizedBox(height: 10),
      GoldText('Stark.', style: tTitel.copyWith(fontSize: 30)),
      const SizedBox(height: 8),
      Text(
        'Zurück in der Übersicht drückst du „Training fertig“.',
        style: tSoft,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      MainButton(
        key: const ValueKey('modus-uebersicht'),
        label: 'Zur Übersicht',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );

  Widget _pausen() {
    final l = s.logs[_ex];
    final u = s.plan[_ex];
    final g = s.logs[(_satz == 0 && _ex > 0) ? _ex - 1 : _ex];
    final gi = (_satz == 0 && _ex > 0) ? _ex - 1 : _ex;
    return Column(
      children: [
        _kopf('Pause'),
        const Spacer(),
        PausenRing(rest: s.pauseRest, gesamt: s.plan[s.pauseFuer ?? _ex].pause),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: tSoft.copyWith(fontSize: 13),
            children: [
              const TextSpan(text: 'Als Nächstes: '),
              TextSpan(
                text: '${u.name}, Satz ${_satz + 1}',
                style: const TextStyle(
                  color: CoachStyle.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: ' · ${satzText(u.art, l.saetze[_satz].werte)}'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Text('Wie war ${g.name}?', style: tSoft),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final f in const ['leicht', 'passt', 'schwer']) ...[
              Expanded(
                child: TChip(
                  f,
                  key: ValueKey('modus-gefuehl-$f'),
                  an: g.gefuehl == f,
                  onTap: () => s.gefuehl(gi, f),
                ),
              ),
              if (f != 'schwer') const SizedBox(width: 6),
            ],
          ],
        ),
        const Spacer(),
        TGhost(
          'Pause überspringen',
          key: const ValueKey('modus-pause-weg'),
          onTap: () {
            s.pauseStopp();
            setState(() => _pause = false);
          },
        ),
      ],
    );
  }

  Widget _satzSeite() {
    final l = s.logs[_ex];
    final u = s.plan[_ex];
    final satz = l.saetze[_satz];
    final gross = tTitel.copyWith(
      fontSize: 52,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    Widget stepper(
      String key,
      double? v,
      String einheit,
      double schritt,
      bool menge,
    ) => Row(
      children: [
        _Knopf(
          key: ValueKey('modus-$key-minus'),
          text: '−${zahl(schritt)}',
          onTap: () => _aendern(menge, -schritt),
        ),
        Expanded(
          child: Column(
            children: [
              GoldText(v == null ? '–' : zahl(v), style: gross),
              Text(einheit, style: tSoft),
            ],
          ),
        ),
        _Knopf(
          key: ValueKey('modus-$key-plus'),
          text: '+${zahl(schritt)}',
          onTap: () => _aendern(menge, schritt),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kopf('Übung ${_ex + 1} von ${s.logs.length}'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var k = 0; k < s.logs.length; k++)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: k < _ex
                      ? CoachStyle.goldLight
                      : (k == _ex ? null : const Color(0xFF3A2E21)),
                  border: k == _ex
                      ? Border.all(color: CoachStyle.goldLight, width: 2)
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Center(child: GoldText(u.name, style: tTitel.copyWith(fontSize: 26))),
        const SizedBox(height: 4),
        Center(child: TLabel('Satz ${_satz + 1} von ${l.saetze.length}')),
        const Spacer(),
        if (u.art.wertEinheit != null) ...[
          stepper(
            'wert',
            satz.wert,
            u.art.wertEinheit!,
            u.art == UebungArt.strecke ? 0.5 : 2.5,
            false,
          ),
          const SizedBox(height: 18),
        ],
        stepper(
          'menge',
          satz.menge,
          u.art.mengeEinheit,
          u.art == UebungArt.zeit ? 5 : 1,
          true,
        ),
        const Spacer(),
        MainButton(
          key: const ValueKey('modus-geschafft'),
          label: 'Satz geschafft',
          onPressed: _geschafft,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.onForm != null && !u.art.ausdauer) ...[
              TLink('Form filmen', onTap: () => widget.onForm!(_ex)),
              const SizedBox(width: 18),
            ],
            TLink(
              'Übung überspringen',
              key: const ValueKey('modus-uebung-weg'),
              soft: true,
              onTap: () => setState(() {
                _ex++;
                _satz = 0;
              }),
            ),
          ],
        ),
        if (_ex + 1 < s.logs.length) ...[
          const SizedBox(height: 10),
          TKarte(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              'Danach: ${s.plan[_ex + 1].name} · ${s.logs[_ex + 1].saetze.length} Sätze',
              style: tSoft,
            ),
          ),
        ],
      ],
    );
  }
}

class _Knopf extends StatelessWidget {
  const _Knopf({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 58,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoachStyle.goldEdge),
        color: const Color(0xFF1A140E),
      ),
      child: Text(text, style: tTitel.copyWith(color: CoachStyle.goldLight)),
    ),
  );
}
