import '../data/user_profile.dart';
import 'schlaf_data.dart';

/// What the coach does on the Schlaf & Energie page. Every call may return
/// null (no coach or not reachable); the page then has its own fallback.
abstract class SchlafCoach {
  /// One line for today after the morning entry.
  Future<String?> morgen(UserProfile profile, String kontext);

  /// The energy forecast for today in one or two sentences.
  Future<String?> energie(UserProfile profile, String kontext);

  /// Patterns that clearly hold only for this user, and their best time.
  Future<({List<SchlafMuster> muster, ({String typ, String text})? besteZeit})?>
  muster(UserProfile profile, String kontext);

  /// The best day for today, around the user's own appointments.
  Future<({List<AblaufPunkt> punkte, String? satz})?> tagesablauf(
    UserProfile profile,
    String kontext,
  );
}

class NoSchlafCoach implements SchlafCoach {
  const NoSchlafCoach();

  @override
  Future<String?> morgen(UserProfile profile, String kontext) async => null;

  @override
  Future<String?> energie(UserProfile profile, String kontext) async => null;

  @override
  Future<({List<SchlafMuster> muster, ({String typ, String text})? besteZeit})?>
  muster(UserProfile profile, String kontext) async => null;

  @override
  Future<({List<AblaufPunkt> punkte, String? satz})?> tagesablauf(
    UserProfile profile,
    String kontext,
  ) async => null;
}
