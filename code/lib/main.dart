import 'dart:async';

import 'package:flutter/material.dart';

import 'checkin/checkin.dart';
import 'checkin/checkin_evaluator.dart';
import 'checkin/checkin_flow.dart';
import 'coach/remote_coach.dart';
import 'data/diary_store.dart';
import 'data/profile_store.dart';
import 'data/user_profile.dart';
import 'feed/feed_coach.dart';
import 'feed/feed_store.dart';
import 'home/home_page.dart';
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
  });

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
  late bool _splashing = widget.app.splash > Duration.zero;
  Timer? _splashTimer;

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
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await widget.app.store.load();
    final checkIns = await widget.app.diary.loadCheckIns();
    final today = dayKey(widget.app.clock());
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _checkedInToday = checkIns.any((c) => dayKey(c.datum) == today);
    });
  }

  Future<void> _restartOnboarding() async {
    await widget.app.store.clear();
    if (mounted) setState(() => _profile = const UserProfile());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null || _splashing) return const SplashScreen();
    if (!profile.isOnboarded) {
      return OnboardingFlow(
        store: widget.app.store,
        evaluator: widget.app.evaluator,
        onFinished: (p) => setState(() => _profile = p),
      );
    }
    if (!_checkedInToday) {
      return CheckInFlow(
        profile: profile,
        store: widget.app.diary,
        evaluator: widget.app.checkInEvaluator,
        today: widget.app.clock(),
        onFinished: (_) => setState(() => _checkedInToday = true),
      );
    }
    return HomePage(
      profile: profile,
      store: widget.app.diary,
      feed: widget.app.feed,
      coach: widget.app.feedCoach,
      clock: widget.app.clock,
      onRestartOnboarding: _restartOnboarding,
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
