import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../ernaehrung/ernaehrung_coach.dart' show fotoAufnahme;
import '../sleep/schlafzeiten.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
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
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: wach != null
                ? const [Color(0xFF5B84AD), Color(0xFFF2D39A)]
                : _aufgabe == 'licht'
                ? const [Color(0xFF0E0C14), Color(0xFF2B2438)]
                : const [Color(0xFF2B2B44), Color(0xFF6D7FA0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: wach == null ? _aufgabeKarte() : _wachKarte(wach),
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

  Widget _wachKarte(DateTime wach) {
    final spaeter = wach.difference(widget.geklingelt).inMinutes;
    final zeit = formatUhrzeit(wach.hour * 60 + wach.minute);
    final nach = spaeter <= 0
        ? 'direkt nach dem Wecker'
        : spaeter == 1
        ? '1 Minute nach dem Wecker'
        : '$spaeter Minuten nach dem Wecker';
    return Column(
      key: const ValueKey('wecker-wach'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, size: 60, color: Colors.white),
        const SizedBox(height: 10),
        Text(
          widget.name.isEmpty
              ? 'Du bist wach.'
              : 'Du bist wach, ${widget.name}.',
          textAlign: TextAlign.center,
          style: tTitel.copyWith(fontSize: 24, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          [
            '$zeit aufgestanden, $nach.',
            ?widget.heute,
            _aufgabe == 'licht'
                ? 'Lass das Licht an, dann der Check-in.'
                : 'Jetzt kurz ans Licht, dann der Check-in.',
          ].join(' '),
          textAlign: TextAlign.center,
          style: tText.copyWith(color: Colors.white),
        ),
        if (_schritteSatz != null) ...[
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('wecker-schritte-satz'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x8CFFFFFF),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _schritteSatz!,
              style: tText.copyWith(
                color: CoachStyle.goldInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: 280,
          child: FilledButton(
            key: const ValueKey('wecker-weiter'),
            style: FilledButton.styleFrom(
              backgroundColor: CoachStyle.gold,
              foregroundColor: CoachStyle.goldInk,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: const StadiumBorder(),
            ),
            onPressed: widget.onFertig,
            child: const Text('Weiter zum Check-in'),
          ),
        ),
      ],
    );
  }
}
