import 'dart:convert';

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'form_aufnahme.dart';
import 'form_video.dart';
import 'training_coach.dart';
import 'training_widgets.dart';

/// Idea 10: film one set of an exercise. The stills are kept with the
/// exercise and the coach gives "Hinweise vom Coach" (Phillip's wording,
/// 2026-10-26): what is good, what can be better, and a comparison with the
/// last video. No exact analysis; with pain it says "geh zum Arzt".
class FormCheckSeite extends StatefulWidget {
  const FormCheckSeite({
    super.key,
    required this.uebung,
    required this.satz,
    required this.coach,
    required this.videos,
    required this.onSpeichern,
    required this.heute,
    this.zeigen,
  });

  final String uebung;

  /// The set it belongs to, e.g. "82,5 kg × 8".
  final String satz;
  final TrainingCoach coach;

  /// All saved videos (to compare with the last one of this exercise).
  final List<FormVideo> videos;
  final Future<void> Function(FormVideo v) onSpeichern;
  final DateTime heute;

  /// Opens a saved video instead of the camera.
  final FormVideo? zeigen;

  @override
  State<FormCheckSeite> createState() => _FormCheckSeiteState();
}

enum _Phase { bereit, auswerten, fertig }

class _FormCheckSeiteState extends State<FormCheckSeite> {
  late _Phase _phase = widget.zeigen == null ? _Phase.bereit : _Phase.fertig;
  late FormVideo? _video = widget.zeigen;
  String? _fehler;

  FormVideo? get _frueher {
    for (final v in widget.videos.reversed) {
      if (v.uebung.toLowerCase() == widget.uebung.toLowerCase() &&
          v.id != _video?.id &&
          v.hinweise != null) {
        return v;
      }
    }
    return null;
  }

  Future<void> _aufnehmen() async {
    setState(() => _fehler = null);
    final bilder = await formAufnahme();
    if (!mounted) return;
    if (bilder == null || bilder.isEmpty) {
      setState(
        () => _fehler =
            'Keine Aufnahme. Film einen Satz oder wähl ein Video aus. Auf '
            'dem Handy geht das ab der Handy-Version direkt mit der Kamera.',
      );
      return;
    }
    final frueher = _frueher;
    var v = FormVideo(
      id: '${widget.heute.microsecondsSinceEpoch}',
      uebung: widget.uebung,
      datum: widget.heute,
      satz: widget.satz,
      bilder: bilder,
    );
    setState(() {
      _video = v;
      _phase = _Phase.auswerten;
    });
    final h = await widget.coach.formCheck(
      widget.uebung,
      widget.satz,
      bilder,
      frueher: frueher?.hinweise?.text,
    );
    if (h != null) v = v.mitHinweisen(h);
    await widget.onSpeichern(v);
    if (!mounted) return;
    setState(() {
      _video = v;
      _phase = _Phase.fertig;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachStyle.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: CoachStyle.goldLight,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: CoachStyle.nightGradient),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                children: switch (_phase) {
                  _Phase.bereit => _bereit(),
                  _Phase.auswerten => _auswerten(),
                  _Phase.fertig => _ergebnis(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _kopf(String label, String titel) => [
    TLabel(label),
    const SizedBox(height: 4),
    GoldText(titel, style: tTitel.copyWith(fontSize: 22)),
    const SizedBox(height: 14),
  ];

  List<Widget> _bereit() => [
    ..._kopf('${widget.uebung} · ${widget.satz}', 'Form filmen'),
    Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const RadialGradient(
          center: Alignment(0, 0.2),
          colors: [Color(0xFF2C2219), Color(0xFF0D0A07)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CoachStyle.goldLight, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x55E0BF7E), blurRadius: 18),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 30,
            right: 30,
            top: 32,
            child: Text(
              'Handy seitlich hinlegen, ganzer Körper im goldenen Rahmen. '
              'Ein Satz reicht.',
              textAlign: TextAlign.center,
              style: tSoft,
            ),
          ),
          const Center(
            child: Icon(
              Icons.accessibility_new,
              size: 90,
              color: Color(0x55CDBB98),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    MainButton(
      key: const ValueKey('form-aufnehmen'),
      label: 'Aufnehmen',
      onPressed: _aufnehmen,
    ),
    const SizedBox(height: 8),
    Text(
      'Das Video wird bei ${widget.uebung} gespeichert.',
      style: tSoft,
      textAlign: TextAlign.center,
    ),
    if (_fehler != null) ...[
      const SizedBox(height: 10),
      Text(
        _fehler!,
        style: tSoft.copyWith(color: CoachStyle.goldLight),
        textAlign: TextAlign.center,
      ),
    ],
  ];

  List<Widget> _auswerten() => [
    ..._kopf(widget.uebung, 'Coach schaut sich das an …'),
    _bilder(const {}),
    const SizedBox(height: 14),
    const Center(child: CircularProgressIndicator(color: CoachStyle.gold)),
  ];

  Widget _bilder(Set<int> markiert) {
    final b = _video?.bilder ?? const [];
    const namen = ['Start', 'unten', 'hoch', 'letzte Wdh'];
    return Row(
      children: [
        for (var k = 0; k < b.length; k++) ...[
          if (k > 0) const SizedBox(width: 6),
          Expanded(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: markiert.contains(k)
                        ? CoachStyle.goldLight
                        : const Color(0xFF4A3B2A),
                    width: markiert.contains(k) ? 1.6 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      base64Decode(b[k]),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Color(0xFF1A140E)),
                    ),
                    Positioned(
                      left: 5,
                      bottom: 4,
                      child: Text(
                        'Bild ${k + 1}${k < namen.length ? ' · ${namen[k]}' : ''}',
                        style: tSoft.copyWith(
                          fontSize: 9,
                          color: CoachStyle.ink,
                        ),
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

  List<Widget> _ergebnis() {
    final v = _video!;
    final h = v.hinweise;
    final markiert = {
      for (final b in h?.besser ?? const <({String text, int? bild})>[])
        if (b.bild != null) b.bild! - 1,
    };
    return [
      ..._kopf('${v.uebung} · ${v.satz}', 'Hinweise vom Coach'),
      _bilder(markiert),
      const SizedBox(height: 12),
      if (h == null)
        TKarte(
          child: Text(
            'Der Coach ist gerade nicht erreichbar. Das Video ist bei '
            '${v.uebung} gespeichert, die Hinweise kannst du später holen.',
            style: tText,
          ),
        )
      else ...[
        TKarte(
          key: const ValueKey('form-hinweise'),
          child: Column(
            children: [
              for (final g in h.gut) _Hinweis(gut: true, text: g),
              for (final b in h.besser)
                _Hinweis(
                  gut: false,
                  text: b.text,
                  bild: b.bild == null ? null : 'Bild ${b.bild}',
                ),
            ],
          ),
        ),
        if (h.vergleich != null) TKarte(child: CoachZeile(text: h.vergleich!)),
      ],
      Text(
        'Hinweise aus ein paar Standbildern, keine exakte Analyse. Tut etwas '
        'weh, lass es abklären: geh zum Arzt.',
        style: tSoft.copyWith(fontSize: 11.5, color: CoachStyle.inkSoft),
      ),
      const SizedBox(height: 12),
      if (h == null)
        MainButton(
          key: const ValueKey('form-nochmal'),
          label: 'Hinweise holen',
          onPressed: () async {
            setState(() => _phase = _Phase.auswerten);
            final neu = await widget.coach.formCheck(
              v.uebung,
              v.satz,
              v.bilder,
              frueher: _frueher?.hinweise?.text,
            );
            final gespeichert = neu == null ? v : v.mitHinweisen(neu);
            await widget.onSpeichern(gespeichert);
            if (!mounted) return;
            setState(() {
              _video = gespeichert;
              _phase = _Phase.fertig;
            });
          },
        ),
      if (widget.zeigen == null || h != null)
        TGhost(
          'Neu aufnehmen',
          key: const ValueKey('form-neu'),
          onTap: () => setState(() {
            _video = null;
            _phase = _Phase.bereit;
          }),
        ),
    ];
  }
}

class _Hinweis extends StatelessWidget {
  const _Hinweis({required this.gut, required this.text, this.bild});
  final bool gut;
  final String text;
  final String? bild;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gut ? const Color(0xFF2D3A22) : const Color(0xFF3D2A14),
          ),
          child: gut
              ? const Icon(Icons.check, size: 14, color: Color(0xFFBCD99A))
              : const Text(
                  '!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5DFAE),
                  ),
                ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: tText.copyWith(fontSize: 13)),
              if (bild != null)
                Text(bild!, style: tSoft.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}
