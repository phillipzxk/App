import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../ernaehrung/ernaehrung_coach.dart' show fotoAufnahme;
import '../sleep/schlafzeiten.dart';
import '../konto/konto_ui.dart' show bewegungAn;
import '../training/training_widgets.dart';
import '../ui/coach_widgets.dart';
import '../ui/coach_style.dart';
import 'morgen_szene.dart';
import 'schlaf_logik.dart';
import 'schritt_weg.dart';
import 'schritt_zaehler.dart';

/// The task of the morning: the chosen one, but "Licht an" instead of the
/// sky photo while it is still dark (Phillip 2026-11-01).
String aufgabeHeute(String gewaehlt, DateTime jetzt) {
  if (gewaehlt != 'foto') return gewaehlt;
  final m = jetzt.hour * 60 + jetzt.minute;
  return nochDunkel(jetzt, m - 15) ? 'licht' : 'foto';
}

/// How bright a photo is, 0 (black) to 1 (white), from a tiny copy.
Future<double> helligkeit(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 24,
    targetHeight: 24,
  );
  final bild = (await codec.getNextFrame()).image;
  final daten = await bild.toByteData();
  if (daten == null) return 0;
  var summe = 0.0;
  final n = daten.lengthInBytes ~/ 4;
  for (var i = 0; i < n; i++) {
    final r = daten.getUint8(i * 4);
    final g = daten.getUint8(i * 4 + 1);
    final b = daten.getUint8(i * 4 + 2);
    summe += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
  }
  return n == 0 ? 0 : summe / n;
}

/// A room with the big light on is at least this bright.
const hellGenug = .33;

/// Checks a photo for "Licht an"; true when bright enough.
typedef HellPruefung = Future<bool> Function(String base64);

Future<bool> hellPruefen(String base64) async =>
    await helligkeit(base64Decode(base64)) >= hellGenug;

/// After the real alarm: the task first, then "Du bist wach", then on to
/// the check-in (vault Umsetzung/Echter Wecker, Entwurf 1).
class WeckerAufgabe extends StatefulWidget {
  const WeckerAufgabe({
    super.key,
    required this.name,
    required this.aufgabe,
    required this.geklingelt,
    required this.onFertig,
    this.heute,
    this.clock = DateTime.now,
    this.pruefen = hellPruefen,
    this.schritte = 30,
    this.zaehler = const KeinZaehler(),
    this.wahl,
    this.onMorgen,
  });

  final String name;

  /// As chosen in "Dein Wecker": foto, frage or schritte.
  final String aufgabe;

  /// When the alarm rang (for "2 Minuten nach dem Wecker").
  final DateTime geklingelt;

  /// One sentence about today, e.g. "Heute: Push um 17:30."
  final String? heute;
  final VoidCallback onFertig;
  final DateTime Function() clock;
  final HellPruefung pruefen;

  /// How many steps for the step task.
  final int schritte;
  final SchrittZaehler zaehler;
  final SchrittWahlStore? wahl;

  /// The morning for the coach, e.g. "Heute Morgen: 30 Schritte in 41
  /// Sekunden, 2 Minuten nach dem Wecker."
  final ValueChanged<String>? onMorgen;

  @override
  State<WeckerAufgabe> createState() => _WeckerAufgabeState();
}

class _WeckerAufgabeState extends State<WeckerAufgabe> {
  late final String _aufgabe = aufgabeHeute(widget.aufgabe, widget.clock());
  String? _fehler;
  String? _schritteSatz;
  bool _prueft = false;
  DateTime? _wach;

  void _geschafft() => setState(() => _wach = widget.clock());

  Future<void> _los() async {
    switch (_aufgabe) {
      case 'foto' || 'licht':
        final bild = await fotoAufnahme();
        if (!mounted) return;
        if (bild == null) {
          setState(() => _fehler = 'Kein Foto. Versuch es nochmal.');
          return;
        }
        if (_aufgabe == 'licht') {
          setState(() => _prueft = true);
          final hell = await widget.pruefen(bild);
          if (!mounted) return;
          setState(() => _prueft = false);
          if (!hell) {
            setState(
              () => _fehler =
                  'Noch zu dunkel. Mach das große Licht an und versuch es '
                  'nochmal.',
            );
            return;
          }
        }
        _geschafft();
      default:
        _geschafft();
    }
  }

  void _schritteFertig(int n, Duration dauer) {
    final jetzt = widget.clock();
    widget.onMorgen?.call(
      morgenSatz(n, dauer, jetzt.difference(widget.geklingelt).inMinutes),
    );
    setState(() {
      _schritteSatz = schritteSatz(n, dauer);
      _wach = jetzt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wach = _wach;
    if (_aufgabe == 'schritte' && wach == null) {
      return SchrittWeg(
        ziel: widget.schritte,
        zaehler: widget.zaehler,
        wahl: widget.wahl,
        clock: widget.clock,
        onFertig: _schritteFertig,
      );
    }
    if (wach != null) {
      return _WachSeite(
        name: widget.name,
        geklingelt: widget.geklingelt,
        wach: wach,
        heute: widget.heute,
        licht: _aufgabe == 'licht',
        schritte: _aufgabe == 'schritte' ? widget.schritte : 0,
        schritteSatz: _schritteSatz,
        onFertig: widget.onFertig,
      );
    }
    return Scaffold(
      backgroundColor: CoachStyle.page,
      body: MorgenSzene(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _aufgabeKarte(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _aufgabeKarte() {
    final (titel, text, knopf) = switch (_aufgabe) {
      'licht' => (
        'Licht an',
        'Draußen ist es noch dunkel. Mach das große Licht an (oder deine '
            'Tageslichtlampe) und fotografier den hellen Raum.',
        'Hellen Raum fotografieren',
      ),
      'foto' => (
        'Foto vom Himmel',
        'Geh ans Fenster und mach ein Foto vom Himmel. Dann ist dein Morgen '
            'offiziell gestartet.',
        'Himmel fotografieren',
      ),
      _ => (
        'Wie bist du aufgewacht?',
        'Nebel, Dämmerung oder Sonnenaufgang? Ehrlich antworten, dann ist '
            'der Wecker aus.',
        'Beantwortet',
      ),
    };
    return Container(
      key: const ValueKey('wecker-aufgabe-karte'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0x991E1812),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x4DF3D79A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUFGABE',
            style: tSoft.copyWith(
              color: const Color(0xFFF3D79A),
              letterSpacing: 1.6,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(titel, style: tTitel.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text(text, style: tText),
          if (_fehler != null) ...[
            const SizedBox(height: 10),
            Text(
              _fehler!,
              key: const ValueKey('wecker-aufgabe-fehler'),
              style: tSoft.copyWith(color: const Color(0xFFF3D79A)),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('wecker-aufgabe-los'),
              style: FilledButton.styleFrom(
                backgroundColor: CoachStyle.gold,
                foregroundColor: CoachStyle.goldInk,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: const StadiumBorder(),
              ),
              onPressed: _prueft ? null : _los,
              child: Text(_prueft ? 'Ich schaue …' : knopf),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ist die Aufgabe nach 3 Minuten nicht erledigt, klingelt der '
            'Wecker noch einmal.',
            style: tSoft.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// "Du bist wach" in the morning scene (Entwurf 3): the sun breaks through,
/// a sprout grows, the lines come in one after another and the coach types
/// one short sentence about the day.
class _WachSeite extends StatefulWidget {
  const _WachSeite({
    required this.name,
    required this.geklingelt,
    required this.wach,
    required this.heute,
    required this.licht,
    required this.schritte,
    required this.schritteSatz,
    required this.onFertig,
  });

  final String name;
  final DateTime geklingelt;
  final DateTime wach;
  final String? heute;
  final bool licht;
  final int schritte;
  final String? schritteSatz;
  final VoidCallback onFertig;

  @override
  State<_WachSeite> createState() => _WachSeiteState();
}

class _WachSeiteState extends State<_WachSeite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    bewegungAn ? _c.forward() : _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int get _spaeter => widget.wach.difference(widget.geklingelt).inMinutes;

  /// The coach's line: honest about the start, then today, then light.
  String get _coach => [
    _spaeter <= 2
        ? 'Starker Start.'
        : _spaeter <= 10
        ? 'Gut, du bist auf.'
        : 'Spät, aber du bist auf. Das zählt.',
    ?widget.heute,
    widget.licht
        ? 'Lass das Licht an, dann der Check-in.'
        : 'Jetzt kurz ans Licht, dann der Check-in.',
  ].join(' ');

  double _ab(double von, double dauer) =>
      ((_c.value * 3.2 - von) / dauer).clamp(0.0, 1.0);

  Widget _rein(double von, Widget kind) {
    final t = Curves.easeOutCubic.transform(_ab(von, .7));
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zeit = formatUhrzeit(widget.wach.hour * 60 + widget.wach.minute);
    final nach = _spaeter <= 0
        ? 'direkt nach dem Wecker'
        : _spaeter == 1
        ? '1 Minute nach dem Wecker'
        : '$_spaeter Minuten nach dem Wecker';
    return Scaffold(
      backgroundColor: CoachStyle.page,
      body: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final coach = _coach;
          final getippt = (coach.length * _ab(1.6, 1.4)).round();
          return MorgenSzene(
            schritte: widget.schritte,
            ziel: math.max(1, widget.schritte),
            durch: widget.schritte > 0
                ? 1
                : Curves.easeOut.transform(_ab(0, 1.2)),
            trieb: Curves.easeOut.transform(_ab(.4, 1.4)),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x8C0D0B08),
                    Color(0x330D0B08),
                  ],
                  stops: [.38, .62, 1],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    key: const ValueKey('wecker-wach'),
                    children: [
                      const Spacer(flex: 5),
                      _rein(
                        .2,
                        GoldText(
                          widget.name.isEmpty
                              ? 'Du bist wach.'
                              : 'Du bist wach, ${widget.name}.',
                          style: tTitel.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _rein(
                        .45,
                        Text(
                          '$zeit aufgestanden, $nach.',
                          textAlign: TextAlign.center,
                          style: tText.copyWith(fontSize: 14),
                        ),
                      ),
                      if (widget.schritteSatz != null) ...[
                        const SizedBox(height: 12),
                        _rein(
                          .7,
                          Container(
                            key: const ValueKey('wecker-schritte-satz'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x8C120F0B),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: const Color(0x73E0BF7E),
                              ),
                            ),
                            child: Text(
                              widget.schritteSatz!,
                              style: tText.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _rein(
                        1.1,
                        Container(
                          key: const ValueKey('wecker-coach'),
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xB818140F),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x38E0BF7E)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFF6DC9C),
                                      Color(0xFFC99A52),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.spa_outlined,
                                  size: 16,
                                  color: CoachStyle.goldInk,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                // The rest stays invisible so the card
                                // keeps its height while the coach types.
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: coach.substring(0, getippt),
                                      ),
                                      TextSpan(
                                        text: coach.substring(getippt),
                                        style: const TextStyle(
                                          color: Color(0x00000000),
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: tText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      _rein(
                        1.6,
                        SizedBox(
                          width: 300,
                          child: FilledButton(
                            key: const ValueKey('wecker-weiter'),
                            style: FilledButton.styleFrom(
                              backgroundColor: CoachStyle.goldLight,
                              foregroundColor: CoachStyle.goldInk,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: const StadiumBorder(),
                              textStyle: tTitel.copyWith(fontSize: 14.5),
                            ),
                            onPressed: widget.onFertig,
                            child: const Text('Weiter zum Check-in'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
