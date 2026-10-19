import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../data/diary_store.dart';
import '../data/user_profile.dart';
import '../feed/feed_coach.dart';
import '../feed/feed_data.dart';
import '../feed/feed_store.dart';
import '../feed/kcal.dart';
import '../future_me/future_me_data.dart';
import '../future_me/future_me_page.dart';
import '../planner/planner_data.dart';
import '../sleep/sleep.dart';
import '../supplements/supplement_data.dart';
import '../ui/coach_style.dart';
import '../weight/weight.dart';
import 'mindset_tab.dart';
import 'nutrition_tab.dart';
import 'sleep_tab.dart';
import 'bereichs_werte.dart';
import 'today_tab.dart';
import 'training_tab.dart';

/// The Main Feed: opens after the daily check-in. A bar at the bottom
/// switches between "Heute" and one page per area (see
/// Umsetzung/Main Feed.md).
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.store,
    required this.feed,
    required this.coach,
    required this.clock,
    required this.onRestartOnboarding,
  });

  final UserProfile profile;
  final DiaryStore store;
  final FeedStore feed;
  final FeedCoach coach;
  final DateTime Function() clock;
  final VoidCallback onRestartOnboarding;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loaded = false;
  int _tab = 0;
  List<CheckIn> _checkIns = const [];
  List<WeightEntry> _weights = const [];
  List<SleepEntry> _sleep = const [];
  TrainingPlan _plan = TrainingPlan.empty();
  List<RoutineStep> _routine = const [];
  KcalProfil? _kcal;
  List<CoachFrage> _fragen = const [];
  List<Termin> _termine = const [];
  int? _mahlzeiten;
  Schwerpunkt? _schwerpunkt;
  FotoEinstellungen? _fotoEinstellungen;
  List<WochenFoto> _wochenFotos = const [];
  List<Supplement> _supplements = const [];
  Set<String> _genommen = const {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final checkIns = await widget.store.loadCheckIns();
    final weights = await widget.store.loadWeights();
    final sleep = await widget.store.loadSleep();
    final plan = await widget.feed.loadPlan();
    final routine = await widget.feed.loadRoutine();
    final kcal = await widget.feed.loadKcal();
    final fragen = await widget.feed.loadFragen();
    final termine = await widget.feed.loadTermine();
    final mahlzeiten = await widget.feed.loadMahlzeiten();
    final schwerpunkt = await widget.feed.loadSchwerpunkt();
    final fotoEinstellungen = await widget.feed.loadFotoEinstellungen();
    final wochenFotos = await widget.feed.loadWochenFotos();
    final supplements = await widget.feed.loadSupplements();
    final genommen = await widget.feed.loadGenommen(widget.clock());
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _checkIns = checkIns;
      _weights = weights;
      _sleep = sleep;
      _plan = plan;
      _routine = routine;
      _kcal = kcal;
      _fragen = fragen;
      _termine = termine;
      _mahlzeiten = mahlzeiten;
      _schwerpunkt = schwerpunkt;
      _fotoEinstellungen = fotoEinstellungen;
      _wochenFotos = wochenFotos;
      _supplements = supplements;
      _genommen = genommen;
    });
  }

  List<CoachFrage> _todayFragen(Bereich b) {
    final key = dayKey(widget.clock());
    return [
      for (final f in _fragen)
        if (f.bereich == b && dayKey(f.datum) == key) f,
    ];
  }

  Future<void> Function(String) _ask(Bereich b) => (text) async {
    final antwort = await widget.coach.answer(
      widget.profile,
      b,
      text,
      context: _context(b),
    );
    await widget.feed.addFrage(
      CoachFrage(
        datum: widget.clock(),
        bereich: b,
        text: text,
        antwort: antwort ?? '',
      ),
    );
    await _reload();
  };

  Future<void> _addWeight() async {
    final kg = await showDialog<double>(
      context: context,
      builder: (context) => const WeightDialog(),
    );
    if (kg == null) return;
    await widget.store.addWeight(WeightEntry(widget.clock(), kg));
    await _reload();
  }

  Future<void> _addSleep() async {
    final h = await showDialog<double>(
      context: context,
      builder: (context) => const SleepDialog(),
    );
    if (h == null) return;
    await widget.store.saveSleep(SleepEntry(widget.clock(), h));
    await _reload();
  }

  Future<void> _saveKcal(KcalProfil profil, double? kg) async {
    await widget.feed.saveKcal(profil);
    if (kg != null) {
      await widget.store.addWeight(WeightEntry(widget.clock(), kg));
    }
    await _reload();
  }

  /// What the user set up for [b], so the coach can refer to it.
  String _context(Bereich b) {
    switch (b) {
      case Bereich.training:
        if (_plan.isEmpty) return '';
        const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
        return [
          'Trainingsplan:',
          for (var i = 0; i < 7; i++)
            '${days[i]}: ${_plan.tage[i].trim().isEmpty ? 'frei' : _plan.tage[i].trim()}',
          'Heute ist ${days[widget.clock().weekday - 1]}.',
        ].join('\n');
      case Bereich.ernaehrung:
        final ziel = _kcalZiel;
        if (ziel == null) return '';
        return 'kcal-Ziel heute: $ziel kcal '
            '(nur als Orientierung, nicht zum Zählen). '
            'Gewicht zuletzt: ${_weights.last.kg} kg.';
      case Bereich.schlaf:
        final lines = [
          if (_routine.isNotEmpty) 'Abendroutine:',
          for (final s in _routine) '${s.zeit} ${s.was}',
          for (final e in _sleep.reversed.take(7))
            'Schlaf ${dayKey(e.datum)}: ${e.stunden} Stunden',
        ];
        return lines.join('\n');
      case Bereich.mindset:
        return '';
    }
  }

  int? get _kcalZiel {
    final p = _kcal;
    if (p == null || _weights.isEmpty) return null;
    return kcalZiel(p, _weights.last.kg);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayTab(
        name: widget.profile.name,
        date: germanDate(widget.clock()),
        today: widget.clock(),
        checkIns: _checkIns,
        termine: _termine,
        training: _plan.forDay(widget.clock()),
        mahlzeiten: _mahlzeiten,
        kcalZiel: _kcalZiel,
        onAddTermin: (text) async {
          await widget.feed.addTermin(parseTermin(text, widget.clock()));
          await _reload();
        },
        onRemoveTermin: (t) async {
          await widget.feed.removeTermin(t);
          await _reload();
        },
        onSetMahlzeiten: (n) async {
          await widget.feed.saveMahlzeiten(n);
          await _reload();
        },
        fotoEinstellungen: _fotoEinstellungen,
        wochenFotos: _wochenFotos,
        onOpenZukunft: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  FutureMePage(store: widget.feed, clock: widget.clock),
            ),
          );
          await _reload();
        },
        supplements: _supplements,
        genommen: _genommen,
        onOpenSupplements: () =>
            setState(() => _tab = Bereich.ernaehrung.index + 1),
        onOpenArea: (b) => setState(() => _tab = b.index + 1),
        onRestartOnboarding: widget.onRestartOnboarding,
      ),
      TrainingTab(
        plan: _plan,
        schwerpunkt: _schwerpunkt,
        today: widget.clock(),
        fragen: _todayFragen(Bereich.training),
        onSchwerpunkt: (sp) async {
          await widget.feed.saveSchwerpunkt(sp);
          await _reload();
        },
        onSavePlan: (p) async {
          await widget.feed.savePlan(p);
          await _reload();
        },
        onAsk: _ask(Bereich.training),
      ),
      NutritionTab(
        kcal: _kcal,
        weights: _weights,
        fragen: _todayFragen(Bereich.ernaehrung),
        onSaveKcal: _saveKcal,
        onAddWeight: _addWeight,
        onAsk: _ask(Bereich.ernaehrung),
        supplements: _supplements,
        genommen: _genommen,
        onSaveSupplements: (list) async {
          await widget.feed.saveSupplements(list);
          await _reload();
        },
        onToggleSupplement: (s, an) async {
          await widget.feed.setGenommen(widget.clock(), s.id, an);
          await _reload();
        },
      ),
      SleepTab(
        routine: _routine,
        sleep: _sleep,
        today: widget.clock(),
        fragen: _todayFragen(Bereich.schlaf),
        onAddSleep: _addSleep,
        onSaveRoutine: (steps) async {
          await widget.feed.saveRoutine(steps);
          await _reload();
        },
        onAsk: _ask(Bereich.schlaf),
      ),
      MindsetTab(
        profile: widget.profile,
        fragen: _todayFragen(Bereich.mindset),
        onAsk: _ask(Bereich.mindset),
      ),
    ];
    // The whole app is dark with beige and gold (Phillip 2026-10-18).
    return Scaffold(
      backgroundColor: CoachStyle.night,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: CoachStyle.nightGradient),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: CoachStyle.nightGlow),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _loaded
                      ? WerteScope(
                          checkIns: _checkIns,
                          today: widget.clock(),
                          child: IndexedStack(index: _tab, children: pages),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: CoachStyle.gold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: TabLeiste(
        selected: _tab,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Floating dark bar at the bottom with the five pages; the open one is
/// gold with a small gold dot.
class TabLeiste extends StatelessWidget {
  const TabLeiste({super.key, required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.today_outlined, 'Heute'),
    (Icons.fitness_center, 'Training'),
    (Icons.eco_outlined, 'Ernährung'),
    (Icons.bedtime_outlined, 'Schlaf'),
    (Icons.spa_outlined, 'Mindset'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            key: const ValueKey('tab-leiste'),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xF2171310),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: CoachStyle.hairline),
              boxShadow: CoachStyle.darkShadow,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == selected,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: i == selected ? 18 : 0,
                                height: 3,
                                margin: const EdgeInsets.only(bottom: 5),
                                decoration: BoxDecoration(
                                  gradient: CoachStyle.goldGradient,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Icon(
                                _items[i].$1,
                                size: 22,
                                color: i == selected
                                    ? CoachStyle.goldLight
                                    : CoachStyle.nightMuted,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _items[i].$2,
                                style: TextStyle(
                                  fontFamily: 'Figtree',
                                  fontSize: 11,
                                  fontWeight: i == selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: i == selected
                                      ? CoachStyle.goldLight
                                      : CoachStyle.nightMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// E.g. "Montag, 12. Oktober".
String germanDate(DateTime d) {
  const days = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  const months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return '${days[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]}';
}
