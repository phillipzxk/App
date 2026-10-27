import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../data/user_profile.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'ernaehrung_coach.dart';
import 'ernaehrung_data.dart';
import 'ernaehrung_logik.dart';

/// The Ernährung data, shared by the page, its sub pages and Heute.
/// Every change is saved right away.
class ErnaehrungStand extends ChangeNotifier {
  ErnaehrungStand(this._speichern);

  final Future<void> Function(ErnaehrungDaten d) _speichern;
  ErnaehrungDaten _d = const ErnaehrungDaten();
  ErnaehrungDaten get d => _d;

  void laden(ErnaehrungDaten d) {
    _d = d;
    notifyListeners();
  }

  Future<void> setze(ErnaehrungDaten d) async {
    _d = d;
    notifyListeners();
    await _speichern(d);
  }
}

/// What every Ernährung sub page needs.
class EssenUmfeld {
  const EssenUmfeld({
    required this.stand,
    required this.profile,
    required this.coach,
    required this.jetzt,
    required this.mahlzeiten,
    required this.tagText,
    required this.musterText,
    this.training,
  });

  final ErnaehrungStand stand;
  final UserProfile profile;
  final ErnaehrungCoach coach;
  final DateTime Function() jetzt;

  /// Today's meals as planned right now.
  final List<MahlzeitSlot> Function() mahlzeiten;

  /// Today in a few lines for the coach (training, meals, plate so far).
  final String Function() tagText;

  /// The user's food patterns for the coach (cravings, check-ins, sleep).
  final String Function() musterText;

  /// Today's training time in minutes, if any.
  final int? training;

  ErnaehrungDaten get d => stand.d;
  String get heute => dayKey(jetzt());
}

/// A sub page of Ernährung that rebuilds with every change.
class EssenSeite extends StatelessWidget {
  const EssenSeite({
    super.key,
    required this.umfeld,
    required this.label,
    required this.titel,
    required this.bau,
    this.unterTitel,
  });

  final EssenUmfeld umfeld;
  final String label, titel;
  final String? unterTitel;
  final List<Widget> Function(BuildContext context) bau;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CoachStyle.night,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: CoachStyle.goldLight,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: CoachStyle.nightGradient),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListenableBuilder(
              listenable: umfeld.stand,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  TLabel(label),
                  const SizedBox(height: 4),
                  GoldText(titel, style: tTitel.copyWith(fontSize: 22)),
                  if (unterTitel != null) ...[
                    const SizedBox(height: 2),
                    Text(unterTitel!, style: tSoft),
                  ],
                  const SizedBox(height: 14),
                  ...bau(context),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<T?> zeigeSeite<T>(BuildContext context, Widget seite) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => seite));

/// "Hinweise vom Coach" level bar: three strokes, 0 to 3 filled.
class StufenBalken extends StatelessWidget {
  const StufenBalken(this.stufe, {super.key});
  final int stufe;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var k = 0; k < 3; k++) ...[
        if (k > 0) const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: k < stufe ? CoachStyle.goldLight : const Color(0xFF2A2118),
            ),
          ),
        ),
      ],
    ],
  );
}

/// The dish's first letter in a warm tile.
class GerichtBild extends StatelessWidget {
  const GerichtBild({super.key, required this.name, this.zu = false});
  final String name;
  final bool zu;

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const RadialGradient(
        center: Alignment(-0.2, -0.2),
        colors: [Color(0xFF8A6A3A), Color(0xFF3A2A16)],
      ),
    ),
    child: zu
        ? const Icon(Icons.lock_outline, size: 18, color: CoachStyle.goldLight)
        : Text(
            name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
            style: tTitel.copyWith(
              fontSize: 18,
              color: const Color(0xFFF5DFAE),
            ),
          ),
  );
}

/// A small tag like "für späte Trainingstage".
class EssenTag extends StatelessWidget {
  const EssenTag(this.text, {super.key, this.gold = true});
  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: gold ? CoachStyle.goldGradient : null,
      color: gold ? null : const Color(0xFF2A1F13),
      border: gold ? null : Border.all(color: const Color(0xFF6B5535)),
    ),
    child: Text(
      text,
      style: tSoft.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: gold ? CoachStyle.goldInk : CoachStyle.beigeLabel,
      ),
    ),
  );
}
