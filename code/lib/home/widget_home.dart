part of 'home_page.dart';

/// The widgets on the phone (vault Umsetzung/Widgets.md): they get fresh
/// data a moment after anything changes, and a tap on one opens the right
/// place.
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
    final jetzt = widget.clock();
    final f = _fokus;
    final trainiert =
        _training.einheitAm(jetzt)?.status == EinheitStatus.fertig;
    // A finished training ticks its point of the day.
    final punkte = [
      for (final p in _tagesPunkte().punkte)
        p.id == 'training' && trainiert && !p.erledigt
            ? BogenPunkt(
                id: p.id,
                minute: p.minute,
                art: p.art,
                titel: p.titel,
                text: p.text,
                erledigt: true,
              )
            : p,
    ];
    // What is done right now. Something new in it is praised for an hour.
    final fertig = <String, String>{
      for (final p in punkte)
        if (p.erledigt) p.id: p.titel,
      if (trainiert) 'training': 'Dein Training',
      if (f != null && f.heuteGeschafft(jetzt)) 'fokus': 'Dein Fokus',
      if (_heute != null) 'checkin': 'Dein Check-in',
    };
    final vorher = _widgetFertig;
    if (vorher != null && vorher.$1 == dayKey(jetzt)) {
      for (final e in fertig.entries) {
        if (!vorher.$2.contains(e.key)) {
          _widgetLob = (
            titel: e.value,
            bis: jetzt.add(const Duration(hours: 1)),
          );
        }
      }
    }
    _widgetFertig = (dayKey(jetzt), fertig.keys.toSet());
    await d.senden(
      widgetDaten(
        jetzt: jetzt,
        name: widget.profile.name.trim(),
        punkte: punkte,
        checkIns: _checkIns,
        fokus: f,
        ziel: widget.profile.zielSatz,
        grund: widget.profile.warum,
        lob: _widgetLob,
      ),
    );
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
      case 'mindset':
        await _oeffneSeite(Bereich.mindset);
      default:
        break;
    }
  }
}
