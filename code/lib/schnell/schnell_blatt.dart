import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'schnell_eintrag.dart';

/// The round gold button next to the glass bar.
class SchnellKnopf extends StatefulWidget {
  const SchnellKnopf({super.key, required this.onTap, this.onHalten});
  final VoidCallback onTap;

  /// Long press: open and start talking right away.
  final VoidCallback? onHalten;

  @override
  State<SchnellKnopf> createState() => _SchnellKnopfState();
}

class _SchnellKnopfState extends State<SchnellKnopf>
    with SingleTickerProviderStateMixin {
  late final bool _lebendig = !WidgetsBinding.instance.runtimeType
      .toString()
      .contains('Test');
  late final _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (_lebendig) _ring.repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Schnell-Eintrag',
      child: GestureDetector(
        key: const ValueKey('schnell-knopf'),
        onTap: widget.onTap,
        onLongPress: widget.onHalten,
        child: SizedBox.square(
          dimension: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ring,
                builder: (_, _) => Transform.scale(
                  scale: .85 + _ring.value * .5,
                  child: Opacity(
                    opacity: _lebendig ? (1 - _ring.value) * .7 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x80F0D49A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CoachStyle.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66F0D49A),
                      blurRadius: 22,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 26, color: CoachStyle.goldInk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the sheet; returns what to file, or null when closed.
Future<List<SchnellEintrag>?> zeigeSchnellEintrag(
  BuildContext context, {
  required String name,
  required Future<SchnellAntwort?> Function(String text) frageCoach,
  required List<Gegenfrage> Function(List<SchnellEintrag> e) gegenfragen,
  List<SchnellVorschlag> vorschlaege = const [],
  bool sofortSprechen = false,
  String? kalender,
}) => showModalBottomSheet<List<SchnellEintrag>>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0xA6000000),
  builder: (_) => SchnellBlatt(
    name: name,
    frageCoach: frageCoach,
    gegenfragen: gegenfragen,
    vorschlaege: vorschlaege,
    sofortSprechen: sofortSprechen,
    kalender: kalender,
  ),
);

class SchnellBlatt extends StatefulWidget {
  const SchnellBlatt({
    super.key,
    required this.name,
    required this.frageCoach,
    required this.gegenfragen,
    this.vorschlaege = const [],
    this.sofortSprechen = false,
    this.kalender,
  });
  final List<SchnellVorschlag> vorschlaege;

  /// The connected calendar's name: appointments say they go there.
  final String? kalender;
  final String name;
  final Future<SchnellAntwort?> Function(String text) frageCoach;
  final List<Gegenfrage> Function(List<SchnellEintrag> e) gegenfragen;
  final bool sofortSprechen;

  @override
  State<SchnellBlatt> createState() => _SchnellBlattState();
}

class _Karte {
  _Karte(this.e, {this.gegen});
  final SchnellEintrag e;

  /// Set for a follow-up card: answered with yes/no first.
  final Gegenfrage? gegen;

  /// null: not answered (only asked cards), true: keep, false: drop.
  bool? ja;
  bool get behalten =>
      ja != false && ((e.frage == null && gegen == null) || ja == true);
}

class _SchnellBlattState extends State<SchnellBlatt> {
  final _text = TextEditingController();
  final _sprache = SpeechToText();
  bool _hoert = false;
  bool _laedt = false;
  String? _fehler;
  String? _satz;
  List<_Karte>? _karten;

  @override
  void initState() {
    super.initState();
    if (widget.sofortSprechen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mikro());
    }
  }

  @override
  void dispose() {
    if (_hoert) _sprache.stop();
    _text.dispose();
    _fokus.dispose();
    super.dispose();
  }

  Future<void> _mikro() async {
    if (_hoert) {
      await _sprache.stop();
      setState(() => _hoert = false);
      return;
    }
    var bereit = false;
    try {
      bereit = await _sprache.initialize(
        onStatus: (s) {
          if (mounted && (s == 'done' || s == 'notListening')) {
            setState(() => _hoert = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _hoert = false);
        },
      );
    } catch (_) {
      bereit = false;
    }
    if (!mounted) return;
    if (!bereit) {
      setState(
        () => _fehler =
            'Das Mikro geht hier gerade nicht. Tipp es einfach unten ein.',
      );
      return;
    }
    final vorher = _text.text.trim();
    setState(() {
      _hoert = true;
      _fehler = null;
    });
    await _sprache.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: 'de_DE',
      ),
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          _text.text = [
            if (vorher.isNotEmpty) vorher,
            r.recognizedWords,
          ].join(' ');
        });
      },
    );
  }

  final _fokus = FocusNode();

  void _nimm(SchnellVorschlag v) {
    setState(() {
      final alt = _text.text.trim();
      _text.text = alt.isEmpty
          ? v.text
          : '$alt${RegExp(r'[.,!?]$').hasMatch(alt) ? '' : ','} ${v.text}';
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
    });
    _fokus.requestFocus();
  }

  Future<void> _senden() async {
    final t = _text.text.trim();
    if (t.isEmpty || _laedt) return;
    if (_hoert) {
      await _sprache.stop();
      _hoert = false;
    }
    setState(() {
      _laedt = true;
      _fehler = null;
    });
    final a = await widget.frageCoach(t);
    if (!mounted) return;
    if (a == null || a.eintraege.isEmpty) {
      setState(() {
        _laedt = false;
        _fehler = a == null
            ? 'Dein Coach ist gerade nicht erreichbar. Versuch es gleich nochmal.'
            : 'Ich habe darin nichts zum Eintragen gefunden. Sag es nochmal anders?';
      });
      return;
    }
    final fragen = widget.gegenfragen(a.eintraege);
    setState(() {
      _laedt = false;
      _satz = a.satz;
      _karten = [
        for (final e in a.eintraege) _Karte(e),
        for (final g in fragen) _Karte(g.ja, gegen: g),
      ];
    });
  }

  void _fertig() {
    Navigator.of(context).pop([
      for (final k in _karten ?? const <_Karte>[])
        if (k.behalten) k.e,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final unten = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: unten),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2016), Color(0xFF17110B)],
          ),
          border: Border(top: BorderSide(color: Color(0x6BC9A25C))),
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: _karten == null ? _eingabe() : _sortiert(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _griff() => Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0x4DD9C4A0),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _eingabe() {
    final label = CoachStyle.goldLabel.copyWith(
      fontFamily: 'Sora',
      fontSize: 10.5,
      letterSpacing: 1.6,
      color: CoachStyle.goldLight,
    );
    return Column(
      key: const ValueKey('schnell-eingabe'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _griff(),
        Text('SCHNELL-EINTRAG', style: label),
        const SizedBox(height: 4),
        GoldText(
          widget.name.isEmpty ? 'Was gibt\'s?' : 'Was gibt\'s, ${widget.name}?',
          style: CoachStyle.title.copyWith(fontSize: 21),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sag einfach alles auf einmal. Ich sortiere es.',
          style: TextStyle(fontSize: 13, color: CoachStyle.inkSoft),
        ),
        const SizedBox(height: 18),
        Center(
          child: _MikroKnopf(hoert: _hoert, onTap: _mikro),
        ),
        const SizedBox(height: 10),
        _Welle(an: _hoert),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _hoert ? 'Ich höre zu …' : 'Tippen und sprechen',
            style: const TextStyle(fontSize: 12.5, color: CoachStyle.inkSoft),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('schnell-feld'),
                controller: _text,
                focusNode: _fokus,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, color: CoachStyle.cream),
                decoration: InputDecoration(
                  hintText: 'Oder hier tippen …',
                  hintStyle: const TextStyle(color: CoachStyle.inkSoft),
                  filled: true,
                  fillColor: const Color(0x40000000),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0x33C9A25C)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0x33C9A25C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: CoachStyle.gold),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              key: const ValueKey('schnell-senden'),
              onTap: _senden,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: _text.text.trim().isEmpty
                      ? null
                      : CoachStyle.goldGradient,
                  color: _text.text.trim().isEmpty
                      ? const Color(0x22C9A25C)
                      : null,
                ),
                child: _laedt
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CoachStyle.goldInk,
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward,
                        color: _text.text.trim().isEmpty
                            ? CoachStyle.inkSoft
                            : CoachStyle.goldInk,
                      ),
              ),
            ),
          ],
        ),
        if (_fehler != null) ...[
          const SizedBox(height: 10),
          Text(
            _fehler!,
            key: const ValueKey('schnell-fehler'),
            style: const TextStyle(fontSize: 13, color: Color(0xFFE39A7E)),
          ),
        ],
        if (widget.vorschlaege.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'GERADE PASSEND',
            style: CoachStyle.goldLabel.copyWith(
              fontFamily: 'Sora',
              fontSize: 9.5,
              letterSpacing: 1.4,
              color: CoachStyle.beigeLabel,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.vorschlaege.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _Rein(
                verzoegerung: Duration(milliseconds: 80 + i * 70),
                child: _VorschlagChip(
                  key: ValueKey('vorschlag-$i'),
                  v: widget.vorschlaege[i],
                  onTap: () => _nimm(widget.vorschlaege[i]),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sortiert() {
    final karten = _karten!;
    return Column(
      key: const ValueKey('schnell-sortiert'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _griff(),
        if ((_satz ?? '').isNotEmpty) ...[
          Row(
            children: [
              const CoachAvatar(size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _satz!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: CoachStyle.cream,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < karten.length; i++)
          if (karten[i].ja != false)
            _Rein(
              key: ValueKey('rein-$i'),
              verzoegerung: Duration(milliseconds: 120 + i * 140),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _karte(i, karten[i]),
              ),
            ),
        const SizedBox(height: 6),
        GestureDetector(
          key: const ValueKey('schnell-fertig'),
          onTap: _fertig,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: CoachStyle.goldGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'Passt so',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CoachStyle.goldInk,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Mit dem Kreuz nimmst du eine Karte raus.',
            style: TextStyle(fontSize: 12.5, color: CoachStyle.inkSoft),
          ),
        ),
      ],
    );
  }

  static IconData _icon(String art) => switch (art) {
    'mahlzeit' => Icons.restaurant,
    'training' => Icons.fitness_center,
    'termin' => Icons.event,
    'gewicht' => Icons.monitor_weight_outlined,
    'schlaf' => Icons.bedtime_outlined,
    'supplement' => Icons.medication_outlined,
    'durchgezogen' => Icons.landscape_outlined,
    _ => Icons.edit_note,
  };

  Widget _karte(int i, _Karte k) {
    final e = k.e;
    final frage = k.gegen?.frage ?? e.frage;
    final offen = frage != null && k.ja == null;
    return Container(
      key: ValueKey('schnell-karte-$i'),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2318), Color(0xFF1B140D)],
        ),
        border: Border.all(
          color: offen ? const Color(0x80C9A25C) : const Color(0x6BC9A25C),
          width: offen ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0x1FC9A25C),
              border: Border.all(color: const Color(0x33C9A25C)),
            ),
            child: Icon(
              k.gegen != null ? Icons.help_outline : _icon(e.art),
              size: 20,
              color: CoachStyle.goldLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.gegen != null
                      ? 'FRAGE VOM COACH'
                      : (e.frage != null
                            ? '${e.bereich} · Frage vom Coach'.toUpperCase()
                            : e.bereich.toUpperCase()),
                  style: CoachStyle.goldLabel.copyWith(
                    fontFamily: 'Sora',
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    color: CoachStyle.gold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  k.gegen != null ? k.gegen!.frage : e.anzeige,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CoachStyle.cream,
                  ),
                ),
                if (k.gegen == null && (e.frage ?? e.wohin).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    e.frage ??
                        (e.art == 'termin' && widget.kalender != null
                            ? 'in deinen ${widget.kalender}'
                            : e.wohin),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoachStyle.inkSoft,
                    ),
                  ),
                ],
                if (offen) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _wahl(
                        'schnell-ja-$i',
                        k.gegen?.jaText ?? 'Ja',
                        () => setState(() => k.ja = true),
                      ),
                      _wahl(
                        'schnell-nein-$i',
                        k.gegen?.neinText ?? 'Nein',
                        () => setState(() => k.ja = false),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!offen)
            k.ja == true || (frage == null)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Haken(),
                      GestureDetector(
                        key: ValueKey('schnell-weg-$i'),
                        onTap: () => setState(() => k.ja = false),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: CoachStyle.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _wahl(String key, String text, VoidCallback onTap) => GestureDetector(
    key: ValueKey(key),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x6BC9A25C)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: CoachStyle.goldLight),
      ),
    ),
  );
}

/// One suggestion: symbol and label in a glass pill; it flashes gold when
/// tapped.
class _VorschlagChip extends StatefulWidget {
  const _VorschlagChip({super.key, required this.v, required this.onTap});
  final SchnellVorschlag v;
  final VoidCallback onTap;

  @override
  State<_VorschlagChip> createState() => _VorschlagChipState();
}

class _VorschlagChipState extends State<_VorschlagChip> {
  bool _an = false;

  static IconData _icon(String i) => switch (i) {
    'essen' => Icons.restaurant,
    'training' => Icons.fitness_center,
    'schlaf' => Icons.bedtime_outlined,
    'supplement' => Icons.medication_outlined,
    'gewicht' => Icons.monitor_weight_outlined,
    'termin' => Icons.event,
    _ => Icons.landscape_outlined,
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      setState(() => _an = true);
      widget.onTap();
      Future.delayed(const Duration(milliseconds: 380), () {
        if (mounted) setState(() => _an = false);
      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(10, 0, 13, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _an
            ? CoachStyle.goldGradient
            : const LinearGradient(
                colors: [Color(0xFF2E2318), Color(0xFF221A11)],
              ),
        border: Border.all(
          color: _an ? Colors.transparent : const Color(0x59C9A25C),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon(widget.v.icon),
            size: 16,
            color: _an ? CoachStyle.goldInk : CoachStyle.goldLight,
          ),
          const SizedBox(width: 7),
          Text(
            widget.v.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _an ? CoachStyle.goldInk : CoachStyle.cream,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Haken extends StatelessWidget {
  const _Haken();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutBack,
    builder: (_, v, child) => Transform.scale(scale: v, child: child),
    child: Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: CoachStyle.goldGradient,
      ),
      child: const Icon(Icons.check, size: 15, color: CoachStyle.goldInk),
    ),
  );
}

/// Slides a card in after [verzoegerung].
class _Rein extends StatefulWidget {
  const _Rein({super.key, required this.verzoegerung, required this.child});
  final Duration verzoegerung;
  final Widget child;

  @override
  State<_Rein> createState() => _ReinState();
}

class _ReinState extends State<_Rein> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.verzoegerung, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (_, child) {
      final v = Curves.easeOutCubic.transform(_c.value);
      return Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      );
    },
  );
}

class _MikroKnopf extends StatelessWidget {
  const _MikroKnopf({required this.hoert, required this.onTap});
  final bool hoert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('schnell-mikro'),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-.3, -.4),
          colors: [Color(0xFFF7E2B2), Color(0xFFC49A55)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(hoert ? 0x8CF0D49A : 0x59F0D49A),
            blurRadius: hoert ? 46 : 34,
            spreadRadius: hoert ? 6 : 0,
          ),
        ],
      ),
      child: Icon(
        hoert ? Icons.stop_rounded : Icons.mic_none_rounded,
        size: 40,
        color: CoachStyle.goldInk,
      ),
    ),
  );
}

/// Small gold bars that move while the mic listens.
class _Welle extends StatefulWidget {
  const _Welle({required this.an});
  final bool an;

  @override
  State<_Welle> createState() => _WelleState();
}

class _WelleState extends State<_Welle> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didUpdateWidget(_Welle old) {
    super.didUpdateWidget(old);
    if (widget.an && !_c.isAnimating) _c.repeat();
    if (!widget.an && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 30,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 26; i++)
            Container(
              width: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              height: widget.an
                  ? 6 +
                        22 *
                            (.5 +
                                .5 *
                                    math.sin(_c.value * math.pi * 8 + i * .7)) *
                            (.4 + .6 * ((i * 37) % 10) / 10)
                  : 6,
              decoration: BoxDecoration(
                color: CoachStyle.goldLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    ),
  );
}

/// After "Passt so": [n] gold light dots fly from [von] up into the page
/// and fade out there.
void lichtpunkteFliegen(BuildContext context, Offset von, int n) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || n <= 0) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _Flug(von: von, n: n.clamp(1, 8), fertig: () => entry.remove()),
    ),
  );
  overlay.insert(entry);
}

class _Flug extends StatefulWidget {
  const _Flug({required this.von, required this.n, required this.fertig});
  final Offset von;
  final int n;
  final VoidCallback fertig;

  @override
  State<_Flug> createState() => _FlugState();
}

class _FlugState extends State<_Flug> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward().whenComplete(widget.fertig);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => CustomPaint(
      size: Size.infinite,
      painter: _FlugMaler(widget.von, widget.n, _c.value),
    ),
  );
}

class _FlugMaler extends CustomPainter {
  _FlugMaler(this.von, this.n, this.t);
  final Offset von;
  final int n;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < n; i++) {
      final ziel = Offset(
        size.width * (.2 + .6 * (n == 1 ? .5 : i / (n - 1))),
        size.height * (.3 + .12 * (i % 3)),
      );
      final k = ((t * 1.25) - i * .06).clamp(0.0, 1.0);
      final u = k * k * (3 - 2 * k);
      final p =
          Offset.lerp(von, ziel, u)! - Offset(0, math.sin(u * math.pi) * 90);
      final a = k < 1 ? 1.0 : (1 - (t - .8) * 5).clamp(0.0, 1.0);
      canvas.drawCircle(
        p,
        11,
        Paint()
          ..shader = RadialGradient(
            colors: [Color.fromRGBO(255, 240, 200, a), const Color(0x00F0C878)],
          ).createShader(Rect.fromCircle(center: p, radius: 11)),
      );
      if (k >= 1) {
        canvas.drawCircle(
          ziel,
          14 + (t - .8).clamp(0.0, 1.0) * 90,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Color.fromRGBO(240, 212, 154, a * .8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FlugMaler old) => old.t != t;
}
