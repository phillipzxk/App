import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'ernaehrung_coach.dart';
import 'ernaehrung_data.dart';
import 'ernaehrung_logik.dart';
import 'ernaehrung_stand.dart';

/// Loads the coach's rescue dishes once: three, the third locked until the
/// user has cooked twice more. Offline it uses a few built-in ones.
Future<void> rettungLaden(EssenUmfeld u, {int anzahl = 3}) async {
  final vorhanden = u.d.gerichte.map((g) => g.name).join(', ');
  final t = u.jetzt().microsecondsSinceEpoch;
  final neu =
      await u.coach.rettung(u.profile, u.musterText(), vorhanden, anzahl) ??
      [
        for (final g in rettungOhneCoach('r$t'))
          if (!u.d.gerichte.any((x) => x.name == g.name)) g,
      ].take(anzahl).toList();
  if (neu.isEmpty) return;
  final n = kochenGesamt(u.d);
  var d = u.d;
  for (var i = 0; i < neu.length; i++) {
    final g = neu[i];
    d = d.mitGericht(
      Gericht(
        id: g.id,
        name: g.name,
        art: g.art,
        dauer: g.dauer,
        gegen: g.gegen,
        warum: g.warum,
        zutaten: g.zutaten,
        schritte: g.schritte,
        quelle: 'coach',
        freiAb: anzahl == 3 && i == 2 ? n + 2 : null,
      ),
    );
  }
  await u.stand.setze(d);
}

/// The rescue dish that fits today best: late training, then cravings.
Gericht? rettungFuerHeute(ErnaehrungDaten d, {required bool spaetesTraining}) {
  final frei = [
    for (final g in d.gerichte)
      if (g.quelle == 'coach' &&
          g.freiAb == null &&
          g.bewertung != 'nicht meins')
        g,
  ];
  if (frei.isEmpty) return null;
  bool hat(Gericht g, String w) =>
      '${g.gegen ?? ''} ${g.warum ?? ''}'.toLowerCase().contains(w);
  if (spaetesTraining) {
    for (final g in frei) {
      if (hat(g, 'training')) return g;
    }
  }
  for (final g in frei) {
    if (hat(g, 'heißhunger')) return g;
  }
  return frei.first;
}

/// Idea E: the cookbook grows. Every dish cooked and kept is a leaf; the
/// coach's rescue dishes (idea D) are each against one of the user's
/// patterns; with 7 leaves the user builds own variants.
class KochbuchSeite extends StatefulWidget {
  const KochbuchSeite({super.key, required this.umfeld});
  final EssenUmfeld umfeld;

  @override
  State<KochbuchSeite> createState() => _KochbuchSeiteState();
}

class _KochbuchSeiteState extends State<KochbuchSeite> {
  final _name = TextEditingController();
  bool _laedt = false;

  EssenUmfeld get u => widget.umfeld;

  @override
  void initState() {
    super.initState();
    if (!u.d.gerichte.any((g) => g.quelle == 'coach')) _holen(3);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _holen(int n) async {
    setState(() => _laedt = true);
    await rettungLaden(u, anzahl: n);
    if (mounted) setState(() => _laedt = false);
  }

  Future<void> _dazu() async {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    final g = Gericht(id: 'e${u.jetzt().microsecondsSinceEpoch}', name: n);
    _name.clear();
    await u.stand.setze(u.d.mitGericht(g));
    if (mounted) {
      await zeigeSeite(context, GerichtEditor(umfeld: u, id: g.id));
    }
  }

  @override
  Widget build(BuildContext context) => EssenSeite(
    umfeld: u,
    label: 'Ernährung',
    titel: 'Dein Kochbuch',
    bau: (context) {
      final d = u.d;
      final blaetter = kochbuchBlaetter(d);
      final rettung = [
        for (final g in d.gerichte)
          if (g.quelle == 'coach') g,
      ];
      final eigene = [
        for (final g in d.gerichte)
          if (g.quelle != 'coach') g,
      ];
      final heute = rettungFuerHeute(
        d,
        spaetesTraining: (u.training ?? 0) >= 17 * 60,
      );
      final rest = math.max(0, variantenAb - blaetter);
      return [
        TKarte(
          key: const ValueKey('kochbuch-blaetter'),
          child: Row(
            children: [
              KochbuchBaum(blaetter: blaetter),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoldText(
                      '$blaetter ${blaetter == 1 ? 'Blatt' : 'Blätter'}',
                      style: tTitel.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rest > 0
                          ? 'Jedes Gericht, das du kochst und bewertest, wird '
                                'ein Blatt. Noch $rest bis zu deiner ersten '
                                'eigenen Variante.'
                          : 'Du kannst jetzt eigene Varianten bauen: Öffne ein '
                                'Gericht, das sitzt.',
                      style: tSoft,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (heute != null)
          TKarte(
            child: CoachZeile(
              text:
                  '${(u.training ?? 0) >= 17 * 60 ? 'Heute trainierst du spät.' : 'Für heute:'} '
                  'Dein Rettungsgericht: ${heute.name}.',
              unten: TLink(
                'Ansehen ›',
                onTap: () =>
                    zeigeSeite(context, GerichtSeite(umfeld: u, id: heute.id)),
              ),
            ),
          ),
        TKarte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TLabel('Deine Rettungsgerichte'),
              const SizedBox(height: 3),
              const Text(
                'Vom Coach, jedes gegen ein Muster von dir.',
                style: tSoft,
              ),
              if (_laedt)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(color: CoachStyle.gold),
                  ),
                ),
              for (final g in rettung)
                _GerichtZeile(
                  key: ValueKey('rettung-${g.id}'),
                  g: g,
                  gesamt: kochenGesamt(d),
                  onTap: g.freiAb == null
                      ? () => zeigeSeite(
                          context,
                          GerichtSeite(umfeld: u, id: g.id),
                        )
                      : null,
                ),
              if (!_laedt)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TLink(
                    'Noch ein Vorschlag',
                    key: const ValueKey('rettung-mehr'),
                    onTap: () => _holen(1),
                  ),
                ),
            ],
          ),
        ),
        TKarte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TLabel('Deine eigenen'),
              for (final g in eigene)
                _GerichtZeile(
                  key: ValueKey('gericht-${g.id}'),
                  g: g,
                  gesamt: kochenGesamt(d),
                  onTap: () =>
                      zeigeSeite(context, GerichtSeite(umfeld: u, id: g.id)),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('gericht-neu-name'),
                      controller: _name,
                      style: tText,
                      decoration: _feld(
                        'Eigenes Gericht, z. B. Thunfisch-Salat',
                      ),
                      onSubmitted: (_) => _dazu(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 96,
                    child: TGhost(
                      'Dazu',
                      key: const ValueKey('gericht-neu-dazu'),
                      onTap: _dazu,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ];
    },
  );
}

InputDecoration _feld(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: tSoft,
  isDense: true,
  filled: true,
  fillColor: const Color(0xFF1A140E),
  contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF4A3B2A)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: CoachStyle.goldLight),
  ),
);

class _GerichtZeile extends StatelessWidget {
  const _GerichtZeile({
    super.key,
    required this.g,
    required this.gesamt,
    required this.onTap,
  });

  final Gericht g;
  final int gesamt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final zu = g.freiAb != null;
    final unter = [
      if (zu)
        'frei nach ${g.freiAb! - gesamt} Mal kochen'
      else if (g.quelle != 'coach' && g.gekocht > 0)
        '${g.gekocht} Mal gekocht'
      else
        g.art,
      if (g.dauer != null && !zu) '${g.dauer} Min',
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: zu ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF2E261C))),
          ),
          child: Row(
            children: [
              GerichtBild(name: g.name, zu: zu),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name, style: tTitel.copyWith(fontSize: 13.5)),
                    if (g.gegen != null)
                      Text(
                        g.gegen!,
                        style: tSoft.copyWith(color: CoachStyle.goldLight),
                      ),
                    Text(unter, style: tSoft),
                  ],
                ),
              ),
              if (g.quelle != 'coach' && g.gekocht > 0)
                EssenTag(g.sitzt ? 'sitzt' : 'übt', gold: false)
              else if (!zu)
                const Icon(
                  Icons.chevron_right,
                  color: CoachStyle.goldLight,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small tree: one leaf per dish, empty leaves still to grow.
class KochbuchBaum extends StatelessWidget {
  const KochbuchBaum({super.key, required this.blaetter});
  final int blaetter;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(blaetter),
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 900),
    curve: Curves.elasticOut,
    builder: (context, t, _) => CustomPaint(
      size: const Size(120, 120),
      painter: _BaumMaler(blaetter, t),
    ),
  );
}

class _BaumMaler extends CustomPainter {
  _BaumMaler(this.blaetter, this.t);
  final int blaetter;
  final double t;

  static const _orte = [
    (32.0, 70.0, -1),
    (88.0, 62.0, 1),
    (28.0, 48.0, -1),
    (94.0, 40.0, 1),
    (44.0, 28.0, -1),
    (80.0, 22.0, 1),
    (60.0, 10.0, -1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    canvas.scale(s);
    final stamm = Paint()
      ..color = const Color(0xFFC9A25C)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(8, 104),
      const Offset(112, 104),
      Paint()
        ..color = const Color(0xFF6B5535)
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(const Offset(60, 104), const Offset(60, 16), stamm);
    final ast = Paint()
      ..color = const Color(0xFFC9A25C)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final wurzel = Paint()
      ..color = const Color(0xFF7A5F38)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(60, 104)
        ..quadraticBezierTo(52, 112, 38, 114)
        ..moveTo(60, 104)
        ..quadraticBezierTo(68, 112, 84, 113)
        ..moveTo(60, 104)
        ..lineTo(60, 117),
      wurzel,
    );
    for (var i = 0; i < _orte.length; i++) {
      final (x, y, seite) = _orte[i];
      canvas.drawPath(
        Path()
          ..moveTo(60, y + 8)
          ..quadraticBezierTo((60 + x) / 2, y + 2, x, y),
        ast,
      );
      final an = i < blaetter;
      final neu = i == blaetter - 1;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(seite * -0.5);
      if (neu) canvas.scale(t.clamp(0.0, 1.3));
      final r = Rect.fromCenter(center: Offset.zero, width: 22, height: 13);
      if (an) {
        canvas.drawOval(
          r,
          Paint()
            ..color = i.isOdd ? const Color(0xFFF5DFAE) : CoachStyle.goldLight,
        );
      } else {
        canvas.drawOval(
          r,
          Paint()
            ..color = const Color(0xFF4A3B2A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BaumMaler old) => old.blaetter != blaetter || old.t != t;
}

/// One dish to cook: why it fits, ingredients for one portion, steps, and
/// after cooking the rating that grows a leaf.
class GerichtSeite extends StatelessWidget {
  const GerichtSeite({super.key, required this.umfeld, required this.id});
  final EssenUmfeld umfeld;
  final String id;

  @override
  Widget build(BuildContext context) {
    final g0 = umfeld.d.gericht(id);
    return EssenSeite(
      umfeld: umfeld,
      label: g0?.quelle == 'coach'
          ? 'Dein Rettungsgericht'
          : g0?.quelle == 'kuehlschrank'
          ? 'Aus deinem Kühlschrank'
          : 'Dein Gericht',
      titel: g0?.name ?? 'Gericht',
      bau: (context) {
        final g = umfeld.d.gericht(id);
        if (g == null) {
          return const [
            Text('Dieses Gericht ist nicht mehr da.', style: tText),
          ];
        }
        final d = umfeld.d;
        final aufListe = (d.einkauf.auswahl[g.id] ?? 0) > 0;
        final varianteFrei = kochbuchBlaetter(d) >= variantenAb && g.sitzt;
        return [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (g.gegen != null) EssenTag(g.gegen!),
              EssenTag(
                [g.art, if (g.dauer != null) '${g.dauer} Min'].join(' · '),
                gold: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (g.warum != null) TKarte(child: CoachZeile(text: g.warum!)),
          if (g.zutaten.isNotEmpty)
            TKarte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TLabel('Zutaten · 1 Portion'),
                  const SizedBox(height: 4),
                  for (final z in g.zutaten)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF2E261C)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(z.name, style: tText)),
                          Text(
                            EinkaufPosten(
                              name: z.name,
                              einheit: z.einheit,
                              gruppe: z.gruppe,
                              menge: z.menge,
                            ).mengeText,
                            style: tSoft,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (g.schritte.isNotEmpty)
            TKarte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TLabel('So geht’s'),
                  const SizedBox(height: 4),
                  for (var i = 0; i < g.schritte.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('${i + 1}. ${g.schritte[i]}', style: tText),
                    ),
                ],
              ),
            ),
          if (g.zutaten.isEmpty && g.quelle == 'eigen')
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Trag Zutaten und Schritte ein, dann kommt es auch auf die '
                'Einkaufsliste.',
                style: tSoft,
              ),
            ),
          TKarte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TLabel(
                  g.gekocht == 0 ? 'Gekocht? Wie war’s?' : 'Wieder gekocht?',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final f in const ['lecker', 'geht so', 'nicht meins'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: TChip(
                            f,
                            key: ValueKey('gekocht-$f'),
                            an: g.bewertung == f,
                            onTap: () async {
                              final vorher = kochbuchBlaetter(umfeld.d);
                              await umfeld.stand.setze(
                                gekocht(umfeld.d, g.id, f),
                              );
                              if (!context.mounted) return;
                              if (umfeld.d.gericht(g.id) == null) {
                                Navigator.of(context).pop();
                                return;
                              }
                              final neu = kochbuchBlaetter(umfeld.d) > vorher;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    neu
                                        ? 'Neues Blatt in deinem Kochbuch.'
                                        : 'Gespeichert, ${umfeld.d.gericht(g.id)!.gekocht} Mal gekocht.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                if (g.bewertung == 'nicht meins')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Okay. Der Coach schlägt dir beim nächsten Mal etwas '
                      'anderes vor.',
                      style: tSoft,
                    ),
                  ),
              ],
            ),
          ),
          if (g.zutaten.isNotEmpty)
            TGhost(
              aufListe
                  ? 'Steht auf der Einkaufsliste'
                  : 'Zutaten auf die Einkaufsliste',
              key: const ValueKey('auf-liste'),
              onTap: aufListe
                  ? null
                  : () => umfeld.stand.setze(
                      d.copyWith(
                        einkauf: d.einkauf.copyWith(
                          auswahl: {...d.einkauf.auswahl, g.id: 1},
                        ),
                      ),
                    ),
            ),
          if (g.quelle == 'eigen') ...[
            const SizedBox(height: 8),
            TGhost(
              'Bearbeiten',
              key: const ValueKey('bearbeiten'),
              onTap: () =>
                  zeigeSeite(context, GerichtEditor(umfeld: umfeld, id: g.id)),
            ),
          ],
          if (varianteFrei) ...[
            const SizedBox(height: 8),
            MainButton(
              key: const ValueKey('variante'),
              label: 'Eigene Variante bauen',
              onPressed: () async {
                final v = Gericht(
                  id: 'v${umfeld.jetzt().microsecondsSinceEpoch}',
                  name: '${g.name} (meine Variante)',
                  art: g.art,
                  dauer: g.dauer,
                  gegen: g.gegen,
                  zutaten: g.zutaten,
                  schritte: g.schritte,
                );
                await umfeld.stand.setze(umfeld.d.mitGericht(v));
                if (context.mounted) {
                  await zeigeSeite(
                    context,
                    GerichtEditor(umfeld: umfeld, id: v.id),
                  );
                }
              },
            ),
          ],
        ];
      },
    );
  }
}

/// Reads "150 g Hähnchenbrust" or "Hähnchenbrust 150 g" into an ingredient.
Zutat zutatLesen(String zeile) {
  final t = zeile.trim();
  final m = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(g|kg|ml|l|stück|stk|el|tl|dose|scheiben?)?\b',
    caseSensitive: false,
  ).firstMatch(t);
  double? menge;
  var einheit = '';
  var name = t;
  if (m != null) {
    menge = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    einheit = switch ((m.group(2) ?? '').toLowerCase()) {
      'stk' || 'stück' => 'Stück',
      'el' => 'EL',
      'tl' => 'TL',
      final e => e,
    };
    name = (t.substring(0, m.start) + t.substring(m.end)).trim();
    if (name.isEmpty) name = t;
  }
  return Zutat(
    name: name,
    menge: menge,
    einheit: einheit,
    gruppe: gruppeRaten(name),
  );
}

/// A guess of the shop section from the name.
String gruppeRaten(String name) {
  final n = name.toLowerCase();
  bool hat(String muster) => RegExp(muster).hasMatch(n);
  if (hat(
    r'hähnchen|huhn|pute|rind|hack|fisch|lachs|thunfisch|tofu|schinken|fleisch|garnele',
  )) {
    return 'Eiweiß';
  }
  if (hat(
    r'quark|skyr|joghurt|milch|käse|feta|mozzarella|ei\b|eier|butter|sahne',
  )) {
    return 'Kühlregal';
  }
  if (hat(r'apfel|banane|beere|obst|orange|mango|kiwi|traube|zitrone')) {
    return 'Obst';
  }
  if (hat(
    r'paprika|spinat|brokkoli|tomate|gurke|salat|zwiebel|möhre|karotte|zucchini|gemüse|pilz|knoblauch',
  )) {
    return 'Gemüse';
  }
  if (hat(
    r'reis|nudel|pasta|hafer|linse|bohne|mehl|brot|wrap|öl|nuss|honig|dose',
  )) {
    return 'Vorrat';
  }
  return 'Sonstiges';
}

/// Name, ingredients and steps of an own dish, one per line.
class GerichtEditor extends StatefulWidget {
  const GerichtEditor({super.key, required this.umfeld, required this.id});
  final EssenUmfeld umfeld;
  final String id;

  @override
  State<GerichtEditor> createState() => _GerichtEditorState();
}

class _GerichtEditorState extends State<GerichtEditor> {
  late final Gericht _g = widget.umfeld.d.gericht(widget.id)!;
  late final _name = TextEditingController(text: _g.name);
  late final _zutaten = TextEditingController(
    text: [
      for (final z in _g.zutaten)
        [
          z.name,
          EinkaufPosten(
            name: z.name,
            einheit: z.einheit,
            gruppe: z.gruppe,
            menge: z.menge,
          ).mengeText,
        ].where((x) => x.isNotEmpty).join(' '),
    ].join('\n'),
  );
  late final _schritte = TextEditingController(text: _g.schritte.join('\n'));

  @override
  void dispose() {
    _name.dispose();
    _zutaten.dispose();
    _schritte.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    final u = widget.umfeld;
    final g = u.d.gericht(widget.id) ?? _g;
    await u.stand.setze(
      u.d.mitGericht(
        g.copyWith(
          name: _name.text.trim().isEmpty ? g.name : _name.text.trim(),
          zutaten: [
            for (final l in _zutaten.text.split('\n'))
              if (l.trim().isNotEmpty) zutatLesen(l),
          ],
          schritte: [
            for (final l in _schritte.text.split('\n'))
              if (l.trim().isNotEmpty) l.trim(),
          ],
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Widget _feldMit(
    String label,
    TextEditingController c, {
    int zeilen = 1,
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TLabel(label),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: c,
          minLines: zeilen,
          maxLines: zeilen == 1 ? 1 : 12,
          style: tText,
          decoration: _feld(''),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => EssenSeite(
    umfeld: widget.umfeld,
    label: 'Dein Gericht',
    titel: 'Bearbeiten',
    bau: (context) => [
      _feldMit('Name', _name, key: const ValueKey('editor-name')),
      _feldMit(
        'Zutaten für 1 Portion, eine pro Zeile',
        _zutaten,
        zeilen: 4,
        key: const ValueKey('editor-zutaten'),
      ),
      _feldMit(
        'Schritte, einer pro Zeile',
        _schritte,
        zeilen: 3,
        key: const ValueKey('editor-schritte'),
      ),
      MainButton(
        key: const ValueKey('editor-speichern'),
        label: 'Speichern',
        onPressed: _speichern,
      ),
    ],
  );
}
