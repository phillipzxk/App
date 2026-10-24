import 'package:flutter/material.dart';

import '../feed/fokus.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'feed_widgets.dart';

/// Gold-edged dark frame shared by both focus cards.
class GoldRahmen extends StatelessWidget {
  const GoldRahmen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CoachStyle.nightShadow,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2118), Color(0xFF1B1611)],
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: child,
      ),
    );
  }
}

Widget _kopf(String label, {String? rechts}) => Row(
  children: [
    const SymbolBadge(Icons.track_changes, size: 30),
    const SizedBox(width: 10),
    Expanded(
      child: Text(
        label,
        style: CoachStyle.goldLabel.copyWith(color: CoachStyle.goldLight),
      ),
    ),
    if (rechts != null)
      Text(
        rechts,
        style: CoachStyle.body.copyWith(
          fontSize: 12,
          color: CoachStyle.inkSoft,
        ),
      ),
  ],
);

/// The running week: the focus, one stroke per day from the start day,
/// and "Heute geschafft" to tick today off (tap again to take it back).
class FokusKarte extends StatelessWidget {
  const FokusKarte({
    super.key,
    required this.fokus,
    required this.today,
    required this.onUmschalten,
  });

  final Wochenfokus fokus;
  final DateTime today;
  final VoidCallback onUmschalten;

  @override
  Widget build(BuildContext context) {
    final tag = fokus.tag(today).clamp(1, Wochenfokus.tage);
    final striche = fokus.striche;
    final bisher = striche.take(tag).where((x) => x).length;
    final heute = fokus.heuteGeschafft(today);
    return GoldRahmen(
      key: const ValueKey('fokus-karte'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kopf('FOKUS DER WOCHE', rechts: 'Tag $tag von ${Wochenfokus.tage}'),
          const SizedBox(height: 11),
          Text(
            fokus.text,
            style: CoachStyle.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF6EEDD),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < Wochenfokus.tage; i++)
                Expanded(
                  child: Container(
                    key: ValueKey('fokus-strich-$i'),
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: striche[i] ? CoachStyle.goldGradient : null,
                      color: striche[i]
                          ? null
                          : i < tag
                          ? const Color(0xFF4A3D2E)
                          : CoachStyle.nightLineStrong,
                      borderRadius: BorderRadius.circular(4),
                      border: i == tag - 1 && !striche[i]
                          ? Border.all(color: CoachStyle.goldBright, width: 1.5)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 8,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$bisher von $tag ${tag == 1 ? 'Tag' : 'Tagen'} geschafft',
                  style: CoachStyle.body.copyWith(
                    fontSize: 12.5,
                    color: CoachStyle.inkSoft,
                  ),
                ),
              ),
              _Pille(
                key: const ValueKey('fokus-heute'),
                label: heute ? '✓ Heute geschafft' : 'Heute geschafft',
                an: heute,
                onTap: onUmschalten,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Round button: gold when done, outlined while open.
class _Pille extends StatelessWidget {
  const _Pille({
    super.key,
    required this.label,
    required this.an,
    required this.onTap,
  });

  final String label;
  final bool an;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: an,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: an ? CoachStyle.goldGradient : null,
              borderRadius: BorderRadius.circular(999),
              border: an ? null : Border.all(color: CoachStyle.goldEdge),
            ),
            child: Text(
              label,
              style: CoachStyle.body.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: an ? CoachStyle.goldInk : CoachStyle.goldLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Choosing the focus: the look back on last week (if any), the coach's
/// three suggestions and "Diesen Fokus starten".
class FokusWahl extends StatefulWidget {
  const FokusWahl({
    super.key,
    required this.auswahl,
    required this.laedt,
    required this.onStart,
    required this.onNochmal,
    this.titel,
    this.mitRueckblick = true,
  });

  /// Null while loading or when the coach could not be reached.
  final FokusAuswahl? auswahl;

  /// Replaces the heading, e.g. on the Reality Check page.
  final String? titel;

  /// "Letzte Woche X von 7." above the options (not on the Reality Check
  /// page, which shows the week itself).
  final bool mitRueckblick;
  final bool laedt;
  final ValueChanged<FokusVorschlag> onStart;
  final VoidCallback onNochmal;

  @override
  State<FokusWahl> createState() => _FokusWahlState();
}

class _FokusWahlState extends State<FokusWahl> {
  int? _gewaehlt;

  @override
  void didUpdateWidget(FokusWahl old) {
    super.didUpdateWidget(old);
    if (old.auswahl != widget.auswahl) _gewaehlt = null;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.auswahl;
    final erstes = a == null || a.geschafft == null;
    return GoldRahmen(
      key: const ValueKey('fokus-wahl'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kopf(
            widget.titel ??
                (erstes
                    ? 'FOKUS DER WOCHE · WÄHL EINEN'
                    : 'NEUER FOKUS · WÄHL EINEN'),
          ),
          const SizedBox(height: 12),
          if (a == null)
            widget.laedt
                ? Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CoachStyle.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dein Coach sucht 3 Vorschläge für dich …',
                          style: CoachStyle.body.copyWith(
                            fontSize: 13.5,
                            color: CoachStyle.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Der Coach ist gerade nicht erreichbar.',
                          style: CoachStyle.body.copyWith(
                            fontSize: 13.5,
                            color: CoachStyle.inkSoft,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('fokus-nochmal'),
                        onPressed: widget.onNochmal,
                        child: const Text(
                          'Nochmal',
                          style: TextStyle(
                            color: CoachStyle.goldLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
          else ...[
            if (a.geschafft != null && widget.mitRueckblick) ...[
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFD4A85E), width: 2),
                  ),
                ),
                child: Text.rich(
                  key: const ValueKey('fokus-rueckblick'),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Letzte Woche ${a.geschafft} von 7.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5DFAE),
                        ),
                      ),
                      if ((a.rueckblick ?? '').isNotEmpty)
                        TextSpan(text: ' ${a.rueckblick}'),
                    ],
                  ),
                  style: CoachStyle.body.copyWith(
                    fontSize: 13.5,
                    color: CoachStyle.beigeLabel,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < a.vorschlaege.length; i++) ...[
              _Option(
                key: ValueKey('fokus-option-$i'),
                v: a.vorschlaege[i],
                gewaehlt: _gewaehlt == i,
                onTap: () => setState(() => _gewaehlt = i),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            MainButton(
              key: const ValueKey('fokus-start'),
              label: 'Diesen Fokus starten',
              onPressed: _gewaehlt == null
                  ? null
                  : () => widget.onStart(a.vorschlaege[_gewaehlt!]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.v,
    required this.gewaehlt,
    required this.onTap,
  });

  final FokusVorschlag v;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = gewaehlt ? CoachStyle.goldInk : const Color(0xFFF6EEDD);
    final sub = gewaehlt ? CoachStyle.creamInkSoft : CoachStyle.inkSoft;
    return Semantics(
      button: true,
      selected: gewaehlt,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
            decoration: BoxDecoration(
              gradient: gewaehlt ? CoachStyle.tileGradient : null,
              color: gewaehlt ? null : const Color(0xFF231C15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: gewaehlt ? const Color(0xFFD4A85E) : CoachStyle.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        v.text,
                        style: CoachStyle.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                    if (v.behalten) ...[
                      const SizedBox(width: 8),
                      Text(
                        'BEHALTEN',
                        style: CoachStyle.body.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: gewaehlt
                              ? const Color(0xFF7A5A2C)
                              : CoachStyle.gold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (v.warum.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    v.warum,
                    style: CoachStyle.body.copyWith(fontSize: 12.5, color: sub),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
