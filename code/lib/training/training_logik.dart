import 'dart:async';

import 'package:flutter/foundation.dart';

import '../checkin/checkin.dart';
import '../feed/feed_data.dart';
import 'training_data.dart';

/// Which plan day applies on [day]: its own, or one moved there after a
/// skip (idea 3). Null on a free day or when today's session was skipped.
int? planTagFuer(TrainingPlan plan, TrainingDaten d, DateTime day) {
  final mo = montagVon(day);
  for (final e in d.einheiten) {
    final ziel = e.verschobenAuf;
    if (e.status == EinheitStatus.uebersprungen &&
        ziel != null &&
        dayKey(ziel) == dayKey(day) &&
        !e.datum.isBefore(mo)) {
      return e.datum.weekday - 1;
    }
  }
  final eigene = d.einheitAm(day);
  if (eigene?.status == EinheitStatus.uebersprungen) return null;
  final i = day.weekday - 1;
  return istTrainingstag(plan.tage[i]) ? i : null;
}

/// This week's plan as it really is: skipped days are free, moved
/// sessions sit on their new day. Other weeks show the plan as it is.
TrainingPlan wochenPlan(TrainingPlan plan, TrainingDaten d, DateTime heute) {
  final mo = montagVon(heute);
  final tage = [...plan.tage];
  final uebungen = [for (var i = 0; i < 7; i++) plan.uebungenAm(i)];
  var geaendert = false;
  for (final e in d.einheiten) {
    if (e.status != EinheitStatus.uebersprungen || e.datum.isBefore(mo)) {
      continue;
    }
    final von = e.datum.weekday - 1;
    final ziel = e.verschobenAuf;
    if (ziel != null && montagVon(ziel) == mo) {
      tage[ziel.weekday - 1] = plan.tage[von];
      uebungen[ziel.weekday - 1] = plan.uebungenAm(von);
    }
    tage[von] = '';
    uebungen[von] = const [];
    geaendert = true;
  }
  return geaendert ? TrainingPlan(tage, uebungen: uebungen) : plan;
}

/// A fresh log for today from the plan: every set prefilled with today's
/// target (idea 1), warm-up sets open.
List<UebungLog> neueLogs(
  List<PlanUebung> uebungen,
  TrainingDaten d,
  DateTime heute,
  Anpassung? anpassung,
) => [
  for (final u in uebungen)
    () {
      final z = zielFuer(u, d, heute, anpassung: anpassung);
      return UebungLog(
        name: u.name,
        art: u.art,
        saetze: [
          for (final s in z.saetze) SatzLog(wert: s.wert, menge: s.menge),
        ],
        aufwaermen: List.filled(aufwaermSaetze(u, z).length, false),
      );
    }(),
];

/// Today's session while training: shared by the training page and the
/// Trainings-Modus, saved after every change. Also runs the rest timer.
class HeuteSession extends ChangeNotifier {
  HeuteSession({
    required this.datum,
    required this.name,
    required this.plan,
    required List<UebungLog> logs,
    required this.onSpeichern,
    this.gestartet = false,
  }) : _logs = List.of(logs);

  final DateTime datum;
  final String name;

  /// The plan's exercises, in the same order as the logs.
  final List<PlanUebung> plan;
  final Future<void> Function(TrainingEinheit e) onSpeichern;

  /// True once something was entered; only then is the session saved.
  bool gestartet;
  List<UebungLog> _logs;
  List<UebungLog> get logs => _logs;

  int? pauseFuer;
  int pauseRest = 0;
  Timer? _timer;

  TrainingEinheit get einheit =>
      TrainingEinheit(datum: datum, name: name, uebungen: _logs);

  void _aendern(int i, UebungLog neu) {
    _logs = [for (var k = 0; k < _logs.length; k++) k == i ? neu : _logs[k]];
    gestartet = true;
    notifyListeners();
    onSpeichern(einheit);
  }

  /// Changing a value also changes the later sets that still had the old
  /// one and are not ticked yet.
  void setWert(int i, int k, double? v, {bool menge = false}) {
    final l = _logs[i];
    final alt = menge ? l.saetze[k].menge : l.saetze[k].wert;
    final saetze = [
      for (var j = 0; j < l.saetze.length; j++)
        if (j == k ||
            (j > k &&
                !l.saetze[j].fertig &&
                (menge ? l.saetze[j].menge : l.saetze[j].wert) == alt))
          SatzLog(
            wert: menge ? l.saetze[j].wert : v,
            menge: menge ? v : l.saetze[j].menge,
            fertig: l.saetze[j].fertig,
          )
        else
          l.saetze[j],
    ];
    _aendern(i, l.copyWith(saetze: saetze));
  }

  /// Ticks a set; ticking on starts the rest.
  void abhaken(int i, int k) {
    final l = _logs[i];
    final an = !l.saetze[k].fertig;
    _aendern(
      i,
      l.copyWith(
        saetze: [
          for (var j = 0; j < l.saetze.length; j++)
            j == k ? l.saetze[j].copyWith(fertig: an) : l.saetze[j],
        ],
      ),
    );
    if (an) {
      _pauseNachSatz(i, k);
    } else if (pauseFuer == i) {
      pauseStopp();
    }
  }

  void _pauseNachSatz(int i, int k) {
    final p = plan[i].pause;
    final letzter = i == _logs.length - 1 && k == _logs[i].saetze.length - 1;
    if (p > 0 && !letzter) startePause(i, p);
  }

  void aufwaermen(int i, int k) {
    final l = _logs[i];
    _aendern(
      i,
      l.copyWith(
        aufwaermen: [
          for (var j = 0; j < l.aufwaermen.length; j++)
            j == k ? !l.aufwaermen[j] : l.aufwaermen[j],
        ],
      ),
    );
  }

  void satzDazu(int i) {
    final l = _logs[i];
    final letzter = l.saetze.isEmpty ? const SatzLog() : l.saetze.last;
    _aendern(
      i,
      l.copyWith(
        saetze: [
          ...l.saetze,
          SatzLog(wert: letzter.wert, menge: letzter.menge),
        ],
      ),
    );
  }

  void satzWeg(int i) {
    final l = _logs[i];
    if (l.saetze.length <= 1) return;
    _aendern(i, l.copyWith(saetze: l.saetze.sublist(0, l.saetze.length - 1)));
  }

  void gefuehl(int i, String g) {
    final l = _logs[i];
    _aendern(
      i,
      l.gefuehl == g ? l.copyWith(gefuehlLeeren: true) : l.copyWith(gefuehl: g),
    );
  }

  /// Replaces the sets of an exercise that has nothing ticked yet, e.g.
  /// after "Rückgängig" on the coach's change.
  void neuAufsetzen(int i, UebungLog neu) {
    if (_logs[i].fertige.isNotEmpty) return;
    _logs = [for (var k = 0; k < _logs.length; k++) k == i ? neu : _logs[k]];
    notifyListeners();
    if (gestartet) onSpeichern(einheit);
  }

  void startePause(int i, int sekunden) {
    _timer?.cancel();
    pauseFuer = i;
    pauseRest = sekunden;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      pauseRest--;
      if (pauseRest <= 0) {
        pauseStopp();
      } else {
        notifyListeners();
      }
    });
  }

  void pauseStopp() {
    _timer?.cancel();
    _timer = null;
    pauseFuer = null;
    pauseRest = 0;
    notifyListeners();
  }

  /// "Training fertig": exercises with nothing ticked count as done the
  /// way they are filled in (you only change what was different).
  TrainingEinheit abschliessen() {
    pauseStopp();
    _logs = [
      for (final l in _logs)
        l.fertige.isNotEmpty
            ? l
            : l.copyWith(
                saetze: [for (final s in l.saetze) s.copyWith(fertig: true)],
              ),
    ];
    return einheit.copyWith(status: EinheitStatus.fertig);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// What the check-in pre-selects for training after a logged session:
/// "Gut trainiert", or "Lief zäh" when most exercises felt heavy.
String? checkInVormerkung(TrainingDaten d, DateTime heute) {
  final gestern = DateTime(heute.year, heute.month, heute.day - 1);
  final e = d.einheitAm(heute) ?? d.einheitAm(gestern);
  if (e == null || e.status != EinheitStatus.fertig) return null;
  final g = [for (final u in e.uebungen) ?u.gefuehl];
  final schwer = g.where((x) => x == 'schwer').length;
  return g.isNotEmpty && schwer * 2 > g.length ? 'Lief zäh' : 'Gut trainiert';
}

/// The plan of one exercise by name, from any day.
PlanUebung? planUebung(TrainingPlan plan, String name) {
  for (var i = 0; i < 7; i++) {
    for (final u in plan.uebungenAm(i)) {
      if (u.name.trim().toLowerCase() == name.trim().toLowerCase()) return u;
    }
  }
  return null;
}

/// The exercise done right before [name] on its day, for the
/// Stagnations-Check answer "Immer nach …".
String? uebungDavor(TrainingPlan plan, String name) {
  for (var i = 0; i < 7; i++) {
    final u = plan.uebungenAm(i);
    final k = u.indexWhere(
      (x) => x.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    if (k > 0) return u[k - 1].name;
  }
  return null;
}

/// All exercise names in the plan, Monday first, no doubles.
List<String> planUebungen(TrainingPlan plan) {
  final seen = <String>{};
  return [
    for (var i = 0; i < 7; i++)
      for (final u in plan.uebungenAm(i))
        if (u.name.trim().isNotEmpty && seen.add(u.name.toLowerCase())) u.name,
  ];
}

/// History as short text for the coach, e.g. "2026-10-05: 80 kg × 8".
String verlaufText(TrainingDaten d, String uebung) => [
  for (final (tag, l) in d.verlauf(uebung).reversed.take(8).toList().reversed)
    '${dayKey(tag)}: ${l.fertige.map((s) => satzText(l.art, s.werte)).join(', ')}'
        '${l.gefuehl == null ? '' : ' (${l.gefuehl})'}',
].join('\n');

@visibleForTesting
String debugEinheit(TrainingEinheit e) => [
  e.name,
  for (final u in e.uebungen)
    '${u.name}: ${u.saetze.map((s) => '${s.fertig ? '✓' : '·'}${satzText(u.art, s.werte)}').join(' ')}',
].join('\n');
