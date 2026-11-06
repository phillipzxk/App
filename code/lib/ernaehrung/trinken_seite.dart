import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../sleep/schlafzeiten.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'ernaehrung_data.dart';
import 'ernaehrung_stand.dart';

/// Trinken: a glass that fills with every tap of water. Coffee and alcohol
/// get one small counter each, because both change the night.
class TrinkenSeite extends StatelessWidget {
  const TrinkenSeite({super.key, required this.umfeld});
  final EssenUmfeld umfeld;

  EssenUmfeld get u => umfeld;

  Future<void> _setze(TrinkTag t) => u.stand.setze(u.d.mitTrinken(u.heute, t));

  @override
  Widget build(BuildContext context) => EssenSeite(
    umfeld: u,
    label: 'Ernährung',
    titel: 'Trinken',
    bau: (context) {
      final t = u.d.trinkTag(u.heute);
      final ziel = wasserZiel(u.kg, training: u.training != null);
      final jetzt = u.jetzt();
      final minute = jetzt.hour * 60 + jetzt.minute;
      return [
        TKarte(child: CoachZeile(text: trinkSatz(t, ziel))),
        TKarte(
          key: const ValueKey('trinken-glas'),
          gold: true,
          child: Column(
            children: [
              TrinkGlas(anteil: t.liter / ziel, size: 150),
              const SizedBox(height: 10),
              GoldText(
                '${literText(t.liter)} von ${literText(ziel)} l',
                key: const ValueKey('trinken-stand'),
                style: tTitel.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 2),
              Text(
                u.kg == null
                    ? 'Ziel grob geschätzt. Trag dein Gewicht ein, dann passt es.'
                    : 'Aus deinem Gewicht${u.training != null ? ' und dem Training heute' : ''}.',
                style: tSoft,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              MainButton(
                key: const ValueKey('trinken-glas-plus'),
                label: 'Ein Glas getrunken',
                onPressed: () => _setze(t.copyWith(glaeser: t.glaeser + 1)),
              ),
              if (t.glaeser > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TLink(
                    'Eins zurück',
                    key: const ValueKey('trinken-glas-minus'),
                    soft: true,
                    onTap: () => _setze(t.copyWith(glaeser: t.glaeser - 1)),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _Zaehler(
                id: 'trinken-kaffee',
                icon: Icons.coffee_outlined,
                name: 'Kaffee',
                zahl: t.kaffee.length,
                unter: t.kaffee.isEmpty
                    ? 'heute noch keiner'
                    : 'letzter ${formatUhrzeit(t.kaffee.last)}',
                plus: () => _setze(t.copyWith(kaffee: [...t.kaffee, minute])),
                minus: t.kaffee.isEmpty
                    ? null
                    : () => _setze(
                        t.copyWith(
                          kaffee: t.kaffee.sublist(0, t.kaffee.length - 1),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Zaehler(
                id: 'trinken-alkohol',
                icon: Icons.wine_bar_outlined,
                name: 'Alkohol',
                zahl: t.alkohol,
                unter: 'Gläser heute',
                plus: () => _setze(t.copyWith(alkohol: t.alkohol + 1)),
                minus: t.alkohol == 0
                    ? null
                    : () => _setze(t.copyWith(alkohol: t.alkohol - 1)),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Der Coach sieht, was du trinkst, und verbindet es mit deinem '
            'Schlaf und deiner Energie.',
            style: tSoft,
            textAlign: TextAlign.center,
          ),
        ),
      ];
    },
  );
}

/// The coach line on top of the page.
String trinkSatz(TrinkTag t, double ziel) {
  if (t.kaffee.any((m) => m >= 14 * 60)) {
    return 'Kaffee nach 14 Uhr wirkt noch, wenn du ins Bett gehst. Morgen '
        'lieber den letzten vor 14 Uhr.';
  }
  if (t.alkohol > 0) {
    return 'Alkohol lässt dich schneller einschlafen, aber die Nacht wird '
        'flacher. Trink heute Abend noch ein Glas Wasser extra.';
  }
  if (t.liter >= ziel) return 'Dein Wasser für heute ist drin. Stark.';
  if (t.glaeser == 0) {
    return 'Fang mit einem Glas Wasser an. Am besten gleich nach dem '
        'Aufstehen.';
  }
  return 'Noch ${literText(ziel - t.liter)} l. Stell dir ein Glas dahin, '
      'wo du gerade bist.';
}

class _Zaehler extends StatelessWidget {
  const _Zaehler({
    required this.id,
    required this.icon,
    required this.name,
    required this.zahl,
    required this.unter,
    required this.plus,
    required this.minus,
  });

  final IconData icon;
  final String id, name, unter;
  final int zahl;
  final VoidCallback plus;
  final VoidCallback? minus;

  @override
  Widget build(BuildContext context) => TKarte(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: CoachStyle.goldLight),
            const SizedBox(width: 6),
            Text(name, style: tText.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        GoldText('$zahl', style: tTitel.copyWith(fontSize: 26)),
        Text(unter, style: tSoft),
        const SizedBox(height: 8),
        Row(
          children: [
            _Rund(icon: Icons.remove, onTap: minus, key: ValueKey('$id-minus')),
            const SizedBox(width: 8),
            _Rund(icon: Icons.add, onTap: plus, key: ValueKey('$id-plus')),
          ],
        ),
      ],
    ),
  );
}

class _Rund extends StatelessWidget {
  const _Rund({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: 22,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: onTap == null
              ? const Color(0x33CDBB98)
              : CoachStyle.goldLight.withValues(alpha: 0.7),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: onTap == null ? const Color(0x55CDBB98) : CoachStyle.goldLight,
      ),
    ),
  );
}

/// A glass drawn as an outline that fills with gold water. The level
/// glides when it changes.
class TrinkGlas extends StatelessWidget {
  const TrinkGlas({super.key, required this.anteil, this.size = 60});
  final double anteil;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: anteil.clamp(0, 1).toDouble()),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) =>
        CustomPaint(size: Size(size * 0.72, size), painter: _GlasMaler(v)),
  );
}

class _GlasMaler extends CustomPainter {
  _GlasMaler(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final innen = 0.1 * w;
    Path glas(double inset) => Path()
      ..moveTo(inset, inset)
      ..lineTo(w - inset, inset)
      ..lineTo(w - innen - inset, h - inset)
      ..lineTo(innen + inset, h - inset)
      ..close();
    final rand = glas(w * 0.03);
    canvas.save();
    canvas.clipPath(rand);
    if (v > 0) {
      final top = h - (h * 0.92) * v;
      final welle = Path()..moveTo(0, top);
      for (var x = 0.0; x <= w; x += 2) {
        welle.lineTo(x, top + math.sin(x / w * math.pi * 2) * h * 0.012);
      }
      welle
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(
        welle,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCCE9CC8E), Color(0xCC8A6A33)],
          ).createShader(Offset.zero & s),
      );
      // A soft light stripe on the left side of the water.
      canvas.drawRect(
        Rect.fromLTWH(w * 0.2, top + h * 0.04, w * 0.06, h - top),
        Paint()..color = const Color(0x22FFF4DC),
      );
    }
    canvas.restore();
    canvas.drawPath(
      rand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, w * 0.03)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFCDBB98),
    );
  }

  @override
  bool shouldRepaint(_GlasMaler old) => old.v != v;
}
