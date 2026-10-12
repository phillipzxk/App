import '../data/user_profile.dart';
import 'feed_data.dart';

/// Answers what the user writes into a field of the Main Feed, e.g. how
/// training went or what they ate today, using the profile and what they
/// set up (training plan, evening routine, kcal target).
abstract class FeedCoach {
  /// Returns the answer, or null if no answer is possible yet.
  Future<String?> answer(UserProfile profile, Bereich bereich, String text);
}

/// Used until the AI backend exists: there is no answer yet.
class NoFeedCoach implements FeedCoach {
  const NoFeedCoach();

  @override
  Future<String?> answer(
    UserProfile profile,
    Bereich bereich,
    String text,
  ) async => null;
}
