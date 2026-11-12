part of 'home_page.dart';

/// Kalender verbinden (vault Umsetzung/Kalender verbinden.md): once
/// connected, the appointments come only from the phone's calendar and new
/// ones go there; the app's own list is gone.
extension _Kalender on _HomePageState {
  bool get _kalenderVerbunden =>
      widget.kalender?.moeglich == true && _kalenderEinst.verbunden;

  /// Today and the coming week, from the calendar or the app's own list.
  Future<List<Termin>> _termineLaden(KalenderEinstellung e) async {
    final dienst = widget.kalender;
    if (dienst == null || !dienst.moeglich || !e.verbunden) {
      return widget.feed.loadTermine();
    }
    final heute = widget.clock();
    return dienst.termine(heute, heute.add(const Duration(days: 8)), e.aus);
  }

  /// A new appointment: into the calendar when connected, else the list.
  Future<void> _terminAnlegen(Termin t) async {
    if (_kalenderVerbunden &&
        await widget.kalender!.anlegen(t, _kalenderEinst.ziel)) {
      return;
    }
    await widget.feed.addTermin(t);
  }

  Future<void> _kalenderVerbinden(Offset von) async {
    final dienst = widget.kalender;
    if (dienst == null) return;
    final ok = await kalenderVerbinden(dienst, widget.feed, widget.clock());
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ohne Erlaubnis geht es nicht. Du kannst es in den '
            'iPhone-Einstellungen unter Groundset erlauben.',
          ),
        ),
      );
      return;
    }
    await _reload();
    if (!mounted) return;
    final n = termineAm(_termine, widget.clock()).length;
    lichtpunkteFliegen(context, von, n == 0 ? 3 : n);
  }
}
