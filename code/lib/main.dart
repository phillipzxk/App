import 'package:flutter/material.dart';

import 'checkin/checkin.dart';
import 'checkin/checkin_evaluator.dart';
import 'checkin/checkin_flow.dart';
import 'data/diary_store.dart';
import 'data/profile_store.dart';
import 'data/user_profile.dart';
import 'feed/feed_coach.dart';
import 'feed/feed_store.dart';
import 'home/home_page.dart';
import 'onboarding/onboarding_evaluator.dart';
import 'onboarding/onboarding_flow.dart';

void main() {
  runApp(
    CoachApp(
      store: LocalProfileStore(),
      diary: LocalDiaryStore(),
      feed: LocalFeedStore(),
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
  });

  final ProfileStore store;
  final DiaryStore diary;
  final FeedStore feed;
  final OnboardingEvaluator evaluator;
  final CheckInEvaluator checkInEvaluator;
  final FeedCoach feedCoach;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        fontFamily: 'Figtree',
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
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

  @override
  void initState() {
    super.initState();
    _load();
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
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
