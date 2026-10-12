import 'package:flutter/material.dart';

import 'checkin/checkin_evaluator.dart';
import 'data/diary_store.dart';
import 'data/profile_store.dart';
import 'data/user_profile.dart';
import 'home/home_page.dart';
import 'onboarding/onboarding_evaluator.dart';
import 'onboarding/onboarding_flow.dart';

void main() {
  runApp(CoachApp(store: LocalProfileStore(), diary: LocalDiaryStore()));
}

class CoachApp extends StatelessWidget {
  const CoachApp({
    super.key,
    required this.store,
    required this.diary,
    this.evaluator = const NoEvaluator(),
    this.checkInEvaluator = const NoCheckInEvaluator(),
    this.clock = DateTime.now,
  });

  final ProfileStore store;
  final DiaryStore diary;
  final OnboardingEvaluator evaluator;
  final CheckInEvaluator checkInEvaluator;
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

/// Shows the onboarding on first start, otherwise the home page.
class StartGate extends StatefulWidget {
  const StartGate({super.key, required this.app});

  final CoachApp app;

  @override
  State<StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<StartGate> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    widget.app.store.load().then((profile) {
      if (mounted) setState(() => _profile = profile);
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
    return HomePage(
      profile: profile,
      store: widget.app.diary,
      evaluator: widget.app.checkInEvaluator,
      clock: widget.app.clock,
      onRestartOnboarding: _restartOnboarding,
    );
  }
}
