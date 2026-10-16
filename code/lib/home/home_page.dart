import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../data/diary_store.dart';
import '../data/user_profile.dart';
import '../feed/feed_coach.dart';
import '../feed/feed_data.dart';
import '../feed/feed_store.dart';
import '../feed/kcal.dart';
import '../planner/planner_data.dart';
import '../sleep/sleep.dart';
import '../ui/coach_style.dart';
import '../weight/weight.dart';
import 'mindset_tab.dart';
import 'nutrition_tab.dart';
import 'sleep_tab.dart';
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
    final antwort = await widget.coach.answer(widget.profile, b, text);
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
        onOpenArea: (b) => setState(() => _tab = b.index + 1),
        onRestartOnboarding: widget.onRestartOnboarding,
      ),
      TrainingTab(
        plan: _plan,
        today: widget.clock(),
        fragen: _todayFragen(Bereich.training),
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
    return Scaffold(
      backgroundColor: CoachStyle.page,
      body: DecoratedBox(
        decoration: const BoxDecoration(color: CoachStyle.page),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _loaded
                    ? IndexedStack(index: _tab, children: pages)
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
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFFF6F2EA),
          surfaceTintColor: Colors.transparent,
          indicatorColor: CoachStyle.gold,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: states.contains(WidgetState.selected)
                  ? CoachStyle.ink
                  : CoachStyle.inkSoft,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : CoachStyle.inkSoft,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.today), label: 'Heute'),
            NavigationDestination(
              icon: Icon(Icons.fitness_center),
              label: 'Training',
            ),
            NavigationDestination(icon: Icon(Icons.eco), label: 'Ernährung'),
            NavigationDestination(icon: Icon(Icons.bedtime), label: 'Schlaf'),
            NavigationDestination(icon: Icon(Icons.spa), label: 'Mindset'),
          ],
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
