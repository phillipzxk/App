import 'dart:convert';

import 'package:flutter/material.dart';

import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'ernaehrung_coach.dart';
import 'ernaehrung_data.dart';
import 'ernaehrung_logik.dart';
import 'ernaehrung_stand.dart';

/// Idea 3: a photo of the plate, the coach says roughly how it fits the
/// goal: protein, vegetables, size. In words, never numbers.
class TellerFotoSeite extends StatefulWidget {
  const TellerFotoSeite({super.key, required this.umfeld, required this.slot});

  final EssenUmfeld umfeld;
  final MahlzeitSlot slot;

  @override
  State<TellerFotoSeite> createState() => _TellerFotoSeiteState();
}

enum _Phase { bereit, lesen, fertig }

class _TellerFotoSeiteState extends State<TellerFotoSeite> {
  EssenUmfeld get u => widget.umfeld;
  MahlzeitEintrag get _eintrag =>
      u.d.tag(u.heute)[widget.slot.id] ?? const MahlzeitEintrag();

  late _Phase _phase = _eintrag.bild != null || _eintrag.teller != null
      ? _Phase.fertig
      : _Phase.bereit;
  String? _fehler;
  bool _ohneCoach = false;

  Future<void> _aufnehmen() async {
    setState(() => _fehler = null);
    final bild = await fotoAufnahme();
    if (!mounted) return;
    if (bild == null) {
      setState(() => _fehler = 'Kein Foto. Versuch es nochmal.');
      return;
    }
    setState(() => _phase = _Phase.lesen);
    final h = await u.coach.teller(u.profile, widget.slot.name, bild);
    await u.stand.setze(
      u.d.mitEintrag(
        u.heute,
        widget.slot.id,
        MahlzeitEintrag(
          gegessen: true,
          gefuehl: _eintrag.gefuehl,
          teller: h,
          bild: bild,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _ohneCoach = h == null;
      _phase = _Phase.fertig;
    });
  }

  @override
  Widget build(BuildContext context) => EssenSeite(
    umfeld: u,
    label: '${widget.slot.name} · ${widget.slot.uhrzeit}',
    titel: _phase == _Phase.fertig
        ? 'Hinweise vom Coach'
        : 'Teller fotografieren',
    bau: (context) => switch (_phase) {
      _Phase.bereit => [
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const RadialGradient(
              colors: [Color(0xFF3A2C1D), Color(0xFF0D0A07)],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CoachStyle.goldLight, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55E0BF7E), blurRadius: 18),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 60,
                    color: Color(0x55CDBB98),
                  ),
                ),
              ),
              const Positioned(
                left: 20,
                right: 20,
                top: 18,
                child: Text(
                  'Von oben, ganzer Teller im goldenen Kreis',
                  textAlign: TextAlign.center,
                  style: tSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        MainButton(
          key: const ValueKey('teller-aufnehmen'),
          label: 'Foto machen',
          onPressed: _aufnehmen,
        ),
        const SizedBox(height: 8),
        Text(
          'Wird bei „${widget.slot.name}“ gespeichert.',
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
        const Center(child: CircularProgressIndicator(color: CoachStyle.gold)),
        const SizedBox(height: 12),
        const Text(
          'Coach schaut drauf …',
          style: tSoft,
          textAlign: TextAlign.center,
        ),
      ],
      _Phase.fertig => _ergebnis(),
    },
  );

  List<Widget> _ergebnis() {
    final e = _eintrag;
    final h = e.teller;
    return [
      if (e.bild != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.memory(
              base64Decode(e.bild!),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF1A140E)),
            ),
          ),
        ),
      const SizedBox(height: 12),
      if (h == null)
        TKarte(
          child: Text(
            _ohneCoach || e.bild != null
                ? 'Der Coach ist gerade nicht erreichbar. Die Mahlzeit ist als '
                      'gegessen gespeichert.'
                : 'Noch kein Foto.',
            style: tText,
          ),
        )
      else ...[
        TKarte(
          key: const ValueKey('teller-hinweise'),
          child: Column(
            children: [
              _Zeile('Eiweiß', h.eiweiss, h.eiweissText),
              _Zeile('Gemüse', h.gemuese, h.gemueseText),
              _Zeile('Größe', h.groesse, h.groesseText),
            ],
          ),
        ),
        if (h.tipp != null) TKarte(child: CoachZeile(text: h.tipp!)),
      ],
      Text(
        'Hinweise aus dem Foto, keine genaue Messung. Gezählt wird nichts.',
        style: tSoft.copyWith(fontSize: 11.5, color: CoachStyle.inkSoft),
      ),
      const SizedBox(height: 12),
      TGhost(
        'Neues Foto',
        key: const ValueKey('teller-neu'),
        onTap: () => setState(() => _phase = _Phase.bereit),
      ),
    ];
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile(this.name, this.stufe, this.text);
  final String name;
  final int stufe;
  final String? text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(name, style: tSoft)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: StufenBalken(stufe),
              ),
              if (text != null) ...[
                const SizedBox(height: 4),
                Text(text!, style: tSoft),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
