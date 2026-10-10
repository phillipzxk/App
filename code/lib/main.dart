import 'package:flutter/material.dart';

import 'data/profile_store.dart';
import 'data/user_profile.dart';
import 'home/home_page.dart';
import 'onboarding/onboarding_flow.dart';

void main() {
  runApp(CoachApp(store: LocalProfileStore()));
}

class CoachApp extends StatelessWidget {
  const CoachApp({super.key, required this.store});

  final ProfileStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: StartGate(store: store),
    );
  }
}

/// Shows the onboarding on first start, otherwise the home page.
class StartGate extends StatefulWidget {
  const StartGate({super.key, required this.store});

  final ProfileStore store;

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
        onFinished: (p) => setState(() => _profile = p),
      );
    }
    return HomePage(profile: profile, onRestartOnboarding: _restartOnboarding);
  }
}
