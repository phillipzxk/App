import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bereiche/glas.dart';
import '../business/business_bilder.dart' show GoldBalken, Striche;
import '../checkin/checkin.dart';
import '../data/user_profile.dart';
import '../ernaehrung/ernaehrung_coach.dart' show fotoAufnahme;
import '../future_me/future_me_data.dart' show WochenFoto;
import '../mindset/dranbleiben.dart' show GoldRing;
import '../mindset/mindset_logik.dart' show tageSeit;
import '../mindset/mindset_ui.dart';
import '../produktiv/produktiv_seiten.dart' show EinundzwanzigPunkte;
import '../ui/coach_style.dart';
import 'persoenlich_coach.dart';
import 'persoenlich_data.dart';
import 'persoenlich_logik.dart';

/// What every Persönlichkeit page needs.
class PersoenlichUmfeld {
  const PersoenlichUmfeld({
    required this.stand,
    required this.profile,
    required this.coach,
    required this.jetzt,
    this.fotos = const [],
    this.onInsTraining,
  });

  final PersoenlichStand stand;
  final UserProfile profile;
  final PersoenlichCoach coach;
  final DateTime Function() jetzt;

  /// The weekly progress photos (Fortschrittsfoto), oldest first.
  final List<WochenFoto> fotos;

  /// Puts the posture exercises into the training plan.
  final Future<void> Function(List<Tipp> uebungen)? onInsTraining;

  String get heute => dayKey(jetzt());
  String get kontext => persoenlichKontext(stand.d, jetzt());
}

abstract class _Seite<T extends StatefulWidget> extends State<T> {
  PersoenlichUmfeld get u;
  PersoenlichDaten get d => u.stand.d;
  bool busy = false;

  Future<void> warte(Future<void> Function() f) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void offline() {
    if (mounted) hinweis(context, 'Der Coach ist gerade nicht erreichbar.');
  }

  Widget inhalt(BuildContext context);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [inhalt(context)],
    ),
  );
}

Widget _spalte(List<Widget> c) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: c);

Widget _gross(String t, {double size = 20}) => Text(
  t,
  style: CoachStyle.title.copyWith(
    fontSize: size,
    height: 1.25,
    color: Glas.text,
  ),
);

Widget _punkt(int n, Tipp t, {bool gold = true}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gold ? CoachStyle.goldGradient : null,
          border: gold ? null : Border.all(color: const Color(0x44FFEECD)),
        ),
        child: Text(
          '$n',
          style: Glas.tLabel.copyWith(
            color: gold ? CoachStyle.goldInk : Glas.label,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.titel,
              style: Glas.tText.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (t.text.isNotEmpty) Text(t.text, style: Glas.tSoft),
          ],
        ),
      ),
    ],
  ),
);

String _datum(String tag) {
  final t = DateTime.parse(tag);
  return '${t.day}.${t.month}.';
}

/// A multiple choice question; [onRichtig] when the right answer is tapped.
class QuizKarte extends StatefulWidget {
  const QuizKarte({
    super.key,
    required this.quiz,
    required this.onRichtig,
    this.prefix = 'quiz',
    this.onFalsch,
  });
  final Quiz quiz;
  final VoidCallback onRichtig;
  final VoidCallback? onFalsch;
  final String prefix;

  @override
  State<QuizKarte> createState() => _QuizKarteState();
}

class _QuizKarteState extends State<QuizKarte> {
  int? _wahl;

  @override
  void didUpdateWidget(QuizKarte old) {
    super.didUpdateWidget(old);
    if (old.quiz.frage != widget.quiz.frage) _wahl = null;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quiz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          q.frage,
          style: Glas.tText.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        for (var k = 0; k < q.antworten.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              key: ValueKey('${widget.prefix}-$k'),
              onTap: () {
                if (_wahl == q.richtig) return;
                setState(() => _wahl = k);
                if (k == q.richtig) {
                  widget.onRichtig();
                } else {
                  widget.onFalsch?.call();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: _wahl == k && k == q.richtig
                      ? CoachStyle.goldGradient
                      : null,
                  color: _wahl == k && k != q.richtig
                      ? const Color(0x22FF8A7A)
                      : const Color(0x0FFFECC8),
                  border: Border.all(color: const Color(0x2EFFEECD)),
                ),
                child: Text(
                  q.antworten[k],
                  style: Glas.tText.copyWith(
                    fontSize: 14.5,
                    color: _wahl == k && k == q.richtig
                        ? CoachStyle.goldInk
                        : Glas.text,
                  ),
                ),
              ),
            ),
          ),
        if (_wahl != null && _wahl != q.richtig)
          Text(
            'Nicht ganz. Lies noch mal und versuch es neu.',
            style: Glas.tSoft,
          ),
      ],
    );
  }
}

// ------------------------------------------------------------ Pflege-Routine

class PflegeSeite extends StatefulWidget {
  const PflegeSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<PflegeSeite> createState() => _PflegeSeiteState();
}

class _PflegeSeiteState extends _Seite<PflegeSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;
  final _neu = TextEditingController();
  bool _abends = false;

  @override
  void dispose() {
    _neu.dispose();
    super.dispose();
  }

  Widget _liste(String label, String rechts, List<String> schritte, String p) {
    final an = d.pflegeAm(u.heute);
    return Block(
      art: p == 'm' ? GlasArt.gold : GlasArt.normal,
      label: label,
      rechts: rechts,
      children: [
        for (var i = 0; i < schritte.length; i++)
          Row(
            children: [
              Expanded(
                child: HakenZeile(
                  key: ValueKey('pflege-$p$i'),
                  an: an.contains('$p$i'),
                  titel: schritte[i],
                  onTap: () =>
                      u.stand.setze(d.pflegeUmschalten(u.heute, '$p$i')),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 15, color: Glas.soft),
                onPressed: () {
                  final l = [...schritte]..removeAt(i);
                  u.stand.setze(
                    p == 'm'
                        ? d.copyWith(morgens: l, pflege: const {})
                        : d.copyWith(abends: l, pflege: const {}),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget inhalt(BuildContext context) {
    final jetzt = u.jetzt();
    final stueck = pflegeAmStueck(d, jetzt);
    final vergessen = meistVergessen(d, jetzt);
    return _spalte([
      _liste(
        'Morgens',
        '${morgensErledigt(d, u.heute)} von ${d.morgens.length}',
        d.morgens,
        'm',
      ),
      _liste(
        'Abends',
        '${abendsErledigt(d, u.heute)} von ${d.abends.length}',
        d.abends,
        'a',
      ),
      Block(
        label: 'Schritt dazu',
        children: [
          Row(
            children: [
              GlasChip(
                label: 'Morgens',
                an: !_abends,
                onTap: () => setState(() => _abends = false),
              ),
              const SizedBox(width: 8),
              GlasChip(
                label: 'Abends',
                an: _abends,
                onTap: () => setState(() => _abends = true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlasFeld(
            key: const ValueKey('pflege-feld'),
            controller: _neu,
            hint: 'z. B. Augencreme',
          ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('pflege-dazu'),
            label: 'Dazu',
            ghost: true,
            onTap: () {
              final t = _neu.text.trim();
              if (t.isEmpty) return;
              u.stand.setze(
                _abends
                    ? d.copyWith(abends: [...d.abends, t])
                    : d.copyWith(morgens: [...d.morgens, t]),
              );
              _neu.clear();
            },
          ),
        ],
      ),
      Block(
        label: 'Gehalten',
        rechts: '$stueck Tage am Stück',
        children: [
          EinundzwanzigPunkte(n: pflege21(d, jetzt).where((x) => x).length),
          if (vergessen != null) ...[
            const SizedBox(height: 12),
            CoachZeile(
              '$vergessen vergisst du am häufigsten. Stell es dahin, wo du '
              'morgens sowieso hinschaust.',
            ),
          ],
        ],
      ),
    ]);
  }
}

// ------------------------------------------------------------ Lern-Ziel + Kurs

/// Fetches the lesson's text and question when it opens.
Future<void> ladeLektion(PersoenlichUmfeld u) async {
  final k = u.stand.d.kurs;
  final l = k?.aktuelle;
  if (k == null || l == null || l.text != null) return;
  final r = await u.coach.lektion(u.profile, k.skill, l.titel, k.erreicht + 1);
  if (r == null) return;
  final neu = u.stand.d.kurs!;
  if (neu.erreicht != k.erreicht) return;
  await u.stand.setze(
    u.stand.d.copyWith(
      kurs: neu.mitLektion(
        k.erreicht,
        Lektion(titel: l.titel, text: r.text, quiz: r.quiz),
      ),
    ),
  );
}

class _KursStart extends StatefulWidget {
  const _KursStart({required this.u});
  final PersoenlichUmfeld u;

  @override
  State<_KursStart> createState() => _KursStartState();
}

class _KursStartState extends _Seite<_KursStart> {
  @override
  PersoenlichUmfeld get u => widget.u;
  final _skill = TextEditingController();

  @override
  void dispose() {
    _skill.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) => Block(
    art: GlasArt.gold,
    label: 'Welchen Skill willst du lernen?',
    children: [
      GlasFeld(
        key: const ValueKey('kurs-feld'),
        controller: _skill,
        hint: 'z. B. Rhetorik',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in const [
            'Rhetorik',
            'Ausstrahlung',
            'Kochen',
            'Englisch',
          ])
            GlasChip(
              label: v,
              an: _skill.text == v,
              onTap: () => setState(() => _skill.text = v),
            ),
        ],
      ),
      const SizedBox(height: 10),
      GlasKnopf(
        key: const ValueKey('kurs-start'),
        label: busy ? 'Einen Moment …' : 'Kurs bauen',
        onTap: busy
            ? null
            : () => warte(() async {
                final s = _skill.text.trim();
                if (s.isEmpty) return;
                final l = await u.coach.kurs(u.profile, s);
                if (l == null) return offline();
                await u.stand.setze(
                  d.copyWith(
                    kurs: Kurs(
                      skill: s,
                      lektionen: [for (final t in l) Lektion(titel: t)],
                    ),
                  ),
                );
                await ladeLektion(u);
              }),
      ),
    ],
  );
}

/// The current lesson with its question; right answer opens the next.
class _LektionBlock extends StatefulWidget {
  const _LektionBlock({required this.u});
  final PersoenlichUmfeld u;

  @override
  State<_LektionBlock> createState() => _LektionBlockState();
}

class _LektionBlockState extends _Seite<_LektionBlock> {
  @override
  PersoenlichUmfeld get u => widget.u;

  @override
  void initState() {
    super.initState();
    final l = d.kurs?.aktuelle;
    if (l != null && l.text == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) warte(() => ladeLektion(u));
      });
    }
  }

  @override
  Widget inhalt(BuildContext context) {
    final k = d.kurs!;
    final l = k.aktuelle;
    if (l == null) {
      return Block(
        art: GlasArt.gold,
        children: [
          CoachZeile(
            'Alle ${k.lektionen.length} Lektionen geschafft. ${k.skill} sitzt.',
          ),
        ],
      );
    }
    return _spalte([
      Block(
        label: 'Lektion ${k.erreicht + 1} · ${l.titel}',
        children: [
          if (l.text == null)
            Text(
              busy
                  ? 'Die Lektion lädt …'
                  : 'Die Lektion kommt, sobald der Coach erreichbar ist.',
              style: Glas.tSoft,
            )
          else
            Text(
              l.text!,
              style: Glas.tText.copyWith(fontSize: 14.5, height: 1.5),
            ),
          if (l.text == null && !busy) ...[
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('lektion-laden'),
              label: 'Noch mal laden',
              ghost: true,
              onTap: () => warte(() => ladeLektion(u)),
            ),
          ],
        ],
      ),
      if (l.quiz != null)
        Block(
          label: 'Kurze Frage vom Coach',
          children: [
            QuizKarte(
              prefix: 'lektion-antwort',
              quiz: l.quiz!,
              onRichtig: () async {
                await u.stand.setze(d.copyWith(kurs: k.weiter()));
                if (mounted) {
                  hinweis(
                    this.context,
                    'Richtig. Die nächste Lektion ist offen.',
                  );
                }
                await ladeLektion(u);
              },
            ),
          ],
        ),
    ]);
  }
}

class LernSeite extends StatefulWidget {
  const LernSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<LernSeite> createState() => _LernSeiteState();
}

class _LernSeiteState extends _Seite<LernSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;
  Timer? _uhr;
  int _sek = 0;

  @override
  void dispose() {
    _uhr?.cancel();
    super.dispose();
  }

  void _start() {
    _uhr?.cancel();
    _uhr = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _sek++);
      if (_sek >= 60) {
        _sek = 0;
        final m = (d.lernMinuten[u.heute] ?? 0) + 1;
        u.stand.setze(d.copyWith(lernMinuten: {...d.lernMinuten, u.heute: m}));
        if (m >= 10) {
          _uhr?.cancel();
          _uhr = null;
          hinweis(
            context,
            '10 Minuten geschafft. Lern-Ziel für heute erreicht.',
          );
        }
      }
    });
    setState(() {});
  }

  @override
  Widget inhalt(BuildContext context) {
    final min = d.lernMinuten[u.heute] ?? 0;
    final rest = (10 * 60 - min * 60 - _sek).clamp(0, 600);
    final k = d.kurs;
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: 'Heute · 10 Minuten',
        children: [
          Center(
            child: GoldSchrift(
              '${rest ~/ 60}:${(rest % 60).toString().padLeft(2, '0')}',
              style: Glas.tBig.copyWith(fontSize: 46),
            ),
          ),
          const SizedBox(height: 8),
          GoldBalken(anteil: min / 10),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '$min von 10 Minuten${k == null ? '' : ' · ${k.skill}, Lektion ${k.erreicht + 1}'}',
              style: Glas.tSoft,
            ),
          ),
          const SizedBox(height: 12),
          GlasKnopf(
            key: const ValueKey('lern-start'),
            label: _uhr != null
                ? 'Pause'
                : min >= 10
                ? 'Weiterlernen, auch ohne Ziel'
                : min == 0
                ? 'Loslernen'
                : 'Weiterlernen',
            onTap: () {
              if (_uhr != null) {
                _uhr!.cancel();
                setState(() => _uhr = null);
              } else {
                _start();
              }
            },
          ),
        ],
      ),
      if (k == null) _KursStart(u: u) else _LektionBlock(u: u),
    ]);
  }
}

class KursSeite extends StatelessWidget {
  const KursSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final k = u.stand.d.kurs;
      if (k == null) return _KursStart(u: u);
      return _spalte([
        Block(
          art: GlasArt.gold,
          label: 'Dein Skill',
          rechts: '${k.erreicht} / ${k.lektionen.length}',
          children: [
            _gross(k.skill, size: 21),
            const SizedBox(height: 6),
            Text(
              'Jede Lektion baut auf der letzten auf. Die nächste öffnet sich '
              'erst, wenn die Frage sitzt.',
              style: Glas.tSoft,
            ),
          ],
        ),
        Block(
          children: [
            for (var j = 0; j < k.lektionen.length; j++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: j < k.erreicht
                            ? CoachStyle.goldGradient
                            : null,
                        border: j < k.erreicht
                            ? null
                            : Border.all(
                                color: j == k.erreicht
                                    ? CoachStyle.goldLight
                                    : const Color(0x33FFEECD),
                                width: 1.4,
                              ),
                      ),
                      child: j < k.erreicht
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: CoachStyle.goldInk,
                            )
                          : Text(
                              '${j + 1}',
                              style: Glas.tLabel.copyWith(
                                fontSize: 12,
                                color: j == k.erreicht ? Glas.label : Glas.soft,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        k.lektionen[j].titel,
                        style: Glas.tText.copyWith(
                          fontSize: 14.5,
                          color: j <= k.erreicht ? Glas.text : Glas.soft,
                        ),
                      ),
                    ),
                    if (j == k.erreicht) Text('heute', style: Glas.tLabel),
                  ],
                ),
              ),
          ],
        ),
        _LektionBlock(u: u),
        Center(
          child: TextButton(
            key: const ValueKey('kurs-neu'),
            onPressed: () => u.stand.setze(
              PersoenlichDaten.fromJson(
                {...u.stand.d.toJson()}..remove('kurs'),
              ),
            ),
            child: Text('Anderen Skill lernen', style: Glas.tSoft),
          ),
        ),
      ]);
    },
  );
}

// ------------------------------------------------------------ Stimme

/// Bars like a sound wave (still, the microphone comes with the phone app).
class Welle extends StatelessWidget {
  const Welle({super.key, this.n = 40, this.hoehe = 60});
  final int n;
  final double hoehe;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: hoehe,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var k = 0; k < n; k++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height:
                  hoehe *
                  (.18 + (((k * 1.7).remainder(3.1) - 1.55).abs() / 1.55) * .8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: CoachStyle.goldGradient,
              ),
            ),
          ),
      ],
    ),
  );
}

class StimmeSeite extends StatelessWidget {
  const StimmeSeite({super.key});

  @override
  Widget build(BuildContext context) => _spalte([
    Block(
      art: GlasArt.gold,
      children: [
        const Opacity(opacity: .5, child: Welle(n: 44)),
        const SizedBox(height: 14),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CoachStyle.goldLight, width: 2),
            ),
            child: const Icon(
              Icons.mic_none,
              color: CoachStyle.goldLight,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '30 Sekunden erzählen, wie dein Tag war',
            style: Glas.tSoft,
          ),
        ),
      ],
    ),
    Block(
      label: 'Darauf höre ich',
      children: [
        _punkt(
          1,
          const Tipp('Tempo', 'Wörter pro Minute, zu schnell wirkt nervös.'),
        ),
        _punkt(
          2,
          const Tipp(
            'Füllwörter',
            'Wie oft „ähm“ und „also“ kommen, Woche für Woche.',
          ),
        ),
        _punkt(
          3,
          const Tipp(
            'Sicherheit',
            'Ob das Satzende unten bleibt oder wie eine Frage klingt.',
          ),
        ),
      ],
    ),
    const Block(
      children: [
        CoachZeile(
          'Das Mikrofon kommt mit der Handy-Version. Dann nimmst du jeden Tag '
          '30 Sekunden auf und siehst, wie du sicherer klingst.',
        ),
      ],
    ),
  ]);
}

// ------------------------------------------------------------ Foto-Befunde

class _FotoKnopf extends StatelessWidget {
  const _FotoKnopf({
    required this.k,
    required this.label,
    required this.busy,
    required this.onFoto,
    this.ghost = false,
  });
  final String k;
  final String label;
  final bool busy;
  final bool ghost;
  final Future<void> Function(String bild) onFoto;

  @override
  Widget build(BuildContext context) => GlasKnopf(
    key: ValueKey(k),
    label: busy ? 'Der Coach schaut …' : label,
    icon: Icons.photo_camera_outlined,
    ghost: ghost,
    onTap: busy
        ? null
        : () async {
            final b = await fotoAufnahme();
            if (b != null) await onFoto(b);
          },
  );
}

class LookSeite extends StatefulWidget {
  const LookSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<LookSeite> createState() => _LookSeiteState();
}

class _LookSeiteState extends _Seite<LookSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;

  Future<void> _foto(String b) => warte(() async {
    final r = await u.coach.look(u.profile, b, u.heute);
    if (r == null) return offline();
    await u.stand.setze(d.copyWith(look: r));
  });

  @override
  Widget inhalt(BuildContext context) {
    final l = d.look;
    return _spalte([
      Block(
        art: GlasArt.gold,
        children: [
          const Center(
            child: Icon(
              Icons.face_retouching_natural,
              size: 56,
              color: CoachStyle.goldLight,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l == null
                  ? 'Ein Foto von vorn, gutes Licht. Keine Punktzahl, nur was du ändern kannst.'
                  : 'Foto vom ${_datum(l.tag)} · keine Punktzahl, nur was du ändern kannst',
              textAlign: TextAlign.center,
              style: Glas.tSoft,
            ),
          ),
        ],
      ),
      if (l != null)
        Block(
          label: 'Deine ${l.punkte.length} Hebel',
          children: [
            for (var k = 0; k < l.punkte.length; k++)
              _punkt(k + 1, l.punkte[k]),
          ],
        ),
      const SizedBox(height: 12),
      _FotoKnopf(
        k: 'look-foto',
        label: l == null
            ? 'Foto für die Analyse'
            : 'Neues Foto für die Analyse',
        ghost: l != null,
        busy: busy,
        onFoto: _foto,
      ),
    ]);
  }
}

Color? _farbe(String hex) {
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

class StilSeite extends StatefulWidget {
  const StilSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<StilSeite> createState() => _StilSeiteState();
}

class _StilSeiteState extends _Seite<StilSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;

  Future<void> _foto(String b) => warte(() async {
    final r = await u.coach.stil(u.profile, b, u.heute);
    if (r == null) return offline();
    await u.stand.setze(d.copyWith(stil: r));
  });

  @override
  Widget inhalt(BuildContext context) {
    final s = d.stil;
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: 'Stil-Check',
        rechts: s == null ? null : _datum(s.tag),
        children: [
          _gross(
            s?.titel ?? 'Foto vom Outfit, ich sage dir ehrlich, was passt.',
            size: s == null ? 16 : 20,
          ),
        ],
      ),
      if (s != null)
        Block(
          children: [
            if (s.passt != null) _punkt(1, Tipp('Passt', s.passt!)),
            if (s.aendern != null)
              _punkt(2, Tipp('Ändern', s.aendern!), gold: false),
          ],
        ),
      if (s != null && s.farben.isNotEmpty)
        Block(
          label: 'Farben, die dir stehen',
          children: [
            Row(
              children: [
                for (final f in s.farben)
                  if (_farbe(f) != null)
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _farbe(f),
                        border: Border.all(color: const Color(0x44FFEECD)),
                      ),
                    ),
              ],
            ),
          ],
        ),
      const SizedBox(height: 12),
      _FotoKnopf(
        k: 'stil-foto',
        label: 'Outfit von heute',
        ghost: s != null,
        busy: busy,
        onFoto: _foto,
      ),
    ]);
  }
}

class HaltungSeite extends StatefulWidget {
  const HaltungSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<HaltungSeite> createState() => _HaltungSeiteState();
}

class _HaltungSeiteState extends _Seite<HaltungSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;

  Future<void> _foto(String b) => warte(() async {
    final r = await u.coach.haltung(u.profile, b, u.heute);
    if (r == null) return offline();
    await u.stand.setze(d.copyWith(haltung: r, haltungImTraining: false));
  });

  @override
  Widget inhalt(BuildContext context) {
    final h = d.haltung;
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: 'Aus dem Foto',
        children: [
          _gross(
            h?.titel ?? 'Ein Foto von der Seite, ganz normal stehen.',
            size: h == null ? 16 : 18,
          ),
          if (h != null) ...[
            const SizedBox(height: 4),
            Text('Ganz normal und gut zu ändern.', style: Glas.tSoft),
          ],
        ],
      ),
      if (h != null)
        Block(
          label: '${h.punkte.length} Übungen · landen in deinem Training',
          children: [
            for (var k = 0; k < h.punkte.length; k++)
              _punkt(k + 1, h.punkte[k]),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('haltung-training'),
              label: d.haltungImTraining
                  ? 'In deinem Training'
                  : 'In mein Training übernehmen',
              icon: d.haltungImTraining ? Icons.check : null,
              ghost: d.haltungImTraining,
              onTap: d.haltungImTraining || u.onInsTraining == null
                  ? null
                  : () async {
                      await u.onInsTraining!(h.punkte);
                      await u.stand.setze(d.copyWith(haltungImTraining: true));
                      if (context.mounted) {
                        hinweis(
                          context,
                          'Die Übungen stehen jetzt an deinen Trainingstagen.',
                        );
                      }
                    },
            ),
          ],
        ),
      const SizedBox(height: 12),
      _FotoKnopf(
        k: 'haltung-foto',
        label: 'Foto von der Seite',
        ghost: h != null,
        busy: busy,
        onFoto: _foto,
      ),
    ]);
  }
}

class LookVerlaufSeite extends StatelessWidget {
  const LookVerlaufSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  Widget build(BuildContext context) {
    final f = [
      for (final x in u.fotos)
        if (x.bilder.isNotEmpty) x,
    ];
    Widget bild(WochenFoto w, String label, bool gold) => Expanded(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: gold ? CoachStyle.goldLight : const Color(0x33FFEECD),
                width: gold ? 1.6 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(
              base64Decode(w.bilder.values.first),
              fit: BoxFit.cover,
              width: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: gold ? Glas.tLabel : Glas.tSoft),
        ],
      ),
    );
    return _spalte([
      Block(
        children: [
          if (f.length < 2)
            Text(
              'Sobald du zwei Wochen dein Fortschrittsfoto gemacht hast, siehst '
              'du hier Woche 1 neben jetzt.',
              style: Glas.tSoft,
            )
          else
            Row(
              children: [
                bild(f.first, 'Woche 1', false),
                const SizedBox(width: 10),
                bild(f.last, 'Woche ${f.length}', true),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            'aus deinem Fortschrittsfoto, jede Woche eins',
            textAlign: TextAlign.center,
            style: Glas.tSoft,
          ),
        ],
      ),
    ]);
  }
}

// ------------------------------------------------------------ Pflege-Seite

class HautSeite extends StatefulWidget {
  const HautSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<HautSeite> createState() => _HautSeiteState();
}

class _HautSeiteState extends _Seite<HautSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;
  final _problem = TextEditingController();

  @override
  void dispose() {
    _problem.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final h = d.haut;
    if (h == null) {
      return _spalte([
        Block(
          art: GlasArt.gold,
          label: 'Was stört dich an deiner Haut?',
          children: [
            GlasFeld(
              key: const ValueKey('haut-feld'),
              controller: _problem,
              hint: 'z. B. unreine Stellen am Kinn',
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('haut-start'),
              label: busy ? 'Einen Moment …' : 'Plan über 8 Wochen',
              onTap: busy
                  ? null
                  : () => warte(() async {
                      final p = _problem.text.trim();
                      if (p.isEmpty) return;
                      final l = await u.coach.haut(u.profile, p);
                      if (l == null) return offline();
                      await u.stand.setze(
                        d.copyWith(
                          haut: HautPlan(problem: p, start: u.heute, phasen: l),
                        ),
                      );
                    }),
            ),
          ],
        ),
        const Block(
          children: [
            CoachZeile(
              'Bei echten Problemen, Schmerzen oder Entzündungen: geh zum Hautarzt.',
            ),
          ],
        ),
      ]);
    }
    final w = hautWoche(h, u.jetzt());
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: 'Dein Haut-Plan',
        rechts: '$w / 8',
        children: [
          _gross(h.problem, size: 19),
          const SizedBox(height: 10),
          Striche(n: w, von: 8),
          const SizedBox(height: 6),
          Text('Woche $w von 8', style: Glas.tSoft),
        ],
      ),
      Block(
        label: 'So läuft der Plan',
        children: [
          for (var k = 0; k < h.phasen.length; k++)
            _punkt(k + 1, h.phasen[k], gold: k * 8 ~/ h.phasen.length < w),
        ],
      ),
      const Block(
        children: [
          CoachZeile(
            'Wenn es nach 8 Wochen nicht besser ist oder weh tut: geh zum '
            'Hautarzt. Das kann ich nicht ersetzen.',
          ),
        ],
      ),
      Center(
        child: TextButton(
          key: const ValueKey('haut-neu'),
          onPressed: () => u.stand.setze(
            PersoenlichDaten.fromJson({...d.toJson()}..remove('haut')),
          ),
          child: Text('Neuer Plan', style: Glas.tSoft),
        ),
      ),
    ]);
  }
}

class FrisurSeite extends StatefulWidget {
  const FrisurSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<FrisurSeite> createState() => _FrisurSeiteState();
}

class _FrisurSeiteState extends _Seite<FrisurSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;
  final _text = TextEditingController();
  bool _neu = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _frag(String? bild) => warte(() async {
    final t = _text.text.trim();
    if (t.isEmpty && bild == null) return;
    final f = await u.coach.frisur(u.profile, t, bild);
    if (f == null) return offline();
    await u.stand.setze(d.copyWith(frisur: f.geschnitten(u.heute)));
    setState(() => _neu = false);
  });

  @override
  Widget inhalt(BuildContext context) {
    final f = d.frisur;
    if (f == null || _neu) {
      return _spalte([
        Block(
          art: GlasArt.gold,
          label: 'Deine Haare gerade',
          children: [
            GlasFeld(
              key: const ValueKey('frisur-feld'),
              controller: _text,
              hint: 'Wie trägst du sie, was stört dich?',
              zeilen: 2,
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('frisur-start'),
              label: busy ? 'Einen Moment …' : 'Was passt zu mir?',
              onTap: busy ? null : () => _frag(null),
            ),
            const SizedBox(height: 8),
            _FotoKnopf(
              k: 'frisur-foto',
              label: 'Mit Foto von vorn',
              ghost: true,
              busy: busy,
              onFoto: _frag,
            ),
          ],
        ),
      ]);
    }
    final tage = frisurTage(f, u.jetzt());
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: 'Für deine Gesichtsform',
        children: [
          _gross(f.empfehlung),
          const SizedBox(height: 6),
          Text(
            tage == null
                ? 'alle ${f.wochen} Wochen'
                : tage <= 0
                ? 'Schnitt ist fällig · alle ${f.wochen} Wochen'
                : 'Nächster Schnitt in $tage Tagen · alle ${f.wochen} Wochen',
            style: Glas.tSoft,
          ),
        ],
      ),
      Block(
        label: 'Zeig das deinem Friseur',
        children: [
          Text(
            '„${f.friseur}“',
            style: Glas.tText.copyWith(fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 10),
          GlasKnopf(
            key: const ValueKey('frisur-kopie'),
            label: 'Text kopieren',
            ghost: true,
            onTap: () {
              Clipboard.setData(ClipboardData(text: f.friseur));
              hinweis(context, 'Kopiert.');
            },
          ),
        ],
      ),
      if (f.styling != null)
        Block(
          label: 'Styling · 1 Minute',
          children: [
            Text(f.styling!, style: Glas.tText.copyWith(fontSize: 14.5)),
          ],
        ),
      const SizedBox(height: 12),
      GlasKnopf(
        key: const ValueKey('frisur-geschnitten'),
        label: 'Heute geschnitten',
        onTap: () => u.stand.setze(d.copyWith(frisur: f.geschnitten(u.heute))),
      ),
      Center(
        child: TextButton(
          key: const ValueKey('frisur-neu'),
          onPressed: () => setState(() => _neu = true),
          child: Text('Neu beraten lassen', style: Glas.tSoft),
        ),
      ),
    ]);
  }
}

class KleineSeite extends StatelessWidget {
  const KleineSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) {
      final d = u.stand.d;
      final jetzt = u.jetzt();
      return _spalte([
        Block(
          children: [
            for (var j = 0; j < d.kleine.length; j++)
              HakenZeile(
                key: ValueKey('klein-$j'),
                an: kleinesHeute(d.kleine[j], jetzt),
                titel: d.kleine[j].name,
                unter: d.kleine[j].wie,
                rechts: kleinesHeute(d.kleine[j], jetzt)
                    ? 'erledigt'
                    : kleinesFaellig(d.kleine[j], jetzt)
                    ? 'heute dran'
                    : 'in ${d.kleine[j].alle - tageSeit(d.kleine[j].zuletzt!, jetzt)} Tagen',
                onTap: () {
                  final l = [...d.kleine];
                  l[j] = l[j].gemacht(
                    kleinesHeute(l[j], jetzt) ? null : u.heute,
                  );
                  u.stand.setze(d.copyWith(kleine: l));
                },
              ),
          ],
        ),
        const Block(
          art: GlasArt.gold,
          children: [
            CoachZeile(
              'Das sind die Dinge, die andere zuerst bemerken und die wenigsten '
              'pflegen. Kostet dich 5 Minuten am Tag.',
            ),
          ],
        ),
      ]);
    },
  );
}

// ------------------------------------------------------------ Wissen

class BibliothekSeite extends StatefulWidget {
  const BibliothekSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<BibliothekSeite> createState() => _BibliothekSeiteState();
}

class _BibliothekSeiteState extends _Seite<BibliothekSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;
  final _titel = TextEditingController();
  int? _quiz;
  int _frage = 0;
  int _richtig = 0;
  bool _fehler = false;

  @override
  void dispose() {
    _titel.dispose();
    super.dispose();
  }

  void _setzeBuch(int i, Buch b) {
    final l = [...d.buecher];
    l[i] = b;
    u.stand.setze(d.copyWith(buecher: l));
  }

  Future<void> _starte(int i) => warte(() async {
    final q = await u.coach.buchQuiz(u.profile, d.buecher[i].titel);
    if (q == null) return offline();
    _setzeBuch(i, d.buecher[i].copyWith(quiz: q));
    setState(() {
      _quiz = i;
      _frage = 0;
      _richtig = 0;
      _fehler = false;
    });
  });

  void _weiter(bool richtig) {
    final i = _quiz!;
    final b = d.buecher[i];
    final r = _richtig + (richtig && !_fehler ? 1 : 0);
    if (_frage + 1 >= b.quiz.length) {
      _setzeBuch(i, b.copyWith(richtig: r));
      setState(() => _quiz = null);
      hinweis(context, '$r von ${b.quiz.length} richtig.');
    } else {
      setState(() {
        _richtig = r;
        _frage++;
        _fehler = false;
      });
    }
  }

  @override
  Widget inhalt(BuildContext context) {
    final q = _quiz == null ? null : d.buecher[_quiz!];
    return _spalte([
      if (q != null && q.quiz.isNotEmpty)
        Block(
          art: GlasArt.gold,
          label: '${q.titel} · Frage ${_frage + 1} von ${q.quiz.length}',
          children: [
            QuizKarte(
              prefix: 'buch-antwort',
              quiz: q.quiz[_frage],
              onFalsch: () => _fehler = true,
              onRichtig: () =>
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) _weiter(true);
                  }),
            ),
          ],
        ),
      Block(
        children: [
          if (d.buecher.isEmpty)
            Text(
              'Noch leer. Trag ein, was du liest oder hörst.',
              style: Glas.tSoft,
            ),
          for (var i = 0; i < d.buecher.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: d.buecher[i].fertig
                          ? CoachStyle.goldGradient
                          : null,
                      color: d.buecher[i].fertig
                          ? null
                          : const Color(0x33FFEECD),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.buecher[i].titel,
                          style: Glas.tText.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          d.buecher[i].richtig != null
                              ? 'abgefragt · ${d.buecher[i].richtig} von ${d.buecher[i].quiz.length} richtig'
                              : d.buecher[i].fertig
                              ? 'gelesen'
                              : 'liest du gerade',
                          style: Glas.tSoft,
                        ),
                      ],
                    ),
                  ),
                  if (!d.buecher[i].fertig)
                    GlasChip(
                      key: ValueKey('buch-fertig-$i'),
                      label: 'Fertig',
                      an: false,
                      onTap: () =>
                          _setzeBuch(i, d.buecher[i].copyWith(fertig: true)),
                    )
                  else
                    GlasChip(
                      key: ValueKey('buch-quiz-$i'),
                      label: busy ? '…' : 'Abfragen',
                      an: true,
                      onTap: () => _starte(i),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          GlasFeld(
            key: const ValueKey('buch-feld'),
            controller: _titel,
            hint: 'Buch oder Podcast dazu',
          ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('buch-dazu'),
            label: 'Dazu',
            ghost: true,
            onTap: () {
              final t = _titel.text.trim();
              if (t.isEmpty) return;
              u.stand.setze(
                d.copyWith(
                  buecher: [
                    ...d.buecher,
                    Buch(titel: t),
                  ],
                ),
              );
              _titel.clear();
            },
          ),
        ],
      ),
      const Block(
        art: GlasArt.gold,
        children: [
          CoachZeile(
            'Was du gelesen hast, frage ich ab. Nur so bleibt es hängen.',
          ),
        ],
      ),
    ]);
  }
}

class UmsetzenSeite extends StatefulWidget {
  const UmsetzenSeite({super.key, required this.u});
  final PersoenlichUmfeld u;

  @override
  State<UmsetzenSeite> createState() => _UmsetzenSeiteState();
}

class _UmsetzenSeiteState extends _Seite<UmsetzenSeite> {
  @override
  PersoenlichUmfeld get u => widget.u;
  final _quelle = TextEditingController();
  final _gelernt = TextEditingController();

  @override
  void dispose() {
    _quelle.dispose();
    _gelernt.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) => _spalte([
    Block(
      children: [
        if (d.umsetzen.isEmpty)
          Text(
            'Noch nichts umgesetzt. Fang unten mit einem Gedanken an.',
            style: Glas.tSoft,
          ),
        for (var i = 0; i < d.umsetzen.length; i++)
          HakenZeile(
            key: ValueKey('umsetzen-$i'),
            an: d.umsetzen[i].erledigt != null,
            titel: d.umsetzen[i].schritt,
            unter: d.umsetzen[i].quelle,
            rechts: d.umsetzen[i].erledigt != null ? 'umgesetzt' : 'offen',
            onTap: () {
              final l = [...d.umsetzen];
              l[i] = l[i].umschalten(u.heute);
              u.stand.setze(d.copyWith(umsetzen: l));
            },
          ),
      ],
    ),
    Block(
      label: 'Was hast du gelesen oder gehört?',
      children: [
        GlasFeld(
          key: const ValueKey('umsetzen-quelle'),
          controller: _quelle,
          hint: 'Buch oder Podcast',
        ),
        const SizedBox(height: 8),
        GlasFeld(
          key: const ValueKey('umsetzen-gelernt'),
          controller: _gelernt,
          hint: 'Was ist hängen geblieben?',
          zeilen: 2,
        ),
        const SizedBox(height: 10),
        GlasKnopf(
          key: const ValueKey('umsetzen-start'),
          label: busy ? 'Einen Moment …' : 'Kleinen Schritt daraus machen',
          onTap: busy
              ? null
              : () => warte(() async {
                  final q = _quelle.text.trim();
                  final g = _gelernt.text.trim();
                  if (g.isEmpty) return;
                  final s = await u.coach.umsetzen(u.profile, q, g, u.kontext);
                  if (s == null) return offline();
                  await u.stand.setze(
                    d.copyWith(
                      umsetzen: [
                        ...d.umsetzen,
                        Umsetzung(
                          quelle: q.isEmpty ? 'Gelesen' : q,
                          schritt: s,
                        ),
                      ],
                    ),
                  );
                  _quelle.clear();
                  _gelernt.clear();
                }),
        ),
      ],
    ),
    const Block(
      art: GlasArt.gold,
      children: [
        CoachZeile(
          'Aus allem, was du liest oder hörst, machen wir einen kleinen Schritt. '
          'Ich frage nach, ob du ihn gemacht hast.',
        ),
      ],
    ),
  ]);
}

/// Small ring for tiles (care steps).
Widget pflegeRing(int n, int von) => GoldRing(
  anteil: von == 0 ? 0 : n / von,
  text: '$n/$von',
  size: 66,
  dicke: 7,
);
