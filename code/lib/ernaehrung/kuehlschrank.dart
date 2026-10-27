import 'package:flutter/material.dart';

import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'ernaehrung_coach.dart';
import 'ernaehrung_data.dart';
import 'ernaehrung_logik.dart';
import 'ernaehrung_stand.dart';
import 'kochbuch.dart';

/// Idea C: a photo of what is at home. The coach names what it sees (wrong
/// ones can be tapped away) and builds one dish from it that fits today.
class KuehlschrankSeite extends StatefulWidget {
  const KuehlschrankSeite({super.key, required this.umfeld});
  final EssenUmfeld umfeld;

  @override
  State<KuehlschrankSeite> createState() => _KuehlschrankSeiteState();
}

enum _Phase { bereit, lesen, fertig }

class _KuehlschrankSeiteState extends State<KuehlschrankSeite> {
  _Phase _phase = _Phase.bereit;
  List<String> _zutaten = const [];
  bool _geaendert = false;
  Gericht? _gericht;
  String? _fehler;
  bool _gespeichert = false;

  EssenUmfeld get u => widget.umfeld;

  Future<void> _frag({String? bild}) async {
    setState(() {
      _phase = _Phase.lesen;
      _fehler = null;
    });
    final r = await u.coach.kuehlschrank(
      u.profile,
      u.tagText(),
      bild: bild,
      zutaten: bild == null ? _zutaten : null,
    );
    if (!mounted) return;
    setState(() {
      if (r?.gericht == null) {
        _fehler =
            'Der Coach ist gerade nicht erreichbar oder hat nichts erkannt. '
            'Versuch es gleich nochmal.';
        _phase = bild == null && _gericht != null
            ? _Phase.fertig
            : _Phase.bereit;
        return;
      }
      _zutaten = r!.zutaten.isEmpty ? _zutaten : r.zutaten;
      _gericht = r.gericht;
      _geaendert = false;
      _gespeichert = false;
      _phase = _Phase.fertig;
    });
  }

  Future<void> _aufnehmen() async {
    final bild = await fotoAufnahme();
    if (!mounted) return;
    if (bild == null) {
      setState(() => _fehler = 'Kein Foto. Versuch es nochmal.');
      return;
    }
    await _frag(bild: bild);
  }

  Future<void> _insKochbuch() async {
    final g = _gericht;
    if (g == null || _gespeichert) return;
    await u.stand.setze(u.d.mitGericht(g));
    await u.stand.setze(gekocht(u.d, g.id, 'lecker'));
    if (mounted) setState(() => _gespeichert = true);
  }

  @override
  Widget build(BuildContext context) {
    final g = _gericht;
    return EssenSeite(
      umfeld: u,
      label: _phase == _Phase.fertig ? 'Aus deinem Kühlschrank' : 'Ernährung',
      titel: _phase == _Phase.fertig && g != null ? g.name : 'Was hast du da?',
      unterTitel: _phase == _Phase.fertig && g != null
          ? [g.art, if (g.dauer != null) '${g.dauer} Min'].join(' · ')
          : null,
      bau: (context) => switch (_phase) {
        _Phase.bereit => [
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const RadialGradient(
                colors: [Color(0xFF3A2C1D), Color(0xFF0D0A07)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CoachStyle.goldLight, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x55E0BF7E), blurRadius: 18),
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.kitchen_outlined,
                    size: 80,
                    color: Color(0x55CDBB98),
                  ),
                ),
                const Positioned(
                  left: 30,
                  right: 30,
                  top: 30,
                  child: Text(
                    'Kühlschrank auf, ein Foto reicht',
                    textAlign: TextAlign.center,
                    style: tSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MainButton(
            key: const ValueKey('kuehl-aufnehmen'),
            label: 'Foto machen',
            onPressed: _aufnehmen,
          ),
          const SizedBox(height: 8),
          const Text(
            'Der Coach schaut, was da ist, und kocht dir daraus etwas für '
            'heute.',
            style: tSoft,
            textAlign: TextAlign.center,
          ),
          if (_fehler != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _fehler!,
                style: tSoft.copyWith(color: CoachStyle.goldLight),
                textAlign: TextAlign.center,
              ),
            ),
        ],
        _Phase.lesen => [
          const SizedBox(height: 30),
          const Center(
            child: CircularProgressIndicator(color: CoachStyle.gold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Coach schaut rein …',
            style: tSoft,
            textAlign: TextAlign.center,
          ),
        ],
        _Phase.fertig => [
          TKarte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TLabel('Das hab ich gesehen'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final z in _zutaten)
                      TChip(
                        z,
                        key: ValueKey('kuehl-zutat-$z'),
                        an: true,
                        onTap: () => setState(() {
                          _zutaten = [..._zutaten.where((x) => x != z)];
                          _geaendert = true;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _geaendert
                      ? 'Geändert. Der Coach kann neu überlegen.'
                      : 'Tipp auf eine Zutat, wenn sie falsch ist.',
                  style: tSoft,
                ),
                if (_geaendert && _zutaten.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TLink(
                      'Mit diesen Zutaten neu',
                      key: const ValueKey('kuehl-neu'),
                      onTap: () => _frag(),
                    ),
                  ),
              ],
            ),
          ),
          if (g?.warum != null)
            TKarte(gold: true, child: CoachZeile(text: g!.warum!)),
          if (g != null && g.schritte.isNotEmpty)
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
          if (_fehler != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _fehler!,
                style: tSoft.copyWith(color: CoachStyle.goldLight),
              ),
            ),
          MainButton(
            key: const ValueKey('kuehl-gekocht'),
            label: _gespeichert
                ? 'Steht in deinem Kochbuch'
                : 'Gekocht, ins Kochbuch',
            onPressed: _gespeichert ? null : _insKochbuch,
          ),
          if (_gespeichert)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Neues Blatt. ${kochbuchBlaetter(u.d)} Blätter in deinem '
                'Kochbuch.',
                style: tSoft.copyWith(color: CoachStyle.goldLight),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          TGhost(
            'Neues Foto',
            onTap: () => setState(() => _phase = _Phase.bereit),
          ),
          if (_gespeichert && g != null) ...[
            const SizedBox(height: 8),
            TLink(
              'Im Kochbuch ansehen ›',
              onTap: () =>
                  zeigeSeite(context, GerichtSeite(umfeld: u, id: g.id)),
            ),
          ],
        ],
      },
    );
  }
}
