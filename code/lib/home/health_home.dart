part of 'home_page.dart';

/// Apple Health on Heute (vault Umsetzung/Apple Health.md): read a moment
/// after loading and when the app comes back, the weight from the scale
/// goes into the weight tracker, a watch workout can be taken over.
extension _Health on _HomePageState {
  Future<void> _healthHolen({bool sofort = false}) async {
    final dienst = widget.health;
    if (dienst == null || !dienst.moeglich || !_loaded) return;
    final jetzt = widget.clock();
    final zuletzt = _healthZuletzt;
    if (!sofort &&
        zuletzt != null &&
        jetzt.difference(zuletzt) < const Duration(minutes: 5)) {
      return;
    }
    _healthZuletzt = jetzt;
    final neu = await healthHolen(dienst, _schlaf.d, jetzt);
    if (neu == null || !mounted) return;
    var d = neu;
    final h = d.healthAm(dayKey(jetzt));
    final kg = h?.gewicht;
    final zeit = h?.gewichtZeit;
    if (kg != null &&
        zeit != null &&
        d.gewichtUebernommen != zeit.toIso8601String()) {
      // What the user entered for that day counts first.
      final schonDa = _weights.any((w) => dayKey(w.datum) == dayKey(zeit));
      if (!schonDa) await widget.store.addWeight(WeightEntry(zeit, kg));
      d = d.copyWith(gewichtUebernommen: zeit.toIso8601String());
      final weights = await widget.store.loadWeights();
      if (!mounted) return;
      setState(() => _weights = weights);
    }
    await _schlaf.setze(d);
  }

  /// "Übernehmen" on a watch workout: logged as done that day, so the
  /// week counts it and the check-in pre-selects "Gut trainiert".
  Future<void> _healthKnopf(HealthFeld f) async {
    if (!f.id.startsWith('training:')) return;
    final id = f.id.substring('training:'.length);
    final h = _schlaf.d.healthAm(dayKey(widget.clock()));
    final t = h?.trainings.where((x) => x.id == id).firstOrNull;
    if (t == null) return;
    if (_training.einheitAm(t.start) == null) {
      final neu = _training.copyWith(
        einheiten: [
          ..._training.einheiten,
          TrainingEinheit(
            datum: DateTime(t.start.year, t.start.month, t.start.day),
            name: t.text,
            status: EinheitStatus.fertig,
          ),
        ],
      );
      await widget.feed.saveTraining(neu);
      setState(() => _training = neu);
    }
    await _schlaf.setze(
      _schlaf.d.copyWith(uebernommen: [..._schlaf.d.uebernommen, id]),
    );
  }

  /// The seeds fall only once a day.
  List<String> get _samenHeute {
    final heute = dayKey(widget.clock());
    if (_schlaf.d.samenTag == heute) return const [];
    return healthSamen(_schlaf.d.healthAm(heute));
  }

  void _samenFertig() => unawaited(
    _schlaf.setze(_schlaf.d.copyWith(samenTag: dayKey(widget.clock()))),
  );
}
