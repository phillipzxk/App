import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../ui/coach_style.dart';
import 'training_data.dart';
import 'training_widgets.dart';

/// Mo..So of this week: what is planned and what is done.
class WochenStreifen extends StatelessWidget {
  const WochenStreifen({
    super.key,
    required this.tage,
    required this.daten,
    required this.heute,
  });

  /// This week's plan days (moved sessions already on their new day).
  final List<String> tage;
  final TrainingDaten daten;
  final DateTime heute;

  @override
  Widget build(BuildContext context) {
    final mo = montagVon(heute);
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(child: _tag(DateTime(mo.year, mo.month, mo.day + i), i)),
        ],
      ],
    );
  }

  Widget _tag(DateTime d, int i) {
    final e = daten.einheitAm(d);
    final fertig = e?.status == EinheitStatus.fertig;
    final weg = e?.status == EinheitStatus.uebersprungen;
    final ist = dayKey(d) == dayKey(heute);
    final text = tage[i];
    final training = istTrainingstag(text);
    final name = weg
        ? e!.name
        : training
        ? text
              .split('\n')
              .first
              .replaceAll(RegExp(r'\s*\d{1,2}[:.]\d{2}'), '')
              .trim()
        : 'Ruhe';
    final zeichen = fertig
        ? 'fertig'
        : weg
        ? (e!.verschobenAuf == null
              ? 'fällt aus'
              : 'auf ${wochentage[e.verschobenAuf!.weekday - 1].substring(0, 2)}')
        : ist
        ? 'heute'
        : training
        ? '·'
        : '';
    return Container(
      key: ValueKey('woche-$i'),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      decoration: BoxDecoration(
        color: fertig ? const Color(0xFF2A1F13) : const Color(0xFF1A140E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fertig || ist ? CoachStyle.goldLight : const Color(0xFF3A2E21),
          width: ist ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            wochentage[i].substring(0, 2),
            style: tTitel.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: tSoft.copyWith(fontSize: 9.5, color: CoachStyle.inkSoft),
          ),
          const SizedBox(height: 2),
          Text(
            zeichen,
            style: tSoft.copyWith(
              fontSize: 10,
              color: fertig ? CoachStyle.goldLight : CoachStyle.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Idea 8: strength against endurance this week, only with more than one
/// sport chosen (Phillip 2026-10-26).
class BalanceKarte extends StatelessWidget {
  const BalanceKarte({
    super.key,
    required this.kraft,
    required this.ausdauer,
    required this.sportarten,
    this.satz,
  });

  final int kraft, ausdauer;
  final List<String> sportarten;
  final String? satz;

  @override
  Widget build(BuildContext context) {
    final summe = kraft + ausdauer;
    return TKarte(
      key: const ValueKey('balance-karte'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TLabel('Balance Kraft und Ausdauer'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (kraft > 0)
                    Expanded(
                      flex: kraft,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF9A6D35), Color(0xFFE0BF7E)],
                          ),
                        ),
                      ),
                    ),
                  if (ausdauer > 0)
                    Expanded(
                      flex: ausdauer,
                      child: const ColoredBox(color: Color(0xFF6F7A5A)),
                    ),
                  if (summe == 0)
                    const Expanded(child: ColoredBox(color: Color(0xFF2A2118))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kraft $kraft ${kraft == 1 ? 'Einheit' : 'Einheiten'}',
                  style: tSoft,
                ),
              ),
              Expanded(
                child: Text(
                  'Ausdauer $ausdauer ${ausdauer == 1 ? 'Einheit' : 'Einheiten'}',
                  style: tSoft,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (satz != null) ...[
            const SizedBox(height: 10),
            CoachZeile(text: satz!),
          ],
          const SizedBox(height: 6),
          Text(
            'Erscheint, weil du ${sportarten.join(' und ')} gewählt hast.',
            style: tSoft.copyWith(fontSize: 11, color: CoachStyle.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Idea 7: a stuck exercise. The coach asks first what the user thinks,
/// then shows its view from the data with one change.
class StagnationsKarte extends StatelessWidget {
  const StagnationsKarte({
    super.key,
    required this.uebung,
    required this.seit,
    required this.check,
    required this.davor,
    required this.laedt,
    required this.onGrund,
    required this.onUebernehmen,
    required this.onLassen,
    required this.onZurueck,
  });

  final String uebung;

  /// E.g. "40 kg × 10".
  final String seit;
  final StagnationsCheck? check;

  /// The exercise right before it, for "Immer nach …".
  final String? davor;
  final bool laedt;
  final ValueChanged<String> onGrund;
  final VoidCallback onUebernehmen;
  final VoidCallback onLassen;
  final VoidCallback onZurueck;

  @override
  Widget build(BuildContext context) {
    final c = check;
    final gruende = [
      'Zu müde',
      if (davor != null) 'Immer nach $davor',
      'Zu schwer gestartet',
      'Keine Ahnung',
    ];
    return TKarte(
      key: const ValueKey('stagnation-karte'),
      gold: c == null || c.status == 'offen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TLabel('Stagnations-Check · $uebung'),
          const SizedBox(height: 6),
          Text(
            'Seit 3 Wochen bei $seit. Was meinst du, woran es liegt?',
            style: tText,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final g in gruende)
                TChip(
                  g,
                  key: ValueKey('stag-$g'),
                  an: c?.grund == g,
                  onTap: c?.status == 'offen' || c == null
                      ? () => onGrund(g)
                      : null,
                ),
            ],
          ),
          if (laedt)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                child: CircularProgressIndicator(color: CoachStyle.gold),
              ),
            )
          else if (c?.grund != null && c?.sicht == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Der Coach ist gerade nicht erreichbar. Tipp später nochmal.',
                style: tSoft,
              ),
            )
          else if (c?.sicht != null) ...[
            const SizedBox(height: 10),
            CoachZeile(text: '${c!.sicht!} ${c.vorschlag ?? ''}'.trim()),
            const SizedBox(height: 10),
            if (c.status == 'uebernommen')
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Übernommen, steht so in deinem Plan.',
                      style: tSoft.copyWith(color: CoachStyle.goldLight),
                    ),
                  ),
                  TLink(
                    'Rückgängig',
                    key: const ValueKey('stag-zurueck'),
                    onTap: onZurueck,
                  ),
                ],
              )
            else if (c.aenderung != null)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('stag-uebernehmen'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CoachStyle.goldLight,
                        foregroundColor: CoachStyle.goldInk,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: onUebernehmen,
                      child: const Text('Übernehmen'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TGhost(
                      'So lassen',
                      key: const ValueKey('stag-lassen'),
                      onTap: onLassen,
                    ),
                  ),
                ],
              )
            else
              TGhost(
                'Verstanden',
                key: const ValueKey('stag-lassen'),
                onTap: onLassen,
              ),
          ],
        ],
      ),
    );
  }
}
