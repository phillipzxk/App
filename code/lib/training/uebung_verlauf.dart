import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'form_video.dart';
import 'training_data.dart';
import 'training_widgets.dart';

/// One exercise over time: best value per week, records, form videos and
/// one sentence from the coach that ties the curve to sleep, food or the
/// head (Entwurf 2, view 6).
class UebungVerlaufSeite extends StatefulWidget {
  const UebungVerlaufSeite({
    super.key,
    required this.namen,
    required this.start,
    required this.daten,
    required this.videos,
    required this.heute,
    required this.coachSatz,
    required this.onVideo,
  });

  final List<String> namen;
  final String start;
  final TrainingDaten daten;
  final List<FormVideo> videos;
  final DateTime heute;

  /// The coach's sentence for an exercise (cached per day by the caller).
  final Future<String?> Function(String uebung) coachSatz;
  final void Function(FormVideo v) onVideo;

  @override
  State<UebungVerlaufSeite> createState() => _UebungVerlaufSeiteState();
}

class _UebungVerlaufSeiteState extends State<UebungVerlaufSeite> {
  late String _name = widget.start;
  final _saetze = <String, String?>{};

  @override
  void initState() {
    super.initState();
    _holeSatz();
  }

  Future<void> _holeSatz() async {
    final n = _name;
    if (_saetze.containsKey(n) || widget.daten.verlauf(n).length < 2) return;
    _saetze[n] = null;
    final s = await widget.coachSatz(n);
    if (mounted) setState(() => _saetze[n] = s);
  }

  @override
  Widget build(BuildContext context) {
    final hist = widget.daten.verlauf(_name);
    final art = hist.isEmpty ? UebungArt.gewicht : hist.last.$2.art;
    final r = rekorde(art, [for (final (_, l) in hist) l]);
    final mo = montagVon(widget.heute);
    // Best value of each of the last 7 weeks.
    final wochen = <double?>[
      for (var w = 6; w >= 0; w--)
        () {
          final von = DateTime(mo.year, mo.month, mo.day - 7 * w);
          final bis = DateTime(von.year, von.month, von.day + 7);
          SatzWert? best;
          for (final (tag, l) in hist) {
            if (tag.isBefore(von) || !tag.isBefore(bis)) continue;
            final b = l.bester;
            if (b != null && (best == null || besser(art, b, best))) best = b;
          }
          if (best == null) return null;
          return switch (art) {
            UebungArt.gewicht || UebungArt.zusatzgewicht => best.wert,
            UebungArt.strecke =>
              (best.menge ?? 0) > 0 && (best.wert ?? 0) > 0
                  ? best.menge! / best.wert!
                  : best.wert,
            _ => best.menge,
          };
        }(),
    ];
    final da = [for (final w in wochen) ?w];
    final tempo =
        art == UebungArt.strecke &&
        hist.any((x) => (x.$2.bester?.menge ?? 0) > 0);
    final kurvenTitel = switch (art) {
      UebungArt.gewicht => 'Bestes Gewicht pro Woche (kg)',
      UebungArt.zusatzgewicht => 'Bestes Zusatzgewicht pro Woche (kg)',
      UebungArt.koerpergewicht => 'Meiste Wiederholungen pro Woche',
      UebungArt.zeit => 'Längste Zeit pro Woche (s)',
      UebungArt.strecke =>
        tempo ? 'Tempo pro Woche (min pro km)' : 'Strecke pro Woche (km)',
    };
    final videos = [
      for (final v in widget.videos.reversed)
        if (v.uebung.toLowerCase() == _name.toLowerCase()) v,
    ];
    final satz = _saetze[_name];
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
                children: [
                  const TLabel('Training · Übung'),
                  const SizedBox(height: 4),
                  GoldText(_name, style: tTitel.copyWith(fontSize: 22)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final n in widget.namen) ...[
                          TChip(
                            n,
                            key: ValueKey('verlauf-chip-$n'),
                            an: n == _name,
                            onTap: () {
                              setState(() => _name = n);
                              _holeSatz();
                            },
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hist.isEmpty)
                    TKarte(
                      child: Text(
                        'Noch nichts eingetragen. Nach deinem ersten Training '
                        'mit $_name siehst du hier die Kurve und deine Rekorde.',
                        style: tText,
                      ),
                    )
                  else ...[
                    TKarte(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TLabel(kurvenTitel),
                          const SizedBox(height: 8),
                          WochenKurve(werte: wochen, hoeher: !tempo),
                          const SizedBox(height: 6),
                          if (da.length > 1)
                            Text(
                              '${zahl(da.first)} auf ${zahl(da.last)} in ${wochen.length - 1 - wochen.indexWhere((w) => w != null)} Wochen',
                              style: tSoft.copyWith(
                                color: CoachStyle.goldLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TKarte(
                      key: const ValueKey('rekorde'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TLabel('Deine Rekorde'),
                          const SizedBox(height: 4),
                          if (r.bester != null)
                            _Zeile(switch (art) {
                              UebungArt.strecke => 'Weiteste Strecke',
                              UebungArt.zeit => 'Längste Zeit',
                              UebungArt.koerpergewicht =>
                                'Meiste Wiederholungen',
                              _ => 'Schwerstes Gewicht',
                            }, satzText(art, r.bester!)),
                          if (r.meisteWdh != null &&
                              (art == UebungArt.gewicht ||
                                  art == UebungArt.zusatzgewicht))
                            _Zeile(
                              'Meiste Wiederholungen',
                              satzText(art, r.meisteWdh!),
                            ),
                          if (r.geschaetzt != null)
                            _Zeile(
                              'Bester Satz geschätzt',
                              'etwa ${zahl((r.geschaetzt! * 2).round() / 2)} kg',
                            ),
                          if (r.weitest != null)
                            _Zeile(
                              'Schnellstes Tempo',
                              '${zahl((r.weitest! * 10).round() / 10)} min pro km',
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (videos.isNotEmpty)
                    TKarte(
                      key: const ValueKey('form-videos'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TLabel('Form-Videos'),
                          const SizedBox(height: 4),
                          for (final v in videos)
                            InkWell(
                              key: ValueKey('video-${v.id}'),
                              onTap: () => widget.onVideo(v),
                              child: _Zeile(
                                '${dayKey(v.datum) == dayKey(widget.heute) ? 'Heute' : _datum(v.datum)} · ${v.satz}',
                                v.hinweise == null ? 'ansehen ›' : 'Hinweise ›',
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (satz != null) TKarte(child: CoachZeile(text: satz)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _datum(DateTime d) => '${d.day}.${d.month}.';
}

class _Zeile extends StatelessWidget {
  const _Zeile(this.links, this.rechts);
  final String links, rechts;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: CoachStyle.edge)),
    ),
    child: Row(
      children: [
        Expanded(child: Text(links, style: tText.copyWith(fontSize: 13))),
        Text(
          rechts,
          style: tText.copyWith(
            fontSize: 13,
            color: CoachStyle.goldLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
