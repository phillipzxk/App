import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../data/user_profile.dart';
import '../feed/feed_data.dart';
import '../feed/feed_store.dart';
import '../training/form_check.dart';
import '../training/form_video.dart';
import '../training/heute_training.dart';
import '../training/plan_editor.dart';
import '../training/training_coach.dart';
import '../training/training_data.dart';
import '../training/training_logik.dart';
import '../training/training_widgets.dart';
import '../training/trainings_modus.dart';
import '../training/uebung_verlauf.dart';
import '../training/woche_karte.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'bereichs_werte.dart';
import 'feed_widgets.dart';

/// The training page (vault Umsetzung/Training eintragen.md, Phillip
/// 2026-10-26): today's session to log set by set or skip, the week with
/// balance and Stagnations-Check, every exercise's history, and the plan
/// that is set once.
class TrainingTab extends StatefulWidget {
  const TrainingTab({
    super.key,
    this.extra = const [],
    this.teil,
    required this.profile,
    required this.feed,
    required this.coach,
    required this.plan,
    required this.schwerpunkt,
    required this.today,
    required this.checkIns,
    required this.fragen,
    required this.onSavePlan,
    required this.onSchwerpunkt,
    required this.onAsk,
    required this.onGeaendert,
  });

  /// Cards that moved here from the old "Heute" page.
  final List<Widget> extra;

  /// Only one part for the glass area page: 'heute', 'woche', 'plan' or
  /// 'uebungen'. Null = the whole old page.
  final String? teil;
  final UserProfile profile;
  final FeedStore feed;
  final TrainingCoach coach;
  final TrainingPlan plan;
  final Schwerpunkt? schwerpunkt;
  final DateTime today;
  final List<CheckIn> checkIns;
  final List<CoachFrage> fragen;
  final Future<void> Function(TrainingPlan plan) onSavePlan;
  final Future<void> Function(Schwerpunkt s) onSchwerpunkt;
  final Future<void> Function(String text) onAsk;

  /// Called after a session was finished or skipped, so "Heute" follows.
  final Future<void> Function() onGeaendert;

  @override
  State<TrainingTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends State<TrainingTab> {
  TrainingDaten? _d;
  List<FormVideo> _videos = const [];
  HeuteSession? _session;
  int? _planTag;
  bool _skipOffen = false;
  bool _tagesformLaedt = false;
  bool _stagLaedt = false;

  DateTime get _heute => widget.today;
  TrainingDaten get d => _d!;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  @override
  void didUpdateWidget(TrainingTab old) {
    super.didUpdateWidget(old);
    if (_d != null && !identical(old.plan, widget.plan)) _sessionAufbauen();
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  Future<void> _laden() async {
    final d = await widget.feed.loadTraining();
    final v = await widget.feed.loadFormVideos();
    if (!mounted) return;
    setState(() {
      _d = d;
      _videos = v;
    });
    _sessionAufbauen();
    _tagesformHolen();
    _balanceHolen();
  }

  Future<void> _speichern(TrainingDaten neu) async {
    _d = neu;
    await widget.feed.saveTraining(neu);
  }

  CheckIn? get _checkInHeute {
    for (final c in widget.checkIns) {
      if (dayKey(c.datum) == dayKey(_heute)) return c;
    }
    return null;
  }

  Anpassung? get _anpassung {
    final t = d.tagesform;
    return t != null && t.tag == dayKey(_heute) ? t.aktiv : null;
  }

  /// Today's session from the plan (or a moved one), or the one already
  /// being logged.
  void _sessionAufbauen() {
    final i = planTagFuer(widget.plan, d, _heute);
    final e = d.einheitAm(_heute);
    _planTag = i;
    final alt = _session;
    if (i == null || (e != null && e.status != EinheitStatus.laeuft)) {
      _session = null;
    } else {
      final plan = widget.plan.uebungenAm(i);
      final frisch = neueLogs(plan, d, _heute, _anpassung);
      final logs = [
        for (var k = 0; k < plan.length; k++)
          e?.uebungen
                  .where(
                    (u) => u.name.toLowerCase() == plan[k].name.toLowerCase(),
                  )
                  .firstOrNull ??
              frisch[k],
      ];
      _session = HeuteSession(
        datum: DateTime(_heute.year, _heute.month, _heute.day),
        name: shortDay(widget.plan.tage[i]),
        plan: plan,
        logs: logs,
        gestartet: e != null,
        onSpeichern: (einheit) => _speichern(d.mitEinheit(einheit)),
      )..addListener(_neu);
    }
    alt?.dispose();
    if (mounted) setState(() {});
  }

  void _neu() {
    if (mounted) setState(() {});
  }

  String _einheitText() {
    final s = _session;
    if (s == null) return '';
    return [
      s.name,
      for (var k = 0; k < s.plan.length; k++)
        () {
          final z = zielFuer(s.plan[k], d, _heute);
          return '${s.plan[k].name}: Ziel heute ${z.saetze.length} × '
              '${z.saetze.isEmpty ? '' : satzText(s.plan[k].art, z.saetze.first)}'
              '${z.letztes == null ? '' : ', letztes Mal ${satzText(s.plan[k].art, z.letztes!)}'}';
        }(),
    ].join('\n');
  }

  /// Idea 4: once per day before the first set.
  Future<void> _tagesformHolen() async {
    final s = _session;
    if (s == null || s.gestartet || _tagesformLaedt) return;
    if (d.tagesform?.tag == dayKey(_heute)) return;
    setState(() => _tagesformLaedt = true);
    final recent = widget.checkIns.reversed.take(5).toList().reversed.toList();
    final r = await widget.coach.tagesform(
      widget.profile,
      _checkInHeute,
      recent,
      _einheitText(),
    );
    if (!mounted) return;
    final satz = r?.satz ?? tagesformOhneCoach(_checkInHeute) ?? '';
    await _speichern(
      d.copyWith(
        tagesform: Tagesform(
          tag: dayKey(_heute),
          satz: satz,
          anpassung: r?.anpassung,
        ),
      ),
    );
    _tagesformLaedt = false;
    if (_session?.gestartet == false && r?.anpassung != null) {
      _sessionAufbauen();
    } else {
      setState(() {});
    }
  }

  Future<void> _anpassungZurueck() async {
    final t = d.tagesform;
    if (t == null) return;
    await _speichern(d.copyWith(tagesform: t.zurueck()));
    final s = _session;
    final a = t.anpassung;
    if (s != null && a != null) {
      final k = s.plan.indexWhere(
        (u) => u.name.toLowerCase() == a.uebung.toLowerCase(),
      );
      if (k >= 0) {
        final neu = neueLogs([s.plan[k]], d, _heute, null).first;
        if (s.logs[k].fertige.isEmpty) {
          s.neuAufsetzen(k, neu);
        } else {
          while (s.logs[k].saetze.length < neu.saetze.length) {
            s.satzDazu(k);
          }
        }
      }
    }
    setState(() {});
  }

  int get _wocheKraft => _balance().kraft;

  ({int kraft, int ausdauer}) _balance() {
    final w = wochenPlan(widget.plan, d, _heute);
    var k = 0, a = 0;
    for (var i = 0; i < 7; i++) {
      if (!istTrainingstag(w.tage[i])) continue;
      final t = artDesTages(w.tage[i], w.uebungenAm(i));
      if (t.kraft) k++;
      if (t.ausdauer) a++;
    }
    return (kraft: k, ausdauer: a);
  }

  Future<void> _balanceHolen() async {
    if (d.sportarten.length < 2) return;
    final woche = dayKey(montagVon(_heute));
    if (d.balance?.woche == woche) return;
    final b = _balance();
    final w = wochenPlan(widget.plan, d, _heute);
    final text = [
      'Sportarten: ${d.sportarten.join(', ')}',
      if (widget.schwerpunkt != null)
        'Schwerpunkt: ${widget.schwerpunkt!.label}',
      'Kraft-Einheiten: ${b.kraft}, Ausdauer-Einheiten: ${b.ausdauer}',
      for (var i = 0; i < 7; i++)
        '${wochentage[i]}: ${istTrainingstag(w.tage[i]) ? w.tage[i].replaceAll('\n', ', ') : 'frei'}',
    ].join('\n');
    final satz = await widget.coach.balance(widget.profile, text);
    if (satz == null || !mounted) return;
    await _speichern(d.copyWith(balance: (woche: woche, satz: satz)));
    setState(() {});
  }

  Future<void> _fertig() async {
    final s = _session!;
    final e = s.abschliessen();
    final vorschlaege = {...d.vorschlaege}
      ..removeWhere((k, _) => e.uebungen.any((u) => u.name.toLowerCase() == k));
    await _speichern(d.copyWith(vorschlaege: vorschlaege).mitEinheit(e));
    _sessionAufbauen();
    await widget.onGeaendert();
  }

  Future<void> _nochAendern() async {
    final e = d.einheitAm(_heute);
    if (e == null) return;
    await _speichern(d.mitEinheit(e.copyWith(status: EinheitStatus.laeuft)));
    _sessionAufbauen();
  }

  Future<void> _skip(String grund) async {
    final s = _session!;
    final ziel = verschiebeZiel(widget.plan.tage, d, _heute, grund);
    await _speichern(
      d.mitEinheit(
        TrainingEinheit(
          datum: s.datum,
          name: s.name,
          status: EinheitStatus.uebersprungen,
          grund: grund,
          verschobenAuf: ziel,
        ),
      ),
    );
    _skipOffen = false;
    _sessionAufbauen();
    await widget.onGeaendert();
  }

  Future<void> _skipZurueck() async {
    await _speichern(d.ohneEinheit(_heute));
    _sessionAufbauen();
    await widget.onGeaendert();
  }

  Future<String?> _vorschlag(String uebung, UebungArt art, String text) async {
    final e = d.einheitAm(_heute);
    final log = e?.uebungen.where((u) => u.name == uebung).firstOrNull;
    final heute = log == null
        ? ''
        : '${log.fertige.map((s) => satzText(art, s.werte)).join(', ')}'
              '${log.gefuehl == null ? '' : ', Gefühl ${log.gefuehl}'}';
    final r = await widget.coach.vorschlag(widget.profile, uebung, heute, text);
    final werte =
        (r != null && !r.ok ? r.werte : null) ?? vorschlagLesen(art, text);
    if (werte == null) {
      return r?.antwort ??
          'Das konnte ich nicht lesen. Schreib es wie „85 × 6“.';
    }
    await _speichern(
      d.copyWith(vorschlaege: {...d.vorschlaege, uebung.toLowerCase(): werte}),
    );
    if (mounted) setState(() {});
    return r?.antwort ??
        'Eingetragen: ${satzText(art, werte)} fürs nächste Mal.';
  }

  Future<void> _stagGrund(String uebung, String grund) async {
    setState(() => _stagLaedt = true);
    final check = StagnationsCheck(
      uebung: uebung,
      tag: dayKey(_heute),
      grund: grund,
    );
    final rest = [
      for (final s in d.stagnation)
        if (!(s.uebung == uebung && s.tag == check.tag)) s,
    ];
    final u = planUebung(widget.plan, uebung) ?? PlanUebung(name: uebung);
    final r = await widget.coach.stagnation(
      widget.profile,
      u,
      verlaufText(d, uebung),
      grund,
      widget.checkIns.reversed.take(14).toList().reversed.toList(),
      uebungDavor(widget.plan, uebung) == null
          ? 'steht als erste Übung'
          : 'kommt nach ${uebungDavor(widget.plan, uebung)}',
    );
    final neu = r == null
        ? check
        : check.copyWith(
            sicht: r.sicht,
            vorschlag: r.vorschlag,
            aenderung: r.aenderung,
          );
    await _speichern(d.copyWith(stagnation: [...rest, neu]));
    if (mounted) setState(() => _stagLaedt = false);
  }

  Future<void> _stagStatus(StagnationsCheck c, String status) async {
    var neu = c.copyWith(status: status);
    if (status == 'uebernommen' && c.aenderung != null) {
      neu = neu.copyWith(vorher: planUebung(widget.plan, c.uebung));
      await widget.onSavePlan(
        widget.plan.mitUebung(
          c.uebung,
          c.aenderung!.uebung,
          zuerst: c.aenderung!.zuerst,
        ),
      );
    }
    if (status == 'offen' && c.vorher != null) {
      await widget.onSavePlan(widget.plan.mitUebung(c.uebung, c.vorher!));
    }
    await _speichern(
      d.copyWith(
        stagnation: [for (final s in d.stagnation) identical(s, c) ? neu : s],
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _plan() async {
    final r = await Navigator.of(context).push<PlanErgebnis>(
      MaterialPageRoute(
        builder: (_) => TrainingPlanEditor(
          plan: widget.plan,
          sportarten: d.sportarten,
          schwerpunkt: widget.schwerpunkt,
        ),
      ),
    );
    if (r == null) return;
    await _speichern(d.copyWith(sportarten: r.sportarten));
    if (r.schwerpunkt != null && r.schwerpunkt != widget.schwerpunkt) {
      await widget.onSchwerpunkt(r.schwerpunkt!);
    }
    await widget.onSavePlan(r.plan);
    _balanceHolen();
  }

  Future<void> _modus() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TrainingsModus(
        session: _session!,
        onForm: (i) => _form(_session!.plan[i].name, i),
      ),
    ),
  );

  Future<void> _form(String uebung, [int? i]) {
    final s = _session;
    var satz = '';
    if (s != null && i != null) {
      final l = s.logs[i];
      final x = l.saetze.firstWhere(
        (x) => !x.fertig,
        orElse: () => l.saetze.last,
      );
      satz = satzText(l.art, x.werte);
    }
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FormCheckSeite(
          uebung: uebung,
          satz: satz,
          coach: widget.coach,
          videos: _videos,
          heute: _heute,
          onSpeichern: _videoSpeichern,
        ),
      ),
    );
  }

  Future<void> _videoSpeichern(FormVideo v) async {
    final list = formVideosKuerzen([
      for (final x in _videos)
        if (x.id != v.id) x,
      v,
    ]);
    await widget.feed.saveFormVideos(list);
    if (mounted) setState(() => _videos = list);
  }

  List<String> get _alleUebungen {
    final seen = <String>{};
    return [
      for (final n in [...planUebungen(widget.plan), ...d.geloggteUebungen])
        if (seen.add(n.toLowerCase())) n,
    ];
  }

  Future<void> _verlauf(String name) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => UebungVerlaufSeite(
        namen: _alleUebungen,
        start: name,
        daten: d,
        videos: _videos,
        heute: _heute,
        onVideo: (v) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FormCheckSeite(
              uebung: v.uebung,
              satz: v.satz,
              coach: widget.coach,
              videos: _videos,
              heute: _heute,
              onSpeichern: _videoSpeichern,
              zeigen: v,
            ),
          ),
        ),
        coachSatz: (u) async {
          final c = d.verlaufSaetze[u.toLowerCase()];
          if (c != null && c.tag == dayKey(_heute)) return c.satz;
          final s = await widget.coach.verlauf(
            widget.profile,
            u,
            verlaufText(d, u),
            widget.checkIns.reversed.take(21).toList().reversed.toList(),
          );
          if (s != null) {
            await _speichern(
              d.copyWith(
                verlaufSaetze: {
                  ...d.verlaufSaetze,
                  u.toLowerCase(): (tag: dayKey(_heute), satz: s),
                },
              ),
            );
          }
          return s;
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final teil = widget.teil;
    if (teil != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _d == null
            ? const [
                Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(color: CoachStyle.gold),
                  ),
                ),
              ]
            : switch (teil) {
                'woche' => widget.plan.isEmpty ? _planTeil() : _wocheTeil(),
                'plan' => _planTeil(),
                'uebungen' =>
                  _alleUebungen.isEmpty
                      ? const [
                          Text(
                            'Sobald du eine Übung eingetragen hast, siehst du '
                            'hier ihre Kurve, Rekorde und Form-Videos.',
                            style: tSoft,
                          ),
                        ]
                      : _uebungenTeil(),
                _ => _heuteTeil(),
              },
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        const PageHeader(
          label: 'Bereich',
          title: 'Training',
          icon: Icons.fitness_center,
        ),
        const AreaChart(bereich: Bereich.training),
        if (_d == null)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(color: CoachStyle.gold),
            ),
          )
        else ...[
          ..._heuteTeil(),
          if (!widget.plan.isEmpty) ..._wocheTeil(),
          if (_alleUebungen.isNotEmpty) ..._uebungenTeil(),
          ..._planTeil(),
        ],
        ...widget.extra,
        const GroupLabel('Frag deinen Coach'),
        AskCoachCard(
          title: 'Wie war dein Training?',
          hint:
              'Was hast du geschafft, was nicht, und warum? Der Coach sieht '
              'auch deine Einträge.',
          today: widget.fragen,
          onSend: widget.onAsk,
        ),
      ],
    );
  }

  List<Widget> _heuteTeil() {
    final e = d.einheitAm(_heute);
    final wochentag = wochentage[_heute.weekday - 1];
    if (widget.plan.isEmpty) {
      return [
        const GroupLabel('Heute'),
        TKarte(
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TLabel('Dein Plan'),
              const SizedBox(height: 6),
              Text(
                'Leg einmal fest, was du an welchem Tag trainierst. Danach '
                'steht hier jeden Tag dein Training zum Eintragen.',
                style: tText,
              ),
              const SizedBox(height: 10),
              MainButton(
                key: const ValueKey('plan-festlegen'),
                label: 'Plan festlegen',
                onPressed: _plan,
              ),
            ],
          ),
        ),
      ];
    }
    if (e?.status == EinheitStatus.uebersprungen) {
      return [
        GroupLabel('Heute · $wochentag'),
        SkipKarte(
          name: e!.name,
          grund: e.grund,
          text: verschiebeText(e.name, e.grund ?? '', e.verschobenAuf),
          onGrund: null,
          onZurueck: _skipZurueck,
        ),
      ];
    }
    if (e?.status == EinheitStatus.fertig) {
      final neu = <String, (SatzWert, SatzWert?, UebungArt)>{
        for (final r in neueRekorde(d, e!).entries)
          r.key: (
            r.value,
            rekorde(e.uebungen.firstWhere((u) => u.name == r.key).art, [
              for (final (_, l) in d.verlauf(r.key, vor: e.datum)) l,
            ]).bester,
            e.uebungen.firstWhere((u) => u.name == r.key).art,
          ),
      };
      final i = _planTag ?? (_heute.weekday - 1);
      final plan = widget.plan.uebungenAm(i);
      final fragen = [
        for (final (k, u) in plan.indexed)
          if (k == 0 || u.steigerung == Steigerung.selbst)
            if (e.uebungen.any((l) => l.name == u.name && l.fertige.isNotEmpty))
              u,
      ];
      final morgen = DateTime(_heute.year, _heute.month, _heute.day + 1);
      return [
        GroupLabel('Heute · $wochentag'),
        FertigKarte(einheit: e, rekorde: neu),
        for (final u in fragen)
          VorschlagFeld(
            uebung: u.name,
            art: u.art,
            vorbelegt: () {
              final z = zielFuer(
                u.copyWith(
                  steigerung: u.steigerung == Steigerung.selbst
                      ? Steigerung.coach
                      : null,
                ),
                d.copyWith(vorschlaege: const {}),
                morgen,
              );
              return z.saetze.isEmpty ? '' : satzText(u.art, z.saetze.first);
            }(),
            gespeichert: d.vorschlaege[u.name.toLowerCase()],
            onSenden: (t) => _vorschlag(u.name, u.art, t),
          ),
        TKarte(
          child: CoachZeile(
            label: 'Im Check-in',
            text:
                'Bei „Training“ ist im nächsten Check-in „${checkInVormerkung(d, _heute) ?? 'Gut trainiert'}“ '
                'schon vorgemerkt. Du bestätigst nur oder änderst es.',
          ),
        ),
        TGhost(
          'Noch etwas ändern',
          key: const ValueKey('noch-aendern'),
          onTap: _nochAendern,
        ),
        const SizedBox(height: 14),
      ];
    }
    final s = _session;
    if (s == null) {
      final next = _naechstesTraining();
      return [
        GroupLabel('Heute · $wochentag'),
        TKarte(
          key: const ValueKey('heute-frei'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TLabel('Ruhetag'),
              const SizedBox(height: 4),
              Text('Heute steht kein Training an.', style: tText),
              if (next != null) ...[
                const SizedBox(height: 4),
                Text('Nächstes Training: $next', style: tSoft),
              ],
            ],
          ),
        ),
      ];
    }
    final tf = d.tagesform;
    final heuteTf = tf != null && tf.tag == dayKey(_heute) ? tf : null;
    return [
      GroupLabel('Heute · $wochentag'),
      Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: GoldText(
          'Heute: ${dayName(widget.plan.tage[_planTag!])}',
          style: tTitel.copyWith(fontSize: 21),
        ),
      ),
      if (_tagesformLaedt)
        const TKarte(
          child: CoachZeile(
            label: 'Deine Tagesform',
            text: 'Ich schaue auf deine Nacht …',
          ),
        )
      else if (heuteTf != null && heuteTf.satz.isNotEmpty)
        TKarte(
          key: const ValueKey('tagesform'),
          child: CoachZeile(label: 'Deine Tagesform', text: heuteTf.satz),
        ),
      if (heuteTf?.aktiv case final a?)
        TKarte(
          key: const ValueKey('anpassung'),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TLabel('Coach hat angepasst'),
                    const SizedBox(height: 3),
                    Text(a.grund, style: tText),
                  ],
                ),
              ),
              TLink(
                'Rückgängig',
                key: const ValueKey('anpassung-zurueck'),
                onTap: _anpassungZurueck,
              ),
            ],
          ),
        ),
      if (_skipOffen)
        SkipKarte(
          name: s.name,
          onGrund: _skip,
          onZurueck: () => setState(() => _skipOffen = false),
        )
      else ...[
        MainButton(
          key: const ValueKey('modus-start'),
          label: 'Trainings-Modus starten',
          onPressed: _modus,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < s.logs.length; i++)
          UebungKarte(
            session: s,
            i: i,
            ziel: zielFuer(s.plan[i], d, _heute, anpassung: _anpassung),
            onForm: s.plan[i].art.ausdauer
                ? null
                : () => _form(s.plan[i].name, i),
            onVerlauf: () => _verlauf(s.plan[i].name),
          ),
        MainButton(
          key: const ValueKey('training-fertig'),
          label: 'Training fertig',
          onPressed: _fertig,
        ),
        const SizedBox(height: 8),
        TGhost(
          'Überspringen',
          key: const ValueKey('training-skip'),
          onTap: () => setState(() => _skipOffen = true),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Wie es war, fragt dich weiter der Check-in.',
            style: tSoft,
          ),
        ),
        const SizedBox(height: 14),
      ],
    ];
  }

  String? _naechstesTraining() {
    final w = wochenPlan(widget.plan, d, _heute);
    for (var k = 1; k <= 7; k++) {
      final i = (_heute.weekday - 1 + k) % 7;
      if (istTrainingstag(w.tage[i])) {
        return '${wochentage[i]} · ${dayName(w.tage[i])}';
      }
    }
    return null;
  }

  List<Widget> _wocheTeil() {
    final w = wochenPlan(widget.plan, d, _heute);
    final b = _balance();
    final faellig = stagnationFaellig(d, planUebungen(widget.plan), _heute);
    final letzte = d.stagnation.where(
      (c) =>
          _heute.difference(DateTime.parse(c.tag)).inDays < 7 &&
          c.status != 'gelassen',
    );
    final check = letzte.isEmpty ? null : letzte.last;
    final stagName = check?.uebung ?? faellig;
    String seit = '';
    if (stagName != null) {
      final h = d.verlauf(stagName);
      if (h.isNotEmpty) seit = satzText(h.last.$2.art, h.last.$2.bester!);
    }
    return [
      const GroupLabel('Deine Woche'),
      WochenStreifen(tage: w.tage, daten: d, heute: _heute),
      const SizedBox(height: 12),
      if (d.sportarten.length > 1 && _wocheKraft + b.ausdauer > 0)
        BalanceKarte(
          kraft: b.kraft,
          ausdauer: b.ausdauer,
          sportarten: d.sportarten,
          satz: d.balance?.woche == dayKey(montagVon(_heute))
              ? d.balance!.satz
              : null,
        ),
      if (stagName != null)
        StagnationsKarte(
          uebung: stagName,
          seit: seit,
          check: check,
          davor: uebungDavor(widget.plan, stagName),
          laedt: _stagLaedt,
          onGrund: (g) => _stagGrund(stagName, g),
          onUebernehmen: () => _stagStatus(check!, 'uebernommen'),
          onLassen: () => _stagStatus(check!, 'gelassen'),
          onZurueck: () => _stagStatus(check!, 'offen'),
        ),
    ];
  }

  List<Widget> _uebungenTeil() => [
    const GroupLabel('Deine Übungen'),
    Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final n in _alleUebungen)
          TChip(
            '$n ›',
            key: ValueKey('uebung-chip-$n'),
            an: false,
            onTap: () => _verlauf(n),
          ),
      ],
    ),
    const SizedBox(height: 16),
  ];

  List<Widget> _planTeil() => [
    const GroupLabel('Dein Plan'),
    if (!widget.plan.isEmpty)
      TKarte(
        key: const ValueKey('plan-karte'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (d.sportarten.isNotEmpty) ...[
              Text(d.sportarten.join(' · '), style: tSoft),
              const SizedBox(height: 8),
            ],
            const TLabel('Dein Schwerpunkt'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in Schwerpunkt.values)
                  TChip(
                    s.label,
                    key: ValueKey('schwerpunkt-${s.name}'),
                    an: s == widget.schwerpunkt,
                    klein: true,
                    onTap: () => widget.onSchwerpunkt(s),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < 7; i++) _planZeile(i),
            const SizedBox(height: 10),
            TGhost(
              'Plan bearbeiten',
              key: const ValueKey('plan-bearbeiten'),
              onTap: _plan,
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Der Plan wiederholt sich jede Woche.',
                style: tSoft.copyWith(
                  color: CoachStyle.inkSoft,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
  ];

  Widget _planZeile(int i) {
    final text = widget.plan.tage[i];
    final heute = i == _heute.weekday - 1;
    final frei = text.trim().isEmpty;
    final u = widget.plan.uebungenAm(i);
    return Container(
      key: ValueKey('plan-tag-$i'),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: heute ? CoachStyle.gold.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(10),
        border: heute || i == 0
            ? null
            : const Border(top: BorderSide(color: CoachStyle.edge)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              wochentage[i].substring(0, 2),
              style: tTitel.copyWith(
                fontSize: 13,
                color: heute ? CoachStyle.goldLight : CoachStyle.inkSoft,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heute ? '${shortDay(text)} · heute' : shortDay(text),
                  style: tText.copyWith(
                    fontWeight: frei ? FontWeight.w400 : FontWeight.w600,
                    color: frei ? CoachStyle.inkSoft : CoachStyle.ink,
                  ),
                ),
                for (final x in u)
                  Text(
                    '${x.name} · ${x.kurz}',
                    style: tSoft.copyWith(color: CoachStyle.inkSoft),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
