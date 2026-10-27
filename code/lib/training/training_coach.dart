import '../checkin/checkin.dart';
import '../data/user_profile.dart';
import 'form_video.dart';
import 'training_data.dart';

/// The coach's parts of training logging (vault Umsetzung/Training
/// eintragen.md). Every method returns null when the coach cannot be
/// reached; the page then works without it.
abstract class TrainingCoach {
  /// Idea 4: "Deine Tagesform" before training, from sleep and energy,
  /// and at most one change for today. [einheit] describes today's plan.
  Future<({String satz, Anpassung? anpassung})?> tagesform(
    UserProfile profile,
    CheckIn? heute,
    List<CheckIn> recent,
    String einheit,
  );

  /// Idea 6: the user's own target for next time; the coach confirms
  /// ([ok]) or suggests other values.
  Future<({String antwort, bool ok, SatzWert? werte})?> vorschlag(
    UserProfile profile,
    String uebung,
    String heute,
    String vorschlag,
  );

  /// Idea 7: the coach's view on a stuck exercise after the user's own
  /// guess [grund], with one change to the plan.
  Future<
    ({
      String sicht,
      String vorschlag,
      ({bool zuerst, PlanUebung uebung})? aenderung,
    })?
  >
  stagnation(
    UserProfile profile,
    PlanUebung uebung,
    String verlauf,
    String grund,
    List<CheckIn> recent,
    String tag,
  );

  /// Idea 8: one sentence on the balance of strength and endurance.
  Future<String?> balance(UserProfile profile, String woche);

  /// Idea 10: "Hinweise vom Coach" from the stills of one set.
  Future<FormHinweise?> formCheck(
    String uebung,
    String satz,
    List<String> bilder, {
    String? frueher,
  });

  /// One sentence for an exercise's history page that ties the curve to
  /// sleep, food or the head.
  Future<String?> verlauf(
    UserProfile profile,
    String uebung,
    String verlauf,
    List<CheckIn> recent,
  );
}

class NoTrainingCoach implements TrainingCoach {
  const NoTrainingCoach();

  @override
  Future<({String satz, Anpassung? anpassung})?> tagesform(
    UserProfile profile,
    CheckIn? heute,
    List<CheckIn> recent,
    String einheit,
  ) async => null;

  @override
  Future<({String antwort, bool ok, SatzWert? werte})?> vorschlag(
    UserProfile profile,
    String uebung,
    String heute,
    String vorschlag,
  ) async => null;

  @override
  Future<
    ({
      String sicht,
      String vorschlag,
      ({bool zuerst, PlanUebung uebung})? aenderung,
    })?
  >
  stagnation(
    UserProfile profile,
    PlanUebung uebung,
    String verlauf,
    String grund,
    List<CheckIn> recent,
    String tag,
  ) async => null;

  @override
  Future<String?> balance(UserProfile profile, String woche) async => null;

  @override
  Future<FormHinweise?> formCheck(
    String uebung,
    String satz,
    List<String> bilder, {
    String? frueher,
  }) async => null;

  @override
  Future<String?> verlauf(
    UserProfile profile,
    String uebung,
    String verlauf,
    List<CheckIn> recent,
  ) async => null;
}

/// Without the coach, a simple Tagesform from the check-in: lighter after
/// a short night or with low energy, otherwise nothing is said.
String? tagesformOhneCoach(CheckIn? heute) {
  if (heute == null) return null;
  final kurz =
      heute.schlaf == 'Zu kurz geschlafen' ||
      heute.schlaf == 'Nachts wach gewesen';
  final muede = heute.energie == 'Niedrig';
  if (kurz && muede) {
    return 'Wenig Schlaf und wenig Energie: Heute nur bis zum Ziel, kein '
        'Extra-Satz, und hör auf, wenn die Technik nachlässt.';
  }
  if (kurz) {
    return 'Die Nacht war kurz. Normal trainieren, aber ohne Extra-Satz.';
  }
  if (muede) {
    return 'Wenig Energie heute. Fang ruhig an, die ersten Sätze zeigen dir, '
        'was drin ist.';
  }
  return null;
}

/// Reads "85 × 6", "85 kg x 6", "85x6", "13" or "+10 kg × 8".
SatzWert? vorschlagLesen(UebungArt art, String text) {
  final t = text.replaceAll(',', '.').toLowerCase();
  final zahlen = RegExp(r'\d+(?:\.\d+)?')
      .allMatches(t)
      .map((m) => double.parse(m.group(0)!))
      .toList();
  if (zahlen.isEmpty) return null;
  if (art.wertEinheit == null) return SatzWert(null, zahlen.first);
  if (zahlen.length == 1) {
    return art == UebungArt.strecke ? SatzWert(zahlen.first, null) : null;
  }
  return SatzWert(zahlen[0], zahlen[1]);
}
