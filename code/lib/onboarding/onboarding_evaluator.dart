import '../data/user_profile.dart';

/// Turns the onboarding answers into the short summary
/// "So sehe ich dich gerade" (2–3 sentences, no tips yet).
abstract class OnboardingEvaluator {
  /// Returns the summary, or null if no evaluation is possible yet.
  Future<String?> summarize(UserProfile answers);
}

/// Used until the AI backend exists: there is no summary yet.
class NoEvaluator implements OnboardingEvaluator {
  const NoEvaluator();

  @override
  Future<String?> summarize(UserProfile answers) async => null;
}
