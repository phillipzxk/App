import 'package:flutter/material.dart';

import 'abo_daten.dart';
import 'abo_logik.dart';
import 'abo_seite.dart';

/// Abo screen, then after buying the thank-you screen (vault
/// Umsetzung/Abo.md). Loads the week first.
class AboAblauf extends StatefulWidget {
  const AboAblauf({
    super.key,
    required this.name,
    required this.laden,
    required this.text,
    required this.kauf,
    required this.stand,
    required this.onStand,
    required this.onFertig,
    required this.clock,
    this.onZurueck,
  });

  final String name;
  final Future<WochenBild> Function() laden;
  final Future<String?> Function(WochenBild bild) text;
  final AboKauf kauf;
  final AboStand stand;

  /// Saves the new state (bought or without Abo).
  final Future<void> Function(AboStand neu) onStand;

  /// Done: back to Heute.
  final VoidCallback onFertig;
  final DateTime Function() clock;

  /// Only from the settings.
  final VoidCallback? onZurueck;

  @override
  State<AboAblauf> createState() => _AboAblaufState();
}

class _AboAblaufState extends State<AboAblauf> {
  WochenBild? _bild;
  Future<String?>? _text;
  AboStand? _gekauft;

  @override
  void initState() {
    super.initState();
    widget
        .laden()
        .catchError((Object e) {
          return WochenBild.aus(jetzt: widget.clock(), checkIns: const []);
        })
        .then((b) {
          if (!mounted) return;
          setState(() {
            _bild = b;
            _text = widget.text(b).catchError((Object _) => null);
          });
        });
  }

  Future<bool> _kaufen(AboPlan plan) async {
    final ok = await widget.kauf.kaufen(plan);
    if (!ok) return false;
    final neu = widget.stand.mitPlan(plan, widget.clock());
    await widget.onStand(neu);
    if (mounted) setState(() => _gekauft = neu);
    return true;
  }

  Future<void> _ohne() async {
    await widget.onStand(widget.stand.ohne());
    widget.onFertig();
  }

  @override
  Widget build(BuildContext context) {
    final g = _gekauft;
    if (g != null) {
      return AboDanke(
        name: widget.name,
        plan: g.plan!,
        naechsteZahlung: g.naechsteZahlung(widget.clock()),
        onWeiter: widget.onFertig,
      );
    }
    final b = _bild;
    if (b == null) {
      return const BernsteinHintergrund(child: SizedBox.expand());
    }
    return AboSeite(
      name: widget.name,
      bild: b,
      text: _text!,
      onKaufen: _kaufen,
      onOhne: _ohne,
      onZurueck: widget.onZurueck,
    );
  }
}
