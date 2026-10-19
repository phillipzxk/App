import '../data/user_profile.dart';
import 'checkin.dart';

/// Writes the AI reply to a whole day: connections between the areas,
/// then one or two concrete tips.
abstract class CheckInEvaluator {
  /// Returns the reply, or null if no evaluation is possible yet.
  Future<String?> reply(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  );

  /// The scores per area (keys = Bereich.name), or null if not possible.
  Future<Map<String, BereichsWert>?> rate(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  );
}

/// Used until the AI backend exists: there is no reply yet.
class NoCheckInEvaluator implements CheckInEvaluator {
  const NoCheckInEvaluator();

  @override
  Future<String?> reply(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) async => null;

  @override
  Future<Map<String, BereichsWert>?> rate(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) async => null;
}
