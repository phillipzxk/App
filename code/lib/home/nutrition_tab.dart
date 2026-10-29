import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../ernaehrung/einkaufsliste.dart';
import '../ernaehrung/energie_kurve.dart';
import '../ernaehrung/ernaehrung_data.dart';
import '../ernaehrung/ernaehrung_logik.dart';
import '../ernaehrung/ernaehrung_stand.dart';
import '../ernaehrung/gewichts_check.dart';
import '../ernaehrung/heisshunger_seite.dart';
import '../ernaehrung/kochbuch.dart';
import '../ernaehrung/kuehlschrank.dart';
import '../ernaehrung/tages_teller.dart';
import '../ernaehrung/teller_foto.dart';
import '../feed/feed_data.dart';
import '../feed/kcal.dart';
import '../sleep/sleep.dart';
import '../supplements/supplement_data.dart';
import '../supplements/supplement_widgets.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../weight/weight.dart';
import '../weight/weight_chart.dart';
import 'bereichs_werte.dart';
import 'feed_widgets.dart';

/// Ernährung page (vault Umsetzung/Ernährung komplett.md, Phillip
/// 2026-10-27): the link to sleep and training, today's energy curve with
/// the meals on it, one plate for the day, the craving button, the kcal
/// target with the Gewichts-Check, cookbook, fridge photo, shopping list,
/// supplements and weight. Nothing is counted.
class NutritionTab extends StatefulWidget {
  const NutritionTab({
    super.key,
    required this.umfeld,
    required this.mahlzeiten,
    required this.anzahl,
    required this.start,
    required this.ende,
    required this.onSetMahlzeiten,
    required this.kcal,
    required this.kcalHeute,
    required this.weights,
    required this.sleep,
    required this.checkIns,
    required this.fragen,
    required this.onSaveKcal,
    required this.onAddWeight,
    required this.onAsk,
    required this.supplements,
    required this.genommen,
    required this.onSaveSupplements,
    required this.onToggleSupplement,
    this.teil,
    this.training,
    this.trainingName,
  });

  final EssenUmfeld umfeld;
  final List<MahlzeitSlot> mahlzeiten;
  final int? anzahl;
  final int start, ende;
  final int? training;
  final String? trainingName;
  final Future<void> Function(int anzahl) onSetMahlzeiten;
  final KcalProfil? kcal;

  /// Today's target including the Gewichts-Check change.
  final int? kcalHeute;
  final List<WeightEntry> weights;
  final List<SleepEntry> sleep;
  final List<CheckIn> checkIns;
  final List<CoachFrage> fragen;

  /// Saves the kcal data and, when given, the first weight.
  final Future<void> Function(KcalProfil profil, double? kg) onSaveKcal;
  final VoidCallback onAddWeight;
  final Future<void> Function(String text) onAsk;
  final List<Supplement> supplements;
  final Set<String> genommen;
  final Future<void> Function(List<Supplement> list) onSaveSupplements;
  final Future<void> Function(Supplement s, bool genommen) onToggleSupplement;

  /// Only one part for the glass area page: 'energie', 'teller', 'kcal',
  /// 'supp' or 'gewicht'. Null = the whole old page.
  final String? teil;

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  /// The meals while a point is dragged, for the live coach line.
  List<MahlzeitSlot>? _ziehen;

  /// Meal that was just ticked: its feeling chips stay open.
  String? _offen;

  EssenUmfeld get u => widget.umfeld;

  @override
  void initState() {
    super.initState();
    _zusammenhang();
  }

  Future<void> _zusammenhang() async {
    final z = u.d.zusammenhang;
    if (z?.tag == u.heute || widget.checkIns.length < 5) return;
    final hh = [
      for (final h in u.d.heisshunger.reversed.take(20))
        '${dayKey(h.zeit)} ${h.zeit.hour}:${h.zeit.minute.toString().padLeft(2, '0')}: '
            '${h.grund}${h.geholfen == null ? '' : (h.geholfen! ? ', geholfen' : ', trotzdem gegessen')}',
    ].join('\n');
    final schlaf = [
      for (final s in widget.sleep.reversed.take(14))
        '${dayKey(s.datum)}: ${s.stunden} h',
    ].join('\n');
    final recent = widget.checkIns.length > 14
        ? widget.checkIns.sublist(widget.checkIns.length - 14)
        : widget.checkIns;
    final satz = await u.coach.zusammenhang(u.profile, recent, hh, schlaf);
    await u.stand.setze(u.d.copyWith(zusammenhang: (tag: u.heute, satz: satz)));
  }

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.of(context).push<(KcalProfil, double?)>(
      MaterialPageRoute(
        builder: (_) => KcalEditor(
          profil: widget.kcal,
          needsWeight: widget.weights.isEmpty,
        ),
      ),
    );
    if (result != null) await widget.onSaveKcal(result.$1, result.$2);
  }

  Future<void> _anzahl(BuildContext context) async {
    final n = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF1A140E),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Wie oft willst du am Tag essen?', style: tTitel),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 1; i <= 6; i++)
                    TChip(
                      '$i',
                      key: ValueKey('anzahl-$i'),
                      an: widget.anzahl == i,
                      onTap: () => Navigator.of(context).pop(i),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (n != null) await widget.onSetMahlzeiten(n);
  }

  Future<void> _essen(MahlzeitSlot s) async {
    final e = u.d.tag(u.heute)[s.id] ?? const MahlzeitEintrag();
    final an = !e.gegessen;
    setState(() => _offen = an ? s.id : null);
    await u.stand.setze(
      u.d.mitEintrag(
        u.heute,
        s.id,
        an ? e.copyWith(gegessen: true) : const MahlzeitEintrag(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = u.d;
    final eintraege = d.tag(u.heute);
    final slots = widget.mahlzeiten;
    final gegessen = {
      for (final e in eintraege.entries)
        if (e.value.gegessen) e.key,
    };
    final teller = tagesTeller(slots, eintraege);
    final lage = gewichtsLage(widget.weights, u.profile.ziel, d, u.jetzt());
    final offenerCheck =
        d.gewicht.isNotEmpty &&
        d.gewicht.last.status == 'offen' &&
        d.gewicht.last.tag == u.heute;
    final rettung = rettungFuerHeute(
      d,
      spaetesTraining: (widget.training ?? 0) >= 17 * 60,
    );
    final offeneListe = einkaufsliste(d)
        .where((p) => !d.einkauf.erledigt.contains(p.key))
        .length;
    final blaetter = kochbuchBlaetter(d);
    final kg = widget.weights.isEmpty ? null : widget.weights.last.kg;
    final naechste = slots.where((s) => !gegessen.contains(s.id));
    final schlaf = widget.sleep.isEmpty ? null : widget.sleep.last.stunden;
    final alles = widget.teil == null;
    bool zeig(String t) => alles || widget.teil == t;
    final kinder = <Widget>[
      if (alles) ...[
        const PageHeader(label: 'Bereich', title: 'Ernährung', icon: Icons.eco),
        const AreaChart(bereich: Bereich.ernaehrung),
      ],
      Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (zeig('energie') &&
                d.zusammenhang?.tag == u.heute &&
                d.zusammenhang?.satz != null)
              TKarte(
                key: const ValueKey('zusammenhang'),
                child: CoachZeile(
                  label: 'Zusammenhang',
                  text: d.zusammenhang!.satz!,
                ),
              ),
            if (zeig('energie'))
              TKarte(
                key: const ValueKey('energie-karte'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: TLabel('Deine Energie heute')),
                        if (slots.isNotEmpty)
                          const Text('Punkte ziehen', style: tSoft),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (slots.isEmpty) ...[
                      const Text(
                        'Leg einmal fest, wie oft du am Tag isst. Dann plant der '
                        'Coach deine Mahlzeiten um Training und Termine herum.',
                        style: tSoft,
                      ),
                      const SizedBox(height: 10),
                      MainButton(
                        key: const ValueKey('mahlzeiten-festlegen'),
                        label: 'Mahlzeiten festlegen',
                        onPressed: () => _anzahl(context),
                      ),
                    ] else ...[
                      EnergieKurve(
                        mahlzeiten: slots,
                        start: widget.start,
                        ende: widget.ende,
                        training: widget.training,
                        trainingName: widget.trainingName,
                        schlaf: schlaf,
                        gegessen: gegessen,
                        onZiehen: (s) => setState(() => _ziehen = s),
                        onVerschieben: (id, m) async {
                          setState(() => _ziehen = null);
                          await u.stand.setze(u.d.mitZeit(u.heute, id, m));
                        },
                      ),
                      const SizedBox(height: 4),
                      CoachZeile(
                        text: energieSatz(
                          _ziehen ?? slots,
                          training: widget.training,
                          ende: widget.ende,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final s in slots)
                        _MahlzeitZeile(
                          slot: s,
                          eintrag: eintraege[s.id],
                          offen: _offen == s.id,
                          rettung: s.id == 'nach' || s.id == 'abend'
                              ? rettung
                              : null,
                          onEssen: () => _essen(s),
                          onGefuehl: (f) async {
                            setState(() => _offen = null);
                            final e =
                                u.d.tag(u.heute)[s.id] ??
                                const MahlzeitEintrag(gegessen: true);
                            await u.stand.setze(
                              u.d.mitEintrag(
                                u.heute,
                                s.id,
                                e.copyWith(gefuehl: f),
                              ),
                            );
                          },
                          onFoto: () => zeigeSeite(
                            context,
                            TellerFotoSeite(umfeld: u, slot: s),
                          ),
                          onRettung: rettung == null
                              ? null
                              : () => zeigeSeite(
                                  context,
                                  GerichtSeite(umfeld: u, id: rettung.id),
                                ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          if (naechste.isNotEmpty)
                            TLink(
                              'Teller fotografieren ›',
                              key: const ValueKey('teller-foto'),
                              onTap: () => zeigeSeite(
                                context,
                                TellerFotoSeite(
                                  umfeld: u,
                                  slot: naechste.first,
                                ),
                              ),
                            ),
                          TLink(
                            '${widget.anzahl} am Tag · ändern',
                            key: const ValueKey('anzahl-aendern'),
                            soft: true,
                            onTap: () => _anzahl(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            if (zeig('teller') && slots.isEmpty && !alles)
              const Text(
                'Leg unter Energie-Kurve fest, wie oft du am Tag isst. '
                'Dann füllt sich hier dein Teller.',
                style: tSoft,
              ),
            if (zeig('teller') && slots.isNotEmpty)
              TKarte(
                key: const ValueKey('tages-teller'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TLabel('Dein Teller heute'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        TagesTeller(
                          werte: [
                            teller.eiweiss,
                            teller.gemuese,
                            teller.energie,
                          ],
                          gegessen: gegessen.length,
                          geplant: slots.length,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var k = 0; k < 3; k++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: tellerFarben[k],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(tellerNamen[k], style: tText),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          tellerWort(
                                            [
                                              teller.eiweiss,
                                              teller.gemuese,
                                              teller.energie,
                                            ][k],
                                          ),
                                          style: tSoft,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CoachZeile(
                      text: tellerSatz(
                        teller,
                        gegessen: gegessen.length,
                        geplant: slots.length,
                      ),
                    ),
                  ],
                ),
              ),
            if (alles)
              _HeisshungerKnopf(
                onTap: () => zeigeSeite(context, HeisshungerSeite(umfeld: u)),
              ),
            if (alles) const SizedBox(height: 12),
            if (zeig('kcal'))
              _KcalKarte(
                profil: widget.kcal,
                kg: kg,
                kcal: widget.kcalHeute,
                angepasst: d.kcalAnpassung != 0,
                hinweis: offenerCheck || lage != null
                    ? (lage?.text ?? 'Wir waren beim Gewichts-Check.')
                    : null,
                onEdit: () => _edit(context),
                onCheck: () => zeigeSeite(
                  context,
                  GewichtsCheckSeite(
                    umfeld: u,
                    weights: widget.weights,
                    kcal: () => widget.kcalHeute,
                  ),
                ),
              ),
            if (alles)
              Row(
                children: [
                  Expanded(
                    child: _Kachel(
                      key: const ValueKey('kachel-kochbuch'),
                      label: 'Dein Kochbuch',
                      wert: '$blaetter ${blaetter == 1 ? 'Blatt' : 'Blätter'}',
                      unter: 'Rettungsgerichte ›',
                      onTap: () =>
                          zeigeSeite(context, KochbuchSeite(umfeld: u)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Kachel(
                      key: const ValueKey('kachel-kuehlschrank'),
                      label: 'Was ist da?',
                      wert: 'Kühlschrank',
                      unter: 'Foto, Coach kocht ›',
                      onTap: () =>
                          zeigeSeite(context, KuehlschrankSeite(umfeld: u)),
                    ),
                  ),
                ],
              ),
            if (alles) const SizedBox(height: 10),
            if (alles)
              _Kachel(
                key: const ValueKey('kachel-einkauf'),
                label: 'Einkaufsliste',
                wert: offeneListe == 0 ? 'Leer' : '$offeneListe offen',
                unter: 'Aus deinen Gerichten ›',
                onTap: () => zeigeSeite(context, EinkaufslisteSeite(umfeld: u)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      if (zeig('supp'))
        SupplementCard(
          supplements: widget.supplements,
          genommen: widget.genommen,
          onSave: widget.onSaveSupplements,
          onToggle: widget.onToggleSupplement,
        ),
      if (alles) const GroupLabel('Frag deinen Coach'),
      if (alles)
        AskCoachCard(
          title: 'Wie sieht deine Ernährung heute aus?',
          hint:
              'Schreib grob, was du heute gegessen hast. Der Coach schätzt '
              'ein, ob es zu deinem Ziel passt.',
          today: widget.fragen,
          onSend: widget.onAsk,
        ),
      if (alles) const GroupLabel('Deine Werte'),
      if (zeig('gewicht'))
        WeightCard(weights: widget.weights, onAdd: widget.onAddWeight),
    ];
    if (!alles) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kinder,
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: kinder,
    );
  }
}

class _MahlzeitZeile extends StatelessWidget {
  const _MahlzeitZeile({
    required this.slot,
    required this.eintrag,
    required this.offen,
    required this.onEssen,
    required this.onGefuehl,
    required this.onFoto,
    this.rettung,
    this.onRettung,
  });

  final MahlzeitSlot slot;
  final MahlzeitEintrag? eintrag;
  final bool offen;
  final VoidCallback onEssen;
  final ValueChanged<String> onGefuehl;
  final VoidCallback onFoto;
  final Gericht? rettung;
  final VoidCallback? onRettung;

  @override
  Widget build(BuildContext context) {
    final e = eintrag;
    final gegessen = e?.gegessen ?? false;
    return Container(
      key: ValueKey('mahlzeit-${slot.id}'),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2E261C))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                slot.uhrzeit,
                style: tTitel.copyWith(
                  fontSize: 13,
                  color: CoachStyle.goldLight,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: slot.name,
                        style: tTitel.copyWith(fontSize: 13.5),
                      ),
                      TextSpan(text: '  ${slot.groesse}', style: tSoft),
                    ],
                  ),
                ),
                if (!gegessen) Text(slot.tipp, style: tSoft),
                if (gegessen && e?.teller?.tipp != null)
                  Text(e!.teller!.tipp!, style: tSoft),
                if (gegessen && (offen || e?.gefuehl != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final f in const ['satt', 'okay', 'noch Hunger'])
                          Padding(
                            padding: EdgeInsets.zero,
                            child: TChip(
                              f,
                              key: ValueKey('gefuehl-${slot.id}-$f'),
                              klein: true,
                              an: e?.gefuehl == f,
                              onTap: () => onGefuehl(f),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (rettung != null && !gegessen)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: TLink(
                      'Rettungsgericht: ${rettung!.name} ›',
                      key: ValueKey('rettung-link-${slot.id}'),
                      onTap: onRettung,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('foto-${slot.id}'),
            tooltip: 'Teller fotografieren',
            visualDensity: VisualDensity.compact,
            onPressed: onFoto,
            icon: Icon(
              e?.teller != null || e?.bild != null
                  ? Icons.photo_camera
                  : Icons.photo_camera_outlined,
              size: 19,
              color: CoachStyle.beigeLabel,
            ),
          ),
          TTick(
            key: ValueKey('gegessen-${slot.id}'),
            an: gegessen,
            onTap: onEssen,
          ),
        ],
      ),
    );
  }
}

class _HeisshungerKnopf extends StatelessWidget {
  const _HeisshungerKnopf({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const ValueKey('heisshunger-knopf'),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1F13),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CoachStyle.goldLight, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: CoachStyle.goldGradient,
              ),
              child: const Icon(
                Icons.local_fire_department_outlined,
                color: CoachStyle.goldInk,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Heißhunger gerade?', style: tTitel),
                  const Text(
                    'Antippen, der Coach hilft dir in dem Moment.',
                    style: tSoft,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _KcalKarte extends StatelessWidget {
  const _KcalKarte({
    required this.profil,
    required this.kg,
    required this.kcal,
    required this.angepasst,
    required this.hinweis,
    required this.onEdit,
    required this.onCheck,
  });

  final KcalProfil? profil;
  final double? kg;
  final int? kcal;
  final bool angepasst;
  final String? hinweis;
  final VoidCallback onEdit;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    if (profil == null || kg == null || kcal == null) {
      return TKarte(
        gold: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TLabel('Dein kcal-Ziel'),
            const SizedBox(height: 6),
            const Text('Einmal einrichten. Gezählt wird nichts.', style: tSoft),
            const SizedBox(height: 12),
            GhostButton(label: 'kcal-Ziel einrichten', onPressed: onEdit),
          ],
        ),
      );
    }
    return TKarte(
      key: const ValueKey('kcal-karte'),
      gold: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: TLabel('Dein kcal-Ziel heute')),
              Tag(angepasst ? 'vom Coach angepasst' : 'passt sich an'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GoldZahl(formatKcal(kcal!), size: 28),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text('kcal', style: tSoft),
              ),
            ],
          ),
          Text('Bei ${formatKg(kg!)} kg. Kein Zählen.', style: tSoft),
          if (hinweis != null) ...[
            const SizedBox(height: 9),
            CoachZeile(
              text: hinweis!,
              unten: TLink(
                'Kurz drüber reden ›',
                key: const ValueKey('gewicht-check-link'),
                onTap: onCheck,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              TLink('Angaben ändern', soft: true, onTap: onEdit),
              TLink(
                'Gewichts-Check ›',
                key: const ValueKey('gewicht-check-oeffnen'),
                onTap: onCheck,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kachel extends StatelessWidget {
  const _Kachel({
    super.key,
    required this.label,
    required this.wert,
    required this.unter,
    required this.onTap,
  });

  final String label, wert, unter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A140E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A2E21)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TLabel(label),
            const SizedBox(height: 4),
            Text(
              wert,
              style: tTitel.copyWith(fontSize: 17, color: CoachStyle.goldLight),
            ),
            Text(unter, style: tSoft),
          ],
        ),
      ),
    ),
  );
}

class WeightCard extends StatelessWidget {
  const WeightCard({super.key, required this.weights, required this.onAdd});

  final List<WeightEntry> weights;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final weeks = weeklyAverages(weights);
    if (weeks.isEmpty) {
      return FeedCard(
        title: 'Gewicht',
        icon: Icons.monitor_weight_outlined,
        children: [
          const HintText('Trag regelmäßig dein Gewicht ein.'),
          const SizedBox(height: 16),
          MainButton(label: 'Gewicht eintragen', onPressed: onAdd),
        ],
      );
    }
    final current = weeks.last;
    final shown = weeks.length > 12 ? weeks.sublist(weeks.length - 12) : weeks;
    final diff = weeks.length > 1
        ? current.kg - weeks[weeks.length - 2].kg
        : null;
    return FeedCard(
      title: 'Gewicht · Wochenschnitt',
      icon: Icons.monitor_weight_outlined,
      children: [
        Text('${formatKg(current.kg)} kg', style: CoachStyle.question),
        if (diff != null)
          Text(
            '${diff > 0
                ? '+'
                : diff < 0
                ? '−'
                : '±'}'
            '${formatKg(diff.abs())} kg zur Vorwoche',
            style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
          ),
        const SizedBox(height: 12),
        WeightChart(weeks: shown),
        const SizedBox(height: 16),
        MainButton(label: 'Gewicht eintragen', onPressed: onAdd),
      ],
    );
  }
}

class WeightDialog extends StatefulWidget {
  const WeightDialog({super.key});

  @override
  State<WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<WeightDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final kg = parseKg(_controller.text);
    if (kg == null) {
      setState(() => _error = 'Bitte ein Gewicht zwischen 30 und 300 kg.');
      return;
    }
    Navigator.of(context).pop(kg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gewicht heute'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: 'kg',
          hintText: 'z. B. 82,4',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }
}

/// Height, age, sex, activity and, if none is stored yet, the weight.
class KcalEditor extends StatefulWidget {
  const KcalEditor({
    super.key,
    required this.profil,
    required this.needsWeight,
  });

  final KcalProfil? profil;
  final bool needsWeight;

  @override
  State<KcalEditor> createState() => _KcalEditorState();
}

class _KcalEditorState extends State<KcalEditor> {
  late final _groesse = TextEditingController(
    text: widget.profil?.groesseCm.toString() ?? '',
  );
  late final _alter = TextEditingController(
    text: widget.profil?.alter.toString() ?? '',
  );
  final _gewicht = TextEditingController();
  late Geschlecht? _geschlecht = widget.profil?.geschlecht;
  late Aktivitaet? _aktivitaet = widget.profil?.aktivitaet;
  bool _tried = false;

  @override
  void dispose() {
    _groesse.dispose();
    _alter.dispose();
    _gewicht.dispose();
    super.dispose();
  }

  int? get _cm => parseInt(_groesse.text, 120, 230);
  int? get _jahre => parseInt(_alter.text, 14, 100);
  double? get _kg => parseKg(_gewicht.text);

  void _save() {
    final cm = _cm, jahre = _jahre, kg = _kg;
    final g = _geschlecht, a = _aktivitaet;
    if (cm == null ||
        jahre == null ||
        g == null ||
        a == null ||
        (widget.needsWeight && kg == null)) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop((
      KcalProfil(groesseCm: cm, alter: jahre, geschlecht: g, aktivitaet: a),
      widget.needsWeight ? kg : null,
    ));
  }

  Widget _choice<T>(
    T value,
    T? group,
    String label,
    String? sub,
    ValueChanged<T> onTap,
  ) {
    final on = value == group;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => onTap(value)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: on ? CoachStyle.selectedFill : CoachStyle.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? CoachStyle.gold : CoachStyle.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: CoachStyle.body),
              if (sub != null) HintText(sub),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const missing = 'Bitte auswählen.';
    return EditorPage(
      title: 'Dein kcal-Ziel',
      intro:
          'Einmal angeben, danach passt sich dein Ziel mit jedem neuen '
          'Gewicht von selbst an.',
      onSave: _save,
      children: [
        EditorField(
          controller: _groesse,
          label: 'Größe',
          suffix: 'cm',
          number: true,
          error: _tried && _cm == null
              ? 'Bitte zwischen 120 und 230 cm.'
              : null,
        ),
        const SizedBox(height: 12),
        EditorField(
          controller: _alter,
          label: 'Alter',
          suffix: 'Jahre',
          number: true,
          error: _tried && _jahre == null ? 'Bitte zwischen 14 und 100.' : null,
        ),
        if (widget.needsWeight) ...[
          const SizedBox(height: 12),
          EditorField(
            controller: _gewicht,
            label: 'Gewicht heute',
            suffix: 'kg',
            number: true,
            error: _tried && _kg == null
                ? 'Bitte ein Gewicht zwischen 30 und 300 kg.'
                : null,
          ),
        ],
        const SizedBox(height: 20),
        const Text('GESCHLECHT', style: CoachStyle.label),
        const SizedBox(height: 8),
        _choice(
          Geschlecht.mann,
          _geschlecht,
          'Mann',
          null,
          (v) => _geschlecht = v,
        ),
        _choice(
          Geschlecht.frau,
          _geschlecht,
          'Frau',
          null,
          (v) => _geschlecht = v,
        ),
        if (_tried && _geschlecht == null) const _Error(missing),
        const SizedBox(height: 12),
        const Text('AKTIVITÄT IM ALLTAG', style: CoachStyle.label),
        const SizedBox(height: 8),
        for (final a in Aktivitaet.values)
          _choice(
            a,
            _aktivitaet,
            a.label,
            a.beschreibung,
            (v) => _aktivitaet = v,
          ),
        if (_tried && _aktivitaet == null) const _Error(missing),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
  );
}
