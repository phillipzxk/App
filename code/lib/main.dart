import 'package:flutter/material.dart';

import 'data/profile_store.dart';
import 'data/user_profile.dart';
import 'home/home_page.dart';
import 'onboarding/onboarding_evaluator.dart';
import 'onboarding/onboarding_flow.dart';

void main() {
  runApp(CoachApp(store: LocalProfileStore()));
}

class CoachApp extends StatelessWidget {
  const CoachApp({
    super.key,
    required this.store,
    this.evaluator = const NoEvaluator(),
  });

  final ProfileStore store;
  final OnboardingEvaluator evaluator;

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
      home: StartGate(store: store, evaluator: evaluator),
    );
  }
}

/// Shows the onboarding on first start, otherwise the home page.
class StartGate extends StatefulWidget {
  const StartGate({super.key, required this.store, required this.evaluator});

  final ProfileStore store;
  final OnboardingEvaluator evaluator;

  @override
  State<StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<StartGate> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    widget.store.load().then((profile) {
      if (mounted) setState(() => _profile = profile);
    });
  }

  Future<void> _restartOnboarding() async {
    await widget.store.clear();
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
        store: widget.store,
        evaluator: widget.evaluator,
        onFinished: (p) => setState(() => _profile = p),
      );
    }
    return HomePage(profile: profile, onRestartOnboarding: _restartOnboarding);
  }
}
