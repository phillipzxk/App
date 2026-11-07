part of 'home_page.dart';

/// The work goals inside Fokus & Arbeit. Business & Beruf is no longer an
/// own area (Phillip 2026-11-04); its Hebel, milestones and skill ladder
/// live on as the page "Ziele" of Fokus & Arbeit, for any job, studies or
/// own company.
extension _Arbeit on _HomePageState {
  BusinessCoach get _businessCoach => widget.coach is BusinessCoach
      ? widget.coach as BusinessCoach
      : const NoBusinessCoach();

  /// Work done (Produktivität value) on training days, other days and after
  /// short nights, over the last 30 days. Each needs 3 days.
  ArbeitKoerper _arbeitKoerper() {
    final jetzt = widget.clock();
    final mit = <int>[], ohne = <int>[], kurz = <int>[];
    final schlaf = {for (final m in _schlaf.d.morgen) m.tag: m.stunden};
    final checks = {for (final c in _checkIns) dayKey(c.datum): c};
    for (var i = 0; i < 30; i++) {
      final k = dayKey(jetzt.subtract(Duration(days: i)));
      final w = produktivWert(_produktiv.d, k);
      if (w == null) continue;
      final c = checks[k];
      if (c != null) {
        (c.training == 'Gut trainiert' || c.training == 'Lief zäh' ? mit : ohne)
            .add(w);
      }
      if ((schlaf[k] ?? 99) < 7) kurz.add(w);
    }
    double? schnitt(List<int> l) =>
        l.length < 3 ? null : l.reduce((a, b) => a + b) / l.length;
    return (
      mit: schnitt(mit),
      ohne: schnitt(ohne),
      kurz: schnitt(kurz),
      tage: mit.length + ohne.length,
    );
  }

  BusinessUmfeld get _businessUmfeld => BusinessUmfeld(
    stand: _business,
    profile: widget.profile,
    coach: _businessCoach,
    jetzt: widget.clock,
    koerper: _arbeitKoerper(),
  );

  Feld _bFeld(
    String titel,
    IconData icon,
    String coach,
    Widget Function(BusinessUmfeld u) seite,
  ) => Feld(
    titel: titel,
    icon: icon,
    coach: coach,
    inhalt: (_) => [seite(_businessUmfeld)],
  );
}
