import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../ui/coach_style.dart';
import 'konto_daten.dart';
import 'konto_dienst.dart';
import 'konto_ui.dart';
import 'konto_web.dart';
import 'sicherung.dart';

/// "Konto und Sicherung" (Entwurf 2, Bildschirm 4): state of the backup,
/// account, the two switches, own data, sign out and delete. Everything
/// the stores and the DSGVO ask for is here.
class KontoEinstellungen extends StatefulWidget {
  const KontoEinstellungen({
    super.key,
    required this.dienst,
    required this.store,
    required this.sicherung,
    required this.name,
    required this.onAbgemeldet,
    required this.onGeloescht,
    this.clock = DateTime.now,
  });

  final KontoDienst dienst;
  final KontoStore store;
  final Sicherung sicherung;
  final String name;
  final VoidCallback onAbgemeldet;
  final VoidCallback onGeloescht;
  final DateTime Function() clock;

  @override
  State<KontoEinstellungen> createState() => _KontoEinstellungenState();
}

class _KontoEinstellungenState extends State<KontoEinstellungen>
    with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  late final AnimationController _balken = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    value: 1,
  );
  Konto? _konto;
  SicherungsStand _stand = const SicherungsStand();
  SicherungsInhalt _inhalt = const SicherungsInhalt();
  bool _sichert = false;
  String? _meldung;

  @override
  void initState() {
    super.initState();
    _laden();
  }

  @override
  void dispose() {
    _a.dispose();
    _balken.dispose();
    super.dispose();
  }

  Future<void> _laden() async {
    final k = await widget.store.loadKonto();
    final s = await widget.store.loadStand();
    final i = await widget.sicherung.inhalt();
    if (mounted) {
      setState(() {
        _konto = k;
        _stand = s;
        _inhalt = i;
      });
    }
  }

  Future<void> _jetzt() async {
    setState(() {
      _sichert = true;
      _meldung = null;
    });
    _balken.forward(from: 0);
    try {
      final s = await widget.sicherung.sichern();
      await _balken.forward();
      if (mounted) setState(() => _stand = s);
    } on KontoFehler catch (e) {
      if (mounted) setState(() => _meldung = e.text);
    } catch (_) {
      if (mounted) {
        setState(() => _meldung = 'Keine Verbindung. Ich versuche es später.');
      }
    }
    if (mounted) setState(() => _sichert = false);
  }

  Future<void> _schalter(SicherungsStand neu) async {
    setState(() => _stand = neu);
    await widget.store.saveStand(neu);
  }

  Future<void> _export() async {
    final text = await widget.sicherung.export();
    final d = widget.clock();
    final ok = dateiSpeichern(
      'groundset-daten-${d.year}-${d.month}-${d.day}.json',
      text,
    );
    if (mounted) {
      setState(
        () => _meldung = ok
            ? 'Deine Daten sind heruntergeladen.'
            : 'Herunterladen geht in der Handy-Version über Teilen.',
      );
    }
  }

  Future<bool> _fragen(String titel, String text, String ja) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF1B1611),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Glas.edge),
          ),
          title: Text(titel, style: Glas.tText.copyWith(fontSize: 17)),
          content: Text(text, style: Glas.tSoft.copyWith(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Abbrechen', style: Glas.tSoft),
            ),
            TextButton(
              key: const ValueKey('dialog-ja'),
              onPressed: () => Navigator.pop(c, true),
              child: Text(ja, style: Glas.tLabel),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _ueberallAbmelden() async {
    final k = _konto;
    if (k == null) return;
    if (!await _fragen(
      'Überall abmelden?',
      'Alle anderen Handys und Browser werden abgemeldet. Dieses Handy bleibt '
          'angemeldet.',
      'Abmelden',
    )) {
      return;
    }
    await widget.dienst.abmelden(k, ueberall: true);
    if (mounted) {
      setState(() => _meldung = 'Alle anderen Geräte sind abgemeldet.');
    }
  }

  Future<void> _abmelden() async {
    final k = _konto;
    if (k == null) return;
    if (!await _fragen(
      'Abmelden?',
      'Deine Daten bleiben gesichert. Melde dich wieder an, dann ist alles da.',
      'Abmelden',
    )) {
      return;
    }
    try {
      await widget.sicherung.sichern();
    } catch (_) {}
    await widget.dienst.abmelden(k);
    await widget.store.saveKonto(null);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    widget.onAbgemeldet();
  }

  Future<void> _loeschen() async {
    final k = _konto;
    if (k == null) return;
    if (!await _fragen(
      'Konto und alle Daten löschen?',
      'Dein Konto, deine Sicherung, alle Einträge, Fotos und Videos werden '
          'für immer gelöscht, auf dem Server und auf diesem Handy. Das lässt '
          'sich nicht rückgängig machen.',
      'Endgültig löschen',
    )) {
      return;
    }
    try {
      await widget.dienst.loeschen(k);
    } on KontoFehler catch (e) {
      if (mounted) setState(() => _meldung = e.text);
      return;
    }
    await widget.sicherung.alleDatenLoeschen();
    await widget.store.saveKonto(null);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    widget.onGeloescht();
  }

  void _textSeite(String titel, String text) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => KontoHintergrund(
        lichtY: 0,
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chevron_left, color: Glas.label),
                label: Text('Zurück', style: Glas.tLabel),
              ),
            ),
            GoldSchrift(titel, style: _titelStil),
            const SizedBox(height: 16),
            GlasBox(
              child: Text(text, style: Glas.tSoft.copyWith(fontSize: 14)),
            ),
          ],
        ),
      ),
    ),
  );

  static const _titelStil = TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w700,
    fontSize: 25,
  );

  @override
  Widget build(BuildContext context) {
    final k = _konto;
    final jetzt = widget.clock();
    final name = widget.name.trim();
    Widget gruppe(double start, String? titel, List<Widget> zeilen) => Auftritt(
      anim: _a,
      start: start,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 7),
              child: Text(
                titel.toUpperCase(),
                style: Glas.tLabel.copyWith(fontSize: 11, letterSpacing: 2),
              ),
            )
          else
            const SizedBox(height: 14),
          GlasBox(
            padding: EdgeInsets.zero,
            radius: 20,
            child: Column(
              children: [
                for (var i = 0; i < zeilen.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Glas.edge),
                  zeilen[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return KontoHintergrund(
      lichtY: 0,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('einstellungen-zurueck'),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left, color: Glas.label),
              label: Text('Zurück', style: Glas.tLabel),
            ),
          ),
          Auftritt(
            anim: _a,
            start: 0,
            child: GoldSchrift('Konto und Sicherung', style: _titelStil),
          ),
          const SizedBox(height: 14),
          Auftritt(
            anim: _a,
            start: .1,
            child: GlasBox(
              key: const ValueKey('sicherung-status'),
              art: GlasArt.gold,
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        _stand.zuletzt == null
                            ? Icons.shield_outlined
                            : Icons.verified_user_outlined,
                        size: 32,
                        color: const Color(0xFFF3DCA6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sichert
                                  ? 'Wird gesichert …'
                                  : _stand.zuletzt == null
                                  ? 'Noch nicht gesichert'
                                  : 'Alles gesichert',
                              style: Glas.tText.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _stand.zuletzt == null
                                  ? 'Tipp auf „Jetzt sichern“'
                                  : '${formatZuletzt(_stand.zuletzt, jetzt)} · '
                                        '${formatGroesse(_stand.bytes)}',
                              key: const ValueKey('sicherung-zuletzt'),
                              style: Glas.tSoft.copyWith(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('jetzt-sichern'),
                        onPressed: _sichert || k == null ? null : _jetzt,
                        child: Text(
                          'Jetzt sichern',
                          style: Glas.tLabel.copyWith(
                            color: const Color(0xFFF3DCA6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      height: 6,
                      child: AnimatedBuilder(
                        animation: _balken,
                        builder: (context, _) => Stack(
                          children: [
                            Container(color: const Color(0x14FFECDC)),
                            FractionallySizedBox(
                              widthFactor: _stand.zuletzt == null && !_sichert
                                  ? 0
                                  : _balken.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: CoachStyle.goldGradient,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _stand.fotosSichern
                        ? _inhalt.text
                        : '${_inhalt.text}\nFotos und Videos nur auf diesem Handy.',
                    style: Glas.tSoft.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (_meldung != null) ...[
            const SizedBox(height: 10),
            Text(
              _meldung!,
              key: const ValueKey('konto-meldung'),
              textAlign: TextAlign.center,
              style: Glas.tSoft.copyWith(color: const Color(0xFFF3DCA6)),
            ),
          ],
          if (!widget.dienst.echt) ...[
            const SizedBox(height: 10),
            Text(
              'Vorschau: noch ohne Server, die Sicherung bleibt auf diesem '
              'Gerät.',
              textAlign: TextAlign.center,
              style: Glas.tSoft.copyWith(fontSize: 12),
            ),
          ],
          gruppe(.2, 'Konto', [
            _Zeile(
              vorne: _Initiale(name.isEmpty ? '?' : name[0].toUpperCase()),
              titel: name.isEmpty ? 'Dein Konto' : name,
              unter: k?.email.isNotEmpty == true ? k!.email : null,
              hinten: k?.art.label ?? '',
            ),
            const _Zeile(
              titel: 'Abo',
              unter:
                  'Kündigen und ändern geht über den App Store bzw. Google '
                  'Play.',
              hinten: 'Beta: kostenlos',
            ),
            _Zeile(
              key: const ValueKey('geraete'),
              titel: 'Angemeldete Geräte',
              unter: 'Alle anderen Geräte abmelden',
              hinten: 'Dieses Handy',
              pfeil: true,
              onTap: _ueberallAbmelden,
            ),
          ]),
          gruppe(.3, 'Sicherung', [
            _Zeile(
              titel: 'Fotos und Videos sichern',
              schalter: _GoldSchalter(
                key: const ValueKey('schalter-fotos'),
                an: _stand.fotosSichern,
                onChanged: (v) => _schalter(_stand.copyWith(fotosSichern: v)),
              ),
            ),
            _Zeile(
              titel: 'Nur im WLAN hochladen',
              unter: 'Damit Videos kein mobiles Datenvolumen fressen.',
              schalter: _GoldSchalter(
                key: const ValueKey('schalter-wlan'),
                an: _stand.nurWlan,
                onChanged: (v) => _schalter(_stand.copyWith(nurWlan: v)),
              ),
            ),
          ]),
          gruppe(.4, 'Deine Daten', [
            _Zeile(
              key: const ValueKey('daten-herunterladen'),
              titel: 'Meine Daten herunterladen',
              pfeil: true,
              onTap: _export,
            ),
            _Zeile(
              titel: 'Datenschutz',
              pfeil: true,
              onTap: () => _textSeite(
                'Datenschutz',
                'Die Datenschutzerklärung kommt hier vor dem Start der Beta '
                    'hin.\n\nKurz: Deine Daten liegen auf deinem Handy und '
                    'verschlüsselt auf einem Server in Frankfurt. Sie werden '
                    'nicht verkauft und nicht für Werbung genutzt.',
              ),
            ),
            _Zeile(
              titel: 'Impressum',
              pfeil: true,
              onTap: () => _textSeite(
                'Impressum',
                'Das Impressum kommt hier vor dem Start der Beta hin.',
              ),
            ),
          ]),
          gruppe(.5, null, [
            _Zeile(
              key: const ValueKey('abmelden'),
              titel: 'Abmelden',
              pfeil: true,
              onTap: _abmelden,
            ),
            _Zeile(
              key: const ValueKey('konto-loeschen'),
              titel: 'Konto und alle Daten löschen',
              rot: true,
              pfeil: true,
              onTap: _loeschen,
            ),
          ]),
        ],
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({
    super.key,
    required this.titel,
    this.unter,
    this.hinten,
    this.vorne,
    this.schalter,
    this.pfeil = false,
    this.rot = false,
    this.onTap,
  });

  final String titel;
  final String? unter;
  final String? hinten;
  final Widget? vorne;
  final Widget? schalter;
  final bool pfeil;
  final bool rot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (vorne != null) ...[vorne!, const SizedBox(width: 11)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titel,
                  style: Glas.tText.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: rot ? const Color(0xFFEC9F8D) : Glas.text,
                  ),
                ),
                if (unter != null)
                  Text(unter!, style: Glas.tSoft.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
          if (hinten != null && hinten!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(hinten!, style: Glas.tSoft.copyWith(fontSize: 12.5)),
          ],
          ?schalter,
          if (pfeil)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right, size: 19, color: Glas.soft),
            ),
        ],
      ),
    ),
  );
}

class _Initiale extends StatelessWidget {
  const _Initiale(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0x1FE0BF7E),
      border: Border.all(color: const Color(0x66E0BF7E)),
    ),
    child: Text(text, style: Glas.tLabel.copyWith(fontSize: 14)),
  );
}

/// Gold switch like in the draft.
class _GoldSchalter extends StatelessWidget {
  const _GoldSchalter({super.key, required this.an, required this.onChanged});

  final bool an;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: an,
    child: GestureDetector(
      onTap: () => onChanged(!an),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 27,
        padding: const EdgeInsets.all(3),
        alignment: an ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: an ? CoachStyle.goldGradient : null,
          color: an ? null : const Color(0x1FFFECDC),
          border: an ? null : Border.all(color: Glas.edge),
          boxShadow: an
              ? const [BoxShadow(color: Color(0x4DE0BF7E), blurRadius: 12)]
              : null,
        ),
        child: Container(
          width: 21,
          height: 21,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: an ? CoachStyle.goldInk : Glas.soft,
          ),
        ),
      ),
    ),
  );
}
