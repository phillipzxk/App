import 'dart:async';

import 'package:flutter/material.dart';

import 'checkin/checkin.dart';
import 'checkin/checkin_evaluator.dart';
import 'checkin/checkin_flow.dart';
import 'training/training_logik.dart';
import 'coach/remote_coach.dart';
import 'data/diary_store.dart';
import 'data/profile_store.dart';
import 'data/user_profile.dart';
import 'feed/feed_coach.dart';
import 'erinnerungen/erinnerung_dienst.dart';
import 'feed/feed_data.dart';
import 'feed/feed_store.dart';
import 'schlaf/wecker_aufgabe.dart';
import 'training/training_data.dart' show istTrainingstag;
import 'home/home_page.dart';
import 'health/health_dienst.dart';
import 'health/health_logik.dart';
import 'konto/konto_daten.dart';
import 'konto/konto_dienst.dart';
import 'konto/konto_einstellungen.dart';
import 'konto/konto_flow.dart';
import 'konto/konto_web.dart';
import 'konto/sicherung.dart';
import 'onboarding/onboarding_evaluator.dart';
import 'onboarding/onboarding_flow.dart';
import 'ui/coach_style.dart';
import 'ui/logo.dart';

void main() {
  final coach = coachUrl.isEmpty
      ? null
      : RemoteCoach(baseUrl: coachUrl, token: coachToken);
  runApp(
    CoachApp(
      store: LocalProfileStore(),
      diary: LocalDiaryStore(),
      feed: LocalFeedStore(),
      evaluator: coach ?? const NoEvaluator(),
      checkInEvaluator: coach ?? const NoCheckInEvaluator(),
      feedCoach: coach ?? const NoFeedCoach(),
      splash: const Duration(milliseconds: 1500),
      kontoDienst: supabaseUrl.isEmpty
          ? VorschauKontoDienst()
          : SupabaseKontoDienst(
              url: supabaseUrl,
              key: supabaseKey,
              anbieter: {
                for (final a in supabaseAnbieter.split(','))
                  ?Anmeldeart.values.asNameMap()[a.trim()],
              },
            ),
      kontoStore: LocalKontoStore(),
      erinnerungen: erinnerungenFuerPlattform(),
      health: healthFuerPlattform(),
    ),
  );
}

class CoachApp extends StatelessWidget {
  const CoachApp({
    super.key,
    required this.store,
    required this.diary,
    required this.feed,
    this.evaluator = const NoEvaluator(),
    this.checkInEvaluator = const NoCheckInEvaluator(),
    this.feedCoach = const NoFeedCoach(),
    this.clock = DateTime.now,
    this.splash = Duration.zero,
    this.kontoDienst,
    this.kontoStore,
    this.erinnerungen,
    this.health,
  });

  /// Apple Health (vault Umsetzung/Apple Health). Null in tests.
  final HealthDienst? health;

  /// Reminders on the phone (vault Umsetzung/Erinnerungen). Null in tests.
  final ErinnerungDienst? erinnerungen;

  /// Account and backup (vault Umsetzung/Konto und Sicherung). Null in
  /// tests that don't care: then there is no account step.
  final KontoDienst? kontoDienst;
  final KontoStore? kontoStore;

  final ProfileStore store;
  final DiaryStore diary;
  final FeedStore feed;
  final OnboardingEvaluator evaluator;
  final CheckInEvaluator checkInEvaluator;
  final FeedCoach feedCoach;
  final DateTime Function() clock;

  /// How long the start screen with the logo stays at least.
  final Duration splash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groundset',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: CoachStyle.gold,
          brightness: Brightness.dark,
          primary: CoachStyle.gold,
          onPrimary: CoachStyle.goldInk,
          surface: CoachStyle.card,
          onSurface: CoachStyle.ink,
        ),
        scaffoldBackgroundColor: CoachStyle.page,
        useMaterial3: true,
        fontFamily: 'Figtree',
      ),
      home: StartGate(app: this),
    );
  }
}

/// Decides what to show: the onboarding on first start, then every day the
/// check-in until it is answered, after that the Main Feed.
class StartGate extends StatefulWidget {
  const StartGate({super.key, required this.app});

  final CoachApp app;

  @override
  State<StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<StartGate> {
  UserProfile? _profile;
  bool _checkedInToday = false;
  Map<String, String> _vorgemerkt = const {};
  late bool _splashing = widget.app.splash > Duration.zero;
  Timer? _splashTimer;
  Konto? _konto;
  bool _schonKonto = false;
  final _erinnerungenNeu = ValueNotifier<int>(0);
  DateTime? _letzteSicherung;
  late final AppLifecycleListener _leben = AppLifecycleListener(
    onHide: () => _sichern(sofort: true),
    onResume: _pruefeWecker,
  );

  /// After the real alarm's "Aufstehen": the task comes first.
  ({DateTime seit, String aufgabe, String? heute})? _weckerAufgabe;

  Future<void> _pruefeWecker() async {
    final d = widget.app.erinnerungen;
    if (d == null) return;
    final seit = await d.weckerAufgabeOffen();
    if (seit == null) {
      if (_weckerAufgabe != null && mounted) {
        setState(() => _weckerAufgabe = null);
      }
      return;
    }
    final schlaf = await widget.app.feed.loadSchlaf();
    final plan = await widget.app.feed.loadPlan();
    final tag = plan.forDay(widget.app.clock()).trim();
    final heute = tag.isNotEmpty && istTrainingstag(tag)
        ? 'Heute: ${dayName(tag)}.'
        : null;
    if (!mounted) return;
    setState(
      () => _weckerAufgabe = (
        seit: seit,
        aufgabe: schlaf.wecker.aufgabe,
        heute: heute,
      ),
    );
  }

  KontoDienst? get _dienst => widget.app.kontoDienst;
  late final KontoStore _kontoStore =
      widget.app.kontoStore ?? MemoryKontoStore();
  late final Sicherung? _sicherung = _dienst == null
      ? null
      : Sicherung(
          dienst: _dienst!,
          store: _kontoStore,
          clock: widget.app.clock,
        );

  /// Backs up in the background: on app start, after the check-in and when
  /// the app goes to the background. At most every 2 minutes unless [sofort].
  Future<void> _sichern({bool sofort = false}) async {
    final s = _sicherung;
    if (s == null || _konto == null) return;
    final jetzt = widget.app.clock();
    final l = _letzteSicherung;
    if (!sofort && l != null && jetzt.difference(l).inMinutes < 2) return;
    _letzteSicherung = jetzt;
    try {
      await s.sichern();
    } catch (_) {
      // Offline or the session ran out: the next try runs later.
    }
  }

  @override
  void initState() {
    super.initState();
    if (_splashing) {
      _splashTimer = Timer(
        widget.app.splash,
        () => setState(() => _splashing = false),
      );
    }
    _load();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _leben.dispose();
    _erinnerungenNeu.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var konto = await _kontoStore.loadKonto();
    // Back from Apple or Google: the session is in the address.
    final d = _dienst;
    final adresse = aktuelleAdresse();
    if (d != null &&
        adresse != null &&
        adresse.fragment.contains('access_token')) {
      final k = await d.ausAdresse(adresse);
      adresseAufraeumen();
      if (k != null) {
        konto = k;
        await _kontoStore.saveKonto(k);
        final p = await widget.app.store.load();
        if (!p.isOnboarded) await _sicherung?.wiederherstellen();
      }
    }
    final profile = await widget.app.store.load();
    final checkIns = await widget.app.diary.loadCheckIns();
    final today = dayKey(widget.app.clock());
    final training = await widget.app.feed.loadTraining();
    final vorgemerkt = checkInVormerkung(training, widget.app.clock());
    if (!mounted) return;
    setState(() {
      _vorgemerkt = {'Training': ?vorgemerkt};
      _profile = profile;
      _konto = konto;
      _checkedInToday = checkIns.any((c) => dayKey(c.datum) == today);
    });
    if (profile.isOnboarded) unawaited(_sichern());
    unawaited(_pruefeWecker());
  }

  /// Reads Apple Health for the check-in and keeps it for Heute.
  Future<String> _messwerte() async {
    final dienst = widget.app.health;
    if (dienst == null) return '';
    final schlaf = await widget.app.feed.loadSchlaf();
    final neu = await healthHolen(dienst, schlaf, widget.app.clock());
    if (neu == null) return '';
    await widget.app.feed.saveSchlaf(neu);
    return messwerteText(neu.healthAm(dayKey(widget.app.clock())));
  }

  Future<void> _kontoOeffnen(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => KontoEinstellungen(
            dienst: _dienst!,
            store: _kontoStore,
            sicherung: _sicherung!,
            name: _profile?.name ?? '',
            clock: widget.app.clock,
            erinnerungen: widget.app.erinnerungen,
            onErinnerungen: () => _erinnerungenNeu.value++,
            health: widget.app.health,
            onAbgemeldet: () => setState(() => _konto = null),
            onGeloescht: () => setState(() {
              _konto = null;
              _profile = const UserProfile();
              _checkedInToday = false;
            }),
          ),
        ),
      );

  Future<void> _restartOnboarding() async {
    await widget.app.store.clear();
    if (mounted) setState(() => _profile = const UserProfile());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null || _splashing) return const SplashScreen();
    final dienst = _dienst;
    if (!profile.isOnboarded) {
      if (_schonKonto && dienst != null) {
        return KontoFlow(
          key: const ValueKey('konto-zurueck-flow'),
          dienst: dienst,
          store: _kontoStore,
          sicherung: _sicherung!,
          zurueck: true,
          onAbbrechen: () => setState(() => _schonKonto = false),
          onFertig: (_) {
            _schonKonto = false;
            _load();
          },
        );
      }
      return OnboardingFlow(
        store: widget.app.store,
        evaluator: widget.app.evaluator,
        onFinished: (p) => setState(() => _profile = p),
        onSchonKonto: dienst == null
            ? null
            : () => setState(() => _schonKonto = true),
      );
    }
    // Account right after the questionnaire, before the first check-in.
    if (dienst != null && _konto == null) {
      return KontoFlow(
        key: const ValueKey('konto-flow'),
        dienst: dienst,
        store: _kontoStore,
        sicherung: _sicherung!,
        name: profile.name,
        ziel: profile.zielSatz,
        onFertig: (_) => _load(),
      );
    }
    final wecker = _weckerAufgabe;
    if (wecker != null) {
      return WeckerAufgabe(
        name: profile.name.trim(),
        aufgabe: wecker.aufgabe,
        geklingelt: wecker.seit,
        heute: wecker.heute,
        clock: widget.app.clock,
        onFertig: () async {
          await widget.app.erinnerungen?.weckerAufgabeErledigt();
          if (mounted) setState(() => _weckerAufgabe = null);
        },
      );
    }
    if (!_checkedInToday) {
      return CheckInFlow(
        profile: profile,
        store: widget.app.diary,
        evaluator: widget.app.checkInEvaluator,
        today: widget.app.clock(),
        vorgemerkt: _vorgemerkt,
        messwerte: widget.app.health == null ? null : _messwerte,
        onFinished: (_) {
          setState(() => _checkedInToday = true);
          _sichern(sofort: true);
        },
      );
    }
    return HomePage(
      profile: profile,
      store: widget.app.diary,
      feed: widget.app.feed,
      coach: widget.app.feedCoach,
      clock: widget.app.clock,
      onRestartOnboarding: _restartOnboarding,
      onKonto: dienst == null ? null : () => _kontoOeffnen(context),
      erinnerungen: widget.app.erinnerungen,
      erinnerungenNeu: _erinnerungenNeu,
      health: widget.app.health,
    );
  }
}

/// Start screen with the logo, shown briefly when the app opens.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachStyle.page,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoMark(size: 120),
            const SizedBox(height: 14),
            const Wordmark(fontSize: 18),
            const SizedBox(height: 28),
            Text(
              'Das Fundament für jeden Tag.',
              style: CoachStyle.body.copyWith(
                color: CoachStyle.inkSoft,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
