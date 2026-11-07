import 'package:flutter/material.dart';

import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'ernaehrung_coach.dart';
import 'ernaehrung_logik.dart';
import 'ernaehrung_stand.dart';
import 'kuehlschrank.dart';
import 'teller_foto.dart';

/// One Foto button for plate and fridge. The coach looks at the photo
/// and opens the right page: a plate gets the rough read, a fridge gets
/// a dish for today. If the coach can't tell, the user taps which one.
class FotoSeite extends StatefulWidget {
  const FotoSeite({super.key, required this.umfeld});
  final EssenUmfeld umfeld;

  @override
  State<FotoSeite> createState() => _FotoSeiteState();
}

class _FotoSeiteState extends State<FotoSeite> {
  bool _laedt = false;
  String? _bild;
  String? _fehler;

  EssenUmfeld get u => widget.umfeld;

  /// The meal a plate photo belongs to: the next open one, else the last.
  MahlzeitSlot? get _slot {
    final slots = u.mahlzeiten();
    if (slots.isEmpty) return null;
    final eintraege = u.d.tag(u.heute);
    for (final s in slots) {
      if (eintraege[s.id]?.gegessen != true) return s;
    }
    return slots.last;
  }

  Future<void> _aufnehmen() async {
    setState(() => _fehler = null);
    final bild = await fotoAufnahme();
    if (!mounted) return;
    if (bild == null) {
      setState(() => _fehler = 'Kein Foto. Versuch es nochmal.');
      return;
    }
    setState(() {
      _bild = bild;
      _laedt = true;
    });
    final art = await u.coach.fotoArt(bild);
    if (!mounted) return;
    setState(() => _laedt = false);
    if (art != null) _weiter(art);
  }

  void _weiter(String art) {
    final bild = _bild;
    if (bild == null) return;
    final slot = _slot;
    final Widget ziel = art == 'teller' && slot != null
        ? TellerFotoSeite(umfeld: u, slot: slot, bild: bild)
        : KuehlschrankSeite(umfeld: u, bild: bild);
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => ziel));
  }

  @override
  Widget build(BuildContext context) => EssenSeite(
    umfeld: u,
    label: 'Ernährung',
    titel: 'Foto',
    bau: (context) {
      if (_laedt) {
        return const [
          SizedBox(height: 30),
          Center(child: CircularProgressIndicator(color: CoachStyle.gold)),
          SizedBox(height: 14),
          Text(
            'Der Coach schaut, was du fotografiert hast.',
            style: tSoft,
            textAlign: TextAlign.center,
          ),
        ];
      }
      if (_bild != null) {
        // The coach couldn't tell: the user taps which one it is.
        return [
          const TKarte(
            child: CoachZeile(
              text: 'Ich bin mir nicht sicher. Was ist auf dem Foto?',
            ),
          ),
          MainButton(
            key: const ValueKey('foto-teller'),
            label: 'Mein Essen',
            onPressed: () => _weiter('teller'),
          ),
          const SizedBox(height: 8),
          TGhost(
            'Mein Kühlschrank',
            key: const ValueKey('foto-kuehlschrank'),
            onTap: () => _weiter('kuehlschrank'),
          ),
        ];
      }
      return [
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant, size: 54, color: Color(0x55CDBB98)),
                    SizedBox(width: 18),
                    Icon(
                      Icons.kitchen_outlined,
                      size: 54,
                      color: Color(0x55CDBB98),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        MainButton(
          key: const ValueKey('foto-aufnehmen'),
          label: 'Foto machen',
          onPressed: _aufnehmen,
        ),
        const SizedBox(height: 8),
        const Text(
          'Dein Teller: grobe Einschätzung, ohne Zahlen. Dein Kühlschrank: '
          'ein Gericht für heute.',
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
      ];
    },
  );
}
