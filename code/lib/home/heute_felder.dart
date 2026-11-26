import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../feed/muster.dart';
import '../health/health_logik.dart';
import '../ui/umbau.dart';

/// The small fields that only show up on "Heute" from time to time (Dein
/// Warum, a pattern, what the phone measured), together in ONE glass tile
/// ("3 klar", confirmed by Phillip 2026-11-13, vault Umsetzung/Umbau.md).
/// Each part is only there when it has something to say.
class HeuteFelder extends StatelessWidget {
  const HeuteFelder({
    super.key,
    this.warum = '',
    this.warumSatz = '',
    this.muster,
    this.musterNeu = false,
    this.onOpenMuster,
    this.health = const [],
    this.onHealthKnopf,
  });

  final String warum;
  final String warumSatz;
  final Muster? muster;
  final bool musterNeu;
  final VoidCallback? onOpenMuster;
  final List<HealthFeld> health;
  final ValueChanged<HealthFeld>? onHealthKnopf;

  bool get _hatWarum => warum.isNotEmpty && warumSatz.isNotEmpty;
  bool get _hatHealth => health.isNotEmpty && onHealthKnopf != null;

  /// Nothing to show: the tile is left out.
  bool get leer => !_hatWarum && muster == null && !_hatHealth;

  static const _gold = Color(0xFFE2BD7A);
  static final _label = Umbau.label.copyWith(color: _gold);
  static const _text = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 14,
    height: 1.4,
    color: Umbau.text,
  );
  static const _leise = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 12.5,
    height: 1.4,
    color: Umbau.weich,
  );

  @override
  Widget build(BuildContext context) {
    final teile = <Widget>[
      if (_hatWarum)
        Row(
          key: const ValueKey('warum-karte'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 34,
              height: 30,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: 70,
                child: GoldMaske(
                  child: Text(
                    '„',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 54,
                      height: .5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEIN WARUM', style: _label),
                  const SizedBox(height: 6),
                  Text(
                    warum,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      height: 1.35,
                      color: Umbau.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(warumSatz, style: _leise.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      if (muster case final m?)
        _MusterZeile(
          key: const ValueKey('muster-feld'),
          muster: m,
          neu: musterNeu,
          onOpen: onOpenMuster,
          label: _label,
          text: _text,
          leise: _leise,
        ),
      if (_hatHealth)
        Column(
          key: const ValueKey('health-felder'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('GESUNDHEIT', style: _label),
            const SizedBox(height: 4),
            for (final f in health)
              ConstrainedBox(
                key: ValueKey('health-feld-${f.id}'),
                constraints: const BoxConstraints(minHeight: 36),
                child: Row(
                  children: [
                    Expanded(child: Text(f.text, style: _text)),
                    const SizedBox(width: 8),
                    if (f.knopf)
                      GestureDetector(
                        key: ValueKey('health-knopf-${f.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onHealthKnopf!(f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: Umbau.grad,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            f.rechts,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: Umbau.tinte,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        f.rechts,
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: _gold,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
    ];
    // Denser glass than the other tiles: the glowing roots behind it must
    // not run through the text (Rundgang 2026-11-26).
    return Einflug(
      platz: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Umbau.radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            key: const ValueKey('heute-felder'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xD92A2119),
              borderRadius: BorderRadius.circular(Umbau.radius),
              border: Border.all(color: const Color(0x0DFFF5E6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < teile.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: SizedBox(
                        height: 1,
                        child: ColoredBox(color: Umbau.linie),
                      ),
                    ),
                  teile[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The newest pattern on Heute: one short sentence that fits completely.
/// Tapping shows the counter-step and a way to all patterns
/// (Rundgang 2026-11-26).
class _MusterZeile extends StatefulWidget {
  const _MusterZeile({
    super.key,
    required this.muster,
    required this.neu,
    required this.onOpen,
    required this.label,
    required this.text,
    required this.leise,
  });
  final Muster muster;
  final bool neu;
  final VoidCallback? onOpen;
  final TextStyle label;
  final TextStyle text;
  final TextStyle leise;

  @override
  State<_MusterZeile> createState() => _MusterZeileState();
}

class _MusterZeileState extends State<_MusterZeile> {
  bool _offen = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.muster;
    final schritt = m.schritt.trim();
    const gold = Color(0xFFE2BD7A);
    const knopf = TextStyle(
      fontFamily: 'Sora',
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: gold,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => schritt.isEmpty
          ? widget.onOpen?.call()
          : setState(() => _offen = !_offen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.neu ? 'NEUES MUSTER' : 'DEINE MUSTER',
            style: widget.label,
          ),
          const SizedBox(height: 4),
          Text(m.heuteText, style: widget.text),
          const SizedBox(height: 8),
          if (schritt.isNotEmpty)
            Text(
              _offen ? 'Gegenschritt' : 'Gegenschritt ›',
              key: const ValueKey('muster-gegenschritt'),
              style: knopf,
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: !_offen
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(schritt, style: widget.leise),
                      if (widget.onOpen != null) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          key: const ValueKey('muster-alle'),
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onOpen,
                          child: const Text('Alle Muster ›', style: knopf),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
