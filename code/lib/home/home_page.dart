import 'package:flutter/material.dart';

import '../data/user_profile.dart';
import '../onboarding/onboarding_questions.dart';

/// Placeholder for the daily feed (next MVP step). Shows what the
/// onboarding stored so it can be checked while testing.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.onRestartOnboarding,
  });

  final UserProfile profile;
  final VoidCallback onRestartOnboarding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dein Coach')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Hier kommt bald dein täglicher Check-in.',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Das weiß dein Coach über dich:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final q in onboardingQuestions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(q.topic),
                    subtitle: Text(q.read(profile)),
                  ),
                if (profile.zusammenfassung.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('So sehe ich dich gerade'),
                    subtitle: Text(profile.zusammenfassung),
                  ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: onRestartOnboarding,
                  child: const Text('Fragebogen neu starten'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
