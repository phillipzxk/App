import 'package:flutter/material.dart';

import '../feed/fokus.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'feed_widgets.dart';
import 'fokus_widgets.dart';

/// Reality Check (see vault Umsetzung/Reality Check.md): on the day a focus
/// week ends, Heute shows only this small field instead of the focus
/// choice. Tapping it opens [RealityCheckSeite].
class RealityFeld extends StatelessWidget {
  const RealityFeld({
    super.key,
    required this.auswahl,
    required this.laedt,
    required this.onOpen,
    required this.onNochmal,
  });

  final FokusAuswahl? auswahl;
  final bool laedt;
  final VoidCallback onOpen;
  final VoidCallback onNochmal;

  @override
  Widget build(BuildContext context) {
    final bereit = auswahl != null;
    final text = bereit
        ? 'Deine Woche ist rum. Schau, was wirklich lief.'
        : laedt
        ? 'Dein Coach wertet deine Woche aus …'
        : 'Der Coach ist gerade nicht erreichbar.';
    return Semantics(
      button: bereit,
      child: GestureDetector(
        key: const ValueKey('reality-feld'),
        behavior: HitTestBehavior.opaque,
        onTap: bereit ? onOpen : null,
        child: GoldRahmen(
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CoachStyle.goldGradient,
                ),
                child: bereit || !laedt
                    ? const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: CoachStyle.goldInk,
                      )
                    : const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CoachStyle.goldInk,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEIN REALITY CHECK',
                      style: CoachStyle.goldLabel.copyWith(
                        color: CoachStyle.goldLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text,
                      style: CoachStyle.body.copyWith(
                        fontSize: 14.5,
                        color: bereit
                            ? const Color(0xFFF6EEDD)
                            : CoachStyle.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (bereit)
                const Text(
                  '›',
                  style: TextStyle(fontSize: 26, color: CoachStyle.goldLight),
                )
              else if (!laedt)
                TextButton(
                  key: const ValueKey('reality-nochmal'),
                  onPressed: onNochmal,
                  child: const Text(
                    'Nochmal',
                    style: TextStyle(
                      color: CoachStyle.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _monate = [
  'Jan',
  'Feb',
  'März',
  'Apr',
  'Mai',
  'Juni',
  'Juli',
  'Aug',
  'Sep',
  'Okt',
  'Nov',
  'Dez',
];

/// "Woche 20. bis 26. Okt" (or "28. Sep bis 4. Okt").
String wochenSpanne(DateTime start) {
  final ende = DateTime(start.year, start.month, start.day + 6);
  final a = start.month == ende.month
      ? '${start.day}.'
      : '${start.day}. ${_monate[start.month - 1]}';
  return 'Woche $a bis ${ende.day}. ${_monate[ende.month - 1]}';
}

/// The page: 1 planned vs. done, 2 what slowed you down, 3 the one change,
/// 4 the new focus (the one change is suggestion 1).
class RealityCheckSeite extends StatelessWidget {
  const RealityCheckSeite({
    super.key,
    required this.auswahl,
    required this.onStart,
  });

  final FokusAuswahl auswahl;
  final Future<void> Function(FokusVorschlag v) onStart;

  @override
  Widget build(BuildContext context) {
    final a = auswahl;
    final vorschlaege = a.vorschlaege;
    final veraenderung = vorschlaege.isEmpty || vorschlaege.first.behalten
        ? null
        : vorschlaege.first;
    // In the list the first option points back up instead of repeating why.
    final liste = FokusAuswahl(
      geschafft: a.geschafft,
      vorschlaege: [
        for (final v in vorschlaege)
          identical(v, veraenderung)
              ? FokusVorschlag(
                  text: v.text,
                  warum: 'Die eine Veränderung von oben',
                )
              : v.behalten && a.geschafft != null
              ? FokusVorschlag(
                  text: v.text,
                  warum: '${a.geschafft} von 7 geschafft',
                  behalten: true,
                )
              : v,
      ],
    );
    final t = a.training;
    return Scaffold(
      backgroundColor: CoachStyle.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: CoachStyle.goldLight,
        elevation: 0,
      ),
      body: NightScope(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            PageHeader(
              label: a.start == null ? 'Deine Woche' : wochenSpanne(a.start!),
              title: 'Reality Check',
            ),
            _Box(
              key: const ValueKey('reality-zahlen'),
              label: '1 · VORGENOMMEN VS. UMGESETZT',
              children: [
                _Balken(
                  key: const ValueKey('reality-fokus'),
                  titel: 'Fokus: ${a.fokusText ?? ''}'.trim(),
                  zahl: '${a.geschafft ?? 0} von 7',
                  anteil: (a.geschafft ?? 0) / 7,
                ),
                if (t != null)
                  t.geplant > 0
                      ? _Balken(
                          key: const ValueKey('reality-training'),
                          titel: 'Training laut Plan',
                          zahl: '${t.gemacht} von ${t.geplant}',
                          anteil: t.gemacht / t.geplant,
                        )
                      : _Balken(
                          key: const ValueKey('reality-training'),
                          titel: 'Training (kein Plan eingetragen)',
                          zahl:
                              '${t.gemacht} ${t.gemacht == 1 ? 'Tag' : 'Tage'}',
                          anteil: t.gemacht / 7,
                        ),
              ],
            ),
            if ((a.bremse ?? '').isNotEmpty)
              _Box(
                key: const ValueKey('reality-bremse'),
                label: '2 · WAS DICH AUSGEBREMST HAT',
                children: [
                  const SizedBox(height: 8),
                  Text(
                    a.bremse!,
                    style: CoachStyle.body.copyWith(
                      fontSize: 14.5,
                      height: 1.45,
                      color: CoachStyle.ink,
                    ),
                  ),
                ],
              ),
            if (veraenderung != null)
              GoldRahmen(
                key: const ValueKey('reality-veraenderung'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 · DIE EINE VERÄNDERUNG',
                      style: CoachStyle.goldLabel.copyWith(
                        fontSize: 10,
                        color: CoachStyle.goldLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${veraenderung.text}.',
                      style: CoachStyle.cardTitle.copyWith(
                        fontSize: 17,
                        color: const Color(0xFFF5DFAE),
                      ),
                    ),
                    if (veraenderung.warum.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        veraenderung.warum,
                        style: CoachStyle.body.copyWith(
                          fontSize: 13.5,
                          height: 1.45,
                          color: CoachStyle.beigeLabel,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 6),
            FokusWahl(
              auswahl: liste,
              laedt: false,
              titel: 'DEIN NEUER FOKUS · WÄHL EINEN',
              mitRueckblick: false,
              onNochmal: () {},
              onStart: (v) async {
                final nav = Navigator.of(context);
                // Map the relabelled option back to the coach's original.
                final i = liste.vorschlaege.indexOf(v);
                await onStart(i < 0 ? v : vorschlaege[i]);
                nav.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CoachStyle.cardBright,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoachStyle.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: CoachStyle.goldLabel.copyWith(fontSize: 10)),
          ...children,
        ],
      ),
    );
  }
}

class _Balken extends StatelessWidget {
  const _Balken({
    super.key,
    required this.titel,
    required this.zahl,
    required this.anteil,
  });

  final String titel;
  final String zahl;
  final double anteil;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  titel,
                  style: CoachStyle.body.copyWith(
                    fontSize: 14,
                    color: CoachStyle.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                zahl,
                style: CoachStyle.cardTitle.copyWith(
                  fontSize: 15,
                  color: const Color(0xFFF5DFAE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 8,
              color: const Color(0xFF2E261C),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: anteil.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, w, _) => FractionallySizedBox(
                  widthFactor: w,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: CoachStyle.goldGradient,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
