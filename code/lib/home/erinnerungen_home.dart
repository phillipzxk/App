part of 'home_page.dart';

/// Reminders from Heute (vault Umsetzung/Erinnerungen.md): planned anew a
/// moment after anything changes, and a tap on one opens the right place.
extension _Erinnerungen on _HomePageState {
  void _erinnerungenAn() {
    final d = widget.erinnerungen;
    if (d == null) return;
    d.getippt.addListener(_getippt);
    widget.erinnerungenNeu?.addListener(_erinnerungenSpaeter);
    unawaited(d.erlaubnisFragen());
    // A tap that opened the app waits until Heute is loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) => _getippt());
  }

  void _erinnerungenAus() {
    _planTimer?.cancel();
    widget.erinnerungen?.getippt.removeListener(_getippt);
    widget.erinnerungenNeu?.removeListener(_erinnerungenSpaeter);
  }

  /// Plans after a short pause, so many changes in a row plan only once.
  void _erinnerungenSpaeter() {
    if (widget.erinnerungen == null || !_loaded) return;
    _planTimer?.cancel();
    _planTimer = Timer(const Duration(seconds: 2), _erinnerungenPlanen);
  }

  Future<void> _erinnerungenPlanen() async {
    final d = widget.erinnerungen;
    if (d == null || !mounted) return;
    unawaited(_getippt());
    final e = await d.ladeEinstellungen();
    if (!mounted) return;
    final jetzt = widget.clock();
    await d.planen(
      planeErinnerungen(
        ErinnerungsLage(
          jetzt: jetzt,
          name: widget.profile.name.trim(),
          einstellungen: e,
          schlafzeiten: _schlafzeiten,
          termine: _termine,
          plan: _plan,
          training: _training,
          supplements: _supplements,
          genommenHeute: _genommen,
          checkinHeute: _checkIns.any((c) => dayKey(c.datum) == dayKey(jetzt)),
          fokus: _fokus,
          fotoEinstellungen: _fotoEinstellungen,
          wochenFotos: _wochenFotos,
          routine: _routine,
          ruheBis: _schlaf.d.ruheBis,
        ),
      ),
    );
  }

  Future<void> _getippt() async {
    final d = widget.erinnerungen;
    final a = d?.getippt.value;
    if (d == null || a == null || !_loaded || !mounted) return;
    d.erledigt();
    final mitte = MediaQuery.sizeOf(context).center(Offset.zero);
    switch (a.ziel) {
      case Ziel.supplements:
        if (a.knopf == Knopf.abhaken) {
          for (final id in a.daten.split(';')) {
            if (id.isNotEmpty) {
              await widget.feed.setGenommen(widget.clock(), id, true);
            }
          }
          await _reload();
        } else {
          await _oeffneSeite(Bereich.ernaehrung);
        }
      case Ziel.fokus:
        final f = _fokus;
        if (a.knopf == Knopf.geschafft) {
          if (f != null && !f.heuteGeschafft(widget.clock())) {
            await _umschalten(f);
          }
        } else if (a.knopf == null) {
          _oeffneFokus(mitte);
        }
      case Ziel.reality:
        _oeffneFokus(mitte);
      case Ziel.training:
        await _oeffneSeite(Bereich.training);
      case Ziel.schlaf:
        await _oeffneSeite(Bereich.schlaf);
      case Ziel.tag:
        await _oeffneTag();
      case Ziel.foto:
        await _oeffneZukunft();
      default:
        // Check-in: already done when Heute is open.
        break;
    }
  }
}
