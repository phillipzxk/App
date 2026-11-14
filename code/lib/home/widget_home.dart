part of 'home_page.dart';

/// The widgets on the phone (vault Umsetzung/Widgets.md): they get fresh
/// data a moment after anything changes, a tap on one opens the right
/// place, and "Heute geschafft" tapped in the widget is taken over.
extension _StartWidgets on _HomePageState {
  void _widgetsAn() {
    final d = widget.widgets;
    if (d == null) return;
    d.getippt.addListener(_widgetGetippt);
    _widgetLeben;
    WidgetsBinding.instance.addPostFrameCallback((_) => _widgetGetippt());
  }

  void _widgetsAus() {
    _widgetTimer?.cancel();
    widget.widgets?.getippt.removeListener(_widgetGetippt);
  }

  void _widgetSpaeter() {
    if (widget.widgets == null || !_loaded) return;
    _widgetTimer?.cancel();
    _widgetTimer = Timer(const Duration(seconds: 2), _widgetSenden);
  }

  Future<void> _widgetSenden() async {
    final d = widget.widgets;
    if (d == null || !mounted || !_loaded) return;
    if (await _widgetGeschafft()) return;
    if (!mounted) return;
    final jetzt = widget.clock();
    final wurzeln = _wurzeln(jetzt);
    await d.senden(
      widgetDaten(
        jetzt: jetzt,
        name: widget.profile.name.trim(),
        punkte: _tagesPunkte().punkte,
        checkinHeute: _heute != null,
        fokus: _fokus,
        coachAntwort: _heute?.kiAntwort ?? '',
        schnitt: fundamentSchnitt(wurzeln),
        trend: fundamentTrend(wurzeln),
        serie: checkInStreak(_checkIns, jetzt),
      ),
    );
  }

  /// Takes over "Heute geschafft" from the widget. True when something
  /// changed (the reload sends the widgets their data again).
  Future<bool> _widgetGeschafft() async {
    final d = widget.widgets;
    final f = _fokus;
    if (d == null) return false;
    final offen = await d.geschafftOffen();
    if (offen.isEmpty) return false;
    await d.geschafftErledigt();
    if (f == null || !mounted) return false;
    final heute = dayKey(widget.clock());
    final tage = {for (var i = 1; i <= Wochenfokus.tage; i++) f.tagKey(i)};
    // Earlier days are simply ticked; today gets the cheer like in the app.
    final frueher = {
      for (final k in offen)
        if (k != heute && tage.contains(k) && !f.geschafft.contains(k)) k,
    };
    var neu = f;
    if (frueher.isNotEmpty) {
      neu = Wochenfokus(
        start: f.start,
        text: f.text,
        geschafft: {...f.geschafft, ...frueher},
      );
      await widget.feed.saveFokus(neu);
    }
    if (offen.contains(heute) &&
        tage.contains(heute) &&
        !neu.heuteGeschafft(widget.clock())) {
      await _umschalten(neu);
      return true;
    }
    if (frueher.isNotEmpty) {
      await _reload();
      return true;
    }
    return false;
  }

  Future<void> _widgetGetippt() async {
    final d = widget.widgets;
    final ziel = d?.getippt.value;
    if (d == null || ziel == null || !_loaded || !mounted) return;
    d.erledigt();
    final mitte = MediaQuery.sizeOf(context).center(Offset.zero);
    switch (ziel) {
      case 'training':
        await _oeffneSeite(Bereich.training);
      case 'ernaehrung':
        await _oeffneSeite(Bereich.ernaehrung);
      case 'schlaf':
        await _oeffneSeite(Bereich.schlaf);
      case 'tag':
        await _oeffneTag();
      case 'fokus':
        _oeffneFokus(mitte);
      default:
        break;
    }
  }
}
