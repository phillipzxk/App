import 'dart:convert';

import 'package:flutter/material.dart';

import '../feed/feed_store.dart';
import '../home/feed_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'foto_aufnahme.dart';
import 'future_me_card.dart';
import 'future_me_data.dart';
import 'vergleich_karte.dart';

/// Starts the photo of today (or the catch-up of yesterday's) and saves it.
/// Returns true when something was saved.
Future<bool> fotoMachen(
  BuildContext context,
  FeedStore store,
  DateTime now,
) async {
  final e = await store.loadFotoEinstellungen();
  if (e == null || !context.mounted) return false;
  final fotos = await store.loadWochenFotos();
  final lage = fotoLage(now, e, fotos);
  if (lage.status == FotoStatus.spaeter || !context.mounted) return false;
  final foto = await Navigator.of(context).push<WochenFoto>(
    MaterialPageRoute(
      builder: (_) => AufnahmePage(
        einstellungen: e,
        lage: lage,
        erstes: fotos.isEmpty ? null : fotos.first,
        letztes: fotos.isEmpty ? null : fotos.last,
        now: now,
      ),
    ),
  );
  if (foto == null) return false;
  await store.saveWochenFoto(foto);
  return true;
}

/// The own page of "Dein zukünftiges Ich" (see Umsetzung/Dein zukünftiges
/// Ich.md): first photo next to the latest with the values then and now,
/// all weeks to swipe through, and what the AI adds later.
class FutureMePage extends StatefulWidget {
  const FutureMePage({super.key, required this.store, required this.clock});

  final FeedStore store;
  final DateTime Function() clock;

  @override
  State<FutureMePage> createState() => _FutureMePageState();
}

class _FutureMePageState extends State<FutureMePage> {
  bool _loaded = false;
  FotoEinstellungen? _e;
  List<WochenFoto> _fotos = const [];
  String? _pose;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final e = await widget.store.loadFotoEinstellungen();
    final fotos = await widget.store.loadWochenFotos();
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _e = e;
      _fotos = fotos;
      if (e != null && !e.posen.contains(_pose)) _pose = e.posen.first;
    });
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<FotoEinstellungen>(
      MaterialPageRoute(builder: (_) => EinrichtenPage(current: _e)),
    );
    if (result == null) return;
    await widget.store.saveFotoEinstellungen(result);
    await _reload();
  }

  Future<void> _foto() async {
    if (await fotoMachen(context, widget.store, widget.clock())) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
    return CoachPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Zurück',
              icon: const Icon(Icons.arrow_back, color: CoachStyle.ink),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: !_loaded
                ? const SizedBox.shrink()
                : e == null
                ? _Leer(onSetup: _edit)
                : _content(e),
          ),
        ],
      ),
    );
  }

  Widget _content(FotoEinstellungen e) {
    final now = widget.clock();
    final lage = fotoLage(now, e, _fotos);
    final pose = _pose ?? e.posen.first;
    final first = _fotos.isEmpty ? null : _fotos.first;
    final last = _fotos.isEmpty ? null : _fotos.last;
    final wochen = alleWochen(now, _fotos);
    final aktuelleWoche = last == null ? 1 : wocheVon(_fotos, last.fototag);
    return ListView(
      children: [
        PageHeader(
          label: 'Woche $aktuelleWoche · Fototag ${wochentage[e.fototag - 1]}',
          title: 'Fortschrittsfoto',
          icon: Icons.photo_camera_outlined,
        ),
        if (lage.status != FotoStatus.spaeter) ...[
          MainButton(
            key: const ValueKey('seite-foto'),
            label: lage.status == FotoStatus.heute
                ? 'Foto machen'
                : 'Heute nachholen',
            onPressed: _foto,
          ),
          const SizedBox(height: 14),
        ],
        if (e.posen.length > 1) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final p in e.posen)
                ChoiceChip(
                  label: Text(p),
                  selected: p == pose,
                  selectedColor: CoachStyle.selectedFill,
                  onSelected: (_) => setState(() => _pose = p),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (first == null)
          const FeedCard(
            title: 'Dein erstes Foto',
            icon: Icons.photo_camera_outlined,
            children: [HintText('Kommt an deinem ersten Fototag.')],
          )
        else
          VergleichKarte(
            key: ValueKey('vergleich-${_fotos.length}'),
            fotos: _fotos,
            pose: pose,
            woche: (f) => wocheVon(_fotos, f.fototag),
          ),
        if (e.werte.isNotEmpty)
          FeedCard(
            title: 'Deine Werte',
            icon: Icons.bar_chart,
            trailing: TextButton(
              onPressed: _edit,
              child: const Text(
                'Ändern',
                style: TextStyle(color: CoachStyle.gold),
              ),
            ),
            children: [
              _WerteTabelle(namen: e.werte, start: first, heute: last),
            ],
          ),
        if (wochen.isNotEmpty)
          FeedCard(
            title: 'Alle Wochen',
            icon: Icons.view_week_outlined,
            children: [
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final w in wochen) _WochenKachel(platz: w, pose: pose),
                  ],
                ),
              ),
            ],
          ),
        const _KiKarte(
          title: 'Was sich verändert hat',
          text:
              'Die KI vergleicht deine Fotos und zeigt, was man mit bloßem '
              'Auge nicht sieht. $aiPending',
        ),
        const _KiKarte(
          title: 'So siehst du aus, wenn du so weitermachst',
          text: 'Realistisch, lieber vorsichtig. $aiPending',
          projektion: true,
        ),
        FeedCard(
          title: 'Einstellungen',
          icon: Icons.tune,
          children: [
            _SettingRow(
              label: 'Fototag',
              value: '${wochentage[e.fototag - 1]} · fest',
            ),
            _SettingRow(label: 'Deine Posen', value: e.posen.join(', ')),
            const SizedBox(height: 6),
            GhostButton(label: 'Posen und Werte ändern', onPressed: _edit),
            const SizedBox(height: 10),
            const HintText('Fotos bleiben nur auf deinem Handy.'),
          ],
        ),
      ],
    );
  }
}

class _Leer extends StatelessWidget {
  const _Leer({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const PageHeader(
          label: 'Fortschritt',
          title: 'Fortschrittsfoto',
          icon: Icons.photo_camera_outlined,
        ),
        FeedCard(
          title: 'Fototag und Posen',
          icon: Icons.photo_camera_outlined,
          children: [
            const HintText('Fototag und Posen einmal festlegen.'),
            const SizedBox(height: 12),
            GhostButton(label: 'Einrichten', onPressed: onSetup),
          ],
        ),
      ],
    );
  }
}

class _WerteTabelle extends StatelessWidget {
  const _WerteTabelle({
    required this.namen,
    required this.start,
    required this.heute,
  });

  final List<String> namen;
  final WochenFoto? start;
  final WochenFoto? heute;

  @override
  Widget build(BuildContext context) {
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
      children: [
        for (var i = 0; i < cells.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              cells[i],
              textAlign: i == 0 ? TextAlign.left : TextAlign.right,
              style: head
                  ? CoachStyle.label.copyWith(fontSize: 11)
                  : CoachStyle.body.copyWith(fontSize: 14),
            ),
          ),
      ],
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        row(['WERT', 'START', 'NEUESTES'], head: true),
        for (final n in namen)
          row([n, start?.werte[n] ?? '–', heute?.werte[n] ?? '–']),
      ],
    );
  }
}

class _WochenKachel extends StatelessWidget {
  const _WochenKachel({required this.platz, required this.pose});

  final WochenPlatz platz;
  final String pose;

  @override
  Widget build(BuildContext context) {
    final f = platz.foto;
    final kurz = f != null && f.nachgeholt
        ? ' · ${wochentage[f.gemacht.weekday - 1].substring(0, 2)}'
        : '';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          SizedBox(
            width: 58,
            height: 76,
            child: f == null
                ? Container(
                    key: ValueKey('woche-${platz.woche}-verpasst'),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CoachStyle.line, width: 1.5),
                    ),
                    child: const Text(
                      'verpasst',
                      style: TextStyle(fontSize: 11, color: CoachStyle.inkSoft),
                    ),
                  )
                : FotoBild(foto: f, pose: pose, radius: 10),
          ),
          const SizedBox(height: 4),
          Text(
            'W${platz.woche}$kurz',
            style: const TextStyle(fontSize: 11, color: CoachStyle.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _KiKarte extends StatelessWidget {
  const _KiKarte({
    required this.title,
    required this.text,
    this.projektion = false,
  });

  final String title;
  final String text;
  final bool projektion;

  @override
  Widget build(BuildContext context) {
    return FeedCard(
      title: title,
      icon: Icons.auto_awesome,
      trailing: const Tag('KI'),
      children: [
        if (projektion) ...[
          Row(
            children: [
              for (final m in const ['3 Monate', '6 Monate', '12 Monate'])
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CoachStyle.line),
                    ),
                    child: Text(
                      m,
                      style: CoachStyle.cardTitle.copyWith(
                        fontSize: 13,
                        color: CoachStyle.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        HintText(text),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label, style: CoachStyle.body.copyWith(fontSize: 14.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: CoachStyle.body.copyWith(
              fontSize: 13.5,
              color: CoachStyle.inkSoft,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Sets photo day, poses and own values. The photo day can only be chosen
/// the first time; after that it stays fixed.
class EinrichtenPage extends StatefulWidget {
  const EinrichtenPage({super.key, required this.current});

  final FotoEinstellungen? current;

  @override
  State<EinrichtenPage> createState() => _EinrichtenPageState();
}

class _EinrichtenPageState extends State<EinrichtenPage> {
  late int _tag = widget.current?.fototag ?? DateTime.sunday;
  late final List<TextEditingController> _posen = [
    for (final p in widget.current?.posen ?? const ['Vorne'])
      TextEditingController(text: p),
  ];
  late final List<TextEditingController> _werte = [
    for (var i = 0; i < 3; i++)
      TextEditingController(
        text: i < (widget.current?.werte.length ?? 0)
            ? widget.current!.werte[i]
            : '',
      ),
  ];

  @override
  void dispose() {
    for (final c in [..._posen, ..._werte]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final posen = [
      for (final c in _posen)
        if (c.text.trim().isNotEmpty) c.text.trim(),
    ];
    final werte = [
      for (final c in _werte)
        if (c.text.trim().isNotEmpty) c.text.trim(),
    ];
    Navigator.of(context).pop(
      FotoEinstellungen(
        fototag: _tag,
        posen: posen.isEmpty ? const ['Vorne'] : posen,
        werte: werte,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fest = widget.current != null;
    return EditorPage(
      title: 'Fortschrittsfoto',
      intro:
          'Einmal festlegen: an welchem Tag du dein Wochenfoto machst, welche '
          'Posen und welche Werte du verfolgen willst.',
      onSave: _save,
      children: [
        const Text('FOTOTAG', style: CoachStyle.label),
        const SizedBox(height: 8),
        if (fest)
          HintText('${wochentage[_tag - 1]}. Der Fototag bleibt fest.')
        else ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                ChoiceChip(
                  key: ValueKey('fototag-$d'),
                  label: Text(wochentage[d - 1].substring(0, 2)),
                  selected: _tag == d,
                  selectedColor: CoachStyle.selectedFill,
                  onSelected: (_) => setState(() => _tag = d),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const HintText(
            'Der Tag bleibt danach fest. Fotografiert wird nur an diesem Tag, '
            'verpasst kannst du es am Tag danach einmal nachholen.',
          ),
        ],
        const SizedBox(height: 22),
        const Text('DEINE POSEN', style: CoachStyle.label),
        const SizedBox(height: 8),
        for (var i = 0; i < _posen.length; i++) ...[
          EditorField(
            key: ValueKey('pose-$i'),
            controller: _posen[i],
            hint: 'z. B. Vorne',
          ),
          const SizedBox(height: 8),
        ],
        GhostButton(
          label: 'Pose hinzufügen',
          onPressed: () => setState(() => _posen.add(TextEditingController())),
        ),
        const SizedBox(height: 6),
        const HintText(
          'Tipp: Nimm jede Woche dieselben Posen, am besten nur eine.',
        ),
        const SizedBox(height: 22),
        const Text('DEINE WERTE (FREIWILLIG)', style: CoachStyle.label),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++) ...[
          EditorField(
            key: ValueKey('wert-$i'),
            controller: _werte[i],
            hint: const [
              'z. B. Klimmzüge am Stück',
              'z. B. 5 km Zeit',
              'z. B. Bankdrücken 1×5',
            ][i],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Takes one photo per pose and asks for the week's values.
class AufnahmePage extends StatefulWidget {
  const AufnahmePage({
    super.key,
    required this.einstellungen,
    required this.lage,
    required this.erstes,
    required this.letztes,
    required this.now,
  });

  final FotoEinstellungen einstellungen;
  final FotoLage lage;
  final WochenFoto? erstes;
  final WochenFoto? letztes;
  final DateTime now;

  @override
  State<AufnahmePage> createState() => _AufnahmePageState();
}

class _AufnahmePageState extends State<AufnahmePage> {
  final _bilder = <String, String>{};
  late final _werte = {
    for (final w in widget.einstellungen.werte) w: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _werte.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _take(String pose) async {
    final bytes = await fotoAufnahme();
    if (bytes == null || !mounted) return;
    setState(() => _bilder[pose] = base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.einstellungen;
    final fertig = e.posen.every(_bilder.containsKey);
    return EditorPage(
      title: 'Woche ${widget.lage.woche}',
      intro: widget.erstes == null
          ? 'Dein erstes Foto. Merk dir Pose, Ort und Licht, damit du jede '
                'Woche genauso stehst.'
          : 'Stell dich so wie letzte Woche hin. Die App löst aus, wenn du '
                'genau so stehst.',
      onSave: () {
        if (!fertig) return;
        Navigator.of(context).pop(
          WochenFoto(
            fototag: widget.lage.tag,
            gemacht: widget.now,
            bilder: Map.of(_bilder),
            werte: {
              for (final entry in _werte.entries)
                if (entry.value.text.trim().isNotEmpty)
                  entry.key: entry.value.text.trim(),
            },
          ),
        );
      },
      children: [
        for (final p in e.posen)
          FeedCard(
            title: p,
            icon: Icons.accessibility_new,
            trailing: _bilder.containsKey(p) ? const Tag('fertig') : null,
            children: [
              Row(
                children: [
                  if (widget.letztes?.bilder[p] != null) ...[
                    Column(
                      children: [
                        FotoBild(
                          foto: widget.letztes,
                          pose: p,
                          width: 60,
                          height: 80,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Letzte Woche',
                          style: TextStyle(
                            fontSize: 11,
                            color: CoachStyle.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (_bilder[p] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(_bilder[p]!),
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const Spacer(),
                  GhostButton(
                    key: ValueKey('aufnehmen-$p'),
                    label: _bilder.containsKey(p) ? 'Neu' : 'Aufnehmen',
                    onPressed: () => _take(p),
                  ),
                ],
              ),
            ],
          ),
        if (_werte.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text('DEINE WERTE DIESE WOCHE', style: CoachStyle.label),
          const SizedBox(height: 8),
          for (final entry in _werte.entries) ...[
            EditorField(
              key: ValueKey('wert-eintrag-${entry.key}'),
              controller: entry.value,
              label: entry.key,
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (!fertig)
          const HintText('Speichern geht, sobald jede Pose ein Foto hat.'),
      ],
    );
  }
}
