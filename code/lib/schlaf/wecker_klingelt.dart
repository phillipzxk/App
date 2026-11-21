import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/coach_style.dart';
import 'morgen_szene.dart';

/// The ringing alarm on Android (vault Umsetzung/Android nachziehen.md,
/// Entwurf 1): the same morning sky as the task, the time, "Guten Morgen"
/// and two buttons. Shows over the lock screen; the iPhone shows Apple's
/// own alarm screen instead.
class WeckerKlingeltSeite extends StatefulWidget {
  const WeckerKlingeltSeite({
    super.key,
    required this.name,
    required this.clock,
    required this.schlummern,
    required this.onAntwort,
  });

  final String name;
  final DateTime Function() clock;

  /// Whether "5 Min" is offered (the setting on the alarm page).
  final bool schlummern;

  /// True for "Aufstehen", false for "5 Min".
  final ValueChanged<bool> onAntwort;

  @override
  State<WeckerKlingeltSeite> createState() => _WeckerKlingeltState();
}

const _tage = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _monate = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

/// "Sa, 22. November".
String weckerDatum(DateTime t) =>
    '${_tage[t.weekday - 1]}, ${t.day}. ${_monate[t.month - 1]}';

String _zwei(int x) => x.toString().padLeft(2, '0');

class _WeckerKlingeltState extends State<WeckerKlingeltSeite> {
  late Timer _uhr;
  bool _fertig = false;

  @override
  void initState() {
    super.initState();
    _uhr = Timer.periodic(const Duration(seconds: 10), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _uhr.cancel();
    super.dispose();
  }

  void _antwort(bool aufstehen) {
    if (_fertig) return;
    _fertig = true;
    widget.onAntwort(aufstehen);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.clock();
    final name = widget.name.trim();
    const creme = Color(0xFFFFF6E6);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0806),
      // The sun halfway up: the morning is coming, the steps of the task
      // bring it all the way.
      body: MorgenSzene(
        schritte: 1,
        ziel: 2,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              children: [
                const SizedBox(height: 56),
                Text(
                  weckerDatum(t),
                  key: const ValueKey('wecker-datum'),
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xD9FFF6E6),
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_zwei(t.hour)}:${_zwei(t.minute)}',
                  key: const ValueKey('wecker-uhr'),
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    color: creme,
                    letterSpacing: -1.5,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name.isEmpty ? 'Guten Morgen' : 'Guten Morgen, $name',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: creme,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (widget.schlummern) ...[
                      Expanded(
                        child: _Knopf(
                          key: const ValueKey('wecker-schlummern'),
                          text: '5 Min',
                          icon: Icons.bedtime_outlined,
                          gold: false,
                          onTap: () => _antwort(false),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _Knopf(
                        key: const ValueKey('wecker-aufstehen'),
                        text: 'Aufstehen',
                        icon: Icons.wb_sunny_rounded,
                        gold: true,
                        onTap: () => _antwort(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Knopf extends StatelessWidget {
  const _Knopf({
    super.key,
    required this.text,
    required this.icon,
    required this.gold,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final bool gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final farbe = gold ? CoachStyle.goldInk : const Color(0xFFFFF6E6);
    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: gold
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF6E6C2), Color(0xFFE2C48A)],
                  )
                : null,
            color: gold ? null : const Color(0x24FFFFFF),
            border: gold ? null : Border.all(color: const Color(0x40FFFFFF)),
            boxShadow: gold
                ? const [
                    BoxShadow(
                      color: Color(0x55E2C48A),
                      blurRadius: 24,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: farbe),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: farbe,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
