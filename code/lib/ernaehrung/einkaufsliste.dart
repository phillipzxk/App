import 'package:flutter/material.dart';

import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import 'ernaehrung_data.dart';
import 'ernaehrung_logik.dart';
import 'ernaehrung_stand.dart';

/// Idea 5: the dishes of the week and how often, their ingredients added
/// up and sorted for the shop, ticked off there; own items on top.
class EinkaufslisteSeite extends StatefulWidget {
  const EinkaufslisteSeite({super.key, required this.umfeld});
  final EssenUmfeld umfeld;

  @override
  State<EinkaufslisteSeite> createState() => _EinkaufslisteSeiteState();
}

class _EinkaufslisteSeiteState extends State<EinkaufslisteSeite> {
  final _eigen = TextEditingController();

  EssenUmfeld get u => widget.umfeld;

  @override
  void dispose() {
    _eigen.dispose();
    super.dispose();
  }

  Future<void> _einkauf(Einkauf e) => u.stand.setze(u.d.copyWith(einkauf: e));

  Future<void> _dazu() async {
    final t = _eigen.text.trim();
    if (t.isEmpty) return;
    _eigen.clear();
    await _einkauf(u.d.einkauf.copyWith(eigene: [...u.d.einkauf.eigene, t]));
  }

  @override
  Widget build(BuildContext context) => EssenSeite(
    umfeld: u,
    label: 'Ernährung',
    titel: 'Einkaufsliste',
    bau: (context) {
      final d = u.d;
      final e = d.einkauf;
      final gerichte = [
        for (final g in d.gerichte)
          if (g.freiAb == null &&
              g.bewertung != 'nicht meins' &&
              g.zutaten.isNotEmpty)
            g,
      ];
      final posten = einkaufsliste(d);
      final gruppen = [...Zutat.gruppen, 'Eigenes'];
      return [
        TKarte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TLabel('Was kochst du diese Woche?'),
              if (gerichte.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Noch keine Gerichte mit Zutaten. Im Kochbuch findest du '
                    'deine Rettungsgerichte.',
                    style: tSoft,
                  ),
                ),
              for (final g in gerichte)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF2E261C))),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(g.name, style: tText)),
                      _Knopf(
                        '−',
                        key: ValueKey('liste-minus-${g.id}'),
                        onTap: () => _einkauf(
                          e.copyWith(
                            auswahl: {
                              ...e.auswahl,
                              g.id: ((e.auswahl[g.id] ?? 0) - 1).clamp(0, 14),
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${e.auswahl[g.id] ?? 0}×',
                          textAlign: TextAlign.center,
                          style: tTitel.copyWith(fontSize: 14),
                        ),
                      ),
                      _Knopf(
                        '+',
                        key: ValueKey('liste-plus-${g.id}'),
                        onTap: () => _einkauf(
                          e.copyWith(
                            auswahl: {
                              ...e.auswahl,
                              g.id: ((e.auswahl[g.id] ?? 0) + 1).clamp(0, 14),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        TKarte(
          key: const ValueKey('einkaufsliste'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (posten.isEmpty)
                const Text(
                  'Wähl oben Gerichte aus oder schreib unten etwas dazu.',
                  style: tSoft,
                ),
              for (final gr in gruppen)
                if (posten.any((p) => p.gruppe == gr)) ...[
                  const SizedBox(height: 8),
                  TLabel(gr),
                  for (final p in posten.where((p) => p.gruppe == gr))
                    _Posten(
                      p: p,
                      an: e.erledigt.contains(p.key),
                      onTap: () => _einkauf(
                        e.copyWith(
                          erledigt: e.erledigt.contains(p.key)
                              ? (e.erledigt.toSet()..remove(p.key))
                              : {...e.erledigt, p.key},
                        ),
                      ),
                    ),
                ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('liste-eigen'),
                      controller: _eigen,
                      style: tText,
                      onSubmitted: (_) => _dazu(),
                      decoration: InputDecoration(
                        hintText: 'Noch was dazu',
                        hintStyle: tSoft,
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF1A140E),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 11,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A3B2A),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: CoachStyle.goldLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 96,
                    child: TGhost(
                      'Dazu',
                      key: const ValueKey('liste-eigen-dazu'),
                      onTap: _dazu,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (posten.isNotEmpty)
          TLink(
            'Neue Woche: Liste leeren',
            key: const ValueKey('liste-neu'),
            soft: true,
            onTap: () => _einkauf(const Einkauf()),
          ),
      ];
    },
  );
}

class _Knopf extends StatelessWidget {
  const _Knopf(this.text, {super.key, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(999),
    onTap: onTap,
    child: Container(
      width: 34,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF4A3B2A)),
        color: const Color(0xFF1A140E),
      ),
      child: Text(text, style: tTitel.copyWith(color: CoachStyle.goldLight)),
    ),
  );
}

class _Posten extends StatelessWidget {
  const _Posten({required this.p, required this.an, required this.onTap});
  final EinkaufPosten p;
  final bool an;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('posten-${p.key}'),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2E261C))),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: an ? CoachStyle.goldGradient : null,
              border: an ? null : Border.all(color: const Color(0xFF6B5535)),
            ),
            child: an
                ? const Icon(Icons.check, size: 14, color: CoachStyle.goldInk)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: tText.copyWith(
                    color: an ? CoachStyle.inkSoft : CoachStyle.ink,
                    decoration: an ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (p.fuer.isNotEmpty)
                  Text(
                    p.fuer.join(', '),
                    style: tSoft.copyWith(fontSize: 10.5),
                  ),
              ],
            ),
          ),
          Text(p.mengeText, style: tSoft),
        ],
      ),
    ),
  );
}
