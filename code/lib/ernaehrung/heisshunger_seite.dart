import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../sleep/schlafzeiten.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'ernaehrung_coach.dart';
import 'ernaehrung_data.dart';
import 'ernaehrung_stand.dart';

/// Idea 2: the craving button. The coach asks once what is behind it and
/// gives one step for right now; time and reason are kept for the
/// overview and the patterns.
class HeisshungerSeite extends StatefulWidget {
  const HeisshungerSeite({super.key, required this.umfeld});
  final EssenUmfeld umfeld;

  @override
  State<HeisshungerSeite> createState() => _HeisshungerSeiteState();
}

class _HeisshungerSeiteState extends State<HeisshungerSeite> {
  late final DateTime _zeit = widget.umfeld.jetzt();
  bool _laedt = false;

  EssenUmfeld get u => widget.umfeld;

  /// This craving, once a reason is tapped.
  Heisshunger? get _dieser {
    for (final h in u.d.heisshunger.reversed) {
      if (h.zeit == _zeit) return h;
    }
    return null;
  }

  Future<void> _ersetzen(Heisshunger neu) => u.stand.setze(
    u.d.copyWith(
      heisshunger: [
        for (final h in u.d.heisshunger)
          if (h.zeit != _zeit) h,
        neu,
      ],
    ),
  );

  Future<void> _grund(String g) async {
    if (_laedt) return;
    setState(() => _laedt = true);
    await _ersetzen(Heisshunger(zeit: _zeit, grund: g));
    final uhr = formatUhrzeit(_zeit.hour * 60 + _zeit.minute);
    final schritt =
        await u.coach.heisshunger(u.profile, g, uhr, _kontext()) ??
        heisshungerOhneCoach(g);
    if (!mounted) return;
    await _ersetzen(Heisshunger(zeit: _zeit, grund: g, schritt: schritt));
    if (mounted) setState(() => _laedt = false);
  }

  String _kontext() => [
    u.tagText(),
    'Frühere Heißhunger-Momente:',
    for (final h in u.d.heisshunger.reversed.take(10))
      if (h.zeit != _zeit)
        '${dayKey(h.zeit)} ${formatUhrzeit(h.zeit.hour * 60 + h.zeit.minute)}: '
            '${h.grund}${h.geholfen == null ? '' : (h.geholfen! ? ', Schritt hat geholfen' : ', trotzdem gegessen')}',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final uhr = formatUhrzeit(_zeit.hour * 60 + _zeit.minute);
    return EssenSeite(
      umfeld: u,
      label: '${_wochentag(_zeit)} · $uhr',
      titel: 'Heißhunger',
      bau: (context) {
        final h = _dieser;
        return [
          TKarte(
            child: CoachZeile(
              text:
                  'Gut, dass du drückst${u.profile.name.isEmpty ? '' : ', ${u.profile.name}'}. '
                  'Was ist es gerade am ehesten?',
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final g in heisshungerGruende)
                TChip(
                  g,
                  key: ValueKey('hh-grund-$g'),
                  an: h?.grund == g,
                  onTap: h == null ? () => _grund(g) : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_laedt && h?.schritt == null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: CircularProgressIndicator(color: CoachStyle.gold),
              ),
            ),
          if (h?.schritt != null) ...[
            TKarte(
              key: const ValueKey('hh-schritt'),
              gold: true,
              child: CoachZeile(label: 'Dein Schritt jetzt', text: h!.schritt!),
            ),
            if (h.geholfen == null)
              Row(
                children: [
                  Expanded(
                    child: MainButton(
                      key: const ValueKey('hh-geholfen'),
                      label: 'Hat geholfen',
                      onPressed: () => _ersetzen(h.mit(geholfen: true)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TGhost(
                      'Trotzdem gegessen',
                      key: const ValueKey('hh-trotzdem'),
                      onTap: () => _ersetzen(h.mit(geholfen: false)),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  h.geholfen!
                      ? 'Gespeichert. Stark.'
                      : 'Gespeichert. Kein Problem, das gehört dazu. Der Coach '
                            'schaut es sich als Muster an, nicht als Fehler.',
                  style: tSoft,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),
          ],
          HeisshungerUebersicht(eintraege: u.d.heisshunger, heute: u.jetzt()),
        ];
      },
    );
  }
}

String _wochentag(DateTime d) => const [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
][d.weekday - 1];

/// The last 14 days as dots and when cravings come, in 2-hour steps.
class HeisshungerUebersicht extends StatelessWidget {
  const HeisshungerUebersicht({
    super.key,
    required this.eintraege,
    required this.heute,
  });

  final List<Heisshunger> eintraege;
  final DateTime heute;

  @override
  Widget build(BuildContext context) {
    final tag = DateTime(heute.year, heute.month, heute.day);
    final von = DateTime(tag.year, tag.month, tag.day - 13);
    final drin = [
      for (final h in eintraege)
        if (!h.zeit.isBefore(von)) h,
    ];
    final stunden = List.filled(9, 0);
    for (final h in drin) {
      final i = ((h.zeit.hour - 6) ~/ 2).clamp(0, 8);
      stunden[i]++;
    }
    final maxS = stunden.fold(1, (a, b) => a > b ? a : b);
    final geholfen = drin.where((h) => h.geholfen == true).length;
    final gruende = <String, int>{};
    for (final h in drin) {
      gruende[h.grund] = (gruende[h.grund] ?? 0) + 1;
    }
    String? satz;
    if (drin.length >= 3) {
      final top = stunden.indexOf(maxS);
      final g = gruende.entries.reduce((a, b) => a.value >= b.value ? a : b);
      satz =
          'Am häufigsten zwischen ${6 + top * 2} und ${8 + top * 2} Uhr. '
          'Grund Nummer 1: ${g.key.toLowerCase()}.';
    }
    return TKarte(
      key: const ValueKey('hh-uebersicht'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TLabel('Deine letzten 14 Tage'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 14; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: () {
                          final d = DateTime(von.year, von.month, von.day + i);
                          final an = drin.where(
                            (h) => dayKey(h.zeit) == dayKey(d),
                          );
                          if (an.isEmpty) return const Color(0xFF2A2118);
                          return an.any((h) => h.geholfen == true)
                              ? CoachStyle.goldLight
                              : const Color(0xFF7A5F38);
                        }(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            drin.isEmpty
                ? 'Noch kein Heißhunger eingetragen.'
                : '${drin.length} Mal Heißhunger, $geholfen Mal hat der Schritt '
                      'geholfen (gold).',
            style: tSoft,
          ),
          if (drin.isNotEmpty) ...[
            const SizedBox(height: 12),
            const TLabel('Wann er kommt'),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 9; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6 + 54 * stunden[i] / maxS,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                            bottom: Radius.circular(2),
                          ),
                          gradient: stunden[i] == maxS && stunden[i] > 0
                              ? CoachStyle.goldGradient
                              : null,
                          color: stunden[i] == maxS && stunden[i] > 0
                              ? null
                              : const Color(0xFF3A2E21),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                for (var i = 0; i < 9; i++)
                  Expanded(
                    child: Text(
                      '${6 + i * 2}',
                      textAlign: TextAlign.center,
                      style: tSoft.copyWith(fontSize: 9.5),
                    ),
                  ),
              ],
            ),
          ],
          if (satz != null) ...[
            const SizedBox(height: 10),
            CoachZeile(text: satz),
          ],
        ],
      ),
    );
  }
}
