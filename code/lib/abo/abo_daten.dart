import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The two plans (vault Umsetzung/Abo.md): 9,99 € a month or 59,99 € a year.
enum AboPlan {
  monat('Monat', '9,99 €', 'pro Monat'),
  jahr('Jahr', '59,99 €', 'nur 5 € im Monat');

  const AboPlan(this.label, this.preis, this.unter);
  final String label;
  final String preis;
  final String unter;

  /// "59,99 € im Jahr", "9,99 € im Monat".
  String get kurz => this == jahr ? '59,99 € im Jahr' : '9,99 € im Monat';
}

/// Where the user stands: free week, with Abo or without.
class AboStand {
  const AboStand({
    this.gratisSeit,
    this.plan,
    this.aboSeit,
    this.ohneAbo = false,
  });

  /// First day of the free week (only the date counts).
  final DateTime? gratisSeit;

  /// The bought plan, null without Abo.
  final AboPlan? plan;
  final DateTime? aboSeit;

  /// Chose "Ohne Abo weiter eintragen".
  final bool ohneAbo;

  bool get mitAbo => plan != null;

  /// Day of the free week, 1 on the first day; null before it started.
  int? gratisTag(DateTime jetzt) {
    final s = gratisSeit;
    if (s == null) return null;
    final a = DateTime(s.year, s.month, s.day);
    final b = DateTime(jetzt.year, jetzt.month, jetzt.day);
    return b.difference(a).inHours ~/ 24 + 1;
  }

  /// The small counter on Heute: only in the free week.
  int? zaehlerTag(DateTime jetzt) {
    if (mitAbo || ohneAbo) return null;
    final t = gratisTag(jetzt);
    return t == null || t > 7 ? null : t;
  }

  /// The Abo screen comes from day 7 on (after the check-in) until the
  /// user decided.
  bool zeigeAbo(DateTime jetzt) =>
      !mitAbo && !ohneAbo && (gratisTag(jetzt) ?? 0) >= 7;

  /// The coach answers: with Abo and in the free week.
  bool coachAn(DateTime jetzt) {
    if (mitAbo) return true;
    final t = gratisTag(jetzt);
    return t == null || (t <= 7 && !ohneAbo);
  }

  /// Without Abo the coach speaks on Sundays: the "Wochen-Satz".
  bool wochenSatzTag(DateTime jetzt) =>
      !coachAn(jetzt) && jetzt.weekday == DateTime.sunday;

  /// Next payment day for "Abo aktiv".
  DateTime? naechsteZahlung(DateTime jetzt) {
    final s = aboSeit;
    final p = plan;
    if (s == null || p == null) return null;
    var d = s;
    while (!d.isAfter(jetzt)) {
      d = p == AboPlan.jahr
          ? DateTime(d.year + 1, d.month, d.day)
          : DateTime(d.year, d.month + 1, d.day);
    }
    return d;
  }

  AboStand mitPlan(AboPlan p, DateTime jetzt) =>
      AboStand(gratisSeit: gratisSeit, plan: p, aboSeit: jetzt);

  AboStand ohne() => AboStand(gratisSeit: gratisSeit, ohneAbo: true);

  AboStand gestartet(DateTime jetzt) => AboStand(
    gratisSeit: DateTime(jetzt.year, jetzt.month, jetzt.day),
    plan: plan,
    aboSeit: aboSeit,
    ohneAbo: ohneAbo,
  );

  Map<String, Object?> toJson() => {
    'gratisSeit': gratisSeit?.toIso8601String(),
    'plan': plan?.name,
    'aboSeit': aboSeit?.toIso8601String(),
    'ohneAbo': ohneAbo,
  };

  factory AboStand.fromJson(Map<String, Object?> j) => AboStand(
    gratisSeit: DateTime.tryParse(j['gratisSeit'] as String? ?? ''),
    plan: AboPlan.values.asNameMap()[j['plan']],
    aboSeit: DateTime.tryParse(j['aboSeit'] as String? ?? ''),
    ohneAbo: j['ohneAbo'] == true,
  );
}

abstract class AboStore {
  Future<AboStand> load();
  Future<void> save(AboStand stand);
}

class LocalAboStore implements AboStore {
  @override
  Future<AboStand> load() async {
    final s = (await SharedPreferences.getInstance()).getString('abo');
    if (s == null || s.isEmpty) return const AboStand();
    return AboStand.fromJson(jsonDecode(s) as Map<String, Object?>);
  }

  @override
  Future<void> save(AboStand stand) async =>
      (await SharedPreferences.getInstance()).setString(
        'abo',
        jsonEncode(stand.toJson()),
      );
}

class MemoryAboStore implements AboStore {
  MemoryAboStore([this.stand = const AboStand()]);
  AboStand stand;

  @override
  Future<AboStand> load() async => stand;

  @override
  Future<void> save(AboStand s) async => stand = s;
}

/// Buying a plan. The real one goes through Apple (StoreKit) once Phillip
/// has the developer account; until then the preview only pretends.
abstract class AboKauf {
  Future<bool> kaufen(AboPlan plan);
}

class VorschauKauf implements AboKauf {
  const VorschauKauf();

  @override
  Future<bool> kaufen(AboPlan plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return true;
  }
}
