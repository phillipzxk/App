import 'package:flutter/foundation.dart';

import '../data/user_profile.dart';
import 'mindset_data.dart';

/// What the coach does on the Mindset page (route /mindset). Every call may
/// return null (no coach or not reachable); the page then has its own
/// fallback.
abstract class MindsetCoach {
  /// The 2-minute first step for a stone. With [eigener] the user named it
  /// first: the coach only adds to it and says whether it fits.
  Future<({String schritt, String satz, bool passt})?> schritt(
    UserProfile profile,
    String titel,
    String? eigener,
    String kontext,
  );

  /// What comes right after the stone, so no gap opens (3 short points).
  Future<List<String>?> danach(
    UserProfile profile,
    String titel,
    String kontext,
  );

  /// A plan against the excuse that comes most often.
  Future<String?> ausredenPlan(
    UserProfile profile,
    String ausrede,
    String kontext,
  );

  /// Sorts worries into "kannst du ändern" and "liegt nicht bei dir".
  Future<({List<Sorge> sorgen, String? satz})?> sorgen(
    UserProfile profile,
    String text,
    String kontext,
  );

  /// The guiding sentence from all evening answers so far.
  Future<String?> leitsatz(UserProfile profile, List<Abendantwort> antworten);

  /// When a letter opens: what has changed since it was written.
  Future<String?> brief(UserProfile profile, Brief brief, String kontext);
}

class NoMindsetCoach implements MindsetCoach {
  const NoMindsetCoach();

  @override
  Future<({String schritt, String satz, bool passt})?> schritt(
    UserProfile profile,
    String titel,
    String? eigener,
    String kontext,
  ) async => null;

  @override
  Future<List<String>?> danach(
    UserProfile profile,
    String titel,
    String kontext,
  ) async => null;

  @override
  Future<String?> ausredenPlan(
    UserProfile profile,
    String ausrede,
    String kontext,
  ) async => null;

  @override
  Future<({List<Sorge> sorgen, String? satz})?> sorgen(
    UserProfile profile,
    String text,
    String kontext,
  ) async => null;

  @override
  Future<String?> leitsatz(
    UserProfile profile,
    List<Abendantwort> antworten,
  ) async => null;

  @override
  Future<String?> brief(
    UserProfile profile,
    Brief brief,
    String kontext,
  ) async => null;
}

/// The Mindset data in memory; every change is saved right away.
class MindsetStand extends ChangeNotifier {
  MindsetStand(this._speichern);

  final Future<void> Function(MindsetDaten d) _speichern;
  MindsetDaten _d = const MindsetDaten();
  MindsetDaten get d => _d;

  void laden(MindsetDaten d) {
    _d = d;
    notifyListeners();
  }

  Future<void> setze(MindsetDaten d) async {
    _d = d;
    notifyListeners();
    await _speichern(d);
  }
}
